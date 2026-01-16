---
name: release
description: Release plugins with version bumping, changelog generation via git-cliff, and git tagging
argument-hint: "[plugin-name] [--bump major|minor|patch] [--dry-run]"
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

Release plugins or the entire marketplace with version bumping, changelog generation via git-cliff, and git tagging. Uses the `/commit` skill for consistent commit messages.

## Argument Parsing

Parse the command arguments to extract:

| Argument | Short | Type | Default | Description |
|----------|-------|------|---------|-------------|
| `plugin-name` | | string | (all) | Specific plugin to release, or empty for full marketplace release |
| `--bump` | `-b` | enum | `patch` | Version bump type: `major`, `minor`, or `patch` |
| `--dry-run` | `-n` | boolean | `false` | Preview changes without committing or tagging |

**Examples:**
```
/release                           # Release all plugins, patch bump
/release sketch-note               # Release specific plugin, patch bump
/release devenv --bump minor       # Minor version bump for devenv
/release -b major                  # Major release for entire marketplace
/release jot --dry-run             # Preview jot release without changes
/release -n -b minor               # Dry run with minor bump
```

---

## Execution Flow

### Step 1: Parse Arguments and Validate

1. **Parse arguments:**
   - First non-flag argument is `plugin-name` (optional)
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

4. **Validate plugin (if specified):**
   - Check if `plugins/<plugin-name>/.claude-plugin/plugin.json` exists
   - If not found:
     ```
     Error: Plugin 'foo' not found.

     Available plugins:
       - devenv
       - git-commit
       - jot
       - sketch-note
     ```

### Step 2: Read Current Versions

1. **Read marketplace.json:**
   ```bash
   cat .claude-plugin/marketplace.json
   ```
   Extract:
   - `metadata.version` (marketplace version)
   - Each plugin's version from the `plugins` array

2. **Read plugin.json files:**
   For each plugin (or just the target plugin):
   ```bash
   cat plugins/<name>/.claude-plugin/plugin.json
   ```

3. **Check version consistency:**
   Compare marketplace.json versions with plugin.json versions.

   If mismatch detected:
   ```
   Warning: Version mismatch detected:

   Plugin        marketplace.json    plugin.json
   sketch-note   1.0.0               1.2.0          MISMATCH

   What would you like to do?
   ○ Sync marketplace to plugin versions (Recommended) - Update marketplace.json
   ○ Cancel - Fix manually before releasing
   ```

   If "Sync" selected, update marketplace.json to match plugin.json versions before proceeding.

### Step 3: Calculate New Versions

1. **Determine base version:**
   - For specific plugin: read from `plugins/<name>/.claude-plugin/plugin.json`
   - For marketplace release: read from `.claude-plugin/marketplace.json` metadata.version

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

Target:           sketch-note plugin
Current Version:  1.2.0
New Version:      1.3.0
Bump Type:        minor
Tag:              v1.3.0

Files to be modified:
  - plugins/sketch-note/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - CHANGELOG.md

Proceed with release?
○ Yes, create release
○ Show changelog preview first
○ Cancel
```

If "Show changelog preview" selected, proceed to Step 5 and return here after preview.

**If `--dry-run` mode:**
Display the plan and skip to Step 10 (Dry Run Summary).

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

2. **Generate changelog for specific plugin:**
   ```bash
   git cliff --unreleased \
     --include-path "plugins/<plugin-name>/**" \
     --exclude-path "CHANGELOG.md" \
     --tag "v<new-version>"
   ```

3. **Generate changelog for full marketplace release:**
   ```bash
   git cliff --unreleased \
     --exclude-path "CHANGELOG.md" \
     --tag "v<new-version>"
   ```

4. **Preview the generated changelog:**
   ```
   Changelog Preview for v1.3.0:

   ────────────────────────────────────────────────────────────────────────
   ## [1.3.0] - 2026-01-16

   ### Added
   - Add PNG export options to sketch-note plugin
   - Add multiple output format support

   ### Changed
   - Update default export settings
   ────────────────────────────────────────────────────────────────────────

   Accept this changelog?
   ○ Yes, proceed (Recommended)
   ○ Edit before proceeding
   ○ Regenerate with different options
   ○ Skip changelog update
   ```

5. **If "Edit" selected:**
   - Allow user to provide edited changelog text
   - Use the edited version

### Step 6: Update Version Files

1. **Update plugin.json (if specific plugin release):**

   Edit `plugins/<plugin-name>/.claude-plugin/plugin.json`:
   - Update `"version": "<new-version>"`

2. **Update marketplace.json:**

   Edit `.claude-plugin/marketplace.json`:
   - Update the specific plugin's version in the `plugins` array
   - **Always** bump `metadata.version` (apply same bump type to marketplace version)

   For example, if releasing sketch-note with minor bump:
   - `plugins[].version` for sketch-note: 1.2.0 → 1.3.0
   - `metadata.version`: 1.1.0 → 1.2.0

### Step 7: Write Changelog

1. **Read existing CHANGELOG.md:**
   ```bash
   cat CHANGELOG.md
   ```

2. **Generate full changelog with the new version:**
   ```bash
   git cliff --tag "v<new-version>" -o CHANGELOG.md
   ```

   Or for plugin-specific changes only, prepend the new section:
   ```bash
   git cliff --unreleased \
     --include-path "plugins/<plugin-name>/**" \
     --tag "v<new-version>" \
     --prepend CHANGELOG.md
   ```

### Step 8: Commit Changes (Two Commits)

**IMPORTANT:** Use the `/commit` skill for both commits to ensure consistent commit message style.

#### Commit 1: Version Bumps

1. **Stage version files:**
   ```bash
   git add plugins/<plugin-name>/.claude-plugin/plugin.json
   git add .claude-plugin/marketplace.json
   ```

2. **Invoke /commit skill:**
   ```
   Use Skill: git-commit:commit
   Args: Release <plugin-name> v<new-version>
   ```

   Expected commit message (classic style):
   ```
   Release sketch-note v1.3.0

   Bump sketch-note plugin version from 1.2.0 to 1.3.0.
   Update marketplace registry with new version and bump
   marketplace metadata version to 1.2.0.
   ```

#### Commit 2: Changelog

1. **Stage changelog:**
   ```bash
   git add CHANGELOG.md
   ```

2. **Invoke /commit skill:**
   ```
   Use Skill: git-commit:commit
   Args: Update CHANGELOG for v<new-version>
   ```

   Expected commit message:
   ```
   Update CHANGELOG for v1.3.0

   Document all changes included in the v1.3.0 release.
   Generated using git-cliff with plugin-specific filtering.
   ```

**Why two commits:**
- Keeps changelog commit separate from version bumps
- The changelog commit won't appear in the next release's changelog
- Makes it easier to revert if needed
- Version bump commits are meaningful on their own

### Step 9: Create Git Tag

1. **Create annotated tag:**
   ```bash
   git tag -a "v<new-version>" -m "Release v<new-version>"
   ```

   For plugin-specific release, include plugin name:
   ```bash
   git tag -a "v<new-version>" -m "Release <plugin-name> v<new-version>"
   ```

2. **Verify tag was created:**
   ```bash
   git tag -l "v<new-version>"
   git show "v<new-version>" --quiet
   ```

### Step 10: Post-Release Summary

**For successful release:**

```
Release Complete!

Plugin:       sketch-note
Version:      1.3.0
Tag:          v1.3.0

Commits created:
  abc1234 Release sketch-note v1.3.0
  def5678 Update CHANGELOG for v1.3.0

Files modified:
  - plugins/sketch-note/.claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - CHANGELOG.md

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

Would release: sketch-note v1.3.0

Files that would be modified:
  - plugins/sketch-note/.claude-plugin/plugin.json: 1.2.0 → 1.3.0
  - .claude-plugin/marketplace.json: sketch-note 1.2.0 → 1.3.0, metadata 1.1.0 → 1.2.0
  - CHANGELOG.md: prepend v1.3.0 section

Commits that would be created:
  1. Release sketch-note v1.3.0
  2. Update CHANGELOG for v1.3.0

Tag that would be created:
  v1.3.0

To perform this release, run:
  /release sketch-note --bump minor
```

---

## Error Handling

### Not a Git Repository
```
Error: Not a git repository.
Run this command from within a git repository.
```

### Plugin Not Found
```
Error: Plugin 'foo' not found.

Available plugins:
  - devenv (1.3.0)
  - git-commit (1.1.1)
  - jot (1.3.0)
  - sketch-note (1.2.0)
```

### Tag Already Exists
```
Error: Tag v1.3.0 already exists.

The tag v1.3.0 was created on 2026-01-15.
To release this version, either:
  - Choose a different version (--bump patch for v1.3.1)
  - Delete the existing tag: git tag -d v1.3.0
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
  2. Commit manually: git commit -m "Release <plugin> v<version>"
  3. Retry the release: /release <plugin> --bump <type>
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

Then retry: /release <plugin> --bump <type>
```

---

## Important Notes

- **Two-commit workflow:** Version bumps and changelog are always in separate commits
- **Marketplace version always bumps:** Any plugin release also bumps marketplace metadata.version
- **Uses /commit skill:** All commits go through the git-commit plugin for consistent messages
- **git-cliff required:** Changelog generation requires git-cliff (available via nix develop)
- **Tag format:** Always `v<version>` (e.g., v1.3.0)
- **Path filtering:** Plugin-specific releases only include commits touching that plugin's files
- **Dry run is safe:** Use `--dry-run` to preview without any modifications
