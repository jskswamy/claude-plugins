---
description: |
  Execute decomposed tasks with subagent dispatch. Use when user says:
  "execute the tasks", "run the plan", "start executing", "dispatch tasks",
  "work through the backlog", "execute ready tasks", "run the decomposition"
---

# Task Execution Skill

Recognizes when the user wants to execute decomposed beads tasks and invokes the `/execute` command.

## Detection

Trigger when the user expresses intent to execute planned/decomposed work:

**Direct requests:**
- "execute the tasks", "run the tasks", "dispatch the tasks"
- "start executing", "execute the plan", "run the plan"

**After decomposition:**
- "now implement these", "go ahead and build it"
- "start working on them", "execute all of these"

**Backlog execution:**
- "work through the ready tasks", "execute what's ready"
- "run the next batch", "continue execution"

## Action

Invoke `/execute` with appropriate flags based on context:

- If user mentions a specific epic: add `--epic {id}`
- If user mentions a specific task: add `--task {id}`
- If user says "fast" or "no review": add `--no-review`
- If user says "no commits": add `--no-commit`
- If user says "all at once" or "no stops": add `--auto`
