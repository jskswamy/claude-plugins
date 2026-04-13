# Refactor Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin that scans committed code for refactoring opportunities (Fowler patterns, code smells, GoF patterns, SOLID/DRY violations, language idioms), classifies them, and creates beads issues with TDD-first refactoring plans.

**Architecture:** Two-agent design (scanner for breadth, validator for depth) orchestrated by a scan command. Scanner queries `codebase-memory-mcp` semantic index; validator reads source files and creates beads issues. Index management delegated to the `codebase` plugin.

**Tech Stack:** Claude Code plugin system (markdown agents, commands, skills), `codebase-memory-mcp` MCP server, `codebase` plugin, `beads` CLI

---

## File Structure

```
plugins/refactor/
  .claude-plugin/
    plugin.json              Already exists — update keywords if needed
  agents/
    scanner.md               refactor-scanner agent (3-pass detection)
    validator.md             refactor-validator agent (confirm + create issues)
  commands/
    scan.md                  /refactor:scan command (orchestrator)
  skills/
    scan/
      SKILL.md               Auto-trigger skill
  README.md                  Prerequisites, usage, examples
```

Additionally modified:
- `.claude-plugin/marketplace.json` — register the plugin (if not already)

---

### Task 1: Scanner Agent

**Files:**
- Create: `plugins/refactor/agents/scanner.md`

This is the most complex component — a 3-pass detection agent that covers the full taxonomy (Sections 5.1-5.5 of the spec).

- [ ] **Step 1: Create agents directory**

```bash
mkdir -p plugins/refactor/agents
```

- [ ] **Step 2: Write the scanner agent**

Create `plugins/refactor/agents/scanner.md`:

```markdown
---
name: refactor-scanner
description: |
  Scans committed code diffs for refactoring opportunities across the codebase.
  Runs three passes: semantic similarity (Fowler structural patterns + GoF),
  structural analysis (code smells + SOLID/DRY violations), and language idiom
  checks. Returns a candidate list for the validator agent to confirm.
model: inherit
color: cyan
tools:
  - Bash
  - Read
  - Grep
  - Glob
---

You are the refactor-scanner agent. Your job is to analyze a git diff and find cross-package refactoring opportunities that per-file code review misses.

## Input

You receive:
- **diff**: The git diff of committed changes (`git diff BASE..HEAD`)
- **task_title**: Title of the completed task (for semantic context)
- **task_description**: Description of the completed task
- **base_sha**: The base SHA the diff is against
- **project**: The codebase-memory-mcp project name

## Process

Run three passes over the diff. Each pass targets different categories of patterns.

### Pass 1: Semantic Similarity (Sections 5.1 and 5.3)

**Goal:** Find functions in the diff that already exist elsewhere in the codebase.

1. Parse the diff. Extract new or substantially modified function definitions.
   - **Qualifies:** Function is ≥5 lines and not in a test file (`*_test.go`, `test_*.py`, `*.test.ts`, `*.spec.ts`)
   - **Skip:** Test helpers, trivial one-liners (getters/setters), configuration constants, generated code

2. For each qualifying function, build a one-sentence semantic description from its body. Describe **what it does**, not what it is named. Example: "Marshals a Go struct to JSON and writes it to an HTTP response with Content-Type header" (not "writeJSON helper").

3. For each description, call `codebase-memory-mcp` `search_graph` with:
   - `semantic_query`: the one-sentence description as an array of keywords
   - `project`: the project name
   - `limit`: 5

4. Filter results:
   - Same file as the new function → skip
   - Same package → note but low priority
   - Different package, same layer (e.g. both in `internal/bmc/`) → medium priority
   - Different layer (e.g. one in `internal/framework`, one in `internal/bmc/`) → high priority

5. For each match, apply judgment. Dismiss obvious false positives:
   - Test scaffolding (setup/teardown functions)
   - Generated boilerplate (protobuf, mock files)
   - Trivially similar functions that serve different purposes
   A candidate is valid if the matched code serves the same purpose and could plausibly be unified.

6. Classify each valid candidate:
   - If the match suggests a missing GoF design pattern → label under **Design Pattern Opportunity** (Section 5.3):
     - Strategy: same signature, different algorithm
     - Template Method: identical structure, differing steps
     - Factory Method: conditional creation logic duplicated
     - Decorator: wrapping behavior duplicated
     - Facade: deep call chains duplicated
     - Observer: manual notification propagation
     - Command: inconsistent Execute() pattern
   - Otherwise → label under **Structural Duplication** (Section 5.1):
     - Replace Inline Code with Function Call: identical body, one may exist in shared layer
     - Extract Function + Move Function: function operates on another package's types
     - Parameterize Function: identical structure differing by constant/type
     - Combine Functions into Class/Group: functions always take same type, used together
     - Pull Up Method: same function in sibling packages implementing same interface
     - Introduce Parameter Object: same 3+ params across multiple signatures
     - Replace Conditional with Polymorphism: duplicated switch/if-else on type discriminant

### Pass 2: Structural Analysis (Sections 5.2 and 5.4)

**Goal:** Detect code smells and principle violations visible in the diff itself, without querying the semantic index.

7. Examine the diff for structural signals:

   **Code Smells (Section 5.2):**
   - **Feature Envy**: Does the new function call more methods/fields from another package than from its own?
   - **Data Clumps**: Does the new function's parameter list share 3+ parameters with other functions visible in the diff?
   - **Shotgun Surgery**: Does this diff touch many packages for a single logical change?
   - **Divergent Change**: Does one package change for multiple unrelated reasons in this diff?
   - **Message Chains**: Long call chains across packages (`a.GetB().GetC().DoD()`)
   - **Inappropriate Intimacy**: Reaching into another package's internals

   **Principle Violations (Section 5.4):**
   - **SRP**: Multiple unrelated concerns in one change
   - **OCP**: New `if type ==` or `switch` branch added to existing chain
   - **ISP**: Empty method bodies on a broad interface
   - **DIP**: Direct instantiation of a concrete implementation type in business logic
   - **DRY**: Same business rule, constraint, or data structure declared independently in multiple packages
   - **Law of Demeter**: `a.B.C.Do()` pattern across package boundaries

8. **Cross-file gate:** For each structural candidate, verify it crosses at least two files or two packages before flagging. Single-file findings belong to `quality-reviewer`, not this plugin.

### Pass 3: Idiom Check (Section 5.5)

**Goal:** Detect language-specific anti-patterns with structural or correctness impact. No codebase-memory query needed — the signal is in the diff alone.

9. Detect the primary language of the diff from file extensions.

10. Evaluate new code against the language-idiomatic anti-patterns:

    **Go:**
    - Raw string/int for typed domain value (e.g. string literal where typed constant expected)
    - Error string conversion (`fmt.Sprintf("%v", err)` instead of `%w`)
    - Unmanaged goroutine (no context, WaitGroup, or shutdown path)
    - Flat config struct / long parameter list (should use functional options)
    - Concrete dependency in business logic (should accept interface)
    - Duplicated struct field group across packages

    **Python:**
    - Manual resource management (no `with` statement)
    - `map(lambda)` / `filter(lambda)` instead of comprehensions
    - Mutable default argument (`def f(items=[])`)
    - Java-style getters/setters instead of `@property`
    - Untyped dict / missing annotations on public APIs

    **TypeScript / JavaScript:**
    - `any` type used broadly
    - Manual null guards instead of optional chaining
    - `||` for defaults on falsy values instead of `??`
    - Duplicated type definitions across files
    - Default exports
    - `.then()` chains instead of async/await

11. Flag only anti-patterns with structural or correctness impact. Skip cosmetic issues (naming, formatting, whitespace).

### Merge and Output

12. Merge candidates from all three passes. If no valid candidates: output an empty list and stop.

## Output Format

Return candidates in this structured format:

```
CANDIDATES:
- category: [Structural Duplication|Code Smell|Design Pattern Opportunity|Principle Violation|Language Idiom]
  pattern: [specific pattern name from the taxonomy]
  confidence: [high|medium]
  new_function: [file_path:function_name]
  matches:
    - [file_path:function_name] ([brief description of similarity])
  note: "[one-sentence explanation of why this is a valid candidate]"
  language: [Go|Python|TypeScript — only for Language Idiom category]
```

If no candidates found:
```
CANDIDATES: none
```

## Important

- Do NOT flag single-file issues — those belong to quality-reviewer
- Do NOT flag cosmetic or naming issues
- Do NOT flag test-only code
- Err on the side of fewer, high-confidence candidates over many noisy ones
- If you're unsure whether something is a valid candidate, mark confidence as `medium`
```

- [ ] **Step 3: Verify file exists**

```bash
cat plugins/refactor/agents/scanner.md | head -5
```

Expected: The YAML frontmatter header.

- [ ] **Step 4: Commit**

```bash
git add plugins/refactor/agents/scanner.md
```

Commit message: `Add refactor-scanner agent with 3-pass detection taxonomy`

---

### Task 2: Validator Agent

**Files:**
- Create: `plugins/refactor/agents/validator.md`

- [ ] **Step 1: Write the validator agent**

Create `plugins/refactor/agents/validator.md`:

```markdown
---
name: refactor-validator
description: |
  Validates refactoring candidates from the scanner agent. Reads actual source
  files to confirm similarity, checks test coverage, deduplicates against
  existing beads issues, and creates new issues with TDD-first refactoring plans.
model: inherit
color: yellow
tools:
  - Bash
  - Read
  - Grep
  - Glob
---

You are the refactor-validator agent. You receive a list of refactoring candidates from the scanner and must confirm or dismiss each one by reading actual source code.

## Input

You receive:
- **candidates**: The candidate list from the scanner agent (CANDIDATES format)
- **task_title**: Title of the completed task (for context)
- **project**: The codebase-memory-mcp project name

## Process

For each candidate in the list:

### Step 1: Confirm Similarity

Read the actual source files for both the new function and each match:
- Use `Read` to read the source files at the specified paths
- Compare the actual code, not just the scanner's description
- Confirm the similarity is real and not a false positive from semantic search

**Dismiss if:**
- The functions look similar but serve fundamentally different purposes
- The "duplication" is coincidental structure (e.g., both are HTTP handlers but do different things)
- The match is in generated or vendored code

### Step 2: Check Test Coverage

For each affected function, check if tests exist:

```bash
# For Go
ls *_test.go in the same directory
grep -l "FunctionName" $(find . -name "*_test.go")

# For Python
ls test_*.py or *_test.py in the same directory
grep -l "function_name" $(find . -name "test_*.py" -o -name "*_test.py")

# For TypeScript
ls *.test.ts or *.spec.ts in the same directory
grep -l "functionName" $(find . -name "*.test.ts" -o -name "*.spec.ts")
```

Classify as:
- `covered` — test file exists AND tests reference the affected function
- `partial` — test file exists but does NOT reference the affected function directly
- `none` — no test file found for the affected code

### Step 3: Check for Existing Issues

Search for existing beads issues that already track this opportunity:

```bash
bd search "[function name]"
bd search "[pattern name]"
```

If a matching open issue exists, skip this candidate silently. Count it for the final report.

### Step 4: Decide Disposition

For each candidate, decide:

- **Create issue:** Confirmed duplicate/misplacement + real impact (≥2 files or cross-layer). Proceed to Step 5.
- **Defer:** Confirmed but trivial or single-file cosmetic improvement. Skip silently.
- **Dismiss:** False positive after reading the actual code. Skip with note.

### Step 5: Create Beads Issue

For each candidate to create, run `bd create` with these fields:

```bash
bd create \
  --title "[Pattern]: [concise description]" \
  --description "Why this opportunity exists: [which files, what duplication, what improvement]" \
  --design "TDD-first refactoring steps:
1. Identify or write tests documenting the current behavior of [function] in [file]
2. Run tests and confirm they pass
3. [Specific extraction/move/refactoring steps for this candidate]
4. Update all call sites to use the new shared implementation
5. Run tests again and confirm behavior is unchanged
6. Remove the duplicated code
7. Run tests one final time
8. Commit" \
  --acceptance "Tests pass before and after refactoring. No change in observable behavior." \
  --notes "Pattern Category: [category]
Pattern: [pattern name]
Affected files: [file1, file2, ...]
Confidence: [high|medium]
Test coverage: [covered|partial|none]$(if language idiom: echo "
Language: [Go|Python|TypeScript]")" \
  --type task \
  --priority [2 if ≥3 files or cross-layer; 3 if 2 files same layer; 4 if minor]
```

**Title format:** Use the Fowler pattern name as prefix, then a concise action description.
- Good: `"Extract writeJSON to internal/framework"`
- Good: `"Parameterize FaultParam as generic FaultParam[T]"`
- Bad: `"Refactoring opportunity in handlers.go"`

**Design field:** Must contain specific, actionable TDD steps. Not generic instructions. Name the actual files, functions, and packages involved.

If `bd create` fails, log the failure with the candidate details and continue with remaining candidates. Do not retry.

## Output Format

Report back with:

```
VALIDATION REPORT:

Issues created:
  [issue-id]  P[priority]  [title]
  [issue-id]  P[priority]  [title]

Dismissed (false positives): [count]
  - [brief reason for each dismissal]

Deferred (trivial): [count]

Already tracked: [count]
```

If no issues were created:
```
VALIDATION REPORT:

No actionable refactoring opportunities confirmed.

Dismissed (false positives): [count]
Deferred (trivial): [count]
Already tracked: [count]
```
```

- [ ] **Step 2: Commit**

```bash
git add plugins/refactor/agents/validator.md
```

Commit message: `Add refactor-validator agent with issue creation workflow`

---

### Task 3: Scan Command

**Files:**
- Create: `plugins/refactor/commands/scan.md`

- [ ] **Step 1: Create commands directory**

```bash
mkdir -p plugins/refactor/commands
```

- [ ] **Step 2: Write the scan command**

Create `plugins/refactor/commands/scan.md`:

```markdown
---
name: scan
description: Scan committed code for refactoring opportunities across the codebase
argument-hint: "[--base <sha>]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
---

# /refactor:scan Command

Scan committed code against the codebase-memory index to detect refactoring opportunities. Uses a two-agent pipeline: scanner for breadth (queries semantic index), validator for depth (reads source files, creates beads issues).

## Argument Parsing

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `--base` | string | auto-detected | Base SHA to compare against. Auto-detects: `@{u}`, or `merge-base HEAD main`, or prompts. |

## Execution Flow

### Step 0: Ensure Codebase is Indexed

1. Call `codebase-memory-mcp` `list_projects` to check availability. If the MCP server is not available:
   ```
   codebase-memory-mcp not found. Cannot run semantic scan.
   Ensure it is configured in your MCP settings.
   ```
   Exit.

2. Check if the current project is indexed. Get the repo name:
   ```bash
   basename $(git rev-parse --show-toplevel)
   ```
   If the project is not in the `list_projects` response, automatically run `/codebase:index` to build the index.

3. If the project is indexed, check `.claude/codebase.local.md` for `last_indexed`. If >24 hours old, run `/codebase:index` to refresh the index.

### Step 1: Determine Base SHA

If `--base` is provided, use it directly.

If not provided, auto-detect:
```bash
git rev-parse @{u} 2>/dev/null
```
If that fails:
```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```
If all fail, use AskUserQuestion:
```
No upstream branch detected. What SHA should I compare against?
```

### Step 2: Check for Function Changes

```bash
git diff BASE..HEAD
```

Scan the diff for new function definitions. Look for lines matching:
- Go: `^+.*func `
- Python: `^+.*def `
- TypeScript/JavaScript: `^+.*(function |const .* = |=> )`
- Other: any new function-like definitions

If no function definitions found:
```
No new function definitions in diff — skipping scan.
```
Exit cleanly.

### Step 3: Dispatch Scanner Agent

Dispatch the `refactor-scanner` agent with:
- **diff**: The full output of `git diff BASE..HEAD`
- **task_title**: If available from context (e.g., from task-executor integration), include it. Otherwise use the most recent commit message.
- **task_description**: If available, include it. Otherwise omit.
- **base_sha**: The resolved base SHA
- **project**: The matched project name from Step 0

### Step 4: Handle Scanner Results

If scanner returns `CANDIDATES: none`:
```
No refactoring opportunities found.
```
Exit cleanly.

If scanner returns candidates, proceed to Step 5.

### Step 5: Dispatch Validator Agent

Dispatch the `refactor-validator` agent with:
- **candidates**: The full candidate list from the scanner
- **task_title**: Same as passed to scanner
- **project**: The matched project name

### Step 6: Print Report

Print the validator's report. Format:

```
Refactoring scan complete.

Issues created:
  [issue-id]  P[priority]  [title]
  [issue-id]  P[priority]  [title]

Dismissed (false positives): [count]
Deferred (trivial): [count]
Already tracked: [count]
```

If no issues were created but candidates were found:
```
Refactoring scan complete. No actionable opportunities confirmed.

Dismissed: [count]
Deferred: [count]
Already tracked: [count]
```
```

- [ ] **Step 3: Commit**

```bash
git add plugins/refactor/commands/scan.md
```

Commit message: `Add /refactor:scan command orchestrating scanner and validator`

---

### Task 4: Auto-trigger Skill

**Files:**
- Create: `plugins/refactor/skills/scan/SKILL.md`

- [ ] **Step 1: Create skills directory**

```bash
mkdir -p plugins/refactor/skills/scan
```

- [ ] **Step 2: Write the skill**

Create `plugins/refactor/skills/scan/SKILL.md`:

```markdown
---
description: |
  Scan for refactoring opportunities in committed code. Use when:
  "scan for refactoring opportunities", "check for code duplication",
  "look for patterns to extract", "refactoring scan",
  after a batch completes in /execute
---

# Refactoring Scan Skill

Automatically invoke `/refactor:scan` when the user asks about refactoring opportunities or after task execution completes.

## Activation

When this skill activates, invoke `/refactor:scan` with appropriate flags:

1. If the user mentions a specific commit SHA or task, pass it as `--base`.
2. If activated after a `/execute` batch completes, the base SHA is the commit before the batch started.
3. Otherwise, let `/refactor:scan` auto-detect the base SHA.

## Integration with task-executor

When the `task-executor` plugin closes a task and this skill is available, it should trigger a refactoring scan automatically:

1. The scan runs after `bd close` — the task is already done
2. Pass the git diff of the committed task changes
3. Report any created issue IDs in the batch summary
4. This is non-blocking: scan creates future work, never prevents completion
5. Skip if the diff contains no new function definitions

The execute command can suppress this with the `--no-refactor` flag.
```

- [ ] **Step 3: Commit**

```bash
git add plugins/refactor/skills/scan/SKILL.md
```

Commit message: `Add auto-trigger skill for refactoring scan`

---

### Task 5: README

**Files:**
- Create: `plugins/refactor/README.md`

- [ ] **Step 1: Write the README**

Create `plugins/refactor/README.md`:

```markdown
# Refactor Plugin

Semantic refactoring opportunity detection for Claude Code. After each task completes (or on demand), scans committed code against the codebase-memory index to find cross-package duplication, code smells, and design pattern opportunities. Creates actionable beads issues with TDD-first refactoring plans.

## Prerequisites

- **codebase-memory-mcp** — Semantic code index. Must be installed and configured.
- **codebase plugin** — Index management. The refactor plugin calls `/codebase:index` to ensure the index is fresh.
- **beads plugin** — Issue tracker. The validator creates beads issues for confirmed opportunities.
- **task-executor plugin** (optional) — Enables automatic post-task scanning.

## Usage

### Manual Scan

```
/refactor:scan                   # scan changes since upstream
/refactor:scan --base abc1234    # scan changes since specific SHA
```

### Automatic (with task-executor)

When installed alongside `task-executor`, the plugin automatically scans after each task closes. Suppress with `--no-refactor` on the execute command.

## What It Detects

### Structural Duplication (Fowler Catalog)
- Replace Inline Code with Function Call
- Extract Function + Move Function
- Parameterize Function
- Pull Up Method
- Introduce Parameter Object
- Replace Conditional with Polymorphism

### Code Smells (Fowler/Beck)
- Feature Envy, Data Clumps, Shotgun Surgery
- Divergent Change, Message Chains, Inappropriate Intimacy

### Design Pattern Opportunities (GoF)
- Strategy, Template Method, Factory Method
- Decorator, Facade, Observer, Command

### Principle Violations
- DRY (logic, knowledge, structural duplication)
- SOLID (SRP, OCP, ISP, DIP)
- Law of Demeter

### Language Idioms (Go, Python, TypeScript)
- Go: raw strings for typed values, error chain loss, unmanaged goroutines
- Python: manual resource management, mutable defaults, missing type annotations
- TypeScript: `any` type, manual null guards, `.then()` chains

## How It Works

1. **Scanner agent** queries `codebase-memory-mcp` for semantic similarity + analyzes the diff for structural patterns. Provides breadth — covers the entire codebase cheaply via the index.

2. **Validator agent** reads actual source files for confirmed candidates. Provides depth — checks test coverage, deduplicates against existing issues, creates beads issues with TDD-first plans.

## Output

```
Refactoring scan complete.

Issues created:
  beads-xxx  P2  Extract writeJSON to internal/framework
  beads-yyy  P3  Parameterize FaultParam as generic FaultParam[T]

Dismissed (false positives): 1
Deferred (trivial): 0
```

Each created issue includes:
- TDD-first refactoring steps in the design field
- Pattern classification in notes
- Test coverage status
- Priority based on scope (P2 for cross-layer, P3 for same-layer, P4 for minor)
```

- [ ] **Step 2: Commit**

```bash
git add plugins/refactor/README.md
```

Commit message: `Add refactor plugin README with detection taxonomy overview`

---

### Task 6: Marketplace Registration and plugin.json Update

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugins/refactor/.claude-plugin/plugin.json` (update description to mention codebase plugin dependency)

- [ ] **Step 1: Update plugin.json**

Read `plugins/refactor/.claude-plugin/plugin.json`. Update the description to reflect the codebase plugin dependency and the full detection scope:

```json
{
  "name": "refactor",
  "version": "0.1.0",
  "description": "Semantic refactoring opportunity detection. Scans committed code for structural duplication (Fowler catalog), code smells (Fowler/Beck), GoF design pattern opportunities, SOLID/DRY principle violations, and language-idiomatic anti-patterns. Creates beads issues with TDD-first refactoring plans.",
  "author": {
    "name": "Krishnaswamy Subramanian",
    "email": "jskswamy@gmail.com"
  },
  "keywords": [
    "refactoring",
    "code-quality",
    "duplication",
    "fowler",
    "beads",
    "codebase-memory",
    "semantic-search",
    "tdd",
    "code-smells",
    "design-patterns"
  ]
}
```

- [ ] **Step 2: Add refactor plugin to marketplace.json**

Read `.claude-plugin/marketplace.json`. Add this entry to the end of the `plugins` array:

```json
{
  "name": "refactor",
  "description": "Semantic refactoring opportunity detection. Scans committed code for structural duplication (Fowler catalog), code smells (Fowler/Beck), GoF design pattern opportunities, SOLID/DRY principle violations, and language-idiomatic anti-patterns (Go, Python, TypeScript). Creates beads issues with TDD-first refactoring plans. Hooks into task-executor after each task closes.",
  "version": "0.1.0",
  "author": {
    "name": "Krishnaswamy Subramanian"
  },
  "source": "./plugins/refactor",
  "category": "code-quality",
  "tags": [
    "refactoring",
    "duplication",
    "fowler",
    "beads",
    "codebase-memory",
    "tdd",
    "semantic-search"
  ]
}
```

- [ ] **Step 3: Validate JSON**

```bash
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); print('Valid JSON')"
python3 -c "import json; data = json.load(open('.claude-plugin/marketplace.json')); print(f'{len(data[\"plugins\"])} plugins registered')"
```

Expected: `Valid JSON` and `11 plugins registered`

- [ ] **Step 4: Commit**

```bash
git add plugins/refactor/.claude-plugin/plugin.json .claude-plugin/marketplace.json
```

Commit message: `Register refactor plugin in marketplace and update metadata`

---

## Self-Review

### Spec Coverage

| Spec Section | Task |
|---|---|
| 1. Problem | Addressed by overall plugin design |
| 2. What It Is Not | Enforced by scope — no review, no linting, no indexing |
| 3. Prerequisites | Checked in scan command Step 0; documented in README |
| 4. Architecture | Scanner (Task 1) + Validator (Task 2) + Scan command orchestration (Task 3) |
| 5.1 Structural Duplication | Scanner Pass 1, classification logic |
| 5.2 Code Smells | Scanner Pass 2 |
| 5.3 GoF Patterns | Scanner Pass 1, classification logic |
| 5.4 Principle Violations | Scanner Pass 2 |
| 5.5 Language Idioms | Scanner Pass 3 |
| 6.1 Scanner Agent | Task 1 |
| 6.2 Validator Agent | Task 2 |
| 6.3 Scan Command | Task 3 |
| 6.4 Auto-trigger Skill | Task 4 |
| 7. task-executor Integration | Documented in skill (Task 4) |
| 8. Plugin File Structure | All tasks combined |
| 9. Error Handling | Scan command handles errors per spec |
| 10. Marketplace Registration | Task 6 |
| 11. Out of Scope | Not implemented (correct) |

### Placeholder Scan

No TBD, TODO, or "implement later" found. All agents and commands contain complete instructions.

### Type Consistency

- Project name: consistently resolved via `list_projects` + repo basename
- Candidate format: scanner output matches validator input (`CANDIDATES:` format)
- Issue fields: validator uses `bd create` with all fields from spec Section 6.2
- Base SHA: consistently auto-detected in scan command, passed through to scanner
