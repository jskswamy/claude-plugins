---
name: release
description: Release marketplace with version bumping, changelog generation via git-cliff, and git tagging
argument-hint: "[--bump major|minor|patch] [--dry-run]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
  - Skill
  - mcp__1mcp__git_1mcp_git_status
  - mcp__1mcp__git_1mcp_git_diff_staged
  - mcp__1mcp__git_1mcp_git_log
  - mcp__1mcp__git_1mcp_git_add
---

# Release Command

Release the marketplace with version bumping, changelog generation via git-cliff, and git tagging. Uses the `/commit` skill for consistent commit messages.

**Philosophy:** One tag = one snapshot of all plugins. The marketplace is released as a unit since Claude installs plugins via git SHA.

## Argument Parsing

Parse the command arguments to extract:

| Argument | Short | Type | Default | Description |
|----------|-------|------|---------|-------------|
| `--bump` | `-b` | enum | `patch` | Version bump type: `major`, `minor`, or `patch` |
| `--dry-run` | `-n` | boolean | `false` | Preview changes without committing or tagging |

**Examples:**
```
/release                    # Release marketplace, patch bump
/release --bump minor       # Minor version bump
/release -b major           # Major release
/release --dry-run          # Preview changes without committing
/release -n -b minor        # Dry run with minor bump
```

---

## Execution Flow

### Step 1: Parse Arguments and Validate

1. **Parse arguments:**
   - `--bump` or `-b`: major, minor, patch (default: patch)
   - `--dry-run` or `-n`: boolean flag

2. **Verify git repository:**
   ```bash
   git rev-parse --git-dir
   ```
   If not a git repo, show error:
   ```
   Error: Not a git repository. Run this command from within a git repository.
   ```

3. **Check for uncommitted changes:**
   ```bash
   git status --porcelain
   ```
   If dirty working tree, warn:
   ```
   Warning: Uncommitted changes detected:
     - src/feature.ts (modified)
     - README.md (modified)

   What would you like to do?
   ○ Proceed anyway (Recommended) - Release with current state
   ○ Cancel - Exit and commit changes first
   ```

### Step 2: Read Current Versions and Sync

1. **Read marketplace.json:**
   ```bash
   cat .claude-plugin/marketplace.json
   ```
   Extract:
   - `metadata.version` (marketplace version)
   - Each plugin's version from the `plugins` array

2. **Read all plugin.json files:**
   ```bash
   cat plugins/<name>/.claude-plugin/plugin.json
   ```
   For each plugin in the plugins directory.

3. **Check version consistency:**
   Compare marketplace.json versions with plugin.json versions.

   If mismatch detected:
   ```
   Version sync needed:

   Plugin           marketplace.json    plugin.json
   task-decomposer  1.3.0               1.3.1          → will sync
   git-commit       1.1.1               1.1.2          → will sync

   These will be synced to marketplace.json during release.
   ```

   Automatically sync marketplace.json to match plugin.json versions.

### Step 3: Calculate New Marketplace Version

1. **Get current marketplace version:**
   Read from `.claude-plugin/marketplace.json` metadata.version

2. **Apply semver bump:**

   | Current | Bump Type | Result |
   |---------|-----------|--------|
   | 1.2.3   | patch     | 1.2.4  |
   | 1.2.3   | minor     | 1.3.0  |
   | 1.2.3   | major     | 2.0.0  |

3. **Check if tag already exists:**
   ```bash
   git tag -l "v<new-version>"
   ```
   If tag exists:
   ```
   Error: Tag v1.3.0 already exists.

   Options:
   ○ Bump to next version - Calculate v1.3.1 or v1.4.0
   ○ Delete existing tag - Remove v1.3.0 and reuse
   ○ Cancel - Exit without changes
   ```

### Step 4: Confirm Release Plan

Display the release plan for confirmation:

```
Release Plan

Marketplace Version:  1.1.7 → 1.1.8
Tag:                  v1.1.8

Plugin versions to sync:
  - task-decomposer: 1.3.0 → 1.3.1
  - git-commit: 1.1.1 → 1.1.2

Files to be modified:
  - .claude-plugin/marketplace.json
  - CHANGELOG.md
  - README.md

Proceed with release?
○ Yes, create release
○ Show changelog preview first
○ Cancel
```

If "Show changelog preview" selected, proceed to Step 5 and return here after preview.

**If `--dry-run` mode:**
Display the plan and skip to Step 9 (Dry Run Summary).

### Step 5: Generate Changelog

1. **Check if git-cliff is available:**
   ```bash
   command -v git-cliff
   ```
   If not available:
   ```
   Warning: git-cliff not found.

   Options:
   ○ Enter nix develop - Run 'nix develop' to get git-cliff
   ○ Skip changelog - Proceed without updating CHANGELOG.md
   ○ Cancel
   ```

2. **Generate changelog for all changes since last tag:**
   ```bash
   git cliff --unreleased \
     --exclude-path "CHANGELOG.md" \
     --tag "v<new-version>"
   ```

3. **Preview the generated changelog:**
   ```
   Changelog Preview for v1.1.8:

   ────────────────────────────────────────────────────────────────────────
   ## [1.1.8] - 2026-01-31

   ### Fixed
   - Fix incorrect bd CLI flags in park and parked commands

   ### Changed
   - Rename commit skill to commit-action to avoid name collision
   ────────────────────────────────────────────────────────────────────────

   Accept this changelog?
   ○ Yes, proceed (Recommended)
   ○ Edit before proceeding
   ○ Regenerate with different options
   ○ Skip changelog update
   ```

4. **If "Edit" selected:**
   - Allow user to provide edited changelog text
   - Use the edited version

### Step 6: Update Version Files

1. **Update marketplace.json:**

   Edit `.claude-plugin/marketplace.json`:
   - Sync each plugin's version from their plugin.json
   - Bump `metadata.version` to new version

2. **Write changelog:**
   ```bash
   git cliff --tag "v<new-version>" -o CHANGELOG.md
   ```

3. **Update README documentation:**
   ```bash
   ./scripts/update-readme.sh
   ```

### Step 7: Commit Changes (Two Commits)

**IMPORTANT:** Use the `/commit` skill for both commits to ensure consistent commit message style.

#### Commit 1: Version Bumps

1. **Stage version files:**
   ```bash
   git add .claude-plugin/marketplace.json
   ```

2. **Invoke /commit skill:**
   ```
   Use Skill: git-commit:commit
   Args: Release v<new-version>
   ```

   Expected commit message (classic style):
   ```
   Release v1.1.8

   Bump marketplace version from 1.1.7 to 1.1.8.
   Sync plugin versions: task-decomposer 1.3.1, git-commit 1.1.2.
   ```

#### Commit 2: Changelog and README

1. **Stage changelog and README:**
   ```bash
   git add CHANGELOG.md README.md
   ```

2. **Invoke /commit skill:**
   ```
   Use Skill: git-commit:commit
   Args: Update CHANGELOG and README for v<new-version>
   ```

   Expected commit message:
   ```
   Update CHANGELOG and README for v1.1.8

   Document all changes included in the v1.1.8 release.
   Regenerate plugins section in README from marketplace.json.
   ```

**Why two commits:**
- Keeps docs commit separate from version bumps
- The docs commit won't appear in the next release's changelog
- Makes it easier to revert if needed
- Version bump commits are meaningful on their own

### Step 8: Create Git Tag

1. **Create annotated tag:**
   ```bash
   git tag -a "v<new-version>" -m "Release v<new-version>"
   ```

2. **Verify tag was created:**
   ```bash
   git tag -l "v<new-version>"
   git show "v<new-version>" --quiet
   ```

### Step 9: Post-Release Summary

**For successful release:**

```
Release Complete!

Version:      1.1.8
Tag:          v1.1.8

Commits created:
  abc1234 Release v1.1.8
  def5678 Update CHANGELOG and README for v1.1.8

Files modified:
  - .claude-plugin/marketplace.json
  - CHANGELOG.md
  - README.md

Next steps:
○ Push changes and tag - git push && git push --tags
○ Done - I'll push manually later
```

If "Push" selected:
```bash
git push origin main
git push origin "v<new-version>"
```

**For dry run:**

```
DRY RUN COMPLETE - No changes were made

Would release: v1.1.8

Plugin versions to sync:
  - task-decomposer: 1.3.0 → 1.3.1
  - git-commit: 1.1.1 → 1.1.2

Files that would be modified:
  - .claude-plugin/marketplace.json: metadata 1.1.7 → 1.1.8
  - CHANGELOG.md: prepend v1.1.8 section
  - README.md: regenerate plugins section

Commits that would be created:
  1. Release v1.1.8
  2. Update CHANGELOG and README for v1.1.8

Tag that would be created:
  v1.1.8

To perform this release, run:
  /release --bump patch
```

---

## Error Handling

### Not a Git Repository
```
Error: Not a git repository.
Run this command from within a git repository.
```

### Tag Already Exists
```
Error: Tag v1.1.8 already exists.

The tag v1.1.8 was created on 2026-01-15.
To release this version, either:
  - Choose a different version (--bump minor for v1.2.0)
  - Delete the existing tag: git tag -d v1.1.8
```

### git-cliff Not Available
```
Warning: git-cliff command not found.

git-cliff is required for changelog generation.
To install, enter the development environment:
  nix develop

Or skip changelog generation by selecting 'Skip changelog' when prompted.
```

### Commit Skill Failed
```
Error: Failed to create commit.

The /commit skill encountered an error. You can:
  1. Review the staged changes: git status
  2. Commit manually: git commit -m "Release v<version>"
  3. Retry the release: /release --bump <type>
```

### Recovery Instructions

If release fails mid-way:
```
Release failed during: [step name]

Current state:
  - Version files: [modified/committed]
  - Changelog: [modified/committed]
  - Tag: [created/not created]

To recover:
  git reset --hard HEAD~<N>  # Undo commits
  git tag -d v<version>      # Remove tag if created

Then retry: /release --bump <type>
```

---

## Important Notes

- **Unified versioning:** One marketplace version = one snapshot of all plugins
- **Auto-sync:** Plugin versions from plugin.json are automatically synced to marketplace.json
- **Two-commit workflow:** Version bumps and changelog are always in separate commits
- **Uses /commit skill:** All commits go through the git-commit plugin for consistent messages
- **git-cliff required:** Changelog generation requires git-cliff (available via nix develop)
- **Tag format:** Always `v<version>` (e.g., v1.1.8)
- **Dry run is safe:** Use `--dry-run` to preview without any modifications
