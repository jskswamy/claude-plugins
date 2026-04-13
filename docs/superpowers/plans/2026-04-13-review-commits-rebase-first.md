# Review-Commits Rebase-First Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace soft-reset with interactive rebase as the default mechanism in review-commits, and add automatic commit hygiene analysis with codebase-memory-mcp integration.

**Architecture:** Single skill file rewrite. The review-commits SKILL.md is a prompt-based skill — all logic is expressed as instructions for Claude Code to follow. No scripts, no code files. The skill orchestrates git commands, MCP tool calls, AskUserQuestion prompts, and `/commit` invocations.

**Tech Stack:** Markdown skill definition, git rebase, `GIT_SEQUENCE_EDITOR`, codebase-memory-mcp MCP tools

---

### Task 1: Update Frontmatter and Introduction

**Files:**
- Modify: `plugins/clean-merge/skills/review-commits/SKILL.md:1-19`

- [ ] **Step 1: Update the frontmatter description**

Replace the current description to reflect rebase-first approach:

```yaml
---
name: review-commits
description: >
  Review and clean up commits before pushing. Auto-detects branch vs main
  workflow. Runs commit hygiene analysis (introduce-then-fix pairs,
  non-atomic commits, unrelated changes) with optional codebase-memory-mcp
  semantic analysis. Uses interactive rebase as default mechanism —
  soft-reset available as escape hatch. Delegates ALL commit message
  creation to /commit. Activates on: "review commits", "clean up commits",
  "prep for push", "squash these commits", "finalize commits",
  "merge branch to main", "clean up my commits before pushing",
  "review before push".
argument-hint: "[--tag <version>] [--base <ref>]"
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---
```

- [ ] **Step 2: Update the introduction text**

Replace the opening paragraph:

```markdown
# Review Commits

Review and clean up commits before pushing. Auto-detects whether you
are on a feature branch or on main and runs the appropriate workflow.
Uses interactive rebase to surgically clean commit history — squashing
introduce-then-fix pairs, splitting non-atomic commits, dropping
unrelated changes. Soft-reset is available as an escape hatch when
commits are too tangled for rebase.
```

- [ ] **Step 3: Commit**

```bash
git add plugins/clean-merge/skills/review-commits/SKILL.md
```
Then invoke `/commit`.

---

### Task 2: Add Codebase Index Resolution Section

This new section goes after "Test Detection (Shared)" and before the Branch Flow. It defines how the skill ensures codebase-memory-mcp is available and indexed.

**Files:**
- Modify: `plugins/clean-merge/skills/review-commits/SKILL.md:57-71`

- [ ] **Step 1: Add the Codebase Index Resolution section**

Insert after the "Test Detection (Shared)" section (after line 71) and before "## Branch Flow":

```markdown
## Codebase Index Resolution (Shared)

Before either flow, attempt to set up codebase-memory-mcp for semantic
commit analysis. This enables Layer 3 of the hygiene analysis.

### Step 1: Check MCP Availability

Call the `codebase-memory-mcp` `list_projects` tool.

- If the MCP server is **not available** (tool call fails or server not
  connected): set `$SEMANTIC_AVAILABLE=false`. Continue without semantic
  analysis — Layers 1 and 2 will still run.
- If the MCP server **is available**: continue to Step 2.

### Step 2: Check Project Index

Call `list_projects` and match against the current repo name (from
`git rev-parse --show-toplevel | xargs basename`).

- **Index exists and fresh** (last indexed < 24 hours ago): set
  `$SEMANTIC_AVAILABLE=true`.
- **Index exists but stale** (last indexed > 24 hours ago): re-index
  by invoking `/codebase:index`. Then set `$SEMANTIC_AVAILABLE=true`.
- **No index exists**: display:
  ```
  Building codebase index for semantic commit analysis... (first time only)
  ```
  Invoke `/codebase:index`. Then set `$SEMANTIC_AVAILABLE=true`.

If indexing fails for any reason, set `$SEMANTIC_AVAILABLE=false` and
continue — do not block the workflow.
```

- [ ] **Step 2: Commit**

```bash
git add plugins/clean-merge/skills/review-commits/SKILL.md
```
Then invoke `/commit`.

---

### Task 3: Add Commit Hygiene Analysis Section

This new section defines the three-layer analysis that runs before the rebase plan is built. It goes after the Codebase Index Resolution section and before the Branch Flow.

**Files:**
- Modify: `plugins/clean-merge/skills/review-commits/SKILL.md` (insert after Codebase Index Resolution)

- [ ] **Step 1: Add the Commit Hygiene Analysis section**

Insert after the "Codebase Index Resolution" section:

```markdown
## Commit Hygiene Analysis (Shared)

Analyze commits in the range `$base..HEAD` for hygiene issues. This
analysis runs in both Branch Flow and Main Flow (Rebase option) before
the rebase plan is built.

Three detection layers run in order. Each layer adds findings to a
shared list.

### Layer 1: Subject-Based (always runs)

Parse `git log --oneline $base..HEAD` and detect introduce-then-fix
pairs:

A pair is flagged when:
- Commit B's subject starts with `Fix`, `Fixup`, `Fix up`, `Correct`,
  or `Update` (case-insensitive)
- The remainder of B's subject shares a significant word (3+ characters,
  excluding stop words: the, for, and, a, an, in, of, to, is, it, on,
  at, by, or, be, as, do, if, so, no, up, we, my, he) with commit A's
  subject
- B is within 3 commits of A in the log (not necessarily adjacent)

Each detected pair is recorded as:
```
finding: pair
commits: [<hash-A>, <hash-B>]
reason: "introduce-then-fix: <shared word>"
action: fixup (mandatory)
```

### Layer 2: File-Structural (always runs)

For each commit in range, run:
```bash
git diff-tree --no-commit-id --name-only -r <hash>
```

Group changed files by top-level directory. Flag a commit as non-atomic
if it touches files in 2+ top-level directories that serve different
concerns. Use these heuristics:
- `plugins/<name-A>/` and `plugins/<name-B>/` are different concerns
  (unless both are in the same plugin)
- `docs/` changes alongside `plugins/` are acceptable (docs for the
  plugin)
- `tests/` alongside `src/` for the same module is acceptable
- Root config files (`.eslintrc`, `package.json`) alongside source
  changes are acceptable if the config change supports the source change

Each flagged commit is recorded as:
```
finding: non-atomic
commit: <hash>
concerns: ["<dir-A>: <description>", "<dir-B>: <description>"]
action: edit (suggested)
```

Also check if any commit's changes are unrelated to the branch's
overall purpose. Compare each commit's changed files against the full
branch diff (`git diff --name-only $base..HEAD`). If a commit only
touches files that no other commit in the range touches AND those
files are in a different area from the branch's main work, flag it:

```
finding: unrelated
commit: <hash>
reason: "<description of why it seems unrelated>"
action: drop (suggested)
```

### Layer 3: Semantic (runs when $SEMANTIC_AVAILABLE=true)

For each commit flagged as potentially non-atomic by Layer 2, and for
any commit where Layer 2 was uncertain, use codebase-memory-mcp to
verify:

1. **Get changed symbols**: For each changed file in the commit, call
   `search_graph` with the file path to find the symbols it defines.

2. **Check cluster membership**: Call `search_graph` with a semantic
   query describing each changed symbol. If changed symbols belong to
   different clusters (e.g., "AuthService" vs "Observability"), the
   commit is non-atomic.

3. **Trace connections**: Call `trace_path` between changed files. If
   a path exists (they're connected through call chains), the changes
   may be related despite being in different directories. Remove the
   non-atomic flag.

4. **Check module boundaries**: Call `get_architecture` and verify
   whether the commit crosses module boundaries. Cross-boundary changes
   with no call-chain connection are non-atomic.

Layer 3 can **upgrade** a Layer 2 finding (uncertain → confirmed
non-atomic) or **dismiss** it (files are in different directories but
semantically connected).

If any `codebase-memory-mcp` tool call fails during Layer 3, skip the
remaining semantic checks for that commit and keep the Layer 2 finding
as-is. Do not fail the workflow.

### Present Hygiene Findings

After all layers complete, present findings using AskUserQuestion if
any issues were found:

```
Commit hygiene analysis complete.

⚠ Issues detected:

  Introduce-then-fix pairs (will be auto-squashed):
    c844c6a + 7de838b — "sync-beads": add then fix shell escaping
    c8fa279 + e526d22 — "hook": expand then fix false-positive

  Non-atomic commits (suggest splitting):
    a1b2c3d — touches auth handler (AuthService) + logging (Observability)
      These are unrelated concerns in different subsystems.

  Unrelated changes (suggest dropping):
    f4e5d6c — README typo fix, unrelated to auth migration branch

Introduce-then-fix pairs are mandatory fixups. For other findings:

○ Accept all suggestions
○ Review one by one — decide per finding
○ Dismiss all — keep commits as-is (only hygiene pairs will be fixed)
```

If "Review one by one": walk through each non-mandatory finding with
AskUserQuestion offering accept/dismiss per finding.

If no issues detected, display:
```
Commit hygiene analysis: all commits are clean and atomic. ✓
```
And proceed directly to the rebase plan.
```

- [ ] **Step 2: Commit**

```bash
git add plugins/clean-merge/skills/review-commits/SKILL.md
```
Then invoke `/commit`.

---

### Task 4: Rewrite Branch Flow with Rebase-First

Replace the current Branch Flow (Steps 1-6) with the new rebase-first workflow.

**Files:**
- Modify: `plugins/clean-merge/skills/review-commits/SKILL.md:72-209` (the entire Branch Flow section)

- [ ] **Step 1: Replace Branch Flow Steps 1-2 (unchanged logic, new step numbers)**

Replace the Branch Flow section starting from `## Branch Flow` through the old Step 2. Keep Steps 1-2 the same but update the display text in Step 2:

```markdown
## Branch Flow (feature branch → main)

### Step 1: Verify Tests

Run the detected test command. If it fails, stop:

    Tests failed. Fix the failures before reviewing commits.

### Step 2: Show Branch State

Determine the merge base:

```bash
base=$(git merge-base HEAD main)
```

If `--base` was provided, use that instead.

Show the commits:

```bash
git log --oneline $base..HEAD
```

Display:
```
Branch <branch-name> has N commits since main:

  <hash> <subject>
  <hash> <subject>
  ...

Analyzing commit hygiene and building rebase plan...
```
```

- [ ] **Step 2: Add new Steps 3-4 (index + hygiene)**

```markdown
### Step 3: Ensure Codebase Index

Run the "Codebase Index Resolution" flow defined above. This sets
`$SEMANTIC_AVAILABLE` for use in Step 4.

### Step 4: Commit Hygiene Analysis

Run the "Commit Hygiene Analysis" flow defined above against the
commit range `$base..HEAD`. Collect findings for use in Step 5.
```

- [ ] **Step 3: Add new Step 5 (build and present rebase plan)**

```markdown
### Step 5: Build & Present Rebase Plan

Using the hygiene findings from Step 4, map each commit to a rebase
action:

| Action | When |
|--------|------|
| `pick` | Commit is clean and atomic — no hygiene findings |
| `fixup` | Fix commit in an introduce-then-fix pair — mandatory |
| `squash` | User wants to combine related commits — user-directed |
| `edit` | Non-atomic commit that needs splitting — from hygiene |
| `drop` | Unrelated/orphan change — from hygiene |
| `reword` | Good commit, bad message — user-directed |

Reorder commits if needed to place related commits adjacent.

Present the plan using AskUserQuestion:

```
Rebase plan for N commits on <branch-name>:

  Proposed sequence:
    pick   c844c6a  Add sync-beads skill
    fixup  7de838b  Fix sync-beads skill
    pick   c8fa279  Expand PostToolUse hook
    fixup  e526d22  Fix UserPromptSubmit hook
    edit   a1b2c3d  Update auth and logging  ← will split
    pick   b2c3d4e  Add retry logic
    drop   f4e5d6c  Fix unrelated typo

○ Accept — execute this rebase plan
○ Modify — adjust actions for specific commits
○ Reset — soft-reset and regroup manually (escape hatch)
```

If "Modify": use AskUserQuestion to let the user change the action
for any commit. Re-display the updated plan for confirmation.

If "Reset": fall back to the soft-reset escape hatch (see below).
```

- [ ] **Step 4: Add new Step 6 (execute rebase)**

```markdown
### Step 6: Execute Rebase

Execute the approved rebase plan on the feature branch.

#### Build GIT_SEQUENCE_EDITOR Script

Construct a sed command or shell script that transforms the default
rebase todo list into the approved plan. The script must:
- Change `pick` to `fixup`, `squash`, `edit`, `drop`, or `reword`
  for the appropriate commits (matching by abbreviated hash)
- Reorder lines if the plan requires it

Run:
```bash
GIT_SEQUENCE_EDITOR='<script>' git rebase -i $base
```

#### Handle Each Stop

The rebase will stop for `edit`, `reword`, and `squash` actions:

**For `fixup` pairs (no stop needed):**
Git handles fixup automatically — the fix commit is folded into the
parent. After the rebase completes, the combined commit needs
rewording. Use `git rebase -i` again with `reword` on just the
combined commit, or if it's HEAD, invoke `/commit --amend` directly.

**For `edit` stops (splitting a non-atomic commit):**
1. The rebase stops with the commit applied
2. Run `git reset HEAD~1` to undo the commit but keep changes
3. Guide the user through staging and committing each concern
   separately — invoke `/commit` for each new atomic commit
4. Run `git rebase --continue`

**For `reword` stops:**
1. The rebase stops to let you edit the message
2. Run `git rebase --continue` with `GIT_SEQUENCE_EDITOR` that
   passes through — the old message stays temporarily
3. Then invoke `/commit --amend` to generate the new message

**For `squash` stops:**
1. Git opens the combined message
2. Run with `GIT_SEQUENCE_EDITOR='true'` to accept the combined
   message temporarily
3. Then invoke `/commit --amend` to generate the proper message

**For `drop`:**
Git handles drop automatically — the commit is removed.

**CRITICAL:** After ALL rebase operations, invoke `/commit --amend`
on any commit that was the target of a `fixup` or `squash` to
generate a proper commit message. The review-commits skill NEVER
generates commit messages — always delegate to `/commit`.

#### Conflict Handling

If the rebase encounters a merge conflict at any step:
1. Report which commit caused the conflict
2. Show the conflicting files: `git diff --name-only --diff-filter=U`
3. Stop and let the user resolve manually
4. After resolution, user runs `git rebase --continue`

#### Soft-Reset Escape Hatch

If the user chose "Reset" in Step 5, instead of interactive rebase:

```bash
git reset --soft $base
git reset HEAD
```

This unstages all changes. Then propose groupings using AskUserQuestion
(same format as the old Step 3 — group files by directory and concern).
For each group:
1. Stage the group's files: `git add <files>`
2. Invoke `/commit`

The hygiene findings from Step 4 carry forward — display them again
as context for grouping decisions.
```

- [ ] **Step 5: Add Steps 7-9 (merge, tag, cleanup)**

```markdown
### Step 7: Merge to Main

Move the cleaned-up commits to main:

```bash
git checkout main
git merge <branch> --ff-only
```

If `--ff-only` fails, use AskUserQuestion:
```
Fast-forward merge failed — main has diverged from <branch>.

○ Rebase — rebase <branch> onto main first (recommended)
○ Merge commit — create a merge commit instead
○ Abort — stop and let me handle it
```

If "Rebase": run `git checkout <branch> && git rebase main`, then
retry the ff merge. If rebase has conflicts, report and stop.

If "Merge commit": run `git merge <branch>` (allow merge commit).

If "Abort": stop.

### Step 8: Optional Tag

Only if `--tag <version>` was provided:

```bash
git tag <version>
```

Never prompt for a tag. Never auto-tag.

### Step 9: Validate and Cleanup

Invoke the `validate-commits` skill to run all five checks.

After validation passes, ask before cleaning up using AskUserQuestion:
```
Branch <branch> has been merged to main. Delete it?
○ Yes — delete the branch
○ No — keep it
```

If "Yes":
```bash
git branch -D <branch>
```

If a worktree was used:
```bash
git worktree remove <path>
```
```

- [ ] **Step 6: Commit**

```bash
git add plugins/clean-merge/skills/review-commits/SKILL.md
```
Then invoke `/commit`.

---

### Task 5: Rewrite Main Flow with Rebase Option

Replace the current Main Flow to use "Rebase" instead of "Regroup" and integrate hygiene analysis.

**Files:**
- Modify: `plugins/clean-merge/skills/review-commits/SKILL.md` (the entire Main Flow section)

- [ ] **Step 1: Replace the Main Flow section**

Replace everything from `## Main Flow` to the end of the Main Flow:

```markdown
## Main Flow (on main/master)

### Step 1: Verify Tests

Same as Branch Flow Step 1.

### Step 2: Identify Unpushed Commits

Try to find commits ahead of upstream:

```bash
git log --oneline @{u}..HEAD 2>/dev/null
```

If this succeeds, show the commits.

If it fails (no upstream), use AskUserQuestion:
```
No upstream tracking branch. Which commit is the base?
○ Use latest tag (<tag from: git describe --tags --abbrev=0>)
○ Enter a commit ref
```

If `--base` was provided, use that instead of detection.

Display:
```
N unpushed commits on main:

  <hash> <subject>
  <hash> <subject>

Review these commits?
```

### Step 3: Review Options

Use AskUserQuestion:
```
What would you like to do?
○ Validate only — check for issues without changing commits
○ Rebase — run hygiene analysis and interactive rebase to clean up
○ Reword — amend commit messages using /commit
```

**Validate only:**
Invoke the `validate-commits` skill. Done.

**Rebase:**
Run the same analysis and rebase workflow as Branch Flow Steps 3-6:
1. Ensure Codebase Index (set `$SEMANTIC_AVAILABLE`)
2. Run Commit Hygiene Analysis against `$base..HEAD`
3. Build & Present Rebase Plan
4. Execute Rebase (or soft-reset escape hatch)

All steps work identically to the Branch Flow — the only difference
is that there is no merge step afterward (commits are already on main).

**Reword:**
Walk through commits oldest-to-newest using interactive rebase with
all commits marked as `edit`:

```bash
GIT_SEQUENCE_EDITOR='sed -i "" "s/^pick/edit/"' git rebase -i $base
```

For each stopped commit:
1. Show the current message:
   ```
   Commit <hash>:
   <current subject>

   <current body>
   ```
2. Use AskUserQuestion:
   ```
   ○ Reword — amend this commit message via /commit
   ○ Keep — leave this commit as-is
   ○ Skip rest — keep all remaining commits as-is
   ```
3. If "Reword": invoke `/commit --amend`
4. If "Keep": run `git rebase --continue`
5. If "Skip rest": run `git rebase --continue` for all remaining
   commits without stopping (use `GIT_SEQUENCE_EDITOR` to change
   remaining `edit` to `pick`)

### Step 4: Optional Tag

Same as Branch Flow Step 8.

### Step 5: Validate

Invoke `validate-commits` (unless "Validate only" was already selected
in Step 3, which already ran it).
```

- [ ] **Step 2: Commit**

```bash
git add plugins/clean-merge/skills/review-commits/SKILL.md
```
Then invoke `/commit`.

---

### Task 6: Update Integration and What-This-Skill-Does-NOT-Do Sections

Update the footer sections to reflect the new capabilities.

**Files:**
- Modify: `plugins/clean-merge/skills/review-commits/SKILL.md` (Integration and footer sections)

- [ ] **Step 1: Update the Integration section**

Replace the Integration section:

```markdown
## Integration

### With /commit

This skill invokes `/commit` for every commit message. It stages files
and provides context, but message generation, style enforcement,
atomicity checks, and user approval are entirely `/commit`'s
responsibility.

### With /codebase:index

This skill invokes `/codebase:index` to build or refresh the
codebase-memory-mcp index when needed. The index enables Layer 3
semantic analysis for commit hygiene checks.

### With Superpowers

- `finishing-a-development-branch` detects this skill when "Merge
  locally" is selected
- `subagent-driven-development` naturally leads here after tasks complete

### Standalone

Run `/review-commits` anytime — before pushing, after a messy session,
to clean up agent commits.
```

- [ ] **Step 2: Update the What This Skill Does NOT Do section**

Replace with:

```markdown
## What This Skill Does NOT Do

- **Generate commit messages** — delegates to `/commit`
- **Enforce commit style** — `/commit`'s job
- **Auto-tag** — only with explicit `--tag`
- **Add co-author** — never
- **Push** — user pushes manually
- **Resolve merge conflicts** — reports and stops
- **Force semantic analysis** — if codebase-memory-mcp is not available,
  Layers 1-2 still provide value
```

- [ ] **Step 3: Commit**

```bash
git add plugins/clean-merge/skills/review-commits/SKILL.md
```
Then invoke `/commit`.

---

## Self-Review Checklist

**Spec coverage:**
- ✓ Introduce-then-fix pair detection (Layer 1, Task 3)
- ✓ Non-atomic commit detection (Layer 2, Task 3)
- ✓ Unrelated change detection (Layer 2, Task 3)
- ✓ Semantic analysis via codebase-memory-mcp (Layer 3, Task 3)
- ✓ Auto-index creation (Task 2)
- ✓ Interactive rebase as default (Tasks 4, 5)
- ✓ Rebase plan presentation (Task 4, Step 5)
- ✓ GIT_SEQUENCE_EDITOR execution (Task 4, Step 6)
- ✓ Soft-reset escape hatch (Task 4, Step 6)
- ✓ Branch Flow updated (Task 4)
- ✓ Main Flow updated with Rebase option (Task 5)
- ✓ Hygiene findings are mandatory for pairs, suggested for others (Task 3)
- ✓ `/commit` delegation preserved (all tasks)

**Placeholder scan:** No TBD, TODO, or vague steps. All sections contain complete instructions.

**Consistency:** `$SEMANTIC_AVAILABLE`, `$base`, `/commit`, `/codebase:index` used consistently across all tasks.
