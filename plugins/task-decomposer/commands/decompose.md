---
name: decompose
description: Decompose complex tasks into structured beads issues with direct argument control
argument-hint: "[task-description] [--epic|-e <title>] [--priority|-p 0-4] [--skip-questions|-q] [--dry-run|-d] [--quick]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

# /decompose Command

Decompose complex tasks into well-structured beads issues. This command provides direct entry point for task decomposition with explicit control over workflow phases.

## Argument Parsing

Parse the command arguments:

| Argument | Short | Type | Default | Description |
|----------|-------|------|---------|-------------|
| `task-description` | | string | (prompt) | The task to decompose |
| `--epic` | `-e` | string | (none) | Create as single epic with this title |
| `--epics` | | string | (none) | Create multiple epics (comma-separated titles) |
| `--priority` | `-p` | number | 2 | Default priority (0-4) |
| `--skip-questions` | `-q` | boolean | false | Skip clarifying questions |
| `--dry-run` | `-d` | boolean | false | Preview without creating |
| `--quick` | | boolean | false | No confirmations, proceed quickly |
| `--skip-design` | | boolean | false | Skip design exploration phase |

**Examples:**
```
/decompose "Add user authentication"
/decompose "Add caching" --epic "Performance Improvements"
/decompose -e "Auth System" -p 1 "Implement OAuth2 login"
/decompose --dry-run "Refactor database layer"
/decompose --quick "Add logout button"

# Multi-epic decomposition
/decompose "Build payment system" --epics "Payment UI,Payment Backend,Payment Security"
/decompose "Full-stack feature" --epics "Frontend Components,API Endpoints,Database Schema"
```

**Note:** `--epic` and `--epics` are mutually exclusive. Use `--epic` for a single epic, `--epics` for multiple.

---

## Execution Flow

### Step 1: Parse Arguments and Gather Task Description

If no task description provided, prompt for it:

```
What task would you like to decompose?
```

Extract all flags and the task description from the input.

### Step 2: Check for Existing Related Work

```bash
bd search "<relevant keywords from task>"
bd list --status=open
```

If related issues found, present them and ask if we should:
- Continue with new decomposition
- Update existing issues instead
- Link new work to existing

### Step 3: Understanding Phase (unless --skip-questions)

If `--skip-questions` is NOT set:

1. Parse the task description for:
   - Primary goals and desired outcomes
   - Scope boundaries (what's in/out)
   - Constraints (time, technology, dependencies)
   - Success criteria

2. Ask 2-3 clarifying questions via AskUserQuestion:
   - Focus on ambiguities or missing information
   - Keep questions targeted, not overwhelming

3. If code changes involved, explore the codebase:
   - Read relevant files to understand current implementation
   - Find patterns and conventions to follow
   - Identify integration points

4. Present Understanding Summary (unless --quick):
   ```
   ## Understanding Summary

   **Goal:** {what we're trying to achieve}

   **Scope:**
   - In scope: {list}
   - Out of scope: {list}

   **Constraints:** {any limitations}

   **Related existing issues:** {if any found}

   Does this capture the work correctly? [Confirm / Adjust]
   ```

If `--quick` flag is set, skip confirmations and proceed directly.

### Step 3b: Design Exploration (unless --skip-design or --quick)

If `--skip-design` is NOT set and `--quick` is NOT set:

1. **Explore project context:**
   - Read relevant source files, docs, and recent commits
   - Understand existing patterns and conventions

2. **Propose 2-3 approaches** with trade-offs:
   ```
   ## Design Exploration

   ### Approach A: {name}
   **How:** {brief description}
   **Pros/Cons:** {trade-offs}
   **Files affected:** {list}

   ### Approach B: {name}
   **How:** {brief description}
   **Pros/Cons:** {trade-offs}
   **Files affected:** {list}

   ### Recommendation: Approach {X}
   **Why:** {reasoning}

   Which approach? [A / B / Adjust]
   ```

3. **Wait for design approval** before proceeding to planning.

### Step 4: Design Phase

Break the task into logical work units using the **Do/Verify pattern** (inspired by superpowers methodology):

1. **Determine hierarchy:**
   - If `--epic` flag provided, create single epic with that title
   - If `--epics` flag provided, create multiple epics from comma-separated list
   - Otherwise, determine if epic(s) needed based on scope:
     - Analyze tasks for natural theme clusters
     - Suggest single epic, multiple epics, or no epic
   - Break into 3-7 tasks per epic (avoid over-decomposition)

2. **Size each task to 2-5 minutes of focused work:**
   - If a task is larger, decompose it further
   - Each task should be independently executable by a fresh agent

3. **Structure each task with Do/Verify:**
   - **Context**: Self-contained background (a fresh agent can work from this alone)
   - **Do**: Specific actions with exact file paths and code examples
   - **Verify**: Exact commands with expected outputs (the Iron Law)

4. **Group tasks into epics** (when multiple epics):
   - Assign each task to its most relevant epic
   - Tasks can be standalone if they don't fit any epic
   - Present grouping for user confirmation

5. **Map dependencies:**
   - What must complete before what?
   - What can be done in parallel?
   - Cross-epic dependencies are supported

6. **Define acceptance criteria as verification commands:**
   - Every criterion MUST map to a runnable command
   - Include expected output for each command
   - No vague criteria — if you can't verify it with a command, make it concrete

7. **Apply priority:**
   - Use `--priority` value as default
   - Adjust individual tasks if some are clearly higher/lower

8. **Draft design approach** with actionable detail:
   - Exact file paths for files to create/modify
   - Step-by-step implementation actions
   - TDD cycle where applicable

### Step 5: Present Decomposition Preview (Do/Verify format)

**Single epic format:**
```
## Decomposition Preview

### Epic: {title} (P{priority})
{description}

### Tasks:

#### Task 1: {descriptive name} (P{priority})

**Context:**
{Self-contained background for a fresh agent}

**Do:**
- {Action with exact file path}
- {Action with code example if needed}

**Verify:**
- `{command}` → {expected result}

**Dependencies:** none

#### Task 2: {descriptive name} (P{priority})
...

### Dependency Graph:
{epic}
  ├── Task 1 (no deps)
  ├── Task 2 (no deps)
  └── Task 3 → depends on Task 1, Task 2
```

**Multi-epic format:**
```
## Decomposition Preview

### Epic 1: {title} (P{priority})
{description}

#### Task 1.1: {descriptive name} (P{priority})

**Context:**
{Self-contained background for a fresh agent}

**Do:**
- {Action with exact file path}

**Verify:**
- `{command}` → {expected result}

### Epic 2: {title} (P{priority})
{description}

#### Task 2.1: {descriptive name} (P{priority})

**Context:**
{Self-contained background for a fresh agent}

**Do:**
- {Action with exact file path}

**Verify:**
- `{command}` → {expected result}

**Dependencies:** depends on Epic 1, Task 1.1

### Dependency Graph:
Epic 1: {title}
  ├── Task 1.1 (no deps)
  └── Task 1.2 (no deps)

Epic 2: {title}
  └── Task 2.1 → depends on Epic 1, Task 1.1
```

### Step 6: Handle --dry-run or Proceed to Creation

If `--dry-run` is set:
```
(Dry run - no issues will be created)

The above decomposition would create:
- {X} epic(s)
- {N} tasks
- {M} dependency relationships

Remove --dry-run to create these issues.
```

If `--quick` is NOT set, ask for approval:
```
Ready to create these issues? [Create / Adjust / Cancel]
```

If `--quick` IS set, proceed directly to creation.

### Step 7: Create Issues (via issue-writer agent)

Spawn the issue-writer agent with the approved decomposition:

```
Use the issue-writer agent to create:
{paste the decomposition preview}
```

The agent will:
1. Create epic first (if applicable)
2. Create independent tasks
3. Create dependent tasks
4. Add dependency edges
5. Report created issue IDs

### Step 8: Report Results

**Single epic:**
```
## Created Issues

- Epic: {id} - {title}
  - Task: {id} - {title}
  - Task: {id} - {title} (depends on {id})
  ...

Run `bd ready` to see what's available to work on.
```

**Multi-epic:**
```
## Created Issues

- Epic: {id} - {title}
  - Task: {id} - {title}
  - Task: {id} - {title}

- Epic: {id} - {title}
  - Task: {id} - {title} (depends on {other-epic-task-id})

- Standalone:
  - Task: {id} - {title}

Run `bd ready` to see what's available to work on.
```

---

## Flag Combinations

| Flags | Behavior |
|-------|----------|
| (none) | Full workflow with confirmations |
| `--quick` | Skip confirmations and design exploration |
| `--skip-questions` | Skip questions, still confirm |
| `--skip-design` | Skip design exploration, still confirm |
| `--quick --skip-questions` | Fastest: straight to design → create |
| `--dry-run` | Full workflow but no creation |
| `--dry-run --quick` | Fast preview only |

---

## Error Handling

### No task description
```
Error: No task description provided.

Usage: /decompose [task-description] [--flags]
Example: /decompose "Add user authentication"
```

### Invalid priority
```
Error: Invalid priority "{value}". Priority must be 0-4.
- P0: Critical/blocking
- P1: High priority
- P2: Medium priority (default)
- P3: Low priority
- P4: Backlog
```

### Conflicting epic flags
```
Error: Cannot use both --epic and --epics flags.

Use --epic for a single epic:
  /decompose "task" --epic "Epic Title"

Use --epics for multiple epics (comma-separated):
  /decompose "task" --epics "Epic 1,Epic 2,Epic 3"
```

### Beads not initialized
```
Error: Beads not initialized in this project.

Run: bd init
Then try again.
```

---

## Delegation Notes

This command delegates to:
- **decompose skill** - Core decomposition logic
- **issue-writer agent** - Issue creation execution

The command adds:
- Argument parsing and validation
- Flag-controlled workflow customization
- Dry-run capability
