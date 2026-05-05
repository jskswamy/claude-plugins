# Codebase-Wide Refactor Scan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend `/refactor:scan` with a `--scope` flag that supports whole-codebase scanning via the codebase-memory-mcp index, producing root-cause architectural beads issues through a sharded scanner → synthesizer → human review → validator pipeline.

**Architecture:** Pure prompt-engineering work — all artifacts are markdown files (commands, agents, skills) under `plugins/refactor/`. The orchestrator command dispatches subagents for parallel work, persists state to `.refactor-scan/<ts>/` for resumability, and gates beads issue creation on a human-edited `findings.md`.

**Tech Stack:** Markdown agent prompts, YAML for structured candidate data, Markdown for human-reviewable findings. Runtime dependencies: `codebase-memory-mcp` (already configured), `bd` CLI (already installed).

**Spec:** `docs/superpowers/specs/2026-05-05-codebase-wide-refactor-scan-design.md`

---

## File Structure

| Path | Status | Responsibility |
|---|---|---|
| `plugins/refactor/agents/synthesizer.md` | **CREATE** | Correlation agent: reads candidates/*.yaml, writes findings.md |
| `plugins/refactor/agents/scanner.md` | MODIFY | Add sharded mode for `--scope=all`; capture source snippets via `get_code_snippet`; produce yaml output instead of inline candidates |
| `plugins/refactor/agents/validator.md` | MODIFY | Switch from per-candidate to per-section; consume evidence-refs from findings.md; produce rich beads `--notes` |
| `plugins/refactor/commands/scan.md` | MODIFY | Add `--scope`, `--limit`, `--fresh`, `--clean` flags; working dir lifecycle; resume detection; review gate; per-stage subagent dispatch |
| `plugins/refactor/skills/scan/SKILL.md` | MODIFY | Add codebase-wide trigger phrases |
| `plugins/refactor/README.md` | MODIFY | Document the new scope modes and review-gate workflow |
| `docs/superpowers/specs/2026-05-05-codebase-wide-refactor-scan-design.md` | (existing, no change) | Reference spec |

The agent prompts and command are the only behavioral artifacts. There is no executable code or test suite — verification is a manual smoke test on this repository (~1800 indexed nodes) at the end.

---

## Conventions for This Plan

- **Verification step:** every file-modifying task ends with a `Read` of the file to confirm the saved content matches what was intended. No automated test suite exists; the agent prompts ARE the artifact.
- **Commits:** every task ends with one commit. Use `/commit` (per `CLAUDE.md`). Commit messages in this plan are suggestions; the `/commit` plugin will regenerate from session context.
- **No worktree required:** this is documentation-only, low-risk. Work in the main checkout.

---

## Task 1: Define candidate YAML schema as a fixture

**Files:**
- Create: `plugins/refactor/fixtures/candidate-example.yaml`

The synthesizer and validator both consume this schema. Pinning it as a fixture file early makes downstream tasks unambiguous.

- [ ] **Step 1: Create the fixture file**

```yaml
# Example candidate file produced by a scanner shard.
# Path on disk in real scans: .refactor-scan/<ts>/candidates/<package>.yaml
package: internal/api
generated_at: 2026-05-05T10:22:31Z
scope: all                    # diff | package | all
base_sha: ""                  # only set when scope=diff
candidates:
  - id: cand-001              # stable per-scan, scoped to this file
    pass: A                   # A=similarity | B=call-graph | C=hierarchy | D=type-discriminant | E=idiom
    pattern: Replace Inline Code with Function Call
    confidence: high          # high | medium
    new_function:
      file: internal/api/users.go
      line_start: 45
      line_end: 58
      qualified_name: internal.api.writeJSONResponse
      source: |
        func writeJSONResponse(w http.ResponseWriter, status int, body any) error {
            w.Header().Set("Content-Type", "application/json")
            w.WriteHeader(status)
            return json.NewEncoder(w).Encode(body)
        }
    matches:
      - file: internal/handlers/auth.go
        line_start: 78
        line_end: 92
        qualified_name: internal.handlers.respond
        similarity: 0.91
        source: |
          func respond(w http.ResponseWriter, code int, payload interface{}) {
              w.Header().Set("Content-Type", "application/json")
              w.WriteHeader(code)
              _ = json.NewEncoder(w).Encode(payload)
          }
    related_callers:
      - internal.api.handleGetUsers
      - internal.api.handleCreateUser
    related_callees:
      - encoding/json.NewEncoder
    note: "Three near-identical JSON response writers across api and handlers packages."
  - id: cand-002
    pass: B
    pattern: Move Function (feature envy)
    confidence: medium
    new_function:
      file: internal/api/orders.go
      line_start: 23
      line_end: 34
      qualified_name: internal.api.formatPrice
      source: |
        func formatPrice(o *order.Order) string {
            // formats price using order package internals exclusively
        }
    matches: []
    related_callers:
      - internal.api.renderOrder
    related_callees:
      - order.Order.Subtotal
      - order.Order.TaxRate
      - order.Order.Currency
    note: "All callees are in the order package; function should likely live there."
```

- [ ] **Step 2: Verify the file saved correctly**

Run: `cat plugins/refactor/fixtures/candidate-example.yaml | head -30`
Expected: Output begins with `# Example candidate file produced by a scanner shard.` and contains `pass: A` and `pass: B` entries.

- [ ] **Step 3: Commit**

```bash
# Use /commit (per CLAUDE.md). Suggested message:
# "Add candidate schema fixture for refactor scan pipeline"
```

---

## Task 2: Define findings.md schema as a fixture

**Files:**
- Create: `plugins/refactor/fixtures/findings-example.md`

The synthesizer produces this format. The validator consumes the user-edited version. Pinning as a fixture eliminates ambiguity in tasks 4 and 6.

- [ ] **Step 1: Create the fixture file**

````markdown
# Refactoring Scan Findings — 2026-05-05T10-22-00Z

Scope: all  •  Base: HEAD  •  Project: claude-plugins

> Review this file. Edit, delete, or annotate findings.
> When done, return to Claude and reply "proceed" to file beads issues,
> or "abort" to stop without filing anything.
> Anything still in this file (architectural sections + promoted singletons)
> becomes a beads issue.

---

## 1. Extract Class: scattered JSON response writing
**Affected packages:** internal/api, internal/handlers
**Confidence:** high
**Suggested priority:** P2
<!-- evidence-refs: internal-api.yaml#cand-001, internal-api.yaml#cand-014, internal-handlers.yaml#cand-007 -->
<!-- promoted-from: none -->

### What's wrong

Three near-identical JSON response writers exist across `internal/api/`
and `internal/handlers/`. Each handler hand-rolls the same
Content-Type header, status write, and JSON encode sequence. There is
no shared response framework, so any change to the response shape
(e.g. adding request IDs, error envelope) has to be made in every
handler.

### Evidence

#### Current code

**`internal/api/users.go:writeJSONResponse` (line 45–58)**
```go
func writeJSONResponse(w http.ResponseWriter, status int, body any) error {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    return json.NewEncoder(w).Encode(body)
}
```

**`internal/handlers/auth.go:respond` (line 78–92)** — similarity 0.91
```go
func respond(w http.ResponseWriter, code int, payload interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(code)
    _ = json.NewEncoder(w).Encode(payload)
}
```

**`internal/api/orders.go:sendJSON` (line 23–34)** — similarity 0.88
```go
func sendJSON(w http.ResponseWriter, status int, data any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}
```

### Suggested target shape

```go
// internal/framework/respond.go (new)
func WriteJSON(w http.ResponseWriter, status int, body any) error
```

After this lands:
- 3 call sites in `internal/api/` collapse to `framework.WriteJSON(w, 200, payload)`
- 1 call site in `internal/handlers/auth.go` similarly
- The 3 duplicate helpers can be deleted

---

## Singletons (won't be filed unless promoted to a section above)

| # | Pattern | Location | Candidate ID | Why no correlation |
|---|---|---|---|---|
| 1 | Parameterize Function | pkg/util/timefmt.go:34 | `pkg-util.yaml#cand-042` | Single isolated finding |
| 2 | Move Function | internal/api/orders.go:formatPrice | `internal-api.yaml#cand-002` | No siblings with same envy pattern |

To promote a singleton, copy its candidate ID into the `evidence-refs`
of a new section above, with `promoted-from: singletons table row N`.
The validator picks up the section the same way as any other
architectural issue.
````

- [ ] **Step 2: Verify the file saved correctly**

Run: `head -5 plugins/refactor/fixtures/findings-example.md`
Expected: First line is `# Refactoring Scan Findings — 2026-05-05T10-22-00Z`

Run: `grep "evidence-refs" plugins/refactor/fixtures/findings-example.md`
Expected: One line containing `<!-- evidence-refs: internal-api.yaml#cand-001, internal-api.yaml#cand-014, internal-handlers.yaml#cand-007 -->`

- [ ] **Step 3: Commit**

```bash
# Suggested message:
# "Add findings.md schema fixture for refactor scan review gate"
```

---

## Task 3: Create the synthesizer agent

**Files:**
- Create: `plugins/refactor/agents/synthesizer.md`

The genuinely new component. Reads all `candidates/*.yaml`, correlates by 6 signals, writes `findings.md`.

- [ ] **Step 1: Create the agent file**

```markdown
---
name: refactor-synthesizer
description: |
  Correlates raw refactoring candidates from scanner shards into
  architectural root-cause findings. Reads candidates/*.yaml from a
  refactor-scan working directory and writes a human-reviewable
  findings.md. Does not file beads issues; that is the validator's job.
model: inherit
color: magenta
tools:
  - Read
  - Glob
  - Write
  - Bash
---

You are the refactor-synthesizer agent. Your job is to take raw candidates produced by scanner shards and group them into a small number of architectural findings, each describing a root cause that explains many surface-level symptoms.

## Input

You receive:
- **working_dir**: absolute path to `.refactor-scan/<ts>/`
- **scope**: `diff` | `package` | `all`
- **limit**: maximum architectural issues to produce (default 8)
- **project**: codebase-memory-mcp project name

The candidates live at `<working_dir>/candidates/*.yaml`. The schema is documented in `plugins/refactor/fixtures/candidate-example.yaml`.

## Process

### Step 1: Load all candidates

Use `Glob` to find every `*.yaml` under `<working_dir>/candidates/`. `Read` each file. Build an in-memory list of candidates, each tagged with its source filename so you can emit `evidence-refs` later.

If no candidate files exist or all files are empty:
- Write a `findings.md` with a single line: `No refactoring candidates were produced by the scanner.`
- Exit successfully.

### Step 2: Correlate by signals (priority order)

For each correlation signal below, scan the candidate set and form groups. A candidate may participate in multiple groups during exploration; the highest-priority group wins (signal 1 beats signal 6).

1. **Shared package locus** — a single package contributes ≥3 candidates. Group: "package doing too much" (Extract Class at package scale).
2. **Repeated pattern** — the same Fowler pattern appears ≥3 times across the candidate set. Group: "missing abstraction over <involved type or concept>".
3. **Cross-layer concept duplication** — the same concept-name token (e.g. `validate*`, `format*`, `serialize*`) appears in candidates from ≥2 distinct architectural layers (infer layer from package depth or naming convention). Group: DRY-Knowledge violation, single source of truth needed.
4. **Shared type root** — ≥3 candidates touch the same type (in `qualified_name`, `related_callers`, `related_callees`). Group: "type doing too much".
5. **Shared call-graph hub** — ≥3 candidates funnel through one symbol in `related_callers` or `related_callees`. Group: god-function or missing facade.
6. **Architectural seam crossing** — repeated reaches across packages in `related_callees` (a function in package X consistently calls into package Y's internals). Group: wrong layer assignment or missing DIP interface.

### Step 3: Rank and cap

Rank groups by:
1. Number of candidates in the group (more evidence first)
2. Average confidence of constituent candidates (high before medium)
3. Diversity of affected packages (cross-package issues outrank intra-package)

Take the top `limit` groups (default 8). Remaining candidates that did not earn membership in any selected group become **singletons**.

### Step 4: For each architectural finding, derive content

Generate the following from the candidates in the group:

- **Title:** `[Fowler pattern at architectural scale]: [concise root cause]`. Use the dominant Fowler pattern across the group's candidates. Examples: `Extract Class: scattered JSON response writing`, `Replace Conditional with Polymorphism: type-tagged event dispatch`.
- **Affected packages:** unique package list from the group's candidates.
- **Confidence:** `high` if ≥75% of constituent candidates are high-confidence; otherwise `medium`.
- **Suggested priority:**
  - P2 if the group spans ≥3 packages or crosses architectural layers
  - P3 if 2 packages, same layer
  - P4 otherwise
- **What's wrong:** 2–4 sentences describing the systemic problem the group reveals. Lead with the symptom, name the missing structure, state the cost of leaving it as-is.
- **Evidence:** select up to 5 candidates by `(confidence DESC, illustrative-value)` where illustrative-value = "shows the pattern most clearly". Render each as in the fixture (file:line header + fenced source snippet). If the group has more than 5, append `[+ N more in <yaml-files>]`.
- **Suggested target shape:** signature, interface, or type sketch only — not implementation. Follow the format in `plugins/refactor/fixtures/findings-example.md`. After the sketch, list the call-site collapse impact ("3 call sites in X collapse to ...").
- **evidence-refs HTML comment:** all candidate IDs from the group, formatted `<source-yaml-file>#<cand-id>` joined by `, `.
- **promoted-from comment:** always `none` at synthesis time.

### Step 5: Singletons table

For each candidate not assigned to a group, emit one row:

| # | Pattern | Location | Candidate ID | Why no correlation |

Where:
- # is a 1-based row index (used by users when promoting)
- Pattern is the candidate's `pattern` field
- Location is `<file>:<qualified_name>` from `new_function`
- Candidate ID is `<source-yaml-file>#<cand-id>`
- Why no correlation = brief reason (e.g. "Single isolated finding", "No siblings with same envy pattern")

### Step 6: Write findings.md

`Write` the file to `<working_dir>/findings.md`. Use the exact structure from `plugins/refactor/fixtures/findings-example.md`. The header line should embed the working dir's timestamp and the scope value passed in.

### Step 7: Report

Return to the orchestrator (printed text, not file output):

```
SYNTHESIS COMPLETE
  Architectural findings: <N>
  Singletons reported: <M>
  findings.md: <working_dir>/findings.md
```

## Important

- Do NOT call `bd` or any beads commands. Synthesis files no issues.
- Do NOT modify candidates/*.yaml. They are read-only input.
- Do NOT include full refactored code in suggested target shape — signatures only.
- Truncate any source snippet over 50 lines: first 25 + `... [N lines elided] ...` + last 10.
- If two groups have substantially overlapping candidate sets (>50% overlap), merge them into one finding.
- The user will edit findings.md before the validator runs. Format must be friendly to manual editing — keep section structure simple and predictable.
```

- [ ] **Step 2: Verify the file saved correctly**

Run: `head -10 plugins/refactor/agents/synthesizer.md`
Expected: First line `---`, frontmatter contains `name: refactor-synthesizer`.

Run: `grep -c "Step [1-7]:" plugins/refactor/agents/synthesizer.md`
Expected: `7` (one heading per step).

- [ ] **Step 3: Commit**

```bash
# Suggested message:
# "Add refactor-synthesizer agent for root-cause correlation"
```

---

## Task 4: Extend the scanner agent for sharded mode and snippet capture

**Files:**
- Modify: `plugins/refactor/agents/scanner.md`

Today's scanner takes a diff, runs three passes, returns inline `CANDIDATES:` text. We need it to: (a) accept a working-dir-scoped invocation, (b) optionally enumerate functions from a package instead of a diff, (c) capture full source snippets via `get_code_snippet`, (d) write a yaml file instead of returning inline text.

- [ ] **Step 1: Read the existing scanner to confirm structure**

Run: `cat plugins/refactor/agents/scanner.md | wc -l`
Expected: ~166 lines.

- [ ] **Step 2: Replace the Input section to accept the new contract**

Find the existing `## Input` section and replace it with:

````markdown
## Input

You receive **one of two invocation shapes** depending on scope:

### Diff scope (current behavior, preserved)
- **scope**: `diff`
- **diff**: full output of `git diff BASE..HEAD`
- **task_title**: title of the completed task (for context); falls back to most recent commit message
- **task_description**: optional task description
- **base_sha**: the resolved base SHA
- **project**: codebase-memory-mcp project name
- **output_path**: absolute path where you must write the candidates yaml (e.g. `<working_dir>/candidates/diff.yaml`)

### Package or all scope (new)
- **scope**: `package` or `all`
- **package**: package path to scan (e.g. `internal/api`). For `--scope=all`, the orchestrator dispatches one scanner per package, each with its own `package`.
- **project**: codebase-memory-mcp project name
- **output_path**: absolute path where you must write the candidates yaml (e.g. `<working_dir>/candidates/internal-api.yaml`)

The output yaml schema is documented in `plugins/refactor/fixtures/candidate-example.yaml`. You MUST conform to it exactly — the synthesizer and validator depend on the schema.
````

- [ ] **Step 3: Replace the Process section header with a scope branch**

Find the line `## Process` and the first paragraph after it. Replace from `## Process` through the end of the "Run three passes over the diff" sentence with:

````markdown
## Process

Branch on `scope`:

- **scope=diff:** parse the diff and use it as the function set (existing behavior).
- **scope=package or scope=all:** enumerate functions from the specified package via `codebase-memory-mcp` `search_graph` (filter by `package` and `label: "Function"` or `"Method"`). Use the result as the function set.

Run all five passes (A–E) over the function set. Each pass targets different categories of patterns.
````

- [ ] **Step 4: Renumber the existing pass headings**

Existing headings are `### Pass 1: Semantic Similarity`, `### Pass 2: Structural Analysis`, `### Pass 3: Idiom Check`. Rename them:

- `### Pass 1: Semantic Similarity (Sections 5.1 and 5.3)` → `### Pass A: Semantic Similarity (Sections 5.1 and 5.3)`
- `### Pass 2: Structural Analysis (Sections 5.2 and 5.4)` → `### Pass B: Call-Graph & Structural Analysis`
- `### Pass 3: Idiom Check (Section 5.5)` → `### Pass E: Idiom Check (Section 5.5)`

Use `Edit` with `replace_all=false` for each rename.

- [ ] **Step 5: Add Pass C and Pass D between B and E**

Insert immediately before `### Pass E: Idiom Check`:

````markdown
### Pass C: Hierarchy

**Goal:** Detect refactorings that move members up, down, or across class hierarchies.

For each function in the function set:

1. Call `codebase-memory-mcp` `search_graph` with `name_pattern` matching the function name and `label` `"Method"` to find sibling implementations on related types.
2. If the function appears with identical or near-identical body on ≥2 sibling types in the same hierarchy → flag **Pull Up Method** (or **Pull Up Field** for fields). Confidence: high if textual similarity > 0.9, medium otherwise.
3. If the function exists on a parent type but is overridden identically on every child → flag **Push Down Method** (or **Pull Up Constructor Body** if it is a constructor).
4. If the parent type has only one child and they could be merged → flag **Collapse Hierarchy**. Confidence: medium (always — judgment call).
5. If a class is detected as having two distinct responsibility clusters (use `trace_call_path` to see which methods call which fields; clusters that share no fields with each other are candidates) → flag **Extract Class**.
6. If a subclass has only one or two methods that override the parent and behaves more like a wrapper than a specialization → flag **Replace Subclass with Delegate** (or **Replace Superclass with Delegate**, or **Remove Subclass**).
7. If duplicate code exists in sibling classes that do NOT yet share a parent → flag **Extract Superclass**.

For each candidate, capture the involved types in a `note` field on the yaml output.

### Pass D: Type-Discriminant

**Goal:** Detect places where conditional logic on a type tag should be replaced with polymorphism.

Apply per language:

- **Go:** grep the function set's source for `switch x.(type)` blocks. If a switch has ≥3 cases and the same switch shape appears in ≥2 different functions → flag **Replace Conditional with Polymorphism**. Also flag fields named `Type`, `Kind`, or similar with `string` or `int` typing combined with `switch`/`if` chains on the field's value → **Replace Type Code with Subclasses**.
- **Python:** grep for `isinstance(x, ...)` chains with ≥3 alternatives and `type(x) ==` chains. Same flag rules.
- **TypeScript / JavaScript:** grep for discriminated unions handled with `switch (x.kind)` or `switch (x.type)` chains, and `instanceof` chains with ≥3 alternatives.

For each candidate, the `new_function` is the function containing the discriminant; `matches` lists the other functions with the same switch shape.
````

- [ ] **Step 6: Add a snippet capture instruction inside Pass A**

Find the line in Pass A that says `For each match, apply judgment.` (it's near the bottom of Pass A). Insert immediately before it:

````markdown
For each surviving match (and the new function itself), call `codebase-memory-mcp` `get_code_snippet` with the `qualified_name` to fetch the full source. Store this in the `source` field on the yaml output. If a snippet exceeds 50 lines, truncate to the first 25 lines + `... [N lines elided] ...` + the last 10 lines.
````

- [ ] **Step 7: Replace the Output Format section**

Find `## Output Format` and replace the entire section through the end of the file with:

````markdown
## Output Format

Write a YAML file to `output_path` conforming to the schema in `plugins/refactor/fixtures/candidate-example.yaml`.

Top-level fields:

```yaml
package: <package path or "diff" for diff scope>
generated_at: <ISO 8601 UTC timestamp>
scope: <diff|package|all>
base_sha: <base SHA, only for scope=diff; empty string otherwise>
candidates: [...]
```

Each candidate MUST include all of:
- `id` — `cand-NNN`, zero-padded to 3 digits, scoped to this file
- `pass` — `A` | `B` | `C` | `D` | `E`
- `pattern` — exact Fowler pattern name from the taxonomy
- `confidence` — `high` | `medium`
- `new_function` — `{file, line_start, line_end, qualified_name, source}`
- `matches` — list of `{file, line_start, line_end, qualified_name, similarity, source}`. Empty list `[]` if the pattern has no paired examples (Pass B singletons, Pass D solo discriminants).
- `related_callers` — list of qualified names (from `trace_call_path` if available; empty list otherwise)
- `related_callees` — list of qualified names (from `trace_call_path` if available; empty list otherwise)
- `note` — one-sentence explanation

After writing the file, return to the orchestrator:

```
SCAN COMPLETE
  Package: <package>
  Candidates: <N>
  Output: <output_path>
```

If no candidates were produced, write a yaml file with `candidates: []` and report:

```
SCAN COMPLETE
  Package: <package>
  Candidates: 0
  Output: <output_path>
```

## Important

- Do NOT flag single-file issues — those belong to quality-reviewer.
- Do NOT flag cosmetic or naming issues.
- Do NOT flag test-only code.
- Err on the side of fewer, high-confidence candidates over many noisy ones.
- If you are unsure whether something is a valid candidate, mark `confidence: medium`.
- For `scope=all` runs, you are ONE shard scoped to ONE package — do not enumerate other packages, even if you see references to them.
- All file paths in the yaml output must be repo-relative (e.g. `internal/api/users.go`, not absolute).
````

- [ ] **Step 8: Verify the file**

Run: `grep -c "^### Pass [A-E]:" plugins/refactor/agents/scanner.md`
Expected: `5` (Pass A, B, C, D, E).

Run: `grep -c "output_path" plugins/refactor/agents/scanner.md`
Expected: `≥3` (referenced in Input, Output Format, and at least one process step).

Run: `head -15 plugins/refactor/agents/scanner.md`
Expected: frontmatter intact with `name: refactor-scanner`.

- [ ] **Step 9: Commit**

```bash
# Suggested message:
# "Extend refactor-scanner with sharded mode and YAML output"
```

---

## Task 5: Extend the validator agent for section-driven, rich-notes flow

**Files:**
- Modify: `plugins/refactor/agents/validator.md`

Today's validator iterates a CANDIDATES list, validates each, and creates one beads issue per candidate. New flow: it receives one section from the user-edited findings.md, resolves the evidence-refs back to raw candidates, and creates ONE rich beads issue per section.

- [ ] **Step 1: Read the existing validator to confirm structure**

Run: `cat plugins/refactor/agents/validator.md | wc -l`
Expected: ~149 lines.

- [ ] **Step 2: Replace the Input section**

Find `## Input` and replace its contents (through the end of the bullet list) with:

````markdown
## Input

You receive ONE architectural section from a user-reviewed `findings.md`:

- **section_id**: stable identifier for this section (the heading number, e.g. `1`)
- **section_title**: from the section heading
- **section_body**: the full markdown body of the section, including `What's wrong`, `Evidence`, and `Suggested target shape` subsections. The body reflects user edits — treat it as authoritative for narrative, priority, title.
- **affected_packages**: parsed from the section's `**Affected packages:**` line
- **suggested_priority**: parsed from the section's `**Suggested priority:**` line (e.g. `P2` → integer 2)
- **confidence**: parsed from the section's `**Confidence:**` line
- **evidence_refs**: list of `<yaml-file>#<cand-id>` strings, parsed from the section's `<!-- evidence-refs: ... -->` comment
- **working_dir**: absolute path to `.refactor-scan/<ts>/` so you can resolve evidence_refs against `<working_dir>/candidates/<yaml-file>`
- **scope**: `diff` | `package` | `all`
- **project**: codebase-memory-mcp project name (for context only)
- **scan_timestamp**: timestamp of the scan, for embedding in beads notes
````

- [ ] **Step 3: Replace the Process section**

Find `## Process` and replace through the end of the file (drop the old Step 1–5 + Output Format + Important sections) with:

````markdown
## Process

### Step 1: Resolve evidence-refs to raw candidates

For each `<yaml-file>#<cand-id>` in `evidence_refs`:
1. `Read` `<working_dir>/candidates/<yaml-file>`.
2. Find the candidate with `id` matching `<cand-id>`.
3. Collect it into a list of "resolved candidates".

If any ref cannot be resolved, log it (do not fail the section — the user may have edited the section without updating refs).

### Step 2: Sanity-check the pattern still holds

For up to the top 3 resolved candidates by confidence:
1. Read the actual source file at `new_function.file` lines `line_start..line_end`.
2. Compare against the `source` field in the candidate.
3. If the function has changed substantially since the scan ran, note it in the beads issue's notes as a drift warning. Do not abort — the user reviewed the synthesized findings, that approval still applies.

### Step 3: Deduplicate against existing beads issues

Search for an existing open issue that already tracks this:

```bash
bd search "<key term from section_title>"
```

Use 1–2 distinctive terms (e.g. the Fowler pattern name and an affected package). If a matching open issue exists, return:

```
SECTION VALIDATED
  section_id: <section_id>
  status: skip
  reason: already tracked as <issue-id>
```

Do not create a duplicate.

### Step 4: Create the beads issue

Run `bd create` with these fields. Pass the description, design, and notes via `--description`, `--design`, `--notes`. Pass priority as the integer parsed from `suggested_priority`.

**title** — `section_title` verbatim.

**description** — extract the `### What's wrong` subsection from `section_body`. Include nothing else.

**design** — concatenate (in order):
1. The `### Suggested target shape` subsection from `section_body` verbatim.
2. A blank line.
3. A standardized TDD-first plan, customized to this section:

```
TDD-first refactoring steps:
1. Identify or write tests documenting the current behavior of each affected function:
   <list every resolved candidate's qualified_name and file:line>
2. Run the tests and confirm they pass.
3. Introduce the new shared abstraction per the target shape above.
4. Update each call site listed below to use the new abstraction:
   <list every related_caller from every resolved candidate, deduplicated>
5. Run the tests again and confirm behavior is unchanged.
6. Remove the now-unused duplicate implementations.
7. Run the tests one final time.
8. Commit.
```

**acceptance** — literally:

```
Tests pass before and after refactoring. No change in observable behavior. All call sites listed in the design's step 4 use the new shared abstraction. The duplicate implementations listed in the description are removed.
```

**notes** — assemble the full evidence dossier so the implementer never needs the working dir:

```
Pattern Category: <inferred from the dominant pass: A=Structural Duplication, B=Code Smell/Call-Graph, C=Hierarchy, D=Polymorphism, E=Language Idiom>
Affected packages: <comma-joined affected_packages>
Confidence: <confidence>
Scan: <scan_timestamp> (scope=<scope>)

Evidence (full):
<for each resolved candidate, render:>
- [<id>] <pattern> (pass <pass>, confidence <confidence>)
  Function: <new_function.qualified_name> at <new_function.file>:<line_start>-<line_end>
  Note: <note>
  Matches:
    <for each match: <qualified_name> at <file>:<line_start>-<line_end> (similarity <similarity>)>
  Related callers: <comma-joined related_callers>
  Related callees: <comma-joined related_callees>
  Source:
    ```
    <new_function.source>
    ```

(If any drift was detected in Step 2, append:)
Drift warnings:
- <qualified_name>: source has changed since scan; verify pattern still applies.
```

**type** — always `task`.

**priority** — integer from `suggested_priority`.

If `bd create` fails (non-zero exit), capture the error and return:

```
SECTION VALIDATED
  section_id: <section_id>
  status: failed
  error: <stderr from bd>
```

### Step 5: Report success

On successful issue creation, return:

```
SECTION VALIDATED
  section_id: <section_id>
  status: created
  issue_id: <bd-issue-id>
  priority: P<priority>
  title: <title>
```

## Important

- The user's edits to `section_body` are authoritative. Do NOT overwrite the title, priority, or narrative based on the raw candidates.
- The full evidence list goes into `--notes`. Nothing collected during scanning should be lost.
- If `evidence_refs` is empty (e.g. user wrote a section from scratch), still create the issue using only the section_body content. Notes will lack the dossier; that is acceptable.
- Do NOT call `bd dolt push` — issue creation auto-commits to Dolt; the orchestrator will manage final reporting.
````

- [ ] **Step 4: Verify the file**

Run: `grep -c "^### Step [1-5]:" plugins/refactor/agents/validator.md`
Expected: `5`.

Run: `grep "evidence_refs\|section_body\|--notes" plugins/refactor/agents/validator.md | wc -l`
Expected: `≥6`.

- [ ] **Step 5: Commit**

```bash
# Suggested message:
# "Switch refactor-validator to section-driven rich issue creation"
```

---

## Task 6: Extend the scan command — flags, working dir, and resume detection

**Files:**
- Modify: `plugins/refactor/commands/scan.md`

The largest change. Today's command is ~120 lines that handle diff scope inline. We need to add scope routing, working dir lifecycle, and resume detection at the top of the flow.

- [ ] **Step 1: Read the current command file in full**

Run: `wc -l plugins/refactor/commands/scan.md`
Expected: ~120 lines.

- [ ] **Step 2: Replace the frontmatter and intro**

Find the existing frontmatter block (lines 1–5) and the `# /refactor:scan Command` heading + intro paragraph. Replace through the end of the intro paragraph with:

````markdown
---
name: scan
description: Scan committed code or the entire codebase for refactoring opportunities
argument-hint: "[--scope=diff|package <path>|all] [--base <sha>] [--limit N] [--fresh] [--clean]"
---

# /refactor:scan Command

Scan code for refactoring opportunities. Supports three scopes:

- **diff** (default): scan committed changes against the base SHA. Single scanner + single validator (preserves prior behavior).
- **package**: scan one package directory. Single scanner shard.
- **all**: scan the entire indexed codebase. Sharded scanners (one per package), then a synthesizer that produces a human-reviewable `findings.md`, then per-section validators that create rich beads issues.

For `package` and `all` scopes, the pipeline persists state to `.refactor-scan/<ISO-timestamp>/` so a dropped session can be resumed by re-running the command.
````

- [ ] **Step 3: Replace the Argument Parsing section**

Find `## Argument Parsing` and replace through the end of its table with:

````markdown
## Argument Parsing

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `--scope` | string | `diff` | Scan scope: `diff`, `package <path>`, or `all`. |
| `--base` | string | auto-detected | Only meaningful with `--scope=diff`. Base SHA. Auto-detects: `@{u}`, or `merge-base HEAD main`, or prompts. |
| `--limit` | integer | `8` | Maximum architectural issues for the synthesizer to produce. Singletons unaffected. Only meaningful with `--scope=package` or `--scope=all`. |
| `--fresh` | boolean | `false` | Force a new scan even if an in-flight working dir exists. |
| `--clean` | boolean | `false` | Remove completed scans (`.completed` marker present) older than 30 days from `.refactor-scan/`, then exit. |
````

- [ ] **Step 4: Add new Steps 0a and 0b for cleanup and resume detection**

The existing file already has the `## Execution Flow` heading. Insert the following content immediately AFTER `## Execution Flow` and BEFORE the existing `### Step 0: Ensure Codebase is Indexed` (do NOT include another `## Execution Flow` heading — the existing one stays):

````markdown
### Step 0a: Handle --clean

If `--clean` is set:

```bash
find .refactor-scan -maxdepth 1 -type d -mtime +30 -exec test -f {}/.completed \; -print -exec rm -rf {} \;
```

Print a count of removed scans and exit. Do not run any scan.

### Step 0b: Resume Detection

If `--scope` is `package` or `all`, check for an in-flight working dir:

```bash
ls -1d .refactor-scan/*/ 2>/dev/null | sort -r | head -1
```

If a directory exists, inspect its state:

| State on disk | Detected stage | Resume action |
|---|---|---|
| no `candidates/` or empty | `scanning` | restart scan in this dir |
| `candidates/*.yaml` exist, no `findings.md` | `synthesis` | skip to Stage 2 |
| `findings.md` exists, no `.proceeded` | `review-gate` | skip to Stage 3 (re-prompt) |
| `.proceeded` exists, no `.completed` | `validating` | skip to Stage 4; cross-check `bd search` to skip already-created issues |
| `.completed` exists | `done` | print `report.md` and suggest `--clean` |

Use AskUserQuestion to prompt:

```
Found in-flight scan from <ts> (scope: <scope>)
Stage: <detected stage>

Resume this scan, or start fresh?
○ Resume — pick up at <stage>
○ Fresh — archive existing dir as .refactor-scan/<ts>.archived/ and start new
```

If `--fresh` is set, skip the prompt and archive immediately. Set `WORKING_DIR` to the resume target (or new dir) and proceed.

If no in-flight dir exists (or scope is `diff`), `WORKING_DIR` is unset (diff scope skips the working dir entirely).
````

- [ ] **Step 5: Rename the existing Step 0 to Step 0c and add scope-aware freshness rule**

Find `### Step 0: Ensure Codebase is Indexed`. Replace the entire section (heading through end of section, before `### Step 1`) with:

````markdown
### Step 0c: Ensure Codebase is Indexed

Required for all scopes (the diff scope already needed this).

1. Call `codebase-memory-mcp` `list_projects` to check availability. If the MCP server is not available:
   ```
   codebase-memory-mcp not found. Cannot run semantic scan.
   Ensure it is configured in your MCP settings.
   ```
   Exit.

2. Determine the project name from the repo:
   ```bash
   basename $(git rev-parse --show-toplevel)
   ```
   If the project is not in `list_projects`, automatically run `/codebase:index`.

3. For `--scope=package` or `--scope=all`, if `last_indexed` (from `.claude/codebase.local.md`) is missing or >24 hours old, run `/codebase:index` automatically. For `--scope=diff`, only re-index if the project is missing entirely (preserve current freshness behavior).
````

- [ ] **Step 6: Wrap the existing Step 1 (base SHA) under a scope=diff guard**

Find `### Step 1: Determine Base SHA`. Insert immediately after the heading (before the existing content):

```markdown
**Skip this step unless `--scope=diff`.**
```

- [ ] **Step 7: Verify**

Run: `grep -c "^### Step" plugins/refactor/commands/scan.md`
Expected: at least `6` (Step 0a, 0b, 0c, 1, plus existing 2–6).

Run: `grep -E "^---$|^name: scan$" plugins/refactor/commands/scan.md | wc -l`
Expected: `3` (frontmatter open, frontmatter close, name line).

- [ ] **Step 8: Commit**

```bash
# Suggested message:
# "Add scope routing, working dir, and resume detection to scan command"
```

---

## Task 7: Extend the scan command — sharded scanner dispatch (Stage 1)

**Files:**
- Modify: `plugins/refactor/commands/scan.md`

Replace the existing Step 3 (single scanner dispatch) with a scope-aware version. Diff scope keeps single dispatch; package scope is single dispatch with new contract; all scope dispatches one scanner per package in parallel batches.

- [ ] **Step 1: Replace Step 2 (Check for Function Changes) heading and contents**

Find `### Step 2: Check for Function Changes`. Replace the entire section (heading through the end of "Exit cleanly.") with:

````markdown
### Step 2: Build Scanner Inputs

Branch on scope:

**scope=diff:**
1. Resolve the base SHA per Step 1.
2. Run `git diff BASE..HEAD` and scan for new function definitions (existing language patterns: Go `^+.*func `, Python `^+.*def `, TypeScript `^+.*(function |const .* = |=> )`).
3. If no new function definitions found, print `No new function definitions in diff — skipping scan.` and exit cleanly.
4. Set `SHARDS = [{scope: "diff", diff: <full diff>, output: "<WORKING_DIR_OR_TMP>/candidates/diff.yaml"}]` (where `WORKING_DIR_OR_TMP` is `WORKING_DIR` if set, otherwise a temp dir).

**scope=package <path>:**
1. Validate `<path>` is a real directory under the repo. If not, exit with an error.
2. Set `SHARDS = [{scope: "package", package: "<path>", output: "<WORKING_DIR>/candidates/<path-with-slashes-as-dashes>.yaml"}]`.

**scope=all:**
1. Call `codebase-memory-mcp` `get_architecture` with `aspects: ["packages"]`. Extract the package list.
2. For each package, append `{scope: "all", package: "<pkg>", output: "<WORKING_DIR>/candidates/<pkg-with-slashes-as-dashes>.yaml"}` to `SHARDS`.

Create `<WORKING_DIR>/candidates/` if it does not exist.

Write `<WORKING_DIR>/meta.yaml`:
```yaml
scope: <scope>
base_sha: <base SHA or "">
project: <project>
started_at: <ISO 8601>
limit: <limit>
```
````

- [ ] **Step 2: Replace Step 3 (Dispatch Scanner Agent)**

Find `### Step 3: Dispatch Scanner Agent`. Replace the section through the end of its bullet list with:

````markdown
### Step 3: Dispatch Scanner Subagents

Dispatch one `refactor-scanner` agent per shard. For `scope=all` with many shards, dispatch in parallel batches of 5 (use the dispatching-parallel-agents skill).

For each shard, the subagent prompt must include:
- The shard's `scope`, `package` (if any), `diff` (if diff scope), `task_title` (diff only), `task_description` (diff only), `base_sha`, `project`, and `output_path` (set to the shard's `output`).
- Instruction: write your YAML output to `output_path` and return a one-line `SCAN COMPLETE` summary.

Collect each shard's report. Verify each shard's `output_path` file exists. If any shard fails to write its file, capture the error in `<WORKING_DIR>/scanner-errors.log` and continue with remaining shards.

After all shards complete:
- Count total candidates across all yaml files (sum of `candidates` list lengths).
- If total candidates is `0` and scope is `diff`, print `No refactoring opportunities found.` and exit cleanly.
- If total candidates is `0` and scope is `package` or `all`, write a stub `findings.md` saying "No refactoring candidates were produced by the scanner." and skip to Stage 5 (Report).
````

- [ ] **Step 3: Verify**

Run: `grep -c "SHARDS\|output_path" plugins/refactor/commands/scan.md`
Expected: `≥4`.

Run: `grep "scope=all\|scope=diff\|scope=package" plugins/refactor/commands/scan.md | wc -l`
Expected: `≥6`.

- [ ] **Step 4: Commit**

```bash
# Suggested message:
# "Add sharded scanner dispatch to scan command"
```

---

## Task 8: Extend the scan command — synthesizer dispatch and review gate (Stages 2–3)

**Files:**
- Modify: `plugins/refactor/commands/scan.md`

After Stage 1, the diff scope skips ahead to Stage 4 (validator) using the legacy single-validator path. Package and all scopes go through synthesizer + review gate.

- [ ] **Step 1: Replace Step 4 (Handle Scanner Results)**

Find `### Step 4: Handle Scanner Results`. Replace the section through the end of "proceed to Step 5." with:

````markdown
### Step 4: Synthesizer (Stage 2)

**Skip this step if `--scope=diff`** — diff scope uses the legacy validator path directly (Step 5 below has a diff branch).

Dispatch a single `refactor-synthesizer` agent with:
- `working_dir`: `<WORKING_DIR>`
- `scope`: scope value
- `limit`: `--limit` value (default 8)
- `project`: project name

The agent reads `<WORKING_DIR>/candidates/*.yaml`, writes `<WORKING_DIR>/findings.md`, and returns a `SYNTHESIS COMPLETE` summary with counts.

If `findings.md` was not written, treat as a hard failure: print the agent's error and exit (the working dir is preserved for debugging).

### Step 4b: Human Review Gate (Stage 3)

**Skip this step if `--scope=diff`.**

Print to the user:

```
Findings written to <WORKING_DIR>/findings.md

  Architectural issues: <N>
  Singletons reported:  <M>

Review the file:
  • Delete sections you don't want filed
  • Edit titles, priorities, descriptions, target shape
  • Promote singletons by moving them into a new section above
  • Add context anywhere

Reply "proceed" to file beads issues, or "abort" to stop.
```

Use AskUserQuestion to capture the response (single-select: Proceed / Abort).

- If **Proceed**: write a `<WORKING_DIR>/.proceeded` marker file (`touch`), then continue to Step 5.
- If **Abort**: leave the working dir on disk, print "Scan aborted. Findings preserved at <WORKING_DIR>/findings.md. Re-run /refactor:scan to resume." and exit cleanly.

If this step is reached during a resume from `.proceeded` already present, skip the prompt and continue.
````

- [ ] **Step 2: Verify**

Run: `grep "Stage 2\|Stage 3\|.proceeded" plugins/refactor/commands/scan.md | wc -l`
Expected: `≥4`.

- [ ] **Step 3: Commit**

```bash
# Suggested message:
# "Add synthesizer dispatch and review gate to scan command"
```

---

## Task 9: Extend the scan command — section-driven validator dispatch and report (Stages 4–5)

**Files:**
- Modify: `plugins/refactor/commands/scan.md`

Final command changes: parse the user-edited findings.md into sections, dispatch one validator per section, write report, mark .completed.

- [ ] **Step 1: Replace Step 5 (Dispatch Validator Agent) and Step 6 (Print Report)**

Find `### Step 5: Dispatch Validator Agent`. Replace from this heading through the end of the file with:

````markdown
### Step 5: Validator (Stage 4)

Branch on scope:

**scope=diff (legacy path, preserved):**

Dispatch a single `refactor-validator` agent with the legacy contract: pass the inline candidates from the single shard's yaml file (`<WORKING_DIR_OR_TMP>/candidates/diff.yaml`) reformatted as the legacy `CANDIDATES:` text block. The agent will run its old per-candidate flow.

(This branch will be removed in a future cleanup once the validator's legacy path is retired. For now, the diff scope behavior is unchanged from the user's perspective.)

**scope=package or scope=all:**

1. Read `<WORKING_DIR>/findings.md`. Parse it into sections by splitting on `^## ` headings (skip the file's H1, skip the `## Singletons` table — it is not a section to file).

2. For each architectural section, extract:
   - `section_id` — the leading number from the heading (e.g. `## 1. Extract Class: ...` → `1`)
   - `section_title` — the rest of the heading after the number
   - `affected_packages` — comma-split from the `**Affected packages:**` line
   - `confidence` — value of the `**Confidence:**` line
   - `suggested_priority` — integer from the `**Suggested priority:**` line (`P2` → `2`)
   - `evidence_refs` — comma-split from the `<!-- evidence-refs: ... -->` HTML comment
   - `section_body` — the full markdown body from after the metadata lines through to the next `^## ` (or end of file)

   If the user added a wholly new section by hand (no `evidence-refs` comment), set `evidence_refs = []`.

3. Dispatch one `refactor-validator` subagent per section, in parallel batches of 3. Each subagent receives all of the parsed fields plus `working_dir`, `scope`, `project`, and `scan_timestamp` (from `meta.yaml`).

4. During a resume from a `validating` state: before dispatching each section's subagent, run `bd search` with the section title's key terms. If a matching open issue exists, mark the section as `skip` (already-tracked) without dispatching.

5. Collect each subagent's `SECTION VALIDATED` reply. Aggregate by `status`:
   - `created` → `(issue_id, priority, title)`
   - `skip` → `(reason, issue_id?)`
   - `failed` → `(error)`

### Step 6: Report (Stage 5)

Write `<WORKING_DIR>/report.md` (for `package`/`all`) or print directly (for `diff`) using this format:

```
Refactoring scan complete (scope: <scope>, scan: <ts>).

Architectural issues created: <N>
  <issue-id>  P<priority>  <title>
  ...

Singletons (review and file manually if needed): <M>
  <pattern> in <file:func> — <reason no correlation>
  ...

Skipped (already tracked): <count>
  <issue-id>  <title>
  ...

Failed: <count>
  <section-title> — <error>
  ...
```

For `package`/`all` scopes only, append:

```
Working directory: <WORKING_DIR>/
  - findings.md (your reviewed version, preserved)
  - candidates/*.yaml (full evidence)
  - report.md (this report)

Run /refactor:scan --clean to remove scans older than 30 days.
```

Print the report to the user. For `package`/`all` scopes, write a `<WORKING_DIR>/.completed` marker file (`touch`).

For `diff` scope, no working dir to mark — exit cleanly.
````

- [ ] **Step 2: Verify**

Run: `grep -c "^### Step" plugins/refactor/commands/scan.md`
Expected: `≥7` (0a, 0b, 0c, 1, 2, 3, 4, 4b, 5, 6).

Run: `tail -5 plugins/refactor/commands/scan.md`
Expected: ends with the diff-scope completion line.

- [ ] **Step 3: Commit**

```bash
# Suggested message:
# "Add section-driven validator dispatch and final report to scan command"
```

---

## Task 10: Extend the scan skill triggers

**Files:**
- Modify: `plugins/refactor/skills/scan/SKILL.md`

Existing trigger phrases focus on diff-mode ("scan for refactoring opportunities", "after a batch completes in /execute"). Add codebase-wide trigger phrases.

- [ ] **Step 1: Read the current skill file**

Run: `cat plugins/refactor/skills/scan/SKILL.md`

- [ ] **Step 2: Update the description in frontmatter**

Find the `description: |` block. Replace its content with:

```
Scan for refactoring opportunities. Use when:
"scan for refactoring opportunities", "check for code duplication",
"look for patterns to extract", "refactoring scan",
"scan the entire codebase for refactoring",
"find architectural issues", "look for refactoring opportunities across the codebase",
"audit refactor opportunities", "refactor health check",
after a batch completes in /execute
```

- [ ] **Step 3: Add a new section before "Integration with task-executor"**

Insert immediately before `## Integration with task-executor`:

````markdown
## Codebase-wide invocation

When the user asks for a *codebase-wide* refactor scan (signal phrases: "scan the entire codebase", "look across the codebase", "audit refactor opportunities", "refactor health check", "find architectural issues"), invoke `/refactor:scan --scope=all`.

When the user names a specific package or directory ("scan internal/api for refactor opportunities"), invoke `/refactor:scan --scope=package <path>`.

The codebase-wide scan produces a `findings.md` for human review before any beads issues are filed. Do not auto-proceed past the review gate; let the user inspect and edit the file.
````

- [ ] **Step 4: Verify**

Run: `grep -c "scope=all\|scope=package" plugins/refactor/skills/scan/SKILL.md`
Expected: `≥2`.

- [ ] **Step 5: Commit**

```bash
# Suggested message:
# "Add codebase-wide scan triggers to refactor scan skill"
```

---

## Task 11: Update the plugin README

**Files:**
- Modify: `plugins/refactor/README.md`

Document the new scope modes, the working dir, the review gate, and the resume behavior.

- [ ] **Step 1: Read the existing README**

Run: `cat plugins/refactor/README.md`

- [ ] **Step 2: Append a "Codebase-wide scanning" section**

Append to the end of the file:

````markdown

## Codebase-wide scanning

Beyond the default diff-anchored scan, `/refactor:scan` supports two broader scopes:

```
/refactor:scan --scope=package internal/api
/refactor:scan --scope=all
```

Both scopes produce **architectural** beads issues (root-cause findings that group many surface-level symptoms), not per-symptom issues. The pipeline is:

1. **Sharded scanners** — one scanner subagent per package (for `--scope=all`) reads the codebase-memory-mcp index and writes raw candidates to `.refactor-scan/<ts>/candidates/<pkg>.yaml`.
2. **Synthesizer** — correlates candidates by package locus, repeated patterns, cross-layer duplication, shared types, call-graph hubs, and architectural seams. Writes a human-reviewable `.refactor-scan/<ts>/findings.md`.
3. **Human review gate** — you edit `findings.md` to keep, drop, or promote findings. Reply `proceed` to continue or `abort` to stop.
4. **Per-section validators** — one validator subagent per finding creates a rich beads issue with the full evidence dossier embedded in `--notes`.
5. **Report** — issue IDs, singletons, skips, and failures.

### Resumability

If a session drops mid-scan, just re-run `/refactor:scan` (with the same scope). The command auto-detects the in-flight working dir and offers to resume from the right stage:

| State on disk | Resume action |
|---|---|
| `candidates/*.yaml` exist, no `findings.md` | Resume from synthesis |
| `findings.md` exists, no `.proceeded` | Resume at review gate |
| `.proceeded` exists, no `.completed` | Resume at validator (skips already-created issues) |
| `.completed` exists | Print final report |

Use `--fresh` to force a new scan instead of resuming. Use `--clean` to remove completed scans older than 30 days.

### Coverage

The codebase-wide scan covers the cross-codebase subset of Fowler's refactoring catalog (https://refactoring.com/catalog/). For the full pass-by-pass mapping, see the design spec at `docs/superpowers/specs/2026-05-05-codebase-wide-refactor-scan-design.md`.

Single-file refactorings (extract variable, rename, decompose conditional, etc.) are out of scope — they belong to `quality-reviewer`.
````

- [ ] **Step 3: Verify**

Run: `grep -c "scope=all\|scope=package\|findings.md\|--proceeded\|.completed" plugins/refactor/README.md`
Expected: `≥4`.

- [ ] **Step 4: Commit**

```bash
# Suggested message:
# "Document codebase-wide scan workflow in refactor README"
```

---

## Task 12: End-to-end smoke test on this repo

**Files:** none modified — manual verification only.

This repo has ~1800 indexed nodes (per the Stage 0 index run earlier). It is the natural test target.

- [ ] **Step 1: Confirm the index is fresh**

Run: `cat .claude/codebase.local.md | grep last_indexed`
Expected: a timestamp within the last 24 hours.

If stale, run `/codebase:index` to refresh.

- [ ] **Step 2: Run a `--scope=package` smoke test on a small package**

Pick a small, real package in this repo. Inspect the marketplace structure:

Run: `ls plugins/refactor/`
Run: `ls plugins/codebase/`

Use one of these as the test target (they're small and self-contained).

Run: `/refactor:scan --scope=package plugins/refactor`

Expected behavior:
1. Index check passes (no re-index).
2. A working dir is created at `.refactor-scan/<new-ts>/`.
3. One scanner shard runs for this package (markdown plugin; expect very few candidates — possibly zero).
4. Synthesizer writes a `findings.md` (possibly with the "No refactoring candidates" stub).
5. If non-empty, the review gate prompts you. Reply `abort` to leave the working dir for inspection.
6. Inspect `<WORKING_DIR>/candidates/*.yaml` and `<WORKING_DIR>/findings.md` manually. Confirm the schemas match the fixtures.

- [ ] **Step 3: Run a `--scope=all` smoke test**

Run: `/refactor:scan --scope=all --limit=3`

Expected behavior:
1. Index check passes.
2. New working dir created.
3. Multiple scanner shards run in parallel (one per package, batched 5 at a time).
4. Synthesizer correlates candidates and writes `findings.md` with at most 3 architectural sections + a singletons table.
5. Review gate prompts.
6. Edit `findings.md` to remove all but one section (test the user-edits-are-authoritative path), then reply `proceed`.
7. One validator subagent runs and creates one beads issue.
8. Report shows `1 issue created`. Issue should appear in `bd list --status=open`.
9. Working dir contains `findings.md`, `report.md`, `.proceeded`, `.completed`.

- [ ] **Step 4: Run a resume test**

Run: `/refactor:scan --scope=all`

Expected: the command detects the completed scan and prints the existing `report.md`, suggesting `--clean`. No new scan kicks off.

- [ ] **Step 5: Run a `--clean` test**

Run: `/refactor:scan --clean`

Expected: prints the count of removed dirs (likely `0` since the test scan is fresh, but the command should exit cleanly without scanning).

- [ ] **Step 6: Verify the diff-scope path still works (regression check)**

Make a trivial change to a Go-style file (or any file with a function-shaped pattern) just for the test, stage and commit it. Then:

Run: `/refactor:scan --scope=diff --base HEAD~1`

Expected: behaves as before — single scanner, single validator, no working dir, no review gate. Either `No refactoring opportunities found.` or one or more issues created via the legacy path.

After the test, revert the throwaway commit:

```bash
git reset --hard HEAD~1
```

- [ ] **Step 7: Document any issues found**

If any task in this smoke test reveals a defect in the agent prompts or command, file a beads issue:

```bash
bd create --title "fix: <defect>" --description "<detail>" --type bug --priority 2
```

Do not attempt to fix during this task — that is a follow-up.

- [ ] **Step 8: Commit any incidental fixes**

If you needed to make small corrections to fixtures or documentation during the smoke test, commit them now. Otherwise this task has no commit.

---

## Spec coverage checklist

| Spec section | Plan task(s) |
|---|---|
| Command interface (flags) | Tasks 6, 7 |
| Pipeline (orchestrator → scanner → synthesizer → validator) | Tasks 6, 7, 8, 9 |
| Working dir & resumability | Tasks 6, 9 |
| Stage 1 — Scanner (sharding, snippet capture, yaml output) | Task 4 |
| Candidate file format | Task 1 (fixture) + Task 4 |
| Stage 2 — Synthesizer (correlation rules, output) | Task 3 |
| `findings.md` format | Task 2 (fixture) + Task 3 |
| Stage 3 — Human review gate | Task 8 |
| Stage 4 — Validator (section-driven, rich notes) | Task 5 |
| Stage 5 — Report + cleanup | Task 9 |
| Index dependency | Task 6 (Step 0c) |
| Skill triggers | Task 10 |
| README documentation | Task 11 |
| Smoke test | Task 12 |
| 5 detection passes (A/B/C/D/E) | Task 4 |
| Refactoring catalog Bucket A coverage | Task 4 (passes) + spec referenced from README in Task 11 |
