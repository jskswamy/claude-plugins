---
name: review-commits
description: >
  Review and clean up commits before pushing. Auto-detects branch vs main
  workflow. On a feature branch: squash commits into logical groups and
  merge to main. On main: validate, regroup, or reword existing commits.
  Delegates ALL commit message creation to /commit — never generates
  messages itself. Activates on: "review commits", "clean up commits",
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

# Review Commits

Review and clean up commits before pushing. Auto-detects whether you
are on a feature branch or on main and runs the appropriate workflow.

## Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `--tag <version>` | string | none | Tag after completion |
| `--base <ref>` | string | auto | Override base commit detection |

## Precondition

Require a clean worktree. Run:

```bash
git status --porcelain
```

If output is non-empty, refuse to proceed:

    Your worktree has uncommitted changes. Please commit or stash them
    before running review-commits.

## Auto-Detection

Check the current branch:

```bash
branch=$(git branch --show-current)
```

- If `$branch` is `main` or `master` → **Main Flow**
- Otherwise → **Branch Flow**

## Test Detection (Shared)

Before either flow, detect the project's test command by checking for
project files in the working directory root:

| File | Command |
|------|---------|
| `go.mod` | `go test ./...` |
| `package.json` | `npm test` |
| `Cargo.toml` | `cargo test` |
| `pyproject.toml` | `pytest` |

Check files in this order. Use the first match. If no project file is
found, skip testing and warn: "No test command detected. Skipping tests."

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

These will be squashed into clean logical groups.
```

### Step 3: Propose Groupings

Analyze changed files:

```bash
git diff --stat $base..HEAD
```

Group files by top-level directory and concern. Present suggested
groupings using AskUserQuestion:

```
Files changed (N files across M areas):

  <dir>/ (X files)
  <dir>/ (Y files)

Suggested groupings (K commits):
  1. <description> → <dir>/*
  2. <description> → <dir>/*

Accept, modify, or define your own?
○ Accept — use these groupings
○ Modify — adjust the groupings
○ Define my own — specify from scratch
```

If "Modify" or "Define my own": ask user for their grouping
(list of descriptions + file globs per group).

### Step 4: Squash and Commit

For the first group only, move changes to main:

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

After merge succeeds, soft-reset to squash:

```bash
git reset --soft $base
git reset HEAD
```

This unstages all changes from the merged commits. Now for each group:

1. Stage the group's files: `git add <files>`
2. Invoke `/commit` — the commit plugin handles message generation,
   style enforcement, atomicity checks, and user approval
3. **CRITICAL:** The review-commits skill NEVER generates commit
   messages. Always delegate to `/commit`.

Repeat for all groups.

### Step 5: Optional Tag

Only if `--tag <version>` was provided:

```bash
git tag <version>
```

Never prompt for a tag. Never auto-tag.

### Step 6: Validate and Cleanup

Invoke the `validate-commits` skill to run all five checks.

After validation passes, clean up:

```bash
git branch -D <branch>    # safe — commits are on main now
```

If a worktree was used:
```bash
git worktree remove <path>
```

Ask before deleting the branch using AskUserQuestion:
```
Branch <branch> has been merged to main. Delete it?
○ Yes — delete the branch
○ No — keep it
```

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
○ Regroup — soft-reset and re-commit into different groupings
○ Reword — amend commit messages using /commit
```

**Validate only:**
Invoke the `validate-commits` skill. Done.

**Regroup:**
Same soft-reset and group-commit loop as Branch Flow Step 4:

```bash
git reset --soft $base
git reset HEAD
```

Then propose groupings, stage per group, invoke `/commit` for each.

**Reword:**
Walk through commits oldest-to-newest. For each commit:

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
3. If "Reword": invoke `/commit --amend` to generate a new message
4. If "Keep": move to next commit
5. If "Skip rest": break out of the loop

**Note on rewording non-HEAD commits:** Only HEAD can be amended
directly. For older commits, use `git rebase -i` to mark them for
`reword`. Since interactive rebase cannot run non-interactively in
this context, the reword flow should process commits by:

1. Run `git rebase --onto $base $base HEAD` with `GIT_SEQUENCE_EDITOR`
   set to a script that marks all commits as `edit`
2. For each stopped commit, invoke `/commit --amend`
3. Run `git rebase --continue`

If this approach is too fragile, fall back to: only offer reword for
HEAD commit, and suggest the user run `git rebase -i` manually for
older commits.

### Step 4: Optional Tag

Same as Branch Flow Step 5.

### Step 5: Validate

Invoke `validate-commits` (unless "Validate only" was already selected
in Step 3, which already ran it).

## Integration

### With /commit

This skill invokes `/commit` for every commit message. It stages files
and provides context, but message generation, style enforcement,
atomicity checks, and user approval are entirely `/commit`'s
responsibility.

### With Superpowers

- `finishing-a-development-branch` detects this skill when "Merge
  locally" is selected
- `subagent-driven-development` naturally leads here after tasks complete

### Standalone

Run `/review-commits` anytime — before pushing, after a messy session,
to clean up agent commits.

## What This Skill Does NOT Do

- **Generate commit messages** — delegates to `/commit`
- **Enforce commit style** — `/commit`'s job
- **Auto-tag** — only with explicit `--tag`
- **Add co-author** — never
- **Push** — user pushes manually
- **Resolve merge conflicts** — reports and stops
