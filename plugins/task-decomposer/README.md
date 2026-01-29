# Task Decomposer Plugin

Transform complex tasks into well-structured beads issues through a thoughtful workflow, capture side ideas without breaking flow, and create rich commit messages with full context.

## Features

### 1. Task Decomposition (`/decompose`)

Break down complex work into structured beads issues through three phases:

1. **Understanding** - Parse goals, ask clarifying questions, explore codebase
2. **Designing** - Create hierarchy, map dependencies, define acceptance criteria
3. **Creating** - Execute beads commands in correct order

**Trigger phrases:**
- "plan this work", "help me plan", "decompose this"
- "break this down", "create issues for", "turn this into beads"
- "structure this work", "how should I approach this"

### 2. Idea Parking (`/park-idea`)

Quickly capture side thoughts while working without breaking your flow.

**Trigger phrases:**
- "park this idea", "save this for later", "side thought"
- "note for later", "don't forget", "tangent:", "btw:"

**How it works:**
- Asks only one question (if the idea isn't already clear)
- Auto-captures current task context
- Creates a deferred issue with `parked-idea` label
- Returns you to work immediately

### 3. Parked Idea Review (`/review-parked`)

Review ideas you've parked and decide what to do with them.

**Trigger phrases:**
- "review parked ideas", "show parked", "what did I park"
- "check my parking lot", "any ideas parked"

**Options for each idea:**
- Promote to real issue
- Run through decomposition for complex ideas
- Keep parked for later
- Discard

### 4. Task Commit (`/task-commit`)

Create rich commit messages combining beads context with code changes.

**Trigger phrases:**
- "commit this task", "task commit", "commit with context"
- "beads commit", after closing a task: "now commit"

**Generated message includes:**
- What: Goal from task description
- Why: Approach from task design
- Changes: Summary of actual code modifications
- Acceptance: Which criteria were met

### 5. Automatic Review Prompt

After committing work for a task, automatically prompts you to review any ideas you parked while working on it.

## Installation

```bash
claude --plugin-dir ./plugins/task-decomposer
```

Or add to your Claude Code settings.

## Usage Examples

### Decomposing a Feature

```
User: Help me plan adding user authentication to the API

Claude: [Enters Understanding phase]
- Asks clarifying questions about auth method, session handling
- Checks existing code patterns
- Presents understanding summary

User: [Confirms understanding]

Claude: [Enters Design phase]
- Breaks into: Epic + 4 tasks with dependencies
- Shows preview with dependency graph

User: [Approves design]

Claude: [Creates issues via issue-writer agent]
- Reports created issue IDs
```

### Parking an Idea

```
User: btw: we should add rate limiting to this endpoint

Claude: Parked as claude-plugins-xyz! Continuing with the auth implementation...
```

### Committing with Context

```
User: task commit

Claude: [Gathers beads context + git diff]

Generated message:
---
feat: Add JWT authentication to API (#claude-plugins-abc)

## What
Implement JWT-based authentication for API endpoints...

## Why
Used RS256 signing for security, with refresh token rotation...

## Changes
- src/auth/jwt.ts: New JWT utilities
- src/middleware/auth.ts: Auth middleware
- src/routes/auth.ts: Login/logout endpoints

## Acceptance
- [x] Tokens expire after 15 minutes
- [x] Refresh tokens rotate on use
- [x] Invalid tokens return 401

Closes: claude-plugins-abc
---

Commit as-is? [Yes / Edit / Regenerate]
```

## Requirements

- [beads plugin](https://github.com/jskswamy/claude-plugins/tree/main/plugins/beads) must be installed and initialized
- Git repository for commit features

## How It Works

### Decomposition Flow

```
Understanding → User Confirms → Designing → User Approves → Creating
     ↓                              ↓                           ↓
Parse goals               Map dependencies            Execute bd commands
Ask questions            Define acceptance           Report created IDs
Explore code             Assign priorities
```

### Parking Flow

```
User says "park this" → Auto-detect context → Create deferred issue → Back to work
                              ↓
                        Current task
                        Current file
                        What triggered it
```

### Commit Flow

```
Identify task → Gather beads context → Gather git context → Generate message → Commit
                      ↓                       ↓
                 title, desc,           staged diff,
                 design, acc            file changes
```

## Plugin Structure

```
task-decomposer/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── decompose.md          # Main decomposition workflow
│   ├── park-idea.md          # Quick idea capture
│   ├── review-parked.md      # Review parked ideas
│   └── task-commit.md        # Commit with beads context
├── hooks/
│   └── review-after-commit.md  # Auto-prompt after task commits
├── agents/
│   └── issue-writer.md       # Executes beads CLI commands
└── README.md
```

## Tips

- **Don't over-decompose**: 3-7 tasks is usually the sweet spot
- **Park liberally**: Capturing ideas is cheap, losing them is expensive
- **Review regularly**: Parked ideas can become stale
- **Use task-commit for traceability**: Links code changes to issues

## License

MIT
