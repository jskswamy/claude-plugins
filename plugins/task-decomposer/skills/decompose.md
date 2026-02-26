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

Wait for user confirmation before proceeding to Phase 1b.

---

## Phase 1b: Design Exploration (Brainstorm Gate)

**Skip this phase if `--skip-design` flag is set.**

Before planning tasks, explore the design space and get user approval on the approach. This prevents wasted effort on a plan built on the wrong foundation.

1. **Explore project context:**
   - Read relevant source files, docs, and recent commits
   - Understand existing patterns and conventions
   - Identify constraints from the codebase

2. **Propose 2-3 approaches** with trade-offs:

   ```
   ## Design Exploration

   I've explored the codebase and identified these approaches:

   ### Approach A: {name}
   **How:** {brief technical description}
   **Pros:** {advantages}
   **Cons:** {disadvantages}
   **Files affected:** {list of key files}
   **Estimated tasks:** {rough count}

   ### Approach B: {name}
   **How:** {brief technical description}
   **Pros:** {advantages}
   **Cons:** {disadvantages}
   **Files affected:** {list of key files}
   **Estimated tasks:** {rough count}

   ### Approach C: {name} (if applicable)
   ...

   ### Recommendation: Approach {X}
   **Why:** {reasoning for the recommendation}

   Which approach should we plan with? [A / B / C / Adjust]
   ```

3. **Ask ONE clarifying question per message** if design decisions need input:
   - Don't overwhelm with multiple questions at once
   - Each question should be focused and specific

4. **Wait for explicit design approval** before proceeding to Phase 2:
   - User must select an approach or provide direction
   - This is a hard gate — no planning without approved design
   - Document the approved design for reference in task creation

---

## Phase 2: Designing

Once understanding is confirmed, design the decomposition:

1. **Break into logical work units** where each:
   - Is independently deliverable
   - Has clear start and end
   - Can be assigned and tracked
   - **Takes 2-5 minutes of focused work** (the critical sizing constraint — if larger, decompose further)
   - Is **self-contained**: a fresh agent with zero prior context can execute it

2. **Structure each task using the Do/Verify pattern:**

   Every task MUST have explicit **Do** (actions) and **Verify** (evidence) sections:

   ```
   ### Task N: {Descriptive Name}

   **Context:**
   {Everything a fresh agent needs to know — goal, relevant architecture,
   files involved, constraints. Assume ZERO prior knowledge.}

   **Do:**
   - {Specific action with exact file path: `src/lib/store.ts`}
   - {Another action with code example if needed}
   - {Action for tests: `src/lib/store.test.ts`}

   **Verify:**
   - `{exact command}` → {expected result description}
   - `{exact command}` → {expected result description}
   ```

   **Do section rules:**
   - Include **exact file paths** for every file to create or modify
   - Include code examples where the approach isn't obvious
   - Each step should be a concrete action, not a vague instruction
   - Follow TDD when applicable: write failing test → verify failure → implement → verify pass

   **Verify section rules:**
   - Every task MUST have at least one verification command
   - Commands must be **exact** — copy-pasteable into a terminal
   - Include **expected output** so the agent knows what "pass" looks like
   - Common verifications: test commands, build commands, lint commands, curl for APIs
   - The "Iron Law": NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE

   **Context section rules:**
   - Include the goal/problem being solved
   - Reference relevant architecture or patterns
   - List files that will be read or modified
   - Mention constraints or gotchas
   - A fresh agent reading ONLY this context should be able to do the work

3. **Determine hierarchy:**
   - **Epics**: Large initiatives spanning multiple tasks (optional, for bigger work)
     - Single epic: When all tasks share one theme
     - Multiple epics: When tasks naturally group into distinct themes/areas
   - **Tasks**: Concrete, actionable work items
   - **Subtasks**: Further breakdown if needed (rare)

3. **Auto-detect epic groupings** (when no explicit `--epic` or `--epics` provided):

   **Indicators for multiple epics:**
   - Tasks span 2+ distinct technology layers (frontend/backend/database/infra)
   - Tasks span 2+ functional areas (auth/payments/notifications/analytics)
   - Tasks have clear owner boundaries (different teams would work on them)
   - Total task count exceeds 6-8 (too many for one epic)

   **Theme detection heuristics:**
   | Theme | Keyword patterns |
   |-------|------------------|
   | UI/Frontend | ui, component, page, view, form, button, style, css, layout |
   | Backend/API | api, endpoint, service, controller, route, handler |
   | Database | database, schema, migration, model, query, table |
   | Security | auth, permission, role, token, encrypt, security |
   | Testing | test, spec, mock, fixture, coverage |
   | Documentation | doc, readme, guide, example |
   | Infrastructure | deploy, config, ci, docker, k8s, infra |

   **Grouping algorithm:**
   1. Analyze each task's title and description for theme keywords
   2. Assign primary theme to each task
   3. Group tasks by theme
   4. If a theme has only 1 task, consider merging with related theme or keeping standalone
   5. Create epic only for groups with 2+ tasks

   **Present grouping decision:**
   ```
   Based on task analysis, I suggest organizing into {N} epics:

   Epic 1: "{Theme A}" (tasks: 1, 2, 5)
   Epic 2: "{Theme B}" (tasks: 3, 4)
   Standalone: task 6

   Would you like to:
   - [Accept] Use this grouping
   - [Single Epic] Combine all into one epic
   - [No Epics] Create tasks without epics
   - [Adjust] Modify the groupings
   ```

4. **Finalize epic groupings** (when multiple epics are appropriate):
   - Confirm theme clusters with user (UI, backend, security, testing, etc.)
   - Ensure each epic has 2+ related tasks
   - Mark tasks as standalone if they don't fit any epic
   - Adjust based on user feedback

5. **Map dependencies:**
   - What must complete before what?
   - What can be done in parallel?
   - Cross-epic dependencies are allowed
   - Draw the dependency graph

6. **Define acceptance criteria** as verification commands:
   - Every criterion MUST map to a runnable command with expected output
   - "Tests pass" → `npm test -- --grep "auth"` → "All tests pass, 0 failures"
   - "API responds correctly" → `curl -s localhost:3000/api/health | jq .status` → `"ok"`
   - "Build succeeds" → `npm run build` → "exit code 0, no errors"
   - Include edge case tests where relevant

7. **Draft design approach** with actionable detail:
   - Technical approach with exact file paths
   - Step-by-step implementation plan (the "Do" steps)
   - Potential risks and mitigations
   - TDD cycle: which test to write first, what failure to expect

8. **Assign priorities** using P0-P4 scale:
   - P0: Critical/blocking
   - P1: High priority
   - P2: Medium priority (default)
   - P3: Low priority
   - P4: Backlog/nice-to-have

9. **Present Decomposition Preview** (using Do/Verify format):

   **For single epic:**
   ```
   ## Decomposition Preview

   ### Epic: {title} (P{priority})
   {description}

   ### Tasks:

   #### Task 1: {descriptive name} (P{priority})

   **Context:**
   {What a fresh agent needs to know to do this work}

   **Do:**
   - {Action with exact file path}
   - {Action with code example if needed}

   **Verify:**
   - `{command}` → {expected result}
   - `{command}` → {expected result}

   **Dependencies:** {none | depends on Task N}

   #### Task 2: {descriptive name} (P{priority})
   ...

   ### Dependency Graph:
   {epic}
     ├── Task 1 (no deps)
     ├── Task 2 (no deps)
     └── Task 3 → depends on Task 1, Task 2

   Ready to create these issues? [Create / Adjust]
   ```

   **For multiple epics:**
   ```
   ## Decomposition Preview

   ### Epic 1: {title} (P{priority})
   {description}

   #### Task 1.1: {descriptive name} (P{priority})

   **Context:**
   {Self-contained context for a fresh agent}

   **Do:**
   - {Action with exact file path}

   **Verify:**
   - `{command}` → {expected result}

   ### Epic 2: {title} (P{priority})
   {description}

   #### Task 2.1: {descriptive name} (P{priority})

   **Context:**
   {Self-contained context for a fresh agent}

   **Do:**
   - {Action with exact file path}

   **Verify:**
   - `{command}` → {expected result}

   **Dependencies:** depends on Epic 1, Task 1.1

   ### Standalone Tasks (no epic):
   #### Task S1: {descriptive name} (P{priority})
   ...

   ### Dependency Graph:
   Epic 1: {title}
     ├── Task 1.1 (no deps)
     └── Task 1.2 (no deps)

   Epic 2: {title}
     ├── Task 2.1 → depends on Epic 1, Task 1.1
     └── Task 2.2 (no deps)

   Standalone:
     └── Task S1 → depends on Epic 2, Task 2.1

   Ready to create these issues? [Create / Adjust]
   ```

Wait for user approval before proceeding to Phase 3.

---

## Phase 3: Creating

Once design is approved, create the issues using the issue-writer agent:

1. **Creation order matters:**
   - Create all epics first (if applicable)
   - Create independent tasks (no dependencies) under their respective epics
   - Create dependent tasks
   - Add dependency edges last (including cross-epic dependencies)

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

- **Task sizing**: Each task should be 2-5 minutes of focused work. If it's bigger, break it down further.
- **Self-contained context**: A fresh agent with zero prior knowledge must be able to execute any task from its Context section alone.
- **Every task needs verification**: No exceptions. If you can't write a verification command, the acceptance criteria are too vague.
- **Do steps must be concrete**: Include exact file paths, code examples where non-obvious, and specific actions. "Implement the feature" is not a Do step.
- **Evidence before claims**: The Iron Law — no task is done until verification commands have been run and produced expected output.
- **Dependencies should be real**: Don't add artificial dependencies.
- **Use the issue-writer agent**: It handles the beads CLI execution correctly.
- **Task ordering pattern**: Setup/scaffolding → Core logic (with tests) → Integration → Cross-cutting concerns → Documentation.

## Spawn the Issue Writer Agent

When ready to create issues, spawn the issue-writer agent with the approved decomposition:

```
Use the issue-writer agent to create:
{paste the approved decomposition preview}
```

The agent will execute the beads commands and report results.
