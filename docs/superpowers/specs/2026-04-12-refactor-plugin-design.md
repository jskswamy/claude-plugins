# Refactor Plugin Design

**Date:** 2026-04-12
**Status:** Approved for implementation
**Location:** `plugins/refactor/` in `jskswamy/claude-plugins`

---

## 1. Problem

The existing `task-executor` pipeline runs a `quality-reviewer` after each task. That reviewer looks at the diff **in isolation** — it asks "is this new code good?" It has no view of the rest of the codebase.

Nobody in the current pipeline asks: *does what was just implemented already exist somewhere else in the repo?*

This is how `writeJSON` ends up defined identically in 12 vendor packages when it already exists (unexported) in `internal/framework`. The quality-reviewer passes every time because each individual file is fine. The duplication is only visible when you look across the codebase.

The `refactor` plugin fills this gap. After each task closes, two agents working in tandem scan the committed code against a semantic index of the codebase, classify duplication by Fowler pattern, and create actionable beads issues with TDD-first refactoring plans.

---

## 2. What It Is Not

- **Not a code quality reviewer** — `quality-reviewer` in `task-executor` already does that.
- **Not a static analysis tool** — no grep-based pattern matching; semantic search only.
- **Not a code indexer** — `codebase-memory-mcp` handles indexing via the `codebase` plugin; this plugin queries it.
- **Not a blocking gate** — the task closes first; the scan creates future work, never prevents completion.
- **Not project-specific** — works across any codebase that has `codebase-memory-mcp` configured.

---

## 3. Prerequisites

The plugin assumes these are installed and configured in the same Claude Code session:

| Prerequisite | Purpose |
|---|---|
| `codebase-memory-mcp` | Semantic code index. The scanner queries this. Without it the plugin cannot run. |
| `codebase` plugin | Index management. The refactor plugin calls `/codebase:index` to ensure the index is fresh before scanning. |
| `beads` plugin | Issue tracker. The validator creates beads issues. |
| `task-executor` plugin | Optional. Enables automatic post-task scanning. Manual `/refactor:scan` works without it. |

---

## 4. Architecture

```
Trigger: task closes in /execute  OR  user runs /refactor:scan
                    │
        ┌───────────▼────────────┐
        │    Scanner Agent       │
        │                        │
        │  Pass 1: semantic      │
        │    similarity via      │
        │    codebase-memory-mcp │
        │  Pass 2: structural    │
        │    analysis of diff    │
        │  Pass 3: idiom check   │
        │    (diff only)         │
        │  → Return candidates   │
        └───────────┬────────────┘
                    │  candidate list (or empty → stop)
        ┌───────────▼────────────┐
        │   Validator Agent      │
        │                        │
        │  1. Read source files  │
        │     for each candidate │
        │  2. Confirm similarity │
        │  3. Check test coverage│
        │  4. Dismiss, defer,    │
        │     or create issue    │
        │  5. bd create with     │
        │     TDD-first plan     │
        └────────────────────────┘
```

The scanner provides **breadth** — it reads the index, not source files, so it can cover the entire codebase cheaply. The validator provides **depth** — it reads actual source files only for confirmed candidates (typically 3–5 files, not the whole repo).

---

## 5. Detection Taxonomy

The scanner classifies candidates across four categories of patterns. Together these cover the major cross-package quality problems that per-file code review misses. The scanner runs three passes over the diff; each pass targets different categories.

---

### 5.1 Structural Duplication — Fowler Refactoring Catalog

Detected by the **semantic similarity pass**: query `codebase-memory-mcp` with a semantic description of each new function; similar snippets elsewhere in the codebase indicate structural duplication.

| Pattern | Signal |
|---|---|
| **Replace Inline Code with Function Call** | Identical or near-identical function body in multiple packages. One may already exist in a shared layer. |
| **Extract Function + Move Function** | Function exists in package A but operates primarily on types/data from package B. Belongs in B or a shared layer. |
| **Parameterize Function** | Two or more functions with identical structure differing only by a constant value or type. Candidates for a generic or parameterised version. |
| **Combine Functions into Class/Group** | Set of functions that always take the same type as their first argument and are always used together. Candidates for a struct with methods. |
| **Pull Up Method** | Same function in multiple sibling packages that implement the same interface. Belongs in the shared layer those packages import. |
| **Introduce Parameter Object** | The same group of 3+ parameters appears together across multiple function signatures. Candidates for a shared struct or config type. |
| **Replace Conditional with Polymorphism** | `switch`/`if-else` chains on a type discriminant duplicated across packages. Candidates for an interface with multiple implementations. |

---

### 5.2 Code Smells — Fowler/Beck Catalog

Detected by the **structural analysis pass**: examine the diff itself for structural signals without querying the index.

| Smell | Signal | Suggested Move |
|---|---|---|
| **Duplicate Code** | Identical or semantically equivalent blocks in multiple files. | Extract shared function; parameterise differences. |
| **Feature Envy** | Function in package A calls methods/accesses fields of package B more than its own. | Move function to the package it envies. |
| **Data Clumps** | Same 3+ parameters appear together across multiple function signatures. | Introduce Parameter Object. |
| **Parallel Inheritance Hierarchies** | Adding to hierarchy A always requires a corresponding addition to hierarchy B. | Eliminate one hierarchy via composition; extract shared interface. |
| **Shotgun Surgery** | One logical change requires edits scattered across many packages (multi-file diff for a single concern). | Consolidate related logic into one module. |
| **Divergent Change** | One package changes for multiple unrelated reasons in a single diff. | Apply Single Responsibility; extract separate packages per concern. |
| **Message Chains** | Long call chains across packages (`a.GetB().GetC().DoD()`). Law of Demeter violation. | Introduce Facade or delegate method; hide navigation. |
| **Inappropriate Intimacy** | Package reaches into another package's unexported-equivalent internals. | Improve encapsulation; expose a formal interface. |

---

### 5.3 Design Pattern Opportunities — GoF Catalog

Detected by the **semantic similarity pass** when matched code suggests a missing design pattern: structural repetition is the signal; a named GoF pattern is the refactoring target.

| Pattern | Signal | Suggested Move |
|---|---|---|
| **Strategy** | Multiple functions with the same signature implement the same algorithm differently across packages. | Extract interface; each variant becomes an implementation; inject the strategy. |
| **Template Method** | Functions with identical structure and differing steps duplicated across sibling packages. | Extract abstract template in a shared base; subpackages override the varying steps. |
| **Factory Method** | Object creation logic with conditional branches replicated across multiple packages. | Centralise creation behind a factory interface; new variants extend, not modify. |
| **Decorator** | Wrapping behaviour (logging, validation, caching) added redundantly around the same core in multiple packages. | Introduce Decorator; compose behaviours without modifying the wrapped type. |
| **Facade** | Deep subsystem call chains duplicated across many call sites. | Introduce Facade; single entry-point hides subsystem complexity. |
| **Observer** | State-change notification propagated manually to multiple recipients across packages. | Introduce Observer/event bus; decouple change source from dependents. |
| **Command** | Operation-wrapping structs with an `Execute()` equivalent implemented inconsistently across packages. | Formalise as Command interface; enables queuing, undo, and deferred execution. |

---

### 5.4 Principle Violations — DRY, SOLID, Law of Demeter

Detected by the **structural analysis pass** on the diff, confirmed where needed by a targeted semantic query.

| Principle | Violation Signal | Refactoring |
|---|---|---|
| **DRY — Logic Duplication** | Same business rule or algorithm implemented independently in multiple packages (semantically equivalent, not textually identical). | Consolidate into one authoritative function; all callers reference it. |
| **DRY — Knowledge Duplication** | Same constraint encoded differently across layers (e.g. validation rule in API, service, and DB separately). | Single source of truth: shared constant, type, or validator. |
| **DRY — Structural Duplication** | Same data structure (DTO, config object) declared independently in multiple packages with identical fields. | Define once in a shared package; all consumers import it. |
| **SRP** | Package/struct changed for multiple unrelated concerns in one diff (e.g. HTTP handler + business logic + persistence). | Extract separate packages per responsibility; one reason to change each. |
| **OCP** | Long `if/else` or `switch` chains extended with each new variant rather than adding an implementation. | Replace with polymorphism (Strategy, Factory); new variants extend without modifying existing code. |
| **ISP** | Large interface partially implemented by multiple structs (empty or panicking method bodies). | Split into smaller focused interfaces; clients depend only on what they use. |
| **DIP** | High-level packages directly instantiate concrete low-level types. | Inject via interface; depend on abstractions, not implementations. |
| **Law of Demeter** | Function reaches through intermediaries (`a.B.C.Do()`); tight implicit coupling across package boundaries. | Delegate method or Facade; talk only to direct collaborators. |

---

### 5.5 Language-Idiomatic Anti-patterns

Detected by the **idiom check pass**: evaluate language-specific idioms against new code in the diff. No `codebase-memory-mcp` query required — the signal is in the diff alone. Flag only anti-patterns with structural or correctness impact; cosmetic style issues belong to `quality-reviewer`.

#### Go

| Anti-pattern | Signal | Idiomatic Replacement |
|---|---|---|
| **Raw string/int for typed domain value** | String or integer literal passed where a typed constant is expected (e.g. `"nvidia-gbx00"` instead of `hardware.NvidiaGBX00`). | Typed constants from the domain package. Typos become compile errors. |
| **Error string conversion** | `fmt.Sprintf("%v", err)` discards the error chain; callers cannot use `errors.Is` / `errors.As`. | `fmt.Errorf("context: %w", err)` preserves the chain. |
| **Unmanaged goroutine** | `go func()` with no context cancellation, WaitGroup, or shutdown path. | Accept `context.Context`; use `sync.WaitGroup`; always define a stop signal. |
| **Flat config struct / long parameter list** | Constructor or function with many optional bool/int parameters. | Functional options pattern (`WithTimeout`, `WithRetry`). |
| **Concrete dependency in business logic** | Business layer imports and directly instantiates an implementation package. | Accept an interface; inject the concrete type from the composition root. |
| **Duplicated struct field group** | Two or more structs with identical field groups across packages. | Extract the common fields into an embedded type; import from a shared package. |

#### Python

| Anti-pattern | Signal | Idiomatic Replacement |
|---|---|---|
| **Manual resource management** | `file.open()` / `file.close()` without `with` statement or explicit try/finally. | `with open(...) as f:` — context manager guarantees cleanup. |
| **`map(lambda…)` / `filter(lambda…)`** | Functional wrappers where a comprehension is clearer and faster. | List/generator comprehension: `[x for x in items if cond]`. |
| **Mutable default argument** | `def f(items=[])` — mutable default is shared state across all calls. | Use `None` as default; initialise mutable object inside function body. |
| **Java-style getters/setters** | `get_field()` / `set_field()` for plain attribute access. | `@property` decorator or direct attribute access. |
| **Untyped dict / missing annotations** | Public API functions with no type annotations; `dict` where a typed structure fits. | `TypedDict`, `dataclass`, or `Protocol` for structural typing. |

#### TypeScript / JavaScript

| Anti-pattern | Signal | Idiomatic Replacement |
|---|---|---|
| **`any` type** | `any` used broadly — removes type safety. | Precise types, generics, or `unknown` with narrowing. |
| **Manual null guards** | `if (obj && obj.field && obj.field.value)` chains. | Optional chaining: `obj?.field?.value`. |
| **`\|\|` for defaults on falsy values** | `value \|\| 'default'` fails for `0`, `''`, `false`. | Nullish coalescing: `value ?? 'default'`. |
| **Duplicated type definitions** | Same interface or type declared independently in multiple files. | Single canonical definition; re-export from a shared types module. |
| **Default exports** | `export default` causes inconsistent import naming across the codebase. | Named exports: predictable, refactoring-friendly. |
| **`.then()` chains** | Promise chains where `async/await` would give linear, readable control flow. | `async/await` with `try/catch`. |

---

## 6. Component Design

### 6.1 Scanner Agent — `agents/scanner.md`

**Identity:** `refactor-scanner`, cyan, `inherit` model

**Input** (provided by the `/refactor:scan` command or the execute integration):
- Git diff of the completed task (`git diff BASE..HEAD`)
- Task title and description (for semantic context)
- Base SHA

**Process:**

The scanner runs three passes over the diff. Passes 1 and 2 may query the semantic index; Pass 3 analyses the diff alone.

**Pass 1 — Semantic similarity (covers Sections 5.1 and 5.3)**
1. Parse the diff. Extract new or substantially modified function definitions. Skip: test helpers, trivial one-liners, configuration. A function qualifies if it is ≥5 lines and not in a `*_test.go` / `test_*.py` / similar test file.
2. For each qualifying function, build a one-sentence semantic description from its body (what it does, not what it is named).
3. Query `codebase-memory-mcp` with that description. Ask for the top 5 semantically similar snippets across the codebase.
4. Filter results: same file → skip. Same package → note but low priority. Different package, same layer → medium. Different layer → high.
5. For each match, apply judgment: dismiss obvious false positives (test scaffolding, generated boilerplate). A candidate is valid if the matched code serves the same purpose and could plausibly be unified.
6. Classify each candidate: if the match suggests a missing GoF design pattern (Strategy, Factory, Decorator, etc.) label it under Section 5.3; otherwise label it under Section 5.1.

**Pass 2 — Structural analysis (covers Sections 5.2 and 5.4)**
7. Examine the diff for structural signals that do not require a codebase-memory query:
   - **Feature Envy**: does the new function call more methods/fields from another package than from its own?
   - **Data Clumps**: does the new function's parameter list share 3+ parameters with other functions visible in the diff?
   - **Principle violations**: SRP (multiple concerns in one change), OCP (new `if type ==` branch added to existing chain), ISP (empty method bodies on a broad interface), DIP (direct instantiation of a concrete implementation type).
8. For each structural candidate, verify it crosses at least two files or two packages before flagging. Single-file findings belong to `quality-reviewer`, not this plugin.

**Pass 3 — Idiom check (covers Section 5.5)**
9. Detect the primary language of the diff (Go, Python, TypeScript, or other).
10. Evaluate new code against the language-idiomatic anti-patterns in Section 5.5. No codebase-memory query needed — the signal is in the diff alone.
11. Flag only anti-patterns with structural or correctness impact (raw domain strings, error chain loss, unmanaged goroutines, mutable defaults, widespread `any`). Skip cosmetic issues.

**Output all passes combined:**
12. Merge candidates from all three passes. If no valid candidates: output empty list and stop.

**Output format:**
```
CANDIDATES:
- category: Structural Duplication
  pattern: Replace Inline Code with Function Call
  confidence: high
  new_function: internal/bmc/nvidia_gbswitch/handlers.go:writeJSON
  matches:
    - internal/framework/response.go:writeJSON (unexported, identical body)
    - internal/bmc/nvidia_gbx00/handlers.go:writeJSON (identical body)
  note: "Framework already has this unexported; 3 packages define their own copy"

- category: Structural Duplication
  pattern: Parameterize Function
  confidence: medium
  new_function: internal/bmc/nvidia_gbswitch/faults.go:getFloat64Param
  matches:
    - internal/bmc/nvidia_gbx00/faults.go:getFloat64Param (identical body)
    - internal/bmc/liteon_powershelf/faults.go:getFloat64Param (identical body)
  note: "3 typed param helpers (float64/int/string) could be one generic FaultParam[T]"

- category: Language Idiom
  pattern: Raw string for typed domain value
  language: Go
  confidence: high
  new_code: internal/bmc/nvidia_gbswitch/instance.go:New
  note: "Passes string literal 'nvidia-gbswitch'; hardware.NvidiaGBSwitch typed constant should be used"
```

**Tools:** All tools (needs access to MCP tools from `codebase-memory-mcp`)

---

### 6.2 Validator Agent — `agents/validator.md`

**Identity:** `refactor-validator`, yellow, `inherit` model

**Input:** Candidate list from scanner + task context

**Process:**
1. For each candidate, read the actual source files. Confirm the similarity is real (not a false positive from semantic search).
2. Check test coverage: does a test file exist that exercises the affected function? Grep for the function name in `*_test.go` / `test_*.py` / similar. Classify as: `covered` (tests exist), `partial` (tests exist but don't exercise this path), `none` (no tests).
3. Check whether a similar beads issue already exists: `bd search "[function name] extract"` and `bd search "[pattern]"`. Skip if a matching open issue exists.
4. Decide disposition:
   - **Create issue:** confirmed duplicate/misplacement + real impact (≥2 files or cross-layer)
   - **Defer:** confirmed but trivial or single-file cosmetic improvement → skip silently
   - **Dismiss:** false positive → skip with note
5. For each issue to create, run `bd create` with the fields below.

**Beads issue fields:**

```
--title    "[Fowler Pattern]: [concise description]"
           e.g. "Extract writeJSON to internal/framework"

--description  Why this opportunity exists (which files, what duplication, what improvement)

--design   TDD-first refactoring steps:
           1. Identify or write tests documenting the current behavior of [function] in [file]
           2. Run tests and confirm they pass
           3. [Specific extraction/move steps]
           4. Run tests again and confirm behavior is unchanged
           5. Commit

--acceptance  "Tests pass before and after refactoring. No change in observable behavior."

--notes    "Pattern Category: [Structural Duplication|Code Smell|GoF Pattern|Principle Violation|Language Idiom]\n
           Pattern: [name]\n
           Affected files: [list]\n
           Confidence: [high|medium]\n
           Test coverage: [covered|partial|none]\n
           Language: [Go|Python|TypeScript — only for Language Idiom category]"

--type     task
--priority [2 if ≥3 files or cross-layer; 3 if 2 files same layer; 4 if minor]
```

**Tools:** `Bash`, `Read`, `Grep`, `Glob`

---

### 6.3 Scan Command — `commands/scan.md`

**Invocation:** `/refactor:scan [--base <sha>]`

| Flag | Default | Meaning |
|---|---|---|
| `--base <sha>` | auto-detected | Compare HEAD against this SHA. Auto-detect: last pushed commit (`@{u}`) or user prompt if no upstream. |

**Flow:**

**Step 0: Ensure codebase is indexed**
Before scanning, verify the codebase index is available and fresh:

1. Call `codebase-memory-mcp` `list_projects`. If the current project is not indexed, automatically run `/codebase:index` (from the `codebase` plugin) to build the index.
2. If the project is indexed, check `.claude/codebase.local.md` for `last_indexed`. If >24 hours old, run `/codebase:index` to refresh.
3. If `codebase-memory-mcp` is not available, print error and exit (see Section 9).

This delegates all index management to the `codebase` plugin. The refactor plugin never calls `index_repository` directly.

**Step 1:** Determine base SHA.
**Step 2:** Run `git diff --stat BASE..HEAD`. If no function definitions changed (no lines matching `^+.*func ` / `^+.*def ` etc.), print "No new function definitions in diff — skipping scan." and exit cleanly.
**Step 3:** Dispatch scanner agent with diff + context.
**Step 4:** If scanner returns empty candidates: "No refactoring opportunities found."
**Step 5:** If scanner returns candidates: dispatch validator agent.
**Step 6:** Print report: issues created (with IDs), issues dismissed, issues deferred.

**Example output:**
```
Refactoring scan complete.

Issues created:
  rfsim-xxx  P2  Extract writeJSON to internal/framework
  rfsim-yyy  P3  Extract FaultParam[T] to internal/framework

Dismissed (false positives): 1
Deferred (trivial): 0
```

---

### 6.4 Auto-trigger Skill — `skills/scan/SKILL.md`

**Trigger phrases:**
- "scan for refactoring opportunities"
- "check for code duplication"
- "look for patterns to extract"
- "refactoring scan"
- After a batch completes in `/execute` (described below)

**Behavior:** Invoke `/refactor:scan` with appropriate flags. If the user mentions a specific commit or task, pass `--base` accordingly.

---

## 7. Integration with task-executor

The `execute.md` command in `task-executor` gains an optional **Step 6a** between Step 6 (close task) and Step 7 (batch checkpoint):

```
#### Step 6a: Refactoring Scan (unless --no-refactor)

After bd close, if the refactor plugin is available, dispatch the scanner agent:
- Pass: git diff of the committed task changes + task title/description
- If scanner returns candidates: dispatch validator agent
- Report created issue IDs in the batch summary
- This step is non-blocking: the task is already closed; scan creates future work only
- Skip if diff contains no new function definitions
```

Add `--no-refactor` flag to the execute command:

| Flag | Default | Meaning |
|---|---|---|
| `--no-refactor` | false | Skip refactoring scan after each task |

The batch checkpoint summary gains a "Refactoring opportunities" row:
```
| Task       | Status | Review | Commit  | Refactoring     |
|------------|--------|--------|---------|-----------------|
| rfsim-4ut  | DONE   | PASS   | abc1234 | 2 issues created |
| rfsim-61r  | DONE   | PASS   | def5678 | none found       |
```

---

## 8. Plugin File Structure

```
plugins/refactor/
  .claude-plugin/
    plugin.json          name, version, description, keywords
  agents/
    scanner.md           refactor-scanner agent
    validator.md         refactor-validator agent
  commands/
    scan.md              /refactor:scan command
  skills/
    scan/
      SKILL.md           auto-trigger skill
  README.md              prerequisites, usage, examples
```

---

## 9. Error Handling

| Situation | Behaviour |
|---|---|
| `codebase-memory-mcp` not available | `/refactor:scan` prints "codebase-memory-mcp not found. Cannot run semantic scan. Ensure it is configured in your MCP settings." and exits. |
| `codebase` plugin not available | `/refactor:scan` prints "codebase plugin not found. Install it for index management." and exits. |
| `/codebase:index` fails | Print the error from the codebase plugin. Do not proceed to scan — index may be partial. Suggest running `/codebase:index --mode full`. |
| Scanner returns no candidates | Print "No refactoring opportunities found." Stop cleanly. |
| `bd create` fails | Log the failure with the candidate details. Continue with remaining candidates. Do not retry. |
| Duplicate issue detected (`bd search` finds existing open issue) | Skip silently. Mention count in final report: "X opportunities already tracked." |
| Diff too large for context window | Scanner processes functions in batches of 10. Each batch is a separate MCP query. |

---

## 10. Marketplace Registration

Add to `.claude-plugin/marketplace.json`:

```json
{
  "name": "refactor",
  "description": "Semantic refactoring opportunity detection. Scans committed code for structural duplication (Fowler catalog), code smells (Fowler/Beck), GoF design pattern opportunities, SOLID/DRY principle violations, and language-idiomatic anti-patterns (Go, Python, TypeScript). Creates beads issues with TDD-first refactoring plans. Hooks into task-executor after each task closes.",
  "version": "0.1.0",
  "author": { "name": "Krishnaswamy Subramanian" },
  "source": "./plugins/refactor",
  "category": "code-quality",
  "tags": ["refactoring", "duplication", "fowler", "beads", "codebase-memory", "tdd", "semantic-search"]
}
```

---

## 11. Out of Scope

- Building or maintaining a code index (delegated to `codebase-memory-mcp` via the `codebase` plugin)
- Syntactic copy-paste detection (grep-based; too brittle)
- Automatic refactoring (the plugin identifies and plans; humans execute)
- Blocking task completion on refactoring findings
- Project-specific rules or pattern libraries
- Cosmetic language idiom violations (naming, formatting, whitespace) — those belong to `quality-reviewer`
- Language idiom checks on single-file changes with no cross-package impact — single-file findings stay with `quality-reviewer`
- Refactoring plans for non-duplicated code smells (complexity, naming) — that is the `quality-reviewer`'s domain
