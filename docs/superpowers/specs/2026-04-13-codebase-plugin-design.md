# Codebase Plugin Design

**Date:** 2026-04-13
**Status:** Approved for implementation
**Location:** `plugins/codebase/` in `jskswamy/claude-plugins`

---

## 1. Problem

When starting a new conversation — whether to brainstorm a feature, debug something, or explore unfamiliar code — Claude burns tokens doing repeated `Grep`, `Glob`, `Read` across the repo to build a mental model. A typical exploration session can cost 20+ tool calls and hundreds of thousands of tokens before any real work begins.

`codebase-memory-mcp` already indexes the codebase into a structural and semantic graph with 14 MCP tools. But nothing orchestrates those tools into a coherent UX or integrates them into existing workflows like brainstorming and planning.

The codebase plugin fills this gap. It provides intelligent codebase exploration commands that orchestrate `codebase-memory-mcp` queries, and a skill that automatically enriches brainstorming and planning sessions with indexed codebase knowledge.

---

## 2. What It Is Not

- **Not a code indexer** — `codebase-memory-mcp` handles indexing; this plugin queries it.
- **Not a code reviewer** — `quality-reviewer` in `task-executor` does that.
- **Not a static analysis tool** — no linting, no style checking.
- **Not a visual graph tool** — text output only. Visual rendering (sketch-note integration) is out of scope for v1.
- **Not project-specific** — works across any codebase that has `codebase-memory-mcp` configured.

---

## 3. Prerequisites

| Prerequisite | Purpose |
|---|---|
| `codebase-memory-mcp` | All intelligence comes from here. Plugin cannot run without it. |

---

## 4. Architecture

```
User question or workflow step
            │
   ┌────────▼─────────┐
   │  /codebase:ask    │◄── smart router (prompt-based intent classification)
   │                   │
   │  Classifies:      │
   │  - Location       │──► search_graph → get_code_snippet
   │  - Understanding  │──► get_architecture → trace_call_path → get_code_snippet
   │  - Impact         │──► routes to /codebase:impact
   │  - Similarity     │──► search_graph (semantic) + search_graph (relationship)
   │  - Onboarding     │──► get_architecture → search_graph → trace_call_path
   └──────────────────┘

   ┌──────────────────┐
   │ /codebase:impact  │──► detect_changes → trace_call_path (CRITICAL/HIGH) → search_graph (tests)
   └──────────────────┘

   ┌──────────────────┐
   │ /codebase:graph   │──► search_graph (resolve) → trace_call_path (in+out) → contextual explanation
   └──────────────────┘

   ┌──────────────────┐
   │ /codebase:index   │──► index_repository (thin wrapper)
   └──────────────────┘

   ┌──────────────────┐
   │  explore skill    │──► auto-triggers during brainstorming/planning "explore project context"
   │                   │    and on direct user codebase questions
   │                   │    routes through /codebase:ask logic
   └──────────────────┘
```

The plugin is a UX and orchestration layer. All intelligence comes from `codebase-memory-mcp`. The plugin's job is: pick the right MCP tools for the question, call them in the right sequence, and present results with contextual explanation.

---

## 5. Commands

### 5.1 `/codebase:ask <question>` — Smart Router

Takes a natural language question about the codebase. Classifies intent and routes to the right MCP tool sequence.

**Intent classification (prompt-based, not hard-coded):**

| Intent | Signal | MCP Tool Sequence |
|---|---|---|
| Location | "where does", "find", "which file" | `search_graph` (semantic_query) → `get_code_snippet` |
| Understanding | "how does", "explain", "walk me through" | `get_architecture` → `trace_call_path` (outbound from entry) → `get_code_snippet` for key nodes |
| Impact | "what's affected", "blast radius", "what breaks" | Routes to `/codebase:impact` internally |
| Similarity | "anything similar to", "what else does X" | `search_graph` (semantic_query) + `search_graph` (relationship filter) |
| Onboarding | "I want to add", "what should I know about" | `get_architecture` → `search_graph` (find similar implementations) → `trace_call_path` (interfaces/types to implement) |

**Output format:** File:line references with contextual explanation. The explanation covers:
- What this code does and why it exists
- How it relates to the user's question
- How it connects to other parts of the system (callers, consumers, related patterns)

No raw MCP JSON. The LLM synthesizes the MCP results into a narrative answer.

**Example:**

```
> /codebase:ask where does webhook validation happen?

Webhook validation lives in `internal/webhooks/validator.go:ValidatePayload` (line 23).

This function verifies the HMAC signature on incoming webhook payloads before
they reach any handler. It's called from the HTTP middleware chain in
`internal/server/middleware.go:WebhookAuth` (line 67), which is mounted on
all `/webhooks/*` routes.

The signature secret comes from `internal/config/secrets.go:WebhookSecret`
(line 12), loaded from environment at startup. Three handlers consume
validated payloads:
  - `internal/webhooks/github.go:HandlePush` (line 34)
  - `internal/webhooks/gitlab.go:HandleMerge` (line 41)
  - `internal/webhooks/custom.go:HandleEvent` (line 28)

There are tests in `internal/webhooks/validator_test.go` covering valid,
invalid, and expired signatures.
```

---

### 5.2 `/codebase:impact [--base <sha>]` — Change Impact Analysis

Shows what's affected by recent code changes, with blast radius and risk classification.

| Flag | Default | Meaning |
|---|---|---|
| `--base <sha>` | auto-detected | Compare HEAD against this SHA. Auto-detect: `@{u}` or prompt if no upstream. |

**Flow:**
1. Determine base SHA (auto-detect or user-provided).
2. Run `detect_changes` with the diff scope. Returns affected symbols with risk labels (CRITICAL/HIGH/MEDIUM/LOW).
3. For CRITICAL and HIGH items, run `trace_call_path` (inbound, depth 2) to show what depends on the changed code.
4. Check for affected tests via `search_graph` filtering on test files.
5. Present results grouped by risk level with contextual explanation.

**Output format:**

```
## Impact Analysis (base: abc1234..HEAD)

### CRITICAL
- `internal/auth/middleware.go:ValidateToken` (line 45)
  Changed the token validation flow. 12 callers across 4 packages
  depend on this — API gateway, admin panel, webhook handler,
  and the batch processor all route through here.
  Tests: 3 test files cover this (partial — no test for batch path)

### HIGH
- `internal/auth/types.go:Claims` (line 12)
  Added field to Claims struct. 8 consumers destructure this.
  Tests: covered

### MEDIUM
- `internal/auth/helpers.go:ParseHeader` (line 78)
  Refactored header parsing. Called by ValidateToken only.
  Tests: covered

No changes detected at LOW risk level.
```

---

### 5.3 `/codebase:graph <symbol>` — Symbol Traversal

Explores a symbol's relationships — who calls it, what it calls, what types it uses.

**Input:** Function name, type name, or fully qualified name. If ambiguous, `search_graph` resolves and prompts for disambiguation.

**Flow:**
1. `search_graph` to resolve the symbol to its qualified name(s). If multiple matches, present disambiguation.
2. `trace_call_path` — inbound (who calls this) + outbound (what this calls), default depth 2.
3. Synthesize contextual explanation of the symbol's role in the architecture.

**Output format:**

```
## writeJSON (internal/framework/response.go:34)

HTTP response helper — marshals data to JSON with content-type
headers. Used as the standard response writer across all BMC
handlers.

### Callers (12)
  internal/bmc/nvidia_gbx00/handlers.go:HandleGet (line 89)
  internal/bmc/nvidia_gbswitch/handlers.go:HandleGet (line 45)
  internal/bmc/liteon_powershelf/handlers.go:HandleGet (line 52)
  ... and 9 more

### Calls
  encoding/json.Marshal
  net/http.ResponseWriter.Header
  net/http.ResponseWriter.Write
```

---

### 5.4 `/codebase:index [--mode full|moderate|fast]` — Index Management

Thin wrapper over `codebase-memory-mcp`'s `index_repository` tool.

| Flag | Default | Meaning |
|---|---|---|
| `--mode full` | — | Full index with all semantic signals. Slowest, most complete. |
| `--mode moderate` | default | Structural + semantic similarity. Good balance. |
| `--mode fast` | — | Structural only, no semantic edges. Fastest. |

**Flow:**
1. Verify `codebase-memory-mcp` is available. If not, print error and exit.
2. Call `index_repository` with the selected mode.
3. Report completion with stats.
4. Write timestamp and mode to `.claude/codebase.local.md`.

**Output:**
```
Indexing codebase (moderate)...
✓ Indexed 847 files in 38.1s

Run /codebase:ask to explore your codebase.
```

---

## 6. Explore Skill — `skills/explore/SKILL.md`

Auto-triggers during brainstorming/planning "explore project context" steps and on direct user codebase questions.

**Trigger description:**
```
Use when exploring project context during brainstorming, planning,
or when the user asks about codebase architecture, structure, how
something works, where something happens, or what would be affected
by a change. Queries codebase-memory-mcp for indexed knowledge
before falling back to grep/glob/read.
```

**Behavior:**
1. Check if `codebase-memory-mcp` is available. If not, fall back to grep/glob/read silently — do not block the workflow.
2. Check index staleness from `.claude/codebase.local.md`. If `last_indexed` is >24h old, print a warning but proceed.
3. Based on context:
   - **Brainstorming/planning step:** Call `get_architecture` first for a high-level view, then targeted `search_graph` queries for the specific topic. Present results as grounded context for the rest of the session.
   - **Direct user question:** Route through `/codebase:ask` logic.

**Integration with superpowers brainstorming/planning:**

Superpowers skills are pure markdown with no extension hooks. Integration works through skill description matching: when brainstorming reaches "Explore project context", the explore skill's description matches that intent. Claude invokes it, gets indexed codebase knowledge, and uses that to ground the rest of the brainstorming/planning session.

No modification to superpowers is needed.

---

## 7. Plugin Settings — `.claude/codebase.local.md`

Stores user preferences across sessions. Created automatically on first use. Never committed — add to `.gitignore`.

**Format:**
```yaml
---
auto_index: ask        # always | never | ask
index_mode: moderate   # full | moderate | fast
last_indexed: 2026-04-13T10:00:00Z
---
```

| Setting | Values | Default | Meaning |
|---|---|---|---|
| `auto_index` | `always`, `never`, `ask` | `ask` | Controls whether commands auto-index before querying. |
| `index_mode` | `full`, `moderate`, `fast` | `moderate` | Mode passed to `index_repository` when auto-indexing. |
| `last_indexed` | ISO 8601 timestamp | — | Written by `/codebase:index` on success. Used for staleness warnings. |

**`auto_index` semantics:**

| Value | Behaviour |
|---|---|
| `always` | Index automatically before every query using `index_mode`. Slowest but always fresh. |
| `never` | Never auto-index. User runs `/codebase:index` on their own schedule. Staleness warning if >24h since last index. |
| `ask` | Prompt on first use per session: "Index the codebase before querying? (Yes, always / Yes, just this once / No, I'll index manually)". If a "save" option is selected, write the preference to `.claude/codebase.local.md`. |

---

## 8. Error Handling

| Situation | Behaviour |
|---|---|
| `codebase-memory-mcp` not available | Commands print "codebase-memory-mcp not found. Install and configure it before using /codebase commands." and exit. Explore skill falls back to grep/glob/read silently. |
| `index_repository` fails | `/codebase:index` prints the error and exits without updating `last_indexed`. |
| Index stale (>24h) and `auto_index: never` | Print staleness warning, proceed with query. Append "(index may be stale)" to output. |
| Symbol not found in graph | "Symbol not found in the index. Try `/codebase:index` to refresh, or check the name." |
| Ambiguous symbol (multiple matches) | Present disambiguation list with file:line for each match. User picks one. |
| `detect_changes` returns empty | "No changes detected between base and HEAD." |
| MCP tool call fails | Print the specific error. Suggest `/codebase:index --mode full` if it seems like an index issue. |

---

## 9. Plugin File Structure

```
plugins/codebase/
  .claude-plugin/
    plugin.json          name, version, description, keywords
  commands/
    ask.md               /codebase:ask command (smart router)
    impact.md            /codebase:impact command
    graph.md             /codebase:graph command
    index.md             /codebase:index command
  skills/
    explore/
      SKILL.md           auto-trigger skill for brainstorming/planning integration
  README.md              prerequisites, usage, examples

# user settings (not committed)
.claude/codebase.local.md
```

---

## 10. Marketplace Registration

Add to `.claude-plugin/marketplace.json`:

```json
{
  "name": "codebase",
  "description": "Intelligent codebase exploration powered by codebase-memory-mcp. Natural language queries, change impact analysis, symbol graph traversal, and automatic integration with brainstorming and planning workflows. Reduces token usage by querying a semantic index instead of manual grep/glob/read exploration.",
  "version": "0.1.0",
  "author": { "name": "Krishnaswamy Subramanian" },
  "source": "./plugins/codebase",
  "category": "code-intelligence",
  "tags": ["codebase", "exploration", "semantic-search", "impact-analysis", "codebase-memory"]
}
```

---

## 11. Out of Scope

- Building or maintaining a code index (delegated to `codebase-memory-mcp`)
- Visual graph rendering (sketch-note integration deferred to future version)
- Code review or quality analysis
- Static analysis or linting
- Project-specific rules or custom queries
- Modifying superpowers plugin source code
- Supporting alternative MCP servers (Codegraph, CKB) as backends
