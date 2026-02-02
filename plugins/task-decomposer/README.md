# Task Decomposer Plugin

Transform complex tasks into well-structured beads issues through a thoughtful workflow, capture side ideas without breaking flow, and create rich commit messages with full context.

## Features

- **Task Decomposition:** Break down complex work into structured beads issues with dependencies and acceptance criteria
- **Multi-Epic Support:** Create multiple epics per decomposition with auto-grouping based on themes
- **Idea Parking:** Capture side thoughts without breaking flow, review and promote later
- **Backlog Dashboard:** View all work with filters for ready, blocked, priorities, and epic progress
- **Dependency Management:** Visualize and manage task dependencies with tree and mermaid formats

## Usage

```bash
/decompose "Add user authentication"                    # Full workflow
/decompose "Add caching" --epic "Performance"           # Create as single epic
/decompose --epics "Frontend,Backend" "Full-stack"      # Multi-epic
/task start abc123                                      # Start working on task
/park "Consider rate limiting"                          # Park an idea
/backlog ready                                          # See ready tasks
```

## Commands and Skills

### Commands

Commands provide explicit entry points with argument control. Use these when you want direct control over the workflow.

| Command | Description | Example |
|---------|-------------|---------|
| `/decompose` | Decompose tasks into beads issues | `/decompose "Add auth" --dry-run` |
| `/task` | Single task operations | `/task start abc123` |
| `/park` | Quick idea parking with metadata | `/park "Add caching" -p 3` |
| `/parked` | Manage parked ideas | `/parked promote xyz` |
| `/backlog` | Dashboard views of work | `/backlog ready` |
| `/epic` | Epic management | `/epic progress abc123` |
| `/deps` | Dependency management | `/deps graph` |

### Skills

Skills are auto-invoked based on conversation context. They complement the commands.

| Skill | Trigger Phrases |
|-------|-----------------|
| `understand` | "help me understand", "clarify this task", "what am I missing" |
| `decompose` | "plan this work", "break this down", "create issues for" |
| `park-idea` | "park this", "btw:", "tangent:", "note for later" |
| `review-parked` | "review parked", "show parked", "what did I park" |
| `task-commit` | "task commit", "commit this task", "beads commit" |

---

## Command Reference

### /decompose - Task Decomposition

Decompose complex tasks into structured beads issues with explicit control.

```bash
/decompose "Add user authentication"                    # Full workflow
/decompose "Add caching" --epic "Performance"           # Create as single epic
/decompose -p 1 "Critical security fix"                 # Set priority
/decompose --dry-run "Refactor database"                # Preview only
/decompose --quick --skip-questions "Simple task"       # Fast mode

# Multi-epic decomposition
/decompose "Build payment system" --epics "Payment UI,Payment Backend,Payment Security"
/decompose "Full-stack feature" --epics "Frontend,API,Database"
```

**Arguments:**
| Flag | Short | Description |
|------|-------|-------------|
| `--epic` | `-e` | Create as single epic with title |
| `--epics` | | Create multiple epics (comma-separated titles) |
| `--priority` | `-p` | Default priority 0-4 |
| `--skip-questions` | `-q` | Skip clarifying questions |
| `--dry-run` | `-d` | Preview without creating |
| `--quick` | | No confirmations |

**Note:** `--epic` and `--epics` are mutually exclusive.

### /task - Single Task Operations

Create, start, complete, and view individual tasks.

```bash
/task create "Fix login bug"                       # Create task
/task create "Add tests" -p 1 --parent abc123      # With options
/task start abc123                                 # Start working
/task done abc123                                  # Mark complete
/task done abc123 --commit                         # Complete and commit
/task show abc123                                  # View details
/task next                                         # Get recommendation
```

**Subcommands:**
- `create <title>` - Create with `--description`, `--design`, `--acceptance`, `--priority`, `--parent`
- `start <id>` - Mark in-progress, show context
- `done <id>` - Close task, `--commit` triggers task-commit skill
- `show <id>` - Display details, `--format brief|full|json`
- `next` - Recommend next task based on priorities

### /park - Quick Idea Parking

Park ideas quickly with optional metadata.

```bash
/park "Add caching to the API"                     # Basic parking
/park "Consider rate limiting" -t abc123           # Link to task
/park -p 3 "Refactor auth module"                  # Set priority
/park --tags "perf,db" "Index user table"          # Add tags
/park -q "Remember to update docs"                 # Quick mode
```

**Arguments:**
| Flag | Short | Description |
|------|-------|-------------|
| `--task` | `-t` | Link to specific task |
| `--priority` | `-p` | Priority override (default: 4) |
| `--tags` | | Additional comma-separated tags |
| `--quick` | `-q` | Minimal output |

### /parked - Manage Parked Ideas

List, filter, and manage parked ideas.

```bash
/parked                                            # List all
/parked list --format full                         # Detailed view
/parked from abc123                                # From specific task
/parked promote xyz                                # Promote to real task
/parked promote xyz --decompose                    # Promote and decompose
/parked discard xyz                                # Delete idea
/parked review                                     # Interactive review
```

**Subcommands:**
- `list` - List all parked (default), `--format`, `--since`, `--limit`
- `from <task-id>` - Ideas from specific task
- `promote <id>...` - Promote to real issues, `--priority`, `--decompose`
- `discard <id>...` - Delete parked ideas, `--force`
- `review` - Interactive review session

### /backlog - Work Dashboard

Dashboard views of all work with filtering.

```bash
/backlog                                           # Overview stats
/backlog ready                                     # Ready to work
/backlog ready -p 1                                # High priority only
/backlog blocked                                   # Show blocked tasks
/backlog priorities                                # Group by priority
/backlog epics                                     # Epic progress view
```

**Views:**
- `overview` - Summary statistics (default)
- `ready` - Tasks ready to work (no blockers)
- `blocked` - Blocked tasks with reasons
- `priorities` - Grouped by P0-P4
- `epics` - Epic-centric progress view

**Filters:** `--status`, `--priority`, `--epic`, `--format`, `--limit`

### /epic - Epic Management

Create and manage epics, track progress.

```bash
/epic create "Auth System"                         # Create epic
/epic create "API v2" -p 1 -d "Full redesign"      # With options
/epic add abc123 task1 task2                       # Add tasks
/epic remove abc123 task1                          # Remove task
/epic progress abc123                              # Show progress
/epic close abc123                                 # Close epic
/epic close abc123 --force                         # Force close
```

**Subcommands:**
- `create <title>` - Create with `--description`, `--priority`, `--design`
- `add <epic> <tasks...>` - Add tasks to epic
- `remove <epic> <tasks...>` - Remove tasks
- `progress <epic>` - Show completion progress
- `close <epic>` - Close epic, `--force` if tasks open

### /deps - Dependency Management

Manage and visualize task dependencies.

```bash
/deps add task1 task2                              # task1 depends on task2
/deps remove task1 task2                           # Remove dependency
/deps show task1                                   # Show dependencies
/deps graph                                        # Full graph
/deps graph task1                                  # Centered on task
/deps graph --format mermaid                       # Mermaid diagram
```

**Subcommands:**
- `add <task> <depends-on>` - Add dependency
- `remove <task> <depends-on>` - Remove dependency
- `show <task>` - Show what blocks this task
- `graph [task]` - Visualize graph, `--format tree|mermaid|json`, `--depth`

---

## Skill Reference

### Task Understanding (`/understand`)

Deeply explore a task through structured questioning before any planning begins.

**When to use:**
- Task is fuzzy or complex
- Suspect hidden complexity
- Want systematic exploration before committing to a plan

**Seven questioning dimensions:**
1. Goal Clarity - What does "done" look like?
2. Context & Background - What triggered this?
3. Scope Boundaries - What's in/out?
4. Constraints & Requirements - Performance, security, tech limits?
5. Dependencies & Integration - What systems does this touch?
6. Risks & Unknowns - What could go wrong?
7. Success Criteria - How will we verify it works?

### Task Decomposition (`/decompose`)

Break down complex work into structured beads issues through three phases.

**Phases:**
1. **Understanding** - Parse goals, ask clarifying questions, explore codebase
2. **Designing** - Create hierarchy, map dependencies, define acceptance criteria
3. **Creating** - Execute beads commands in correct order

### Idea Parking (`/park-idea`)

Quickly capture side thoughts while working without breaking flow.

**Principles:**
- Maximum 1 question (if idea isn't clear)
- Auto-captures current task context
- Creates deferred issue with `parked-idea` label
- Returns you to work immediately

### Parked Idea Review (`/review-parked`)

Review ideas you've parked and decide what to do with them.

**Options for each idea:**
- Promote to real issue
- Run through decomposition
- Keep parked for later
- Discard

### Task Commit (`/task-commit`)

Create rich commit messages combining beads context with code changes.

**Generated message includes:**
- What: Goal from task description
- Why: Approach from task design
- Changes: Summary of code modifications
- Acceptance: Which criteria were met

---

## Installation

```bash
claude --plugin-dir ./plugins/task-decomposer
```

Or add to your Claude Code settings.

## Requirements

- [beads plugin](https://github.com/jskswamy/claude-plugins/tree/main/plugins/beads) must be installed and initialized
- Git repository for commit features

## Workflows

### Planning New Work

```
1. /decompose "Add feature X"      # Decompose into issues
2. bd ready                        # See what's available
3. /task start <id>                # Start working
4. /park "Related idea"            # Capture side thoughts
5. /task done <id> --commit        # Complete and commit
6. /parked review                  # Review captured ideas
```

### Managing Epics

```
1. /epic create "Auth System"      # Create epic
2. /decompose "..." --epic "Auth..." # Add decomposed work
3. /epic progress <id>             # Track progress
4. /epic close <id>                # Close when done
```

### Multi-Epic Decomposition

When work spans multiple themes or areas, decompose into multiple epics:

```
# Explicit multi-epic
/decompose "Build payment system" --epics "Payment UI,Payment Backend,Payment Security"

# Auto-detected grouping (no flags)
/decompose "Implement full-stack authentication with OAuth, UI components, and security hardening"
# → Suggests: Epic 1: "Auth UI", Epic 2: "Auth Backend", Epic 3: "Security"
# → You can accept, adjust, or flatten to single epic
```

**Auto-grouping detection:**
- Analyzes task descriptions for theme keywords (UI, backend, security, etc.)
- Groups tasks with 2+ related items into epics
- Presents suggestions for user confirmation
- Handles cross-epic dependencies correctly

### Understanding Dependencies

```
1. /deps graph                     # See full picture
2. /deps show <task>               # What blocks this?
3. /backlog blocked                # All blocked work
4. /task next                      # What's ready?
```

## Plugin Structure

```
task-decomposer/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── decompose.md      # Task decomposition command
│   ├── task.md           # Single task operations
│   ├── park.md           # Quick idea parking
│   ├── parked.md         # Manage parked ideas
│   ├── backlog.md        # Dashboard views
│   ├── epic.md           # Epic management
│   └── deps.md           # Dependency management
├── skills/
│   ├── understand.md     # Deep task exploration
│   ├── decompose.md      # Main decomposition workflow
│   ├── park-idea.md      # Quick idea capture
│   ├── review-parked.md  # Review parked ideas
│   └── task-commit.md    # Commit with beads context
├── hooks/
│   └── review-after-commit.md  # Auto-prompt after commits
├── agents/
│   └── issue-writer.md   # Executes beads CLI commands
└── README.md
```

## Tips

- **Commands vs Skills**: Use commands for explicit control, skills trigger automatically
- **Understand before decomposing**: For fuzzy tasks, use `/understand` first
- **Don't over-decompose**: 3-7 tasks is usually the sweet spot
- **Park liberally**: Capturing ideas is cheap, losing them is expensive
- **Review regularly**: Parked ideas can become stale
- **Use /task next**: Let it recommend based on priorities and dependencies
- **Visualize with /deps graph**: Understand the big picture

## Changelog

### v1.4.0
- **Feature:** Multi-epic support in `/decompose` command
  - New `--epics` flag for explicit multi-epic decomposition (comma-separated titles)
  - Auto-grouping heuristics detect when multiple epics are appropriate
  - Theme-based task clustering (UI, backend, security, testing, etc.)
  - Cross-epic dependency support
  - Updated issue-writer agent for multi-epic creation

### v1.3.0
- **Breaking:** Renamed `/plan` command to `/decompose` to avoid conflict with Claude Code's built-in `/plan` command

### v1.2.0
- Added 7 commands: `/decompose`, `/task`, `/park`, `/parked`, `/backlog`, `/epic`, `/deps`
- Commands provide explicit argument control complementing auto-invoked skills

### v1.1.0
- Added `/understand` skill for deep task exploration

### v1.0.0
- Initial release with decompose, park-idea, review-parked, task-commit skills
- Issue-writer agent for beads CLI execution
- Review-after-commit hook

## License

MIT
