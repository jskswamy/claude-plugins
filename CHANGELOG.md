# Changelog

All notable changes to the Claude Code Plugin Marketplace will be documented in this file.

## [1.6.4] - 2026-03-30

### Removed

- Remove commit message validation hook from guardrails

The Bash PreToolUse prompt hook fired an LLM evaluation on every
bash command, not just git commit. The LLM non-deterministically
blocked legitimate commands by overriding its own allow instruction.
The git-commit plugin already validates commit messages in its own
workflow, making this hook redundant.
## [1.6.3] - 2026-03-30

### Added

- Add review-commits design spec for clean-merge plugin

Document the approved design for a standalone clean-merge plugin
with two skills: review-commits (workflow for regrouping, rewording,
and merging branch commits) and validate-commits (deterministic
post-commit checks for AI co-author leaks, conflict markers, and
squash residue). Produced through collaborative brainstorming to
automate the repetitive commit-cleanup workflow. by @jskswamy
- Add clean-merge plugin with commit review and validation

Introduce a standalone plugin for cleaning up commits before pushing.
Two skills: review-commits (auto-detects branch vs main, orchestrates
squashing/regrouping/rewording via /commit delegation) and
validate-commits (five deterministic checks — clean worktree, tests,
AI co-author leaks, conflict markers, squash residue).

Registered in marketplace under the git category. by @jskswamy

### Changed

- Update CHANGELOG and README for v1.6.3

Document all changes included in the v1.6.3 release.
Regenerate plugins section in README from marketplace.json. by @jskswamy

### Other

- Release v1.6.3

Bump marketplace version from 1.6.2 to 1.6.3. by @jskswamy
## [1.6.2] - 2026-03-18

### Changed

- Update CHANGELOG and README for v1.6.2

Document bugfixes for Stop hook validation and restored
MCP commit intercept prompt. by @jskswamy

### Fixed

- Fix Stop hook JSON validation failure in task-decomposer

The prompt-type Stop hook produced natural language output instead
of valid JSON, causing validation errors on every Claude response.

Replace with a command-type hook that runs a shell script:
- Checks last commit for beads task ID references
- If found, checks for linked parked ideas
- Exits silently (code 0, no output) when nothing to surface
- Only prints when parked ideas exist after a task commit

Bump task-decomposer 1.6.0 → 1.6.1. by @jskswamy

### Other

- Restore MCP commit intercept prompt deleted during v2.0 migration

The v2.0 migration incorrectly deleted intercept-mcp-commit.md
which is actively referenced by hooks.json as a prompt-type
PreToolUse hook. Without it, the hook fails when Claude attempts
to use the MCP git commit tool directly.

Bump git-commit 1.2.1 → 1.2.2. by @jskswamy
- Release v1.6.2

Bump marketplace version from 1.6.1 to 1.6.2.
Bugfixes: task-decomposer 1.6.1 (Stop hook), git-commit 1.2.2
(restored MCP intercept prompt). by @jskswamy
## [1.6.1] - 2026-03-18

### Changed

- Migrate devenv command to v2.0 skills directory format

Move commands/devenv.md to skills/devenv/SKILL.md and remove
the legacy commands/ directory. Bump devenv 1.3.1 → 1.3.2. by @jskswamy
- Update CHANGELOG and README for v1.6.1

Document devenv migration to v2.0 skills directory format. by @jskswamy

### Other

- Release v1.6.1

Bump marketplace version from 1.6.0 to 1.6.1.
Complete v2.0 migration: devenv 1.3.1 → 1.3.2 (skill dir format). by @jskswamy
## [1.6.0] - 2026-03-18

### Changed

- Migrate all plugin skills to v2.0 directory format

Convert all flat skills/<name>.md files to the new
skills/<name>/SKILL.md directory structure across 7 plugins:
task-decomposer (5), task-executor (1), git-commit (2),
jot (1), sketch-note (1), guardrails (1), typst-notes (2).

Move task-decomposer frameworks/ into skills/decompose/ as
reference material accessible via ${CLAUDE_PLUGIN_ROOT}.

Add allowed-tools to typst-notes publish command. Add v2.0
agent frontmatter: isolation: worktree for task-executor
reviewers, memory: project for issue-writer, memory: user
for jot learning-tutor. by @jskswamy
- Update CHANGELOG and README for v1.6.0

Document plugin v2.0 migration: skills directory format,
hooks.json conversion, agent frontmatter fields, and
${CLAUDE_PLUGIN_ROOT} usage across all plugins. by @jskswamy

### Fixed

- Fix plugin v2.0 critical issues

Add missing name: field to agent frontmatter in task-decomposer
(issue-writer) and task-executor (spec-reviewer, quality-reviewer).

Convert task-decomposer legacy hook from review-after-commit.md
with event: Stop frontmatter to hooks/hooks.json prompt-type format.

Remove unused legacy hook .md files from git-commit plugin
(intercept-bash-commit.md, intercept-mcp-commit.md) — hooks.json
already handles the functionality. by @jskswamy

### Other

- Use ${CLAUDE_PLUGIN_ROOT} for framework file paths

Replace find-based framework file lookup with direct
${CLAUDE_PLUGIN_ROOT}/skills/decompose/frameworks/ paths
in both the decompose skill and command. by @jskswamy
- Bump plugin versions for v2.0 migration

Patch bumps for format-only changes:
  git-commit 1.2.0 → 1.2.1
  jot 1.4.1 → 1.4.2
  sketch-note 1.2.1 → 1.2.2
  guardrails 1.0.0 → 1.0.1
  typst-notes 1.0.2 → 1.0.3

Minor bumps for feature additions:
  task-decomposer 1.5.0 → 1.6.0
  task-executor 1.1.0 → 1.2.0 by @jskswamy
- Release v1.6.0

Bump marketplace version from 1.5.0 to 1.6.0.
Migrate all plugins to Claude Code v2.0 structure:
skills/<name>/SKILL.md format, hooks.json, agent name
fields, memory/isolation frontmatter, ${CLAUDE_PLUGIN_ROOT}. by @jskswamy
## [1.5.0] - 2026-03-18

### Added

- Add configurable decomposition framework support

Wrap different task decomposition methodologies (superpowers, speckit,
bmad) under a unified UX. On first /decompose, the plugin detects
available frameworks, asks the user to choose, and persists the
selection per-project in .claude/task-decomposer.local.md.

The /execute command now reads the persisted framework and adapts
subagent prompts and review criteria accordingly — TDD enforcement
for superpowers, requirements traceability for speckit, architecture
compliance for bmad.

All framework artifacts (constitutions, PRDs, architecture docs) are
stored in beads rather than framework-specific files, ensuring a
single source of truth across sessions and context compaction.

- task-decomposer v1.4.0 → v1.5.0
- task-executor v1.0.0 → v1.1.0 by @jskswamy

### Changed

- Update CHANGELOG and README for v1.5.0

Document all changes included in the v1.5.0 release.
Regenerate plugins section in README from marketplace.json. by @jskswamy

### Fixed

- Fix invalid autoActivation key in task-executor manifest

The plugin.json used an unrecognized autoActivation key which
caused installation to fail. Replace with valid author and
keywords fields matching the format of other plugins. by @jskswamy

### Other

- Reinitialize beads with dolt backend

The previous beads database was missing from the dolt server.
Ran bd init --force to bootstrap a fresh dolt-backed database
with updated hooks (v0.61.0) and agent instructions. by @jskswamy
- Release v1.5.0

Bump marketplace version from 1.4.0 to 1.5.0.
Plugin versions: task-decomposer 1.5.0, task-executor 1.1.0. by @jskswamy
## [1.4.0] - 2026-02-26

### Added

- Add task tracker noise filtering to commit styles

When agents use tools like beads for task tracking, internal
references (tracker IDs, workflow phases, agent metadata) were
leaking into commit messages. Someone reading git history without
context of these tools would find the references confusing.

Changes:
- Add "Content Filtering" section to both classic and conventional
  style files with explicit rules and before/after examples
- Expand Step 7b validation in the commit command to catch broader
  patterns: bd commands, dependency references, acceptance criteria
  leaks, agent dispatch metadata, and specification fragments by @jskswamy
- Add superpowers-inspired task structure to decomposer

The decomposer now produces richer, more actionable tasks using
the Do/Verify pattern: each task includes self-contained context,
exact file paths, step-by-step actions, and verification commands
with expected outputs. Tasks are sized to 2-5 minutes of work so
a fresh agent can execute any task independently.

Key enhancements:
- Tasks use Context/Do/Verify structure instead of flat
  Description/Design/Acceptance fields
- Issue-writer maps Do to design, Verify to acceptance, and
  Context to description for richer beads issues
- Task completion requires running verification commands before
  closing (the "Iron Law"), with --skip-verify escape hatch
- Design exploration gate between understanding and planning
  proposes 2-3 approaches with trade-offs before decomposing by @jskswamy
- Add task-executor plugin for subagent-driven execution

New plugin that executes decomposed tasks using isolated subagents.
Each task gets a fresh agent with self-contained context from the
Do/Verify structure, followed by dual-stage review and an atomic
commit via the /commit plugin.

Components:
- /execute command with batch processing, dependency-ordered
  dispatch, and human checkpoints between batches
- Spec compliance reviewer agent that independently runs
  verification commands and checks requirement coverage
- Code quality reviewer agent that categorizes issues as
  Critical/Important/Minor with security focus
- Auto-detection skill for natural execution triggers
- Registered in marketplace under workflow category by @jskswamy

### Changed

- Update CHANGELOG and README for v1.4.0

Document all changes included in the v1.4.0 release.
Regenerate plugins section in README from marketplace.json. by @jskswamy

### Other

- Release v1.4.0

Bump marketplace version from 1.3.3 to 1.4.0. by @jskswamy
## [1.3.3] - 2026-02-19

### Added

- Add commit message validation guardrails

Prevent internal workflow context from leaking into git
history. Commit messages are now evaluated for task tracker
IDs, workflow phase labels, AI attribution, and progress
tracking artifacts before they enter the log.

- Add LLM-as-judge validation step (Step 7b) to /commit
  command that silently strips violations during generation
- Add commit-eval agent for standalone message evaluation
  and auditing existing history
- Add prompt-based PreToolUse hook on Bash as advisory
  safety net for commits bypassing /commit
- Update guardrails plugin description and hooks config by @jskswamy

### Changed

- Update CHANGELOG and README for v1.3.3

Document all changes included in the v1.3.3 release.
Regenerate plugins section in README from marketplace.json. by @jskswamy

### Other

- Release v1.3.3

Bump marketplace version from 1.3.2 to 1.3.3. by @jskswamy
## [1.3.2] - 2026-02-10

### Changed

- Update CHANGELOG and README for v1.3.2 by @jskswamy

### Fixed

- Fix commit plugin hook blocking its own commit

The PreToolUse Bash hook intercepted git commit commands issued
by the /commit workflow itself, creating a circular block. The
hook regex also missed env-var-prefixed commands, allowing
accidental bypasses like `SKIP_COMMIT_HOOK=1 git commit`.

- Broaden hook regex to catch env-var-prefixed git commits
- Add `__GIT_COMMIT_PLUGIN__=1` bypass token to hook script
- Prefix all git commit templates in commit.md with the token by @jskswamy

### Other

- Release v1.3.2

Bump marketplace version from 1.3.0 to 1.3.2. by @jskswamy
## [1.3.0] - 2026-02-04

### Added

- Add guardrails plugin for IDE refactoring handoff

New plugin that provides efficiency guardrails, starting with IDE
refactoring handoff. IDEs use AST-based semantic refactoring (instant,
atomic, accurate) while AI uses text-based pattern matching (slower,
sequential). This plugin teaches Claude when to delegate structural
changes to the user's IDE.

Components:
- Background knowledge skill (ide-handoff.md) - primary mechanism where
  Claude self-regulates based on understanding refactoring patterns
- Safety net hook - detects repeated edit patterns (3+ identical
  substitutions) and suggests handoff
- /handoff command - generates IDE-specific instructions for IntelliJ/
  GoLand and VSCode
- Templates for both IDE families with keyboard shortcuts

Triggers handoff for: package moves, cross-file renames, signature
changes, interface extraction, any 10+ file coordinated structural
change.

Extensible design allows adding future guardrails for security, cost
awareness, and testing patterns. by @jskswamy

### Changed

- Update CHANGELOG and README for v1.3.0

Document all changes included in the v1.3.0 release.
Regenerate plugins section in README from marketplace.json. by @jskswamy

### Fixed

- Fix README template extraction for task-decomposer and typst-notes

The gomplate template extracts features using bold bullet patterns like
"- **Feature:** description". Both plugins had formats that didn't match:

- task-decomposer: Used tables and subsection headers instead of bullets
- typst-notes: Missing the ## Features section entirely

This caused the README generator to fall back to marketplace.json tags,
displaying keyword-only features ("Beads", "Typst") instead of real
descriptions. task-decomposer also showed wrong usage "/taskdecomposer"
instead of "/decompose".

Changes:
- Add ## Features section with bold bullets to both plugin READMEs
- Add ## Usage section with /decompose examples to task-decomposer
- Regenerate main README.md via update-readme.sh by @jskswamy
## [1.2.0] - 2026-02-02

### Added

- Add multi-epic support to task-decomposer

Enable decomposition to create multiple epics when breaking down
complex work that spans multiple themes or areas. Previously limited
to creating at most one epic per decomposition.

Changes:
- Add --epics flag for explicit multi-epic specification (comma-sep)
- Add auto-grouping heuristics with theme detection keywords
- Update issue-writer agent to handle multiple epics and cross-epic
  dependencies
- Update decomposition preview format for multi-epic output
- Bump version to 1.4.0

The auto-grouping feature analyzes task descriptions for common
themes (UI, backend, security, etc.) and suggests epic groupings
when tasks naturally cluster together.

Closes: claude-plugins-4j4 by @jskswamy

### Changed

- Update CHANGELOG and README for v1.2.0

Document all changes included in the v1.2.0 release.
Regenerate plugins section in README from marketplace.json. by @jskswamy

### Fixed

- Fix unreliable commit interception with deterministic hook

The prompt-based PreToolUse hook for intercepting git commit commands
was non-deterministic - LLM evaluation varied between calls, sometimes
blocking unrelated commands while allowing actual git commits through.

Changes:
- Replace prompt hook with command hook using bash pattern matching
- Add intercept-git-commit.sh script for reliable git commit detection
- Add Step 1b to /commit command: check CLAUDE.md for commit
  instructions and offer to add them on first use
- Update README with changelog and new hook architecture docs
- Bump version to 1.2.0

The CLAUDE.md integration helps ensure agents use /commit in future
sessions by adding explicit instructions to the project configuration.

Closes: claude-plugins-qy5 by @jskswamy

### Other

- Release v1.2.0

Bump marketplace version from 1.1.8 to 1.2.0.
Plugin versions: task-decomposer 1.4.0, git-commit 1.2.0. by @jskswamy
## [1.1.8] - 2026-01-31

### Changed

- Rename commit skill to commit-action to avoid name collision

The skill and command both had name "commit", causing the command's
short description to appear in the system reminder instead of the
skill's trigger phrases. This prevented auto-invocation when users
said "commit the changes".

Renamed skill to "commit-action" so both are distinctly visible
and the skill's trigger phrase list is properly exposed.

Fixes: claude-plugins-z9l by @jskswamy
- Update CHANGELOG and README for v1.1.8

Document all changes included in the v1.1.8 release.
Regenerate plugins section in README from marketplace.json. by @jskswamy

### Fixed

- Fix incorrect bd CLI flags in park and parked commands

The bd CLI uses -l/--label (singular) not --labels (plural).
Also fixed bd label remove syntax and added instructions
for setting deferred status when updating existing issues.

Files fixed:
- commands/park.md - fixed --labels and added update flow
- commands/parked.md - fixed --labels and label remove syntax
- commands/task.md - fixed --labels
- skills/park-idea.md - fixed --labels
- skills/review-parked.md - fixed --labels and label remove
- hooks/review-after-commit.md - fixed --labels

Fixes: claude-plugins-1uw by @jskswamy

### Other

- Simplify /release to unified marketplace versioning

Remove plugin-specific tagging in favor of single marketplace version
tags. Since Claude installs plugins via git SHA, individual plugin tags
add no value - one marketplace version equals one snapshot of all
plugins.

Changes:
- Remove plugin-name argument from /release command
- Always release entire marketplace with single v{version} tag
- Auto-sync plugin.json versions to marketplace.json during release
- Simplify documentation and examples throughout by @jskswamy
- Release v1.1.8

Bump marketplace version from 1.1.7 to 1.1.8.
Sync plugin versions: task-decomposer 1.3.1, git-commit 1.1.2. by @jskswamy
## [task-decomposer-v1.3.0] - 2026-01-31

### Changed

- Rename /plan to /decompose to avoid built-in command conflict

The /plan command conflicted with Claude Code's built-in /plan command
which enters plan mode. Renamed to /decompose which aligns with the
existing decompose skill and clearly describes the action.

Changes:
- Rename commands/plan.md to commands/decompose.md
- Update all command references in README.md and epic.md
- Bump version to 1.3.0 (breaking change) by @jskswamy
- Update CHANGELOG and README for task-decomposer-v1.3.0

Document the /plan to /decompose rename in changelog.
Regenerate plugins section in README from marketplace.json. by @jskswamy

### Other

- Release task-decomposer v1.3.0

Bump task-decomposer plugin version to 1.3.0 in marketplace.
Update marketplace metadata version to 1.1.7.

Breaking change: /plan command renamed to /decompose to avoid
conflict with Claude Code's built-in /plan command. by @jskswamy
## [task-decomposer-v1.2.0] - 2026-01-29

### Added

- Add missing plugin documentation to README

The main README was outdated, listing only 3 of 6 plugins. Users
browsing the marketplace couldn't discover sketch-note, typst-notes,
or task-decomposer.

Added documentation sections for:
- sketch-note: Visual sketch notes in Excalidraw format
- task-decomposer: Transform complex tasks into beads issues
- typst-notes: PDF/HTML notes with Typst templates

Each section follows the existing format with features, install
command, usage examples, and link to the plugin README.

Closes: claude-plugins-csj by @jskswamy
- Add README auto-generation using gomplate

The README plugins section was manually maintained and often fell out
of sync with actual plugin features. Now uses gomplate templates to
auto-generate content from marketplace.json and plugin READMEs.

Changes:
- Add gomplate to flake.nix dev packages
- Create templates/readme-plugins.md.tmpl for plugin section generation
- Add scripts/update-readme.sh to regenerate README between markers
- Add <!-- PLUGINS:START/END --> markers to README.md
- Update release command with Step 7.5 for README regeneration
- Document nix prerequisite in CONTRIBUTING.md

The template extracts features from plugin READMEs (bold bullets or
numbered headings) and falls back to marketplace tags. Usage examples
are extracted from the first code block in each plugin's Usage section. by @jskswamy
- Add beads viewer setup and agent instructions

Configure gitignore for .bv/ directory (beads viewer local config and
caches) and add comprehensive beads workflow documentation to AGENTS.md.

The AGENTS.md additions cover:
- Essential bd CLI commands for agents
- Workflow pattern (ready → claim → work → complete → sync)
- Key concepts (dependencies, priority, types, blocking)
- Session close protocol checklist
- Best practices for issue tracking by @jskswamy
- Add commands to task-decomposer plugin

Add 7 explicit commands to complement existing auto-invoked skills:
- /plan: Task decomposition with --dry-run, --quick, --epic flags
- /task: Single task operations (create, start, done, show, next)
- /park: Quick idea parking with metadata options
- /parked: Manage parked ideas (list, promote, discard, review)
- /backlog: Dashboard views (overview, ready, blocked, priorities, epics)
- /epic: Epic management (create, add, remove, progress, close)
- /deps: Dependency management (add, remove, show, graph)

Commands follow kubectl/unix conventions with noun-verb patterns and
provide explicit argument control for workflows that skills handle
automatically.

Bump version to 1.2.0. by @jskswamy

### Changed

- Update CHANGELOG and README for task-decomposer-v1.2.0

Document all changes included in the v1.2.0 release.
Regenerate plugins section in README from marketplace.json. by @jskswamy

### Other

- Release task-decomposer v1.2.0

Sync marketplace.json with plugin.json version 1.2.0 which added
7 commands to complement auto-invoked skills. Bump marketplace
metadata version to 1.1.6. by @jskswamy
## [task-decomposer-v1.1.0] - 2026-01-29

### Added

- Add task-decomposer plugin for beads workflow integration

New plugin that enhances beads-based project management with four
main capabilities:

- Task decomposition: Transform complex work into structured beads
  issues through Understanding → Designing → Creating phases with
  user gates between each phase

- Idea parking: Quick capture of side thoughts while working without
  breaking flow, using deferred status and parked-idea labels

- Parked idea review: On-demand or automatic (after task commits)
  review of parked ideas with promote/keep/discard options

- Task-aware commits: Generate rich commit messages combining beads
  context (what/why/acceptance) with actual code changes

Includes issue-writer agent for executing beads CLI commands in
correct dependency order. by @jskswamy
- Add auto-activation to git-commit plugin

The plugin previously required explicit /commit invocation. Now it
triggers automatically when users express intent to commit, such as
"commit these changes" or "let's commit".

Changes:
- Add intent-based commit skill that recognizes action phrases
- Add PreToolUse hooks to intercept direct git commit attempts
- Update commit-style skill to clarify it handles educational queries
- Document auto-activation, trigger phrases, and hook architecture

The hooks intercept both MCP git_commit tool and bash git commit
commands, redirecting to the /commit workflow for proper atomic
validation and style-consistent message generation.

Closes: claude-plugins-n1c, claude-plugins-l2t, claude-plugins-2g5 by @jskswamy
- Add understand skill to task-decomposer plugin

New skill for deep task exploration through structured questioning
before any planning begins. Unlike decompose which quickly moves to
issue creation, understand systematically probes seven dimensions:

- Goal clarity: What does "done" look like?
- Context & background: What triggered this?
- Scope boundaries: What's in/out?
- Constraints & requirements: Performance, security, tech limits?
- Dependencies & integration: What systems does this touch?
- Risks & unknowns: What could go wrong?
- Success criteria: How will we verify it works?

The skill uses a five-phase conversation flow (discovery, probing,
assumption surfacing, synthesis, transition) and adapts questioning
based on task type (technical, product, bug fix, refactoring).

Output is an understanding summary that can feed into the decompose
skill for issue creation. by @jskswamy

### Changed

- Update CHANGELOG for task-decomposer-v1.1.0

Document all changes included in the task-decomposer v1.1.0 release.
Generated using git-cliff with plugin-specific filtering. by @jskswamy

### Other

- Release task-decomposer v1.1.0

Bump task-decomposer plugin version from 1.0.0 to 1.1.0.
Update marketplace registry with new version and bump
marketplace metadata version to 1.1.5. by @jskswamy
## [1.0.2] - 2026-01-23

### Added

- Add typst-notes plugin for document generation

New plugin that converts conversation context, jot
notes, or files into professionally formatted PDFs
and HTML using Typst with 7 templates (executive
summary, cheat sheet, sketchnote, meeting minutes,
study guide, technical brief, portfolio) and 4
color themes.

Includes jot integration that resolves note paths
via workbench_path config, preference persistence
across sessions, and compile.sh with --root / for
correct absolute imports. Bundled Inter, Source
Serif, and JetBrains Mono fonts. by @jskswamy

### Changed

- Update CHANGELOG for v1.0.2

Document all changes included in the v1.0.2 release.
Generated using git-cliff with plugin-specific filtering. by @jskswamy

### Other

- Release typst-notes v1.0.2

Bump typst-notes plugin version from 1.0.0 to 1.0.2.
Update marketplace registry with new version and bump
marketplace metadata version to 1.1.4. by @jskswamy
## [1.3.1] - 2026-01-23

### Added

- Add attribution for Feynman Learning Framework source

Credit the original prompt that inspired the /teach command
implementation. Following the same pattern as git-commit plugin
which has a dedicated Sources section.

Attribution added to:
- README.md (inline blockquote + Sources section)
- commands/teach.md (inline blockquote)
- agents/learning-tutor.md (inline blockquote)

Also fixed redundant phrasing in README description. by @jskswamy
- Add 1mcp NixOS server discovery to devenv plugin

Prefer an already-running NixOS MCP server via 1mcp proxy over
starting the plugin's own bundled server. The bundled server is
kept as fallback for environments without 1mcp.

Changes to the package search priority order:
1. 1mcp (preferred, already running, no extra process)
2. Global/project mcp-nixos
3. Plugin's bundled mcp-nixos
4. Bash fallback (nix search)

Also adds version resolution support using nixhub_find_version
and nixhub_package_versions tools for handling versioned package
requests like nodejs@20. by @jskswamy

### Changed

- Update CHANGELOG for v1.3.1

Document all changes included in the v1.3.1 release.
Generated using git-cliff with plugin-specific filtering. by @jskswamy

### Other

- Release devenv v1.3.1

Bump devenv plugin version from 1.3.0 to 1.3.1.
Update marketplace registry with new version and bump
marketplace metadata version to 1.1.3. by @jskswamy
## [1.1.2] - 2026-01-17

### Added

- Add /teach command for Feynman-style learning to jot plugin

Implements the Richard Feynman Iterative Learning Framework:
- /teach command for papers, videos, articles, and concepts
- Phase 0 prerequisite check - confirms user has engaged with content
- 7-phase interactive loop: assessment, explanation, gaps, questions,
  refinement, application, and analogy creation
- Depth levels: shallow (1 iter), standard (2), deep (3)
- Teaching notes saved to notes/learned/ with wikilinks

Key components:
- commands/teach.md: Main command with argument parsing
- agents/content-extractor.md: PDF, YouTube, article extraction
- agents/learning-tutor.md: Interactive Feynman loop with prereq check
- templates/teach/teaching-note.md: Output template

Philosophy: There are no shortcuts to learning. The Feynman Technique
deepens understanding through explanation, not acquisition. by @jskswamy

### Changed

- Update CHANGELOG for v1.1.2

Document all changes included in the v1.1.2 release.
Generated using git-cliff.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com> by @jskswamy

### Other

- Release marketplace v1.1.2 with jot plugin version sync

Bump marketplace metadata version from 1.1.1 to 1.1.2.
Sync jot plugin version from 1.3.1 to 1.4.1 to match plugin.json.
Update jot description to include teaching notes feature.
Add new tags: learning, feynman, teach, teaching-notes.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com> by @jskswamy
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
or to create visual summaries of external resources. by @jskswamy

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
- update-changelog.sh: Notifies when changelog updates are needed by @jskswamy
- Move release command to .claude/commands directory

Local slash commands must be in .claude/commands/ to be discovered by
Claude Code. The previous .claude/plugins/ location is for installable
plugins, not local commands.

This fixes the /release command not appearing in the command list. by @jskswamy
- Update CHANGELOG for v1.1.1

Document all changes included in the v1.1.1 release.
Generated using git-cliff. by @jskswamy

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
- marketplace metadata: 1.1.0 → 1.1.1 by @jskswamy
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
[1.6.4]: https://github.com/jskswamy/claude-plugins/compare/v1.6.3..v1.6.4
[1.6.3]: https://github.com/jskswamy/claude-plugins/compare/v1.6.2..v1.6.3
[1.6.2]: https://github.com/jskswamy/claude-plugins/compare/v1.6.1..v1.6.2
[1.6.1]: https://github.com/jskswamy/claude-plugins/compare/v1.6.0..v1.6.1
[1.6.0]: https://github.com/jskswamy/claude-plugins/compare/v1.5.0..v1.6.0
[1.5.0]: https://github.com/jskswamy/claude-plugins/compare/v1.4.0..v1.5.0
[1.4.0]: https://github.com/jskswamy/claude-plugins/compare/v1.3.3..v1.4.0
[1.3.3]: https://github.com/jskswamy/claude-plugins/compare/v1.3.2..v1.3.3
[1.3.2]: https://github.com/jskswamy/claude-plugins/compare/v1.3.0..v1.3.2
[1.3.0]: https://github.com/jskswamy/claude-plugins/compare/v1.2.0..v1.3.0
[1.2.0]: https://github.com/jskswamy/claude-plugins/compare/v1.1.8..v1.2.0
[1.1.8]: https://github.com/jskswamy/claude-plugins/compare/task-decomposer-v1.3.0..v1.1.8
[task-decomposer-v1.3.0]: https://github.com/jskswamy/claude-plugins/compare/task-decomposer-v1.2.0..task-decomposer-v1.3.0
[task-decomposer-v1.2.0]: https://github.com/jskswamy/claude-plugins/compare/task-decomposer-v1.1.0..task-decomposer-v1.2.0
[task-decomposer-v1.1.0]: https://github.com/jskswamy/claude-plugins/compare/v1.0.2..task-decomposer-v1.1.0
[1.0.2]: https://github.com/jskswamy/claude-plugins/compare/v1.3.1..v1.0.2
[1.3.1]: https://github.com/jskswamy/claude-plugins/compare/v1.1.2..v1.3.1
[1.1.2]: https://github.com/jskswamy/claude-plugins/compare/v1.1.1..v1.1.2
[1.1.1]: https://github.com/jskswamy/claude-plugins/compare/v1.0.1..v1.1.1
[1.0.1]: https://github.com/jskswamy/claude-plugins/compare/v1.0.0..v1.0.1

