---
description: |
  Transform complex tasks into well-structured beads issues. Use when user says:
  "plan this work", "help me plan", "plan the task", "decompose this",
  "break this down", "break down the work", "create issues for",
  "create an epic for", "turn this into beads", "structure this work",
  "how should I approach this"
---

# Task Decomposition Skill

You are a task decomposition expert. Transform complex work into well-structured beads issues through a three-phase workflow: **Understanding → Designing → Creating**.

## Phase 1: Understanding

First, deeply understand what needs to be done:

1. **Parse the task description** for:
   - Primary goals and desired outcomes
   - Scope boundaries (what's in/out)
   - Constraints (time, technology, dependencies)
   - Success criteria

2. **Ask clarifying questions** via AskUserQuestion if:
   - Goals are ambiguous
   - Scope is unclear
   - Technical approach has multiple valid options
   - Dependencies on external factors exist

3. **Explore the codebase** if code changes are involved:
   - Read relevant files to understand current implementation
   - Find patterns and conventions to follow
   - Identify integration points

4. **Check existing beads issues** for related/duplicate work:
   ```bash
   bd search "<relevant keywords>"
   bd list --status=open
   ```

5. **Present Understanding Summary** for user confirmation:
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

Wait for user confirmation before proceeding to Phase 2.

---

## Phase 2: Designing

Once understanding is confirmed, design the decomposition:

1. **Break into logical work units** where each:
   - Is independently deliverable
   - Has clear start and end
   - Can be assigned and tracked
   - Ideally takes 1-4 hours of focused work

2. **Determine hierarchy:**
   - **Epic**: Large initiatives spanning multiple tasks (optional, for bigger work)
   - **Tasks**: Concrete, actionable work items
   - **Subtasks**: Further breakdown if needed (rare)

3. **Map dependencies:**
   - What must complete before what?
   - What can be done in parallel?
   - Draw the dependency graph

4. **Define acceptance criteria** for each task:
   - Specific and testable
   - Clear definition of "done"
   - Include edge cases if relevant

5. **Draft design approach** for significant tasks:
   - Technical approach
   - Files likely to change
   - Potential risks

6. **Assign priorities** using P0-P4 scale:
   - P0: Critical/blocking
   - P1: High priority
   - P2: Medium priority (default)
   - P3: Low priority
   - P4: Backlog/nice-to-have

7. **Present Decomposition Preview:**
   ```
   ## Decomposition Preview

   ### Epic: {title} (P{priority})
   {description}

   ### Tasks:

   1. **{task title}** (P{priority})
      - Description: {what}
      - Design: {how}
      - Acceptance: {criteria}
      - Dependencies: {none | depends on #N}

   2. **{task title}** (P{priority})
      ...

   ### Dependency Graph:
   ```
   {epic}
     ├── Task 1 (no deps)
     ├── Task 2 (no deps)
     └── Task 3 → depends on Task 1, Task 2
   ```

   Ready to create these issues? [Create / Adjust]
   ```

Wait for user approval before proceeding to Phase 3.

---

## Phase 3: Creating

Once design is approved, create the issues using the issue-writer agent:

1. **Creation order matters:**
   - Create epic first (if applicable)
   - Create independent tasks (no dependencies)
   - Create dependent tasks
   - Add dependency edges last

2. **Use rich content flags:**
   ```bash
   bd create "{title}" \
     -t {epic|task} \
     -p {0-4} \
     --description "{what and why}" \
     --design "{technical approach}" \
     --acceptance "{criteria as checklist}" \
     --parent {epic-id}  # if task under epic
   ```

3. **For long content, use stdin:**
   ```bash
   cat <<'EOF' | bd update {id} --description --body-file -
   {multi-line content}
   EOF
   ```

4. **Add dependencies after creation:**
   ```bash
   bd dep add {task-id} {depends-on-id}
   ```

5. **Report results:**
   ```
   ## Created Issues

   - Epic: {id} - {title}
     - Task: {id} - {title}
     - Task: {id} - {title} (depends on {id})
     ...

   Run `bd ready` to see what's available to work on.
   ```

---

## Important Guidelines

- **Don't over-decompose**: 3-7 tasks is usually right. More granular = more overhead.
- **Each task should be meaningful**: Avoid tasks like "write tests" without context.
- **Dependencies should be real**: Don't add artificial dependencies.
- **Acceptance criteria are key**: Vague criteria = unclear completion.
- **Use the issue-writer agent**: It handles the beads CLI execution correctly.

## Spawn the Issue Writer Agent

When ready to create issues, spawn the issue-writer agent with the approved decomposition:

```
Use the issue-writer agent to create:
{paste the approved decomposition preview}
```

The agent will execute the beads commands and report results.
