---
name: execute
description: Execute decomposed beads tasks using isolated subagents with batch processing, dual-stage review, and atomic commits
argument-hint: "[--batch-size N] [--auto] [--no-commit] [--no-review] [--epic <id>] [--task <id>]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

# /execute Command

Execute decomposed beads tasks using isolated subagents. Each task gets a fresh agent with complete context, followed by dual-stage review (spec compliance + code quality) and an atomic commit via `/commit`.

## Argument Parsing

| Argument | Short | Type | Default | Description |
|----------|-------|------|---------|-------------|
| `--batch-size` | `-b` | number | 3 | Tasks per batch before human checkpoint |
| `--auto` | | boolean | false | Skip human checkpoints between batches |
| `--no-commit` | | boolean | false | Skip atomic commit after each task |
| `--no-review` | | boolean | false | Skip dual-stage review |
| `--epic` | `-e` | string | (none) | Execute tasks from specific epic only |
| `--task` | `-t` | string | (none) | Execute a single specific task |

**Examples:**
```
/execute                          # Execute all ready tasks, batch of 3
/execute --batch-size 5           # Larger batches
/execute --auto                   # No human checkpoints
/execute --epic abc123            # Only tasks from this epic
/execute --task xyz789            # Execute single task
/execute --no-commit              # Skip commits (stage changes only)
/execute --no-review --no-commit  # Fast mode: just implement
```

---

## Execution Flow

### Step 1: Discover Ready Tasks

```bash
bd ready --json
```

Apply filters:
- If `--epic` provided, filter to tasks under that epic
- If `--task` provided, use only that task
- Otherwise, use all ready tasks

If no ready tasks:
```
No tasks are ready to execute. All tasks may be blocked or completed.

Check status: bd list --status=open
Check blockers: bd blocked
```

### Step 2: Build Execution Plan

1. **Topological sort** tasks by dependencies
2. **Group into batches** of `--batch-size` tasks
3. Within each batch, identify tasks that can run **in parallel** (no mutual dependencies)
4. Present execution plan:

```
## Execution Plan

**Ready tasks:** {N}
**Batches:** {M}

### Batch 1:
- {id} - {title} (P{priority}) [parallel]
- {id} - {title} (P{priority}) [parallel]
- {id} - {title} (P{priority}) [sequential, depends on above]

### Batch 2:
- {id} - {title} (P{priority})
...

Proceed? [Execute / Adjust batch size / Cancel]
```

### Step 3: Execute Batch

For each task in the batch:

#### 3a. Mark In Progress

```bash
bd update {id} --status=in_progress
```

#### 3b. Build Self-Contained Prompt

Read the task's full details:
```bash
bd show {id} --json
```

Construct a prompt for the subagent containing:

```
You are executing a single task. Here is your complete context:

## Task: {title}

### Context (from description)
{description field — self-contained background}

### What To Do (from design)
{design field — step-by-step actions with file paths}

### How To Verify (from acceptance)
{acceptance field — exact commands with expected outputs}

### Additional Notes
{notes field — file paths, constraints, references}

## Instructions

1. Read and understand the context fully before making any changes.
2. Follow the "What To Do" steps exactly.
3. After implementation, run EVERY verification command from "How To Verify".
4. Report your results in this format:

### Implementation Report
- **Files changed:** {list with brief description}
- **Verification results:**
  | Command | Expected | Actual | Status |
  |---------|----------|--------|--------|
  | {cmd} | {expected} | {actual} | PASS/FAIL |
- **Concerns or deviations:** {any issues encountered}
```

#### 3c. Dispatch Subagent

```
Use the Task tool with subagent_type="general-purpose" and isolation="worktree":
- Send the self-contained prompt
- The agent works in an isolated worktree
- Capture the implementation report
```

For parallel tasks within a batch, dispatch multiple subagents simultaneously.

#### 3d. Collect Results

Parse the subagent's implementation report:
- Files changed
- Verification results (pass/fail per command)
- Concerns or deviations

### Step 4: Review (unless --no-review)

#### 4a. Spec Compliance Review

Spawn a reviewer subagent:

```
You are reviewing a task implementation for spec compliance.

## Original Task Specification
{task title, description, design, acceptance}

## Implementation Report
{subagent's report}

## Your Job

Check for:
1. **Missing requirements** — things in the spec that weren't implemented
2. **Extra work** — things implemented that weren't in the spec
3. **Misunderstandings** — wrong interpretation of requirements
4. **Verification gaps** — claims without evidence

IMPORTANT: The implementer may have finished quickly. Their report
may be incomplete, inaccurate, or optimistic. Be skeptical.

Output format:
- PASS: All requirements met with evidence ✓
- FAIL: {specific issues with file/line references}
```

If FAIL: Present issues to user, ask whether to re-execute or skip.

#### 4b. Code Quality Review (only if spec compliance passes)

Spawn a code quality reviewer:

```
You are reviewing code quality for a task implementation.

## Git Diff
{diff of changes}

## Review Criteria

Check for:
1. **Code style** — consistent with project conventions
2. **Error handling** — appropriate for the context
3. **Security** — no vulnerabilities introduced (OWASP top 10)
4. **Test quality** — tests are meaningful, not just coverage padding
5. **Complexity** — no over-engineering

Categorize issues:
- **Critical** — must fix before merge (security, data loss, crashes)
- **Important** — should fix (poor patterns, missing edge cases)
- **Minor** — nice to fix (naming, formatting)

Output: PASS (with strengths noted) or FAIL (with categorized issues)
```

If Critical issues found: Block completion, present to user.
If only Important/Minor: Present but allow proceeding.

### Step 5: Atomic Commit (unless --no-commit)

After successful review (or if --no-review):

1. Stage the changed files from the task
2. Invoke `/commit` with task context:
   ```
   /commit {task title} - {brief description of what was implemented}
   ```
3. The commit plugin handles message generation, style enforcement, and noise filtering

### Step 6: Close Task

```bash
bd close {id}
```

### Step 7: Batch Checkpoint (unless --auto)

After each batch completes, present a summary:

```
## Batch {N} Complete

| Task | Status | Review | Commit |
|------|--------|--------|--------|
| {id} - {title} | DONE | PASS | abc1234 |
| {id} - {title} | DONE | PASS | def5678 |
| {id} - {title} | FAILED | FAIL (spec) | — |

**Next batch:** {M} tasks
- {id} - {title}
- {id} - {title}

Continue? [Execute next batch / Re-execute failed / Stop]
```

If `--auto`: Skip checkpoint, continue to next batch automatically.

### Step 8: Final Report

After all batches complete:

```
## Execution Complete

**Summary:**
- Tasks executed: {N}
- Passed: {P}
- Failed: {F}
- Commits created: {C}

**Commits:**
- abc1234 - {subject}
- def5678 - {subject}

**Failed tasks (require attention):**
- {id} - {title}: {reason}

**Newly unblocked tasks:**
{Output from bd ready}
```

---

## Error Handling

### Subagent failure
If a subagent crashes or times out:
- Report the failure
- Ask user: Retry / Skip / Abort

### Review failure
If review identifies critical issues:
- Present the issues
- Ask user: Re-execute with fixes / Skip review / Abort

### Commit failure
If `/commit` fails:
- Stage changes are preserved
- Report the error
- Ask user: Retry commit / Skip commit / Abort

### Dependency violation
If a task's dependencies aren't met (race condition in parallel execution):
- Move task to next batch
- Continue with other tasks

---

## Integration Points

- **beads plugin**: Task discovery, status updates, closing
- **git-commit plugin**: Atomic commits via `/commit` command
- **task-decomposer**: Tasks follow Do/Verify format for optimal execution
