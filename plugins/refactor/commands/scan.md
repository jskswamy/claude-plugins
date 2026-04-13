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
