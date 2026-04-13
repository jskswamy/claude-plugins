# Review-Commits: Rebase-First with Commit Hygiene Analysis

**Date:** 2026-04-13
**Issue:** jskswamy/claude-plugins#1
**Plugin:** clean-merge
**Skill:** review-commits

## Problem

The review-commits skill has two issues:

1. **No introduce-then-fix detection.** When a branch has commit pairs where
   commit B fixes what commit A just introduced, the skill relies on the user
   to notice and manually squash them. These pairs violate atomicity — the
   first commit introduces a broken state that fails `git bisect`.

2. **Soft-reset is too blunt.** The default mechanism destroys all commit
   structure and re-stages from scratch. This is overkill when most commits
   are already good and only a few need squashing or splitting.

## Solution

Replace soft-reset with interactive rebase as the default mechanism, and add
automatic commit hygiene analysis that detects problems before the rebase
plan is built.

## Design

### Commit Hygiene Analysis

Three layers of detection, each progressively deeper:

#### Layer 1: Subject-Based (fast, no code analysis)

Detect introduce-then-fix pairs by parsing `git log` subjects:

- Commit B's subject starts with `Fix`, `Fixup`, `Fix up`, `Correct`, or
  `Update`
- The remainder of B's subject shares a significant word (3+ chars,
  excluding stop words like "the", "for", "and") with commit A's subject
- B is within 3 commits of A in the log

#### Layer 2: File-Structural (medium, uses git diff-tree)

Detect non-atomic commits via file path analysis:

- For each commit, run `git diff-tree --no-commit-id -r <hash>` to get
  changed files
- Group files by top-level directory and concern
- Flag a commit if it touches 2+ unrelated concerns (different top-level
  directories with no shared purpose, or changes to unrelated subsystems)

#### Layer 3: Semantic (deep, uses codebase-memory-mcp)

If the codebase-memory-mcp server is available, semantic analysis is
guaranteed — if no index exists, create it before proceeding.

Index resolution flow:

1. Call `list_projects` to check if MCP server is reachable
2. Server not available → skip Layer 3 entirely (Layers 1+2 only)
3. Server available → check for project index:
   - Index exists and fresh → use it
   - Index exists but stale → re-index, then use it
   - No index → create it via `/codebase:index`, then use it

Semantic tools used per commit:

- **`search_graph`** — find what each changed symbol relates to (its
  cluster, callers/callees). Two changes in the same commit that belong to
  different clusters → non-atomic flag.
- **`get_code_snippet`** — understand what a changed function actually does,
  not just its file path.
- **`trace_path`** — verify whether changes in different files are connected
  through call chains. Connected → atomic. Not connected → flag.
- **`get_architecture`** — understand module boundaries. A commit that
  crosses module boundaries with unrelated changes → non-atomic flag.

#### Hygiene Output

All findings shown in a categorized notice:

```
Hygiene issues detected:

  Pair: c844c6a + 7de838b → fixup (introduce-then-fix)
    sync-beads skill: initial add then immediate shell escaping fixes

  Split: a1b2c3d → edit (non-atomic)
    - auth handler (AuthService cluster) — token refresh logic
    - logging utility (Observability cluster) — log format change
    These are unrelated concerns in different subsystems.

  Drop: f4e5d6c → drop (unrelated to branch purpose)
    README typo fix — branch is about auth migration
```

Introduce-then-fix pairs are mandatory fixups — the user cannot override
this. Non-atomic and unrelated findings are suggestions the user can accept
or dismiss.

### Rebase-First Workflow

Interactive rebase replaces soft-reset as the default mechanism.

#### Rebase Plan

After hygiene analysis, the skill builds a rebase plan mapping each commit
to an action:

| Action | When | Example |
|--------|------|---------|
| `pick` | Commit is clean and atomic | Keep as-is |
| `fixup` | Fix commit in an introduce-then-fix pair | Fold into parent silently |
| `squash` | Related commits that should merge (user-directed) | Combine with message rewrite |
| `edit` | Non-atomic commit that needs splitting | Stop for manual split |
| `drop` | Unrelated/orphan change | Remove from branch |
| `reword` | Good commit, bad message | Stop for `/commit --amend` |
| `reorder` | Commits out of logical sequence | Move to correct position |

#### Plan Presentation

```
Rebase plan for 9 commits:

  Hygiene issues detected:
    Pair: c844c6a + 7de838b → fixup (introduce-then-fix)
    Split: a1b2c3d → edit (touches auth + logging, unrelated concerns)
    Drop: f4e5d6c → drop (unrelated config change)

  Proposed rebase sequence:
    pick   c844c6a  Add sync-beads skill
    fixup  7de838b  Fix sync-beads skill
    pick   c8fa279  Expand PostToolUse hook
    fixup  e526d22  Fix UserPromptSubmit hook
    edit   a1b2c3d  Update auth and logging  ← will split
    pick   b2c3d4e  Add retry logic
    drop   f4e5d6c  Fix unrelated typo

  Accept, modify, or reset from scratch?
  ○ Accept — execute this rebase plan
  ○ Modify — adjust actions for specific commits
  ○ Reset — soft-reset and regroup manually (escape hatch)
```

#### Execution

1. Write the todo list via `GIT_SEQUENCE_EDITOR`
2. For `fixup` pairs: after folding, stop to reword the combined commit via
   `/commit --amend`
3. For `edit` stops: guide the user through splitting (unstage, re-add by
   concern, commit each)
4. For `reword` stops: invoke `/commit --amend`
5. For `drop`: confirm with user before executing

#### Soft-Reset Escape Hatch

Available only if the user explicitly picks "Reset" in the plan
presentation. For cases where commits are so tangled that surgical rebase
is not worth it. Even then, hygiene analysis results carry forward into the
new grouping step.

### Updated Flow: Branch Flow

1. **Step 1: Verify Tests** — run detected test command, stop on failure
2. **Step 2: Show Branch State** — show commits since merge base
3. **Step 3: Ensure Codebase Index** — resolve index via codebase-memory-mcp
   (create if missing, re-index if stale, skip if MCP unavailable)
4. **Step 4: Commit Hygiene Analysis** — run Layers 1-3, present findings
5. **Step 5: Build & Present Rebase Plan** — map commits to actions, show to
   user for approval
6. **Step 6: Execute Rebase** — run via `GIT_SEQUENCE_EDITOR` on the feature
   branch, invoke `/commit` at each stop. Soft-reset available as escape
   hatch. All cleanup happens on the branch before merging.
7. **Step 7: Merge to Main** — `git checkout main && git merge <branch> --ff-only`.
   If ff-only fails, offer rebase-onto-main / merge commit / abort (unchanged
   from current behavior).
8. **Step 8: Optional Tag** — only with explicit `--tag`
9. **Step 9: Validate and Cleanup** — invoke `validate-commits`, offer branch
   deletion

### Updated Flow: Main Flow

1. **Step 1: Verify Tests** — unchanged
2. **Step 2: Identify Unpushed Commits** — unchanged
3. **Step 3: Review Options** — revised:
   - **Validate only** — run validate-commits, done
   - **Rebase** (was "Regroup") — runs Branch Flow Steps 3-6 (index →
     hygiene → plan → execute)
   - **Reword** — walk commits, `/commit --amend` for each
4. **Step 4: Optional Tag** — unchanged
5. **Step 5: Validate** — invoke validate-commits

### Key Changes Summary

| Aspect | Before | After |
|--------|--------|-------|
| Default mechanism | Soft-reset + re-stage | Interactive rebase |
| Pair detection | None (user catches manually) | Automatic, mandatory fixup |
| Atomicity check | None | 3-layer analysis |
| Codebase understanding | None | Semantic via codebase-memory-mcp |
| Soft-reset | Default | Escape hatch only |
| Index requirement | N/A | Auto-created if MCP available |

## What Does NOT Change

- `/commit` still owns all message generation, style, and atomicity checks
- `validate-commits` still runs at the end
- No auto-tagging, no auto-push, no co-author addition
- Merge conflict handling: report and stop
