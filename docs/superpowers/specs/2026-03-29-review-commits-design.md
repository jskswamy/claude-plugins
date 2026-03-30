# Review Commits — Design Spec

**Date:** 2026-03-29
**Status:** Approved
**Plugin:** `clean-merge` (standalone plugin, not part of git-commit or guardrails)

## Problem

When completing feature work (via superpowers or manual development),
commits need cleanup before pushing. Two common scenarios:

1. **Feature branch:** Many small commits (implementation, review fixes,
   lint) that need squashing into logical groups with clean messages
   before merging to main.

2. **Direct on main:** Agent worked directly on main, commits exist but
   may have poor messages, AI co-author leaks, or fixup residue.

Both end the same way: clean commits via `/commit` + validation. This
was done manually 3+ times in a single session — tedious and error-prone.

## Architecture

Two skills in a single `clean-merge` plugin:

- **`review-commits`** — the workflow skill (regroup, reword, merge)
- **`validate-commits`** — standalone validation (five deterministic checks)

`review-commits` invokes `validate-commits` at the end. Users can also
invoke `validate-commits` independently for any workflow.

### File Structure

```
clean-merge/
  .claude-plugin/
    plugin.json
  skills/
    review-commits/
      SKILL.md
    validate-commits/
      SKILL.md
```

---

## Skill 1: `validate-commits`

### Trigger Phrases

"validate commits", "check commits before push", "any AI leaks",
"check for co-author", "are my commits clean"

### Precondition

Clean worktree required. Refuse to start if `git status --porcelain`
produces output.

### Input: Commit Range

Determined by (in priority order):

1. Explicit `--base <ref>` argument
2. Upstream tracking: `@{u}..HEAD`
3. No upstream: ask user (offer latest tag or manual ref)

### Five Checks (All Deterministic)

| # | Check | Method | Fails if |
|---|-------|--------|----------|
| 1 | Clean worktree | `git status --porcelain` | Any output |
| 2 | Tests pass | Auto-detect project test command | Non-zero exit |
| 3 | No AI co-author | `git log --format=%b base..HEAD` | `Co-Authored-By` with Claude, Anthropic, GPT, OpenAI, Copilot, or AI-associated emails (noreply@anthropic.com, noreply@openai.com) |
| 4 | No conflict markers | Grep committed files in range | `<<<<<<<` or `>>>>>>>` in any file |
| 5 | No squash residue | `git log --format=%s base..HEAD` | Subject starting with `fixup!` or `squash!` |

No LLM judgment. All checks are grep/exit-code based.

### Test Command Detection

Auto-detect from project files:

| File | Command |
|------|---------|
| `go.mod` | `go test ./...` |
| `package.json` | `npm test` |
| `Cargo.toml` | `cargo test` |
| `pyproject.toml` | `pytest` |

### Auto-Fix

Only for AI co-author. Offers to amend the affected commit to strip
the `Co-Authored-By` line. All other failures are reported for the
user to handle.

### Output Format

**Success:**
```
Post-commit validation:

  ✓ Clean worktree
  ✓ Tests pass (12 packages, 0 failures)
  ✓ No AI co-author
  ✓ No conflict markers
  ✓ No squash residue

All checks passed. Ready to push.
```

**Failure:**
```
Post-commit validation failed:

  ✗ AI co-author in commit 7ce2788
    Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

  ✓ Clean worktree
  ✓ Tests pass
  ✓ No conflict markers
  ✓ No squash residue

Fix automatically? (amends the affected commit)
○ Yes — remove the co-author line
○ No — I'll handle it
```

---

## Skill 2: `review-commits`

### Trigger Phrases

"review commits", "clean up commits", "prep for push",
"squash these commits", "finalize commits", "merge branch to main"

### Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `--tag <version>` | string | none | Tag after completion |
| `--base <ref>` | string | auto | Override base commit detection |

### Precondition

Clean worktree required. Refuse to start if dirty.

### Auto-Detection

```
current branch == main/master?
  ├── YES → Main Flow
  └── NO  → Branch Flow
```

No flags needed. The skill figures out what to do.

---

### Branch Flow (not on main/master)

#### Step 1: Verify Tests

Run the project's test command (same detection as validate-commits).
If tests fail, stop.

#### Step 2: Show Branch State

```bash
base=$(git merge-base HEAD main)
git log --oneline $base..HEAD
```

Display commit count and list:
```
Branch feat/robustness-hardening has 8 commits since main:

  18bea24 test: add capability detection tests
  d3e24c3 feat: show detected capabilities in banner
  ...

These will be squashed into clean logical groups.
```

#### Step 3: Propose Groupings

Analyze `git diff --stat base..HEAD`, group by directory/concern:

```
Files changed (19 files across 4 areas):

  pkg/seatbelt/guards/ (13 files)
  internal/capability/ (1 file)
  internal/launcher/ (1 file)
  internal/ui/ (4 files)

Suggested groupings (2 commits):
  1. Guard robustness hardening → pkg/seatbelt/guards/*
  2. Auto-suggest pipeline fix → internal/*

Accept, modify, or define your own?
```

User accepts, modifies, or replaces.

#### Step 4: Squash and Commit

For each group:

1. **First group only:** Fast-forward merge to main, then soft-reset
   ```bash
   git checkout main
   git merge <branch> --ff-only
   git reset --soft <base>
   git reset HEAD
   ```
   If ff-only fails: report and offer rebase / merge-commit / abort.

2. **Stage the group's files**

3. **Invoke `/commit`** — delegates entirely to the commit plugin for
   message generation, style enforcement, and user approval.
   The review-commits skill NEVER generates commit messages itself.

4. **Repeat for remaining groups**

#### Step 5: Optional Tag

Only if `--tag` was provided. Never prompt, never auto-tag.

#### Step 6: Validate and Cleanup

Invoke `validate-commits` skill, then cleanup:
```bash
git worktree remove <path>    # if worktree was used
git branch -D <branch>        # safe — commits are on main
```

---

### Main Flow (on main/master)

#### Step 1: Verify Tests

Same as Branch Flow.

#### Step 2: Identify Unpushed Commits

```bash
git log --oneline @{u}..HEAD 2>/dev/null || git log --oneline -10
```

If no upstream tracking, ask user for the base reference:
```
No upstream tracking branch. Which commit is the base?
○ Use latest tag (v1.4.1)
○ Enter a commit ref
```

#### Step 3: Review Options

```
What would you like to do?
○ Validate only — check for issues without changing commits
○ Regroup — soft-reset and re-commit into different groupings
○ Reword — amend commit messages using /commit
```

- **Validate only:** Invoke `validate-commits`, done.
- **Regroup:** Soft-reset to base, same stage-and-commit loop as
  Branch Flow Step 4.
- **Reword:** Walk commits oldest-to-newest, invoke `/commit --amend`
  for each.

#### Step 4: Optional Tag

Same as Branch Flow.

#### Step 5: Validate

Invoke `validate-commits` (unless "Validate only" already ran it).

---

## Integration

### With `/commit`

Every commit message goes through `/commit`. The review-commits skill
stages files and provides context, but message generation, style
enforcement, atomicity checks, and user approval are all `/commit`'s
job.

### With Superpowers

- `finishing-a-development-branch` triggers review-commits when
  "Merge locally" is selected.
- `subagent-driven-development` naturally leads to review-commits
  after all tasks complete.
- The skill descriptions cover the trigger phrases for auto-discovery.

### Standalone

`/review-commits` or `/validate-commits` anytime. No dependency on
superpowers.

---

## What This Plugin Does NOT Do

- **Generate commit messages** — delegates to `/commit`
- **Enforce commit style** — `/commit`'s job
- **Auto-tag** — only with explicit `--tag`
- **Add co-author** — never
- **Push** — user pushes manually
- **Resolve merge conflicts** — reports and stops

---

## Open Items

### Hook Bypass Token

The git-commit plugin's bash hook (`intercept-git-commit.sh`) blocks
direct `git commit` commands and redirects to `/commit`. The bypass
token `__GIT_COMMIT_PLUGIN__=1` allows `/commit` to execute the actual
commit. In testing, the script correctly detects the token. However,
there are reports of the bypass being blocked in practice. This needs
debugging when the issue surfaces again. The clean-merge plugin
delegates to `/commit` which handles the bypass — no additional bypass
logic needed in clean-merge itself.

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Standalone plugin (not in git-commit or guardrails) | Different workflow; uses git-commit but doesn't belong inside it |
| Two skills (review-commits + validate-commits) | Validator is independently useful for pre-push, manual merges, other skills |
| Skills (auto-triggered) not commands (explicit-only) | Discoverable — Claude suggests it when cleanup intent is detected |
| Clean worktree required to start | Skill does soft-resets and branch switches; uncommitted work would be lost |
| Deterministic validation only | No LLM judgment in checks — grep/exit-code based for reliability |
| Never generates commit messages | Single responsibility; `/commit` is the authority on messages |
