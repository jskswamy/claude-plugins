# Codebase-Wide Refactor Scan — Design

**Date:** 2026-05-05
**Plugin:** `plugins/refactor`
**Status:** Design approved, implementation pending

## Problem

`/refactor:scan` today operates only on git diffs. It extracts new function definitions from a diff, semantic-searches the codebase index for similar code, and files beads issues for confirmed duplications. This is useful after a task lands, but it cannot answer the question "what refactoring opportunities exist in the codebase as it stands today?" — which is the more common ask when a team wants to plan a quality campaign.

The codebase plugin already maintains a semantic+structural index via `codebase-memory-mcp`. That index includes pre-computed `SIMILAR_TO` and `SEMANTICALLY_RELATED` edges, call-graph relationships, and architectural metadata. The new mode mines this index instead of re-running per-function semantic search.

## Goals

- Add a codebase-wide scan mode that surfaces architectural refactoring opportunities, not just diff-anchored ones.
- Cover the full set of Fowler refactorings that produce cross-codebase signals (Bucket A in `## Refactoring Catalog Coverage` below).
- Produce **architectural** issues (root-cause), not a flood of per-candidate issues. Reviewer addresses systemic problems, not individual symptoms.
- Provide a human review gate before any beads issues are filed, so the user controls what gets tracked.
- Survive lost sessions: the working dir on disk is the source of truth; re-running the command auto-resumes.
- Preserve all evidence collected during scanning into the eventual beads issue — nothing thrown away.

## Non-Goals

- Replacing `quality-reviewer` for single-file smells. This plugin is for cross-package patterns.
- Auto-applying refactorings. This plugin produces issues; implementation is a separate workflow.
- Generating fully-refactored code in `findings.md`. Suggested target shapes (signatures, interfaces, layouts) only — not implementations.
- Diff-mode behavior changes. Existing diff scope is preserved unchanged.

## Refactoring Catalog Coverage

Of the 66 refactorings in Fowler's catalog (https://refactoring.com/catalog/), this mode targets **Bucket A**: those detectable from cross-codebase signals.

| Pass | Catalog patterns covered |
|---|---|
| **A. Similarity-cluster** | Extract Function, Replace Inline Code with Function Call, Combine Functions into Class, Combine Functions into Transform, Parameterize Function, Substitute Algorithm, Introduce Parameter Object, Preserve Whole Object |
| **B. Call-graph** | Inline Function (1 caller), Inline Class (1 consumer), Remove Dead Code (0 callers, non-exported), Hide Delegate (chains across packages), Remove Middle Man (mostly-delegating funcs), Move Function (feature envy: outbound calls cross packages > intra-package) |
| **C. Hierarchy** | Pull Up Method, Pull Up Field, Pull Up Constructor Body, Push Down Method, Push Down Field, Collapse Hierarchy, Replace Subclass with Delegate, Replace Superclass with Delegate, Remove Subclass, Extract Superclass, Extract Class |
| **D. Type-discriminant** | Replace Conditional with Polymorphism, Replace Type Code with Subclasses |
| **E. Idiom check** | Existing Go/Python/TypeScript anti-patterns from current scanner, runs unchanged |

(Today's scanner uses three numbered passes; this design renames them A/B/C/D/E for clarity. Pass A is today's "semantic similarity" pass extended to mine pre-built `SIMILAR_TO` edges; Pass E is today's "idiom check" pass renamed.)

**Excluded — Bucket B (single-file, belongs to `quality-reviewer`):** Decompose/Consolidate Conditional, Extract/Inline/Split/Rename Variable, Replace Magic Literal, Introduce Assertion, Slide Statements, Split Loop, Split Phase, Replace Loop with Pipeline, Replace Nested Conditional with Guard Clauses, Replace Control Flag with Break, Replace Temp with Query, Replace Derived Variable with Query, Separate Query from Modifier, Move Statements into/to Callers, Rename Field, Encapsulate Variable/Record/Collection, Change Function Declaration.

**Deferred — Bucket C (judgment-heavy API/type design, future work):** Change Reference↔Value, Replace Primitive with Object, Remove Setting Method, Remove Flag Argument, Replace Error Code↔Exception, Replace Parameter↔Query, Replace Constructor with Factory, Replace Function↔Command, Return Modified Value, Introduce Special Case.

## Command Interface

```
/refactor:scan [--scope=diff|package <path>|all]
               [--base <sha>]
               [--limit N]
               [--fresh]
               [--clean]
```

| Flag | Default | Description |
|---|---|---|
| `--scope` | `diff` | Scan scope. `diff` preserves current behavior. `package <path>` scopes to one package. `all` scans the entire indexed codebase. |
| `--base` | auto-detected | Only meaningful with `--scope=diff`. Existing flag, unchanged. |
| `--limit` | `8` | Cap synthesis output (architectural issues). Singletons reported separately and unaffected. |
| `--fresh` | off | Force a new scan even if an in-flight scan exists on disk. |
| `--clean` | off | Remove completed scans older than 30 days from `.refactor-scan/`. |

## Pipeline

```
Orchestrator (the command)
  │
  ├─► Scanner subagent(s)        — sharded per-package for --scope=all
  │     │
  │     └─► writes candidates/<package>.yaml
  │
  ├─► Synthesizer subagent       — single, reads all candidates
  │     │
  │     └─► writes findings.md (human-reviewable)
  │
  ├─► [HUMAN REVIEW GATE]
  │     User edits findings.md, replies "proceed" or "abort"
  │
  └─► Validator subagents        — one per architectural issue, parallel
        │
        └─► creates beads issues, writes report.md
```

The orchestrator's context only ever holds: filepaths, counts, issue IDs, the singleton list. It never loads raw candidate data or source snippets. Each subagent's context is bounded by its own input slice.

## Working Directory & Resumability

Each scan creates `.refactor-scan/<ISO-timestamp>/` containing:

```
.refactor-scan/2026-05-05T10-22-00Z/
├── meta.yaml              # scope, base SHA, project, started_at
├── candidates/
│   ├── internal-api.yaml
│   ├── internal-handlers.yaml
│   └── ...                # one file per scanner shard
├── findings.md            # synthesizer output, user-reviewable
├── .proceeded             # marker: user approved findings.md
├── report.md              # final issue list
└── .completed             # marker: scan finished successfully
```

On entry, the orchestrator checks for an in-flight scan in `.refactor-scan/`:

| State on disk | Resume action |
|---|---|
| No working dir | Start fresh: scan |
| `candidates/*.yaml` exist, no `findings.md` | Resume from synthesis |
| `findings.md` exists, no `.proceeded` | Resume at review gate (re-prompt user) |
| `.proceeded` exists, no `.completed` | Resume at validator; cross-check beads (`bd search`) to skip already-created issues |
| `.completed` exists | Print `report.md`, suggest `--clean` |

If an in-flight scan is found, prompt:

```
Found in-flight scan from <ts> (scope: <scope>)
Stage: <detected stage>

Resume this scan, or start fresh? [resume|fresh]
```

`--fresh` skips the prompt. `--clean` removes scans with `.completed` markers older than 30 days.

## Stage 1 — Scanner

For `--scope=diff`: single scanner subagent, current behavior preserved. Writes `candidates/diff.yaml`.

For `--scope=package <path>`: single scanner subagent scoped to that path. Writes `candidates/<package>.yaml`.

For `--scope=all`:
1. Orchestrator calls `codebase-memory-mcp`'s `get_architecture` to enumerate packages.
2. Orchestrator dispatches scanner subagents per package, in parallel batches of 5.
3. Each scanner shard runs all 5 passes (A/B/C/D/E), scoped to its package's symbols.
4. Each shard writes `candidates/<package>.yaml` and returns only `{count, filepath}` to the orchestrator.

### Candidate file format

```yaml
package: internal/api
generated_at: 2026-05-05T10:22:31Z
candidates:
  - id: cand-001                 # stable per-scan ID for cross-references
    pass: A                       # A | B | C | D | E
    pattern: Replace Inline Code with Function Call
    confidence: high              # high | medium
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
    related_callers: [...]        # from trace_call_path
    related_callees: [...]
    note: "..."
```

Snippets come from `codebase-memory-mcp`'s `get_code_snippet`. If a function exceeds 50 lines, it's truncated to first 25 + `... [N lines elided] ...` + last 10.

## Stage 2 — Synthesizer

Single subagent. Reads all `candidates/*.yaml`. Correlates candidates by these signals (priority order):

1. **Shared package locus** — ≥3 findings in one package → "package doing too much" (Extract Class at package scale)
2. **Repeated pattern** — ≥3 instances of same Fowler pattern → missing abstraction over involved type
3. **Cross-layer concept duplication** — same concept-name (e.g. `validate*`) across architectural layers → DRY-Knowledge violation, single source of truth needed
4. **Shared type root** — ≥3 findings touch same type → that type is doing too much
5. **Shared call-graph hub** — ≥3 findings funnel through one symbol → god-function or missing facade
6. **Architectural seam crossing** — repeated reaches across packages → wrong layer assignment or missing DIP interface

Writes `findings.md` with one section per architectural issue, plus a singletons table. Each architectural section contains:

- Title (Fowler pattern at architectural scale + concise root cause)
- Affected packages, confidence, suggested priority
- "What's wrong" — synthesizer's narrative
- Evidence — top 5 candidates by confidence × illustrative-value, each with current code snippet
- Suggested target shape — signatures/interfaces/types only, not implementations
- Footer: "+ N more in `candidates/<package>.yaml`" if the finding has more than 5 evidence items

Singletons table at the end:

| Pattern | Location | Why no correlation |
|---|---|---|
| ... | ... | ... |

The synthesizer does not call `bd` and creates no issues. Its only side effect is writing `findings.md`.

### `findings.md` format

```markdown
# Refactoring Scan Findings — 2026-05-05T10-22-00Z

Scope: all  •  Base: HEAD  •  Project: <project-name>

> Review this file. Edit, delete, or annotate findings.
> When done, return to Claude and reply "proceed" to file beads issues,
> or "abort" to stop without filing anything.
> Anything still in this file (architectural sections + promoted singletons)
> becomes a beads issue.

---

## 1. [Architectural pattern]: [root cause]
**Affected packages:** internal/api, internal/handlers
**Confidence:** high
**Suggested priority:** P2
<!-- evidence-refs: internal-api.yaml#cand-001, internal-api.yaml#cand-014, internal-handlers.yaml#cand-007, ... -->
<!-- promoted-from: none -->  <!-- or: singletons table row 3, if user promoted -->


### What's wrong
[narrative]

### Evidence
#### Current code

**`internal/api/users.go:writeJSONResponse` (line 45–58)**
\`\`\`go
[snippet]
\`\`\`

**`internal/handlers/auth.go:respond` (line 78–92)** — similarity 0.91
\`\`\`go
[snippet]
\`\`\`

[+ 7 more in `candidates/internal-api.yaml`]

### Suggested target shape
\`\`\`go
// internal/framework/respond.go (new)
func WriteJSON(w http.ResponseWriter, status int, body any) error
\`\`\`

After this lands:
- 3 call sites in `internal/api/` collapse to `framework.WriteJSON(...)`
- 1 call site in `internal/handlers/auth.go` similarly
- 3 duplicate helpers can be deleted

---

## 2. ...

---

## Singletons (won't be filed unless promoted to a section above)

| # | Pattern | Location | Candidate ID | Why no correlation |
|---|---|---|---|---|
| 1 | Parameterize Function | pkg/util/timefmt.go:34 | `pkg-util.yaml#cand-042` | Single isolated finding |
| ... | ... | ... | ... | ... |
```

To promote a singleton, copy its candidate ID into the `evidence-refs` of a new section above, with `promoted-from: singletons table row N`. The validator picks up the section the same way as any other architectural issue.

## Stage 3 — Human Review Gate

After `findings.md` is written, orchestrator prints:

```
Findings written to .refactor-scan/<ts>/findings.md

  Architectural issues: <N>
  Singletons reported:  <M>

Review the file:
  • Delete sections you don't want filed
  • Edit titles, priorities, descriptions, target shape
  • Promote singletons by moving them into a new section above
  • Add context anywhere

Reply "proceed" to file beads issues, or "abort" to stop.
```

Orchestrator waits for the user's reply. On "proceed": write `.proceeded` marker, continue to Stage 4. On "abort": leave working dir on disk, exit cleanly. The user can return later — the resume logic picks up at the review gate.

## Stage 4 — Validator

Orchestrator parses the (possibly edited) `findings.md` into sections. For each remaining architectural section (and each promoted singleton), dispatches a validator subagent in parallel batches of 3.

Each validator subagent:

1. Receives its section's title, body, and the `evidence-refs` HTML comment listing `<yaml-file>#<candidate-id>` pointers.
2. Reads its section text (user's edits are source of truth for narrative, priority, title).
3. Resolves each `evidence-refs` pointer by loading the named candidate from `candidates/*.yaml` (full evidence beyond the top-5 shown to the user).
4. Optionally re-reads source for the top 3 evidence files to sanity-check the pattern still holds (defends against stale findings if the user took days to review).
5. Calls `bd search` with key terms from the title to deduplicate against existing beads issues. If a matching open issue exists, skip and report.
6. Calls `bd create` with:
   - `--title` — from the section heading
   - `--description` — the "What's wrong" section verbatim
   - `--design` — "Suggested target shape" + a TDD-first plan referencing actual files
   - `--notes` — full evidence list (every candidate, not just top-5), with file:line, qualified names, similarity scores, related callers/callees, related types, pattern category, scan timestamp, scope, base SHA. **Nothing thrown away.**
   - `--acceptance` — "Tests pass before and after refactoring. No change in observable behavior."
   - `--priority` — from the section's "Suggested priority" line
   - `--type=task`
7. Returns `{section_id, issue_id | skip_reason}` to the orchestrator.

If `bd create` fails for any section, log it and continue with the rest. The orchestrator collates results.

## Stage 5 — Report

Orchestrator writes `report.md` and prints to terminal:

```
Refactoring scan complete (scope: all, scan: <ts>).

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

Working directory: .refactor-scan/<ts>/
  - findings.md (your reviewed version, preserved)
  - candidates/*.yaml (full evidence)
  - report.md (this report)

Run /refactor:scan --clean to remove scans older than 30 days.
```

Writes `.completed` marker.

## Index Dependency

`--scope=all` and `--scope=package` require an index that is ≤24 hours old:
- If `codebase-memory-mcp` is unavailable: print error, exit.
- If project not indexed: auto-run `/codebase:index`.
- If `last_indexed` (from `.claude/codebase.local.md`) >24h: auto-run `/codebase:index`.

`--scope=diff` keeps the existing freshness behavior (re-index only if missing).

## Agent Layout

```
plugins/refactor/
├── commands/
│   └── scan.md              # extended with new flags + orchestration logic
├── agents/
│   ├── scanner.md           # extended: sharded mode, all 4 passes, get_code_snippet capture
│   ├── synthesizer.md       # NEW: correlation + findings.md generation
│   └── validator.md         # extended: section-driven, rich beads issue creation
└── skills/
    └── scan/SKILL.md        # extended trigger phrases for codebase-wide scan
```

## Open Questions Resolved

- **Sync vs async review gate** — sync prompt + disk-based resume. No `--resume` flag; auto-detected from working dir state.
- **Singletons** — reported in `findings.md`, never auto-filed. User can promote by editing the file.
- **Evidence cap** — top 5 per finding inline in `findings.md`, full evidence preserved in `candidates/*.yaml` and embedded in beads `--notes`.
- **Target shape vs full before/after** — target shape only (signatures/interfaces/types). Full refactored code is the implementer's job.
- **Issue grouping** — synthesis is the grouping. No epic wrapper needed.

## Risks

- **Scanner shard runtime** — for very large codebases (10k+ symbols), even sharded scanning may take many minutes. Mitigate with parallel batches; document expected runtime in README.
- **False positives in synthesis** — correlation rules are heuristic. Mitigate with the human review gate; the user can delete bad sections.
- **`findings.md` size** — top-5 cap keeps it bounded, but a 50-issue scan still produces a large file. Acceptable for v1; revisit if it becomes a UX problem.
- **Index staleness during long-running review** — if user takes days to review and source changes underneath, validator's optional re-read step (Stage 4 step 4) catches drift.

## Implementation Order

1. New `synthesizer.md` agent (the genuinely new piece).
2. Extend `scanner.md` with sharded mode and `get_code_snippet` capture for source.
3. Extend `validator.md` to be section-driven and produce rich `--notes`.
4. Extend `commands/scan.md` orchestration: scope routing, working-dir lifecycle, resume logic, review gate.
5. Extend `skills/scan/SKILL.md` trigger phrases.
6. Manual end-to-end test on this repo (~1800 nodes — perfect test target).
