# Changelog

All notable changes to the Claude Code Plugin Marketplace will be documented in this file.

## [1.1.1] - 2026-01-16

### Added

- Add duplicate detection and enhance workflow to jot plugin

Before creating a note, agents now check if a note with the same name
already exists. If found, users can choose to enhance the existing
note or create a new one.

Changes:
- Add 'Check for Existing Note' step to both capture agents
- Add 'Enhance Existing Note Workflow' section for updating notes
- Update filename conventions: remove date prefix from reference
  items (session, article, video, person, book, organisation, trove)
- Keep date prefix only for inbox items (task, note, idea) for GTD
- Bump plugin version to 1.2.0

Inbox items use pattern matching (*-slug.md) for duplicate detection
while reference items use exact filename matching. by @jskswamy
- Add sketch-note plugin for Excalidraw visual documentation

Implement a new plugin that generates visual sketch notes in Excalidraw
format from conversations, code architecture, or custom descriptions.

Features:
- /sketch command with three modes: conversation, code, custom
- Proactive sketch agent triggered by visualization requests
- Excalidraw format skill with complete JSON schema reference
- Customizable styling: roughness, stroke width, colors, effects
- Persistent user preferences via .claude/sketch-note.local.md
- Output saved to sketches/ directory as .excalidraw files

Plugin structure:
- 1 command (sketch.md)
- 1 agent (sketch.md)
- 1 skill (excalidraw-format)
- 3 style definitions (hand-drawn, sketchy, clean)
- 3 content templates (conversation, code-architecture, custom) by @jskswamy
- Add .beads/.gitignore to exclude unnecessary files

This commit introduces a .gitignore file for the .beads directory to
prevent tracking of various temporary and machine-specific files.

The patterns include:

- SQLite database files
- Daemon runtime files
- Local version tracking files
- Legacy database files
- Worktree redirect files
- Merge artifacts
- Sync state files by @jskswamy
- Add beads configuration for AI-native issue tracking

Initialize beads in this repository with:
- README explaining beads usage and quick start guide
- Configuration with sync-branch set to 'beads-sync'
- Git attributes for JSONL merge driver
- AGENTS.md with workflow instructions for AI coding agents

Beads provides git-native issue tracking designed for AI-assisted
development workflows. Issues live in the repo as JSONL, sync with
git, and work seamlessly with Claude Code and other AI agents. by @jskswamy
- Add PNG export options to sketch-note plugin

Implement multiple approaches for generating PNG output from sketches:

1. Direct PNG via Mermaid CLI - generates PNG directly without
   intermediate Excalidraw file, uses hand-drawn theme styling

2. Excalidraw conversion - creates Excalidraw first, then converts
   using excalidraw-brute-export-cli or excalidraw-cli

The workflow detects available tool runners (nix-shell, npx) and
globally installed tools, enabling zero-install mode where tools run
on-demand via npx or nix-shell without requiring global installation.

Features:
- --format argument: excalidraw, png, both, or direct-png
- --scale argument: 1, 2, or 4 for PNG resolution
- Interactive workflow guides users through export options
- Automatic tool detection with smart fallbacks
- export-png.sh helper script with nix/npx support by @jskswamy
- Add auto-version sync hook for plugins

When plugin content files are modified (commands/, agents/, skills/,
etc.), this hook automatically:
- Bumps the patch version in plugin.json
- Syncs the version to marketplace.json
- Shows a system message confirming the bump

Uses session markers (/tmp/.claude-version-bumped-{plugin}) to ensure
only one bump per plugin per session, preventing multiple bumps when
editing several files.

Skips metadata files (plugin.json, marketplace.json, README, CHANGELOG)
to avoid infinite loops. by @jskswamy
- Add unified storage and cross-plugin skills to sketch-note

Update sketch-note plugin to use the shared workbench_path configuration
from .claude/jot.local.md, ensuring sketches and captures are stored
together in a unified location (default: ~/workbench/sketches/).

Add two cross-plugin skills enabling seamless workflows between jot
and sketch-note:

- plugins/jot/skills/sketch-from-capture.md: Enables creating visual
  diagrams from captured content (articles, videos, blips)
- plugins/sketch-note/skills/capture-for-sketch.md: Enables sketching
  directly from URLs, YouTube videos, or GitHub repos

This makes it easier to capture content and immediately visualize it,
or to create visual summaries of external resources.

### Changed

- Update changelog with v1.0.1 release notes

Add changelog entries documenting recent changes:
- Initial changelog generation with git-cliff automation
- Removal of automatic Claude co-author attribution from git-commit
  plugin (v1.1.1)

Updates version link to compare v1.0.0..v1.0.1. by @jskswamy
- Move file existence check to start of capture workflow

Previously, the capture agents would process through multiple steps
before checking if a note already existed, wasting time when the
user wanted to update an existing note.

Changes:
- capture.md: Merge Step 1 and 1b into unified step that checks for
  existing notes immediately after type detection and slug extraction
- quick-capture.md: Move existence check to Step 1c, right after
  parsing and alias resolution, before any context gathering
- Both agents now read and display existing note info before asking
  any user questions
- Renumber subsequent steps in quick-capture.md (Steps 2-10)

Closes claude-plugins-3f3 by @jskswamy
- Move plugin hooks to local .claude/hooks directory

Relocate version sync and changelog notification hooks from the public
hooks/ directory to .claude/hooks/ for repository-local use only.

This keeps automation scripts private to this repository rather than
publishing them as part of the marketplace. The hooks can be exported
to other repositories later if needed.

Hooks moved:
- sync-plugin-version.sh: Auto-bumps patch version on plugin changes
- update-changelog.sh: Notifies when changelog updates are needed
- Move release command to .claude/commands directory

Local slash commands must be in .claude/commands/ to be discovered by
Claude Code. The previous .claude/plugins/ location is for installable
plugins, not local commands.

This fixes the /release command not appearing in the command list.

### Other

- Bd sync: 2026-01-12 23:01:25 by @jskswamy
- Sync plugin versions in marketplace registry

Update marketplace.json to match actual plugin versions:
- jot: 1.0.0 → 1.3.0
- sketch-note: 1.0.0 → 1.2.0 (includes PNG export feature)

Also bump sketch-note plugin.json from 1.1.0 to 1.2.0 to reflect
the PNG export changes added earlier. by @jskswamy
- Release marketplace v1.1.1 with plugin version bumps

Bump versions for plugins with changes since last sync:
- jot: 1.3.0 → 1.3.1 (added sketch-from-capture skill)
- sketch-note: 1.2.0 → 1.2.1 (added unified storage, capture-for-sketch)
- marketplace metadata: 1.1.0 → 1.1.1
## [1.0.1] - 2026-01-12

### Added

- Add initial changelog for plugin marketplace

Document all notable changes since the initial commit using Keep a
Changelog format. The changelog is generated by git-cliff configured
for classical/imperative commit messages.

Sections included:
- Added: devenv plugin, git-commit plugin, jot plugin, changelog
  automation, and plugin documentation
- Changed: marketplace naming, pre-commit config, devenv enhancements
- Initial Setup: marketplace foundation and development environment
- Removed: welcome message from shell hook

This provides project history visibility and supports the changelog
automation workflow added in commit 346dc78. by @jskswamy

### Removed

- Remove automatic Claude co-author attribution from commits

Update the git-commit plugin to only add Co-Authored-By lines when the
--pair flag is explicitly used and a human co-author is selected.

Changes:
- Clarify co-author handling rules in commit command documentation
- Add explicit instruction to never add Claude/Anthropic co-author lines
- Bump version to 1.1.1

This ensures commit messages remain clean and co-authorship reflects
actual pair programming sessions rather than AI assistance. by @jskswamy
## [1.0.0] - 2026-01-12

### Added

- Add Devenv Plugin for Nix Flake Management

Introduce the Devenv plugin to initialize and manage Nix flake
development environments easily. This plugin features auto-detection
of project stacks, generates `flake.nix` with best practices, and
integrates security tooling for enhanced safety.

Key features include:

- Auto-detection of project stacks (Node.js, Python, Go, Rust, etc.)
- Pre-commit hooks with SAST tools
- Automatic linting and formatting with nixfmt, statix, and deadnix

Additionally, comprehensive documentation and installation instructions
are provided to streamline user adoption and integration into
development workflows. by @jskswamy
- Add options for secret scanning and fix gitleaks hook

Update the plugin version to 1.0.1 and enhance the documentation
to include options for secret scanning with trufflehog and gitleaks.

The changes also fix the gitleaks pre-commit hook configuration
to enable it as a custom hook, ensuring that secrets can be
properly scanned before commits. This provides users with
flexibility in choosing their secret scanning tool while
maintaining compatibility with the existing setup.

- Added secret scanner preference prompt in the documentation
- Specified the configuration for gitleaks as a custom hook
- Updated keywords for better categorization in plugin.json
- Ensured gitleaks is included in the packages for manual use. by @jskswamy
- Add MCP server support for enhanced Nix package search

This commit introduces support for the MCP server in the Nix
development environment, improving package searchability. The
plugin now integrates with `mcp-nixos`, allowing users to access
over 130K NixOS packages with accurate names and version history
via NixHub.io.

The integration works as follows:
- The plugin first checks for a global or project-level MCP
  configuration to avoid duplicates.
- If not available, it utilizes the bundled MCP server, which
  runs via `nix-shell -p uv`.
- As a fallback, the native `nix search` command is used.

Additionally, users can customize their settings in
`.claude/devenv.local.md` to enable or disable MCP search,
ensuring flexibility in package management. by @jskswamy
- Add git-commit plugin for intelligent commit message generation

Introduce a Claude Code plugin that generates commit messages with
support for classic and conventional commit styles. The plugin
validates atomic commits, detects related unstaged changes, and
supports pair programming attribution.

Features:
- Classic and conventional commit style support
- Strict atomic commit validation with split commit workflow
- Related unstaged/untracked file detection
- Pair programming co-author attribution (--pair flag)
- Configurable preferences via .claude/git-commit.local.md by @jskswamy
- Add session context awareness to commit message generation

The plugin now reviews the conversation history before generating
commit messages to capture the reasoning behind changes.

New Step 6b extracts from the session:
- User's original intent and problem being solved
- Key decisions and trade-offs discussed
- Issue/ticket references mentioned
- Clarifications and scope adjustments

This enables commit messages that explain WHY changes were made, not
just WHAT changed. The diff shows implementation details, but session
context captures the motivation that would otherwise be lost.

Context priority: CLI arguments > session context > diff analysis

Bumps version to 1.1.0 for this feature addition. by @jskswamy
- Add jot plugin for quick knowledge capture

Introduce a Claude Code plugin for low-friction capture of notes,
tasks, ideas, and tech radar blips with Obsidian-style auto-linking.

Key features:
- Single /capture command with type flags (task, note, idea, blip)
- URL-based extraction for articles, videos, people, books, and more
- ThoughtWorks-style tech radar with rings and quadrants
- Auto-linking to related notes via [[wikilinks]]
- Rich content templates targeting 60-120+ lines per capture
- Zettelkasten-inspired book template with reflection prompts
- Configurable workbench path for central storage

All tools and technologies are captured as "blips" (tech radar items)
with comprehensive documentation including features, installation,
usage examples, pros/cons, and alternatives. by @jskswamy
- Add changelog automation with git-cliff and hooks

Implement automated changelog generation using git-cliff configured for
classical/imperative commit messages (not conventional commits).

Changes:
- Add cliff.toml with parsers that categorize commits by imperative
  verbs (Add, Fix, Update, Remove, etc.) into Keep a Changelog sections
- Add pre-push hook in flake.nix that warns about unreleased commits
- Add Claude Code PostToolUse hook that notifies when plugin versions
  change, suggesting changelog updates
- Add jq dependency for JSON processing in hooks

The git-cliff configuration supports the repository's classical commit
style, grouping commits into Added, Changed, Fixed, Removed, and other
standard changelog sections. by @jskswamy
- Add plugin documentation for git-commit and jot

Document the git-commit plugin featuring intelligent commit message
generation with classic/conventional styles, atomic commit validation,
pair programming support, and session context awareness.

Document the jot plugin for quick knowledge capture including tasks,
notes, ideas, session summaries, tech radar blips, and URL-based
captures with Obsidian-style auto-linking.

Update roadmap to reflect completed milestones:
- Git commit helpers (now git-commit plugin)
- Note-taking and knowledge management (now jot plugin) by @jskswamy

### Changed

- Rename marketplace to avoid violating Claude's naming rules

Updated the marketplace name from "claude-plugins" to
"jskswamy-plugins" to comply with the restrictions set by
Claude regarding marketplace names. by @jskswamy
- Update pre-commit configuration in documentation

Revise the documentation for the pre-commit hooks to reflect changes in
the configuration. Specifically, the `trailing-whitespace` and
`end-of-file-fixer` hooks have been replaced with
`trim-trailing-whitespace` for better clarity and functionality.

Additionally, include instructions to update `.gitignore` to exclude
generated files, ensuring a cleaner project structure. This change
aims to streamline the setup process for new developers and improve
the overall maintainability of the project. by @jskswamy
- Update devenv plugin version and enhance direnv support

Upgrade the devenv plugin to version 1.2.0, which includes updates to
the metadata and adds new tags for improved functionality. The tags
now include "direnv" and "direnv-instant" to support enhanced
environment loading options.

Additionally, remove the obsolete settings.local.json file, as it is no
longer needed. The README and command documentation have been updated
to reflect the new direnv-instant integration, allowing for async
environment loading and an instant shell prompt. Detailed setup
instructions for direnv-instant are provided, ensuring a smoother
developer experience when managing Nix flake environments. by @jskswamy
- Allow customization of welcome message style

Added the ability for users to specify how the welcome message
should appear when entering their development environment. The
configuration options include various styles such as `box`,
`minimal`, `project`, `tech`, and `custom`. A custom message
can be set for the `custom` style.

Updated the README and commands documentation to reflect these
changes, providing guidance on how to modify the welcome
message style and text. This enhancement aims to improve
user experience by allowing more personalized greetings. by @jskswamy
- Update version of devenv plugin to 1.3.0

Bump the version of the devenv plugin from 1.2.0 to 1.3.0 in the
marketplace configuration. This update includes improvements and
enhancements that justify the version increment. The plugin helps
initialize and manage Nix flake development environments with
auto-detection and security tooling. by @jskswamy
- Enhance jot plugin with session capture and context features

Add new capture capabilities to support realistic work session workflows:

Session summaries:
- New /capture session command with guided questions
- Captures goal, accomplishments, decisions, lessons, and follow-ups
- Saves to notes/sessions/ directory
- Alias: /capture conversation

Type aliases for reduced friction:
- todo → task
- thought → note
- conversation → session

URL references in quick captures:
- /capture todo use https://example.com/ to do X
- Keeps as quick capture, not full extraction
- Optionally fetches page title only

Automatic session context:
- Silently captures git repo, branch, working directory
- Embedded in all quick captures for context recovery

Optional additional context:
- "Anything else you want to remember?" after discovery context
- User can skip; section omitted if skipped

These features address the need to capture notes, tasks, and session
summaries during active Claude Code sessions without losing the
context needed to regain understanding later. by @jskswamy

### Initial Setup

- Initial commit of Claude Plugins Marketplace

This commit establishes the Claude Plugins Marketplace, a curated
collection of Claude Code plugins aimed at enhancing developer
workflows, code generation, and productivity.

Key components included in this initial setup:

- .claude-plugin/marketplace.json: Marketplace registry for plugins
- .claude/settings.json: Configuration to enable the official
  plugin-dev tool
- .claude/settings.local.json: Local settings with necessary
  permissions
- .gitignore: Common files and directories to ignore
- CLAUDE.md: Guidance for using the marketplace and creating new
  plugins
- CONTRIBUTING.md: Guidelines for contributing plugins
- README.md: Overview of the marketplace and available plugins
- plugins/: Directory for individual plugins (currently empty) by @jskswamy
- Initialize development environment for Claude Code plugin

Add necessary files and configurations to set up the
development environment for the Claude Code plugin marketplace.

This includes:

- .gitignore: Added entries for Nix/direnv and
  pre-commit configuration files.
- flake.lock: New file to manage dependencies with
  specific versions.
- flake.nix: Configuration file defining the inputs
  and outputs for the development environment,
  including pre-commit hooks for linting,
  spell checking, and other checks. by @jskswamy
- Initialize direnv for development environment

Update the project to use the direnv plugin for managing the
development environment. This includes adding necessary files
to .gitignore to avoid committing sensitive environment files
and updating flake.lock and flake.nix to include direnv-instant
as a dependency.

- Added .env, .env.*, .envrc to .gitignore
- Included direnv-instant in flake.nix and flake.lock
  to ensure proper environment setup
- Updated nixpkgs references in flake.lock for compatibility by @jskswamy

### Removed

- Remove welcome message from shell hook by @jskswamy
[1.1.1]: https://github.com/jskswamy/claude-plugins/compare/v1.0.1..v1.1.1
[1.0.1]: https://github.com/jskswamy/claude-plugins/compare/v1.0.0..v1.0.1

