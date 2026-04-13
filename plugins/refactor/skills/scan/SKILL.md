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
