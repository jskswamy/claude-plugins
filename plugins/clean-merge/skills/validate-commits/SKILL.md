---
name: validate-commits
description: >
  Validate commits before pushing. Runs five deterministic checks: clean
  worktree, tests pass, no AI co-author leaks (Claude, Anthropic, GPT,
  OpenAI, Copilot), no conflict markers, no squash/fixup residue.
  Activates on: "validate commits", "check commits before push",
  "any AI leaks", "check for co-author", "are my commits clean",
  "validate before pushing", "check commits".
argument-hint: "[--base <ref>]"
allowed-tools:
  - Bash
  - Grep
  - Glob
  - Read
  - AskUserQuestion
---

# Validate Commits

Run five deterministic checks against unpushed commits. All checks use
git commands and grep — no LLM judgment.

## Precondition

Require a clean worktree before starting. Run:

```bash
git status --porcelain
```

If output is non-empty, refuse to proceed:

    Your worktree has uncommitted changes. Please commit or stash them
    before running validation.

## Determine Commit Range

Establish the base ref for `base..HEAD` in this priority order:

1. **Explicit `--base <ref>` argument** — use directly
2. **Upstream tracking** — run `git rev-parse @{u}` to get upstream ref.
   If it succeeds, use `@{u}..HEAD`
3. **No upstream** — ask the user using AskUserQuestion:
   - Get the latest tag: `git describe --tags --abbrev=0 2>/dev/null`
   - Offer options:
     - "Use latest tag (<tag>)" — if a tag exists
     - "Enter a commit ref" — free text input

Store the resolved base as `$BASE` for all subsequent checks.

If `git log --oneline $BASE..HEAD` produces no commits, report
"No commits to validate between $BASE and HEAD" and stop.

## Checks

Run ALL five checks regardless of individual failures. Collect results,
then report everything at once.

### Check 1: Clean Worktree

Run: `git status --porcelain`

- **Pass:** No output
- **Fail:** List the dirty files

### Check 2: Tests Pass

Detect the project test command by checking for project files in the
working directory root:

| File | Command |
|------|---------|
| `go.mod` | `go test ./...` |
| `package.json` | `npm test` |
| `Cargo.toml` | `cargo test` |
| `pyproject.toml` | `pytest` |

Check files in this order. Use the first match. If no project file is
found, skip this check and mark as "Skipped (no test command detected)".

Run the detected command. Capture exit code.

- **Pass:** Exit code 0
- **Fail:** Show the test command and its exit code

### Check 3: No AI Co-Author

Scan all commits in range for AI co-author lines:

```bash
git log --format=%B $BASE..HEAD
```

Search the output for `Co-Authored-By:` lines matching ANY of these
patterns (case-insensitive):

- Names: `Claude`, `Anthropic`, `GPT`, `OpenAI`, `Copilot`, `GitHub Copilot`
- Emails: `noreply@anthropic.com`, `noreply@openai.com`
- Model refs: `Claude Opus`, `Claude Sonnet`, `Claude Haiku`, `Claude Code`

For each match, record the commit hash and the offending line.

- **Pass:** No matches
- **Fail:** List each commit hash and the matched Co-Authored-By line

### Check 4: No Conflict Markers

Get the list of files changed in the commit range:

```bash
git diff --name-only $BASE..HEAD
```

For each file that still exists in the working tree, search for
conflict markers:

```bash
grep -n '<<<<<<< \|>>>>>>>' <file>
```

- **Pass:** No matches in any file
- **Fail:** List each file and line number with the marker

### Check 5: No Squash Residue

Check commit subjects for fixup/squash prefixes:

```bash
git log --format=%s $BASE..HEAD
```

Check each subject line. A subject starting with `fixup! ` or `squash! `
is a failure.

- **Pass:** No subjects start with `fixup!` or `squash!`
- **Fail:** List each commit hash and subject

## Report Results

Display all five results using checkmark/cross format:

```
Post-commit validation:

  ✓ Clean worktree
  ✓ Tests pass (summary)
  ✗ AI co-author in commit 7ce2788
    Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
  ✓ No conflict markers
  ✓ No squash residue
```

If ALL pass: "All checks passed. Ready to push."

If ANY fail: "Post-commit validation failed." followed by the results.

## Auto-Fix: AI Co-Author

If Check 3 fails AND all other checks pass (or the user wants to fix
incrementally), offer to auto-fix:

Use AskUserQuestion:
```
Fix automatically? (amends the affected commit to remove the AI co-author line)
○ Yes — remove the co-author line
○ No — I'll handle it
```

If "Yes":
- For each affected commit (most recent first):
  - Get the full commit message: `git log -1 --format=%B <hash>`
  - Remove the offending `Co-Authored-By:` line(s)
  - If the commit is HEAD: `git commit --amend -m "<cleaned message>"`
  - If the commit is NOT HEAD: use interactive rebase is not possible
    in this context, so report: "Commit <hash> is not HEAD. To fix,
    run: `git rebase -i <hash>^` and edit the commit message manually."
- Re-run Check 3 to confirm the fix worked

If "No": Report the failure and let the user handle it.

## No Other Auto-Fixes

Checks 1, 2, 4, and 5 report failures only. The user must fix them.
