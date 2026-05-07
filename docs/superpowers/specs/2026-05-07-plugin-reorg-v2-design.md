# Plugin reorganization for v2.0.0

**Marketplace:** `jskswamy-plugins`
**Date:** 2026-05-07
**Status:** Approved for implementation
**Type:** Breaking change (major version bump)

---

## Problem

Five of the eleven plugins in this marketplace have boundaries and names
that don't match how a developer actually uses them.

**Names misaligned with primary commands.** `clean-merge` is the
plugin name, but its primary command is `/review-commits`. Reading
`clean-merge` in a plugin list does not signal what the plugin does.
The plugin is named for an outcome (a clean merge to main) instead of
the action (reviewing commits).

**Boundaries split single workflows in half.** `task-decomposer` and
`task-executor` are separate plugins for the two halves of one
end-to-end pipeline (decompose work → execute it → commit it). The
split exposes the implementation seam to users; from a creator's
perspective there is one continuous flow.

**Names tied to today's backend.** `task-decomposer` and
`task-executor` describe their internal mechanism (decomposing into
beads issues, executing via subagents). If the task-store backend
changes (beads → Linear → local SQLite → anything else), the plugin
names go stale even when the user-visible capability is unchanged.

## Goal

Reorganize the marketplace into three capability-named plugins whose
boundaries match the developer's actual workflows. Drop the
implementation-flavored names. Ship as v2.0.0 with a clean break and
documented migration steps.

## Non-goals

- Changing any command names (`/commit`, `/review-commits`,
  `/decompose`, `/execute`, etc. all stay).
- Changing skill behavior or agent behavior — purely a packaging
  reorganization.
- Touching the other six plugins (`devenv`, `jot`, `sketch-note`,
  `typst-notes`, `guardrails`, `codebase`).
- Backward-compatibility aliases or deprecation windows. The break is
  clean.

## Design

### Three plugins after reorg

| New plugin | Absorbs | Commands |
|------------|---------|----------|
| **`commit-tools`** | `git-commit` + `clean-merge` | `/commit`, `/commit-style`, `/commit-action`, `/review-commits`, `/validate-commits` |
| **`craft`** | `task-decomposer` + `task-executor` | `/decompose`, `/epic`, `/park`, `/parked`, `/understand`, `/backlog`, `/task`, `/deps`, `/review-parked`, `/task-commit`, `/execute` |
| **`refactor`** | (unchanged) | `/scan` |

### Naming rationale

- **`commit-tools`** — names the surface (commit-related tools) the way
  the official Anthropic `commit-commands` plugin does. Direct,
  kebab-case, matches the marketplace convention. The plugin name
  prefixes every command in a way that reads naturally
  (`/commit-tools:review-commits`).
- **`craft`** — names the *act* (skilled making of software), not the
  bookkeeping artifacts (tasks, work items). Pairs with `commit-tools`
  thematically (both about doing the work well). Survives any future
  backend swap because nothing about "craft" implies beads.
- **`refactor`** — already capability-named; keep as-is.

### Command name preservation

Command names do not change. Day-to-day muscle memory is preserved.
Only the plugin namespace changes:

| Today | After v2.0.0 |
|-------|--------------|
| `git-commit:commit` | `commit-tools:commit` |
| `clean-merge:review-commits` | `commit-tools:review-commits` |
| `task-decomposer:decompose` | `craft:decompose` |
| `task-executor:execute` | `craft:execute` |
| `refactor:scan` | `refactor:scan` (unchanged) |

CLAUDE.md instructions that say `/commit` or `/review-commits` continue
to work — those use bare command names, not namespaced.

### Internal references

Skills inside the merged plugins reference each other by absolute path
in some places:

- `clean-merge/skills/review-commits/SKILL.md` reads
  `plugins/git-commit/styles/<style>.md` directly.
- The git-commit hook script lives at
  `plugins/git-commit/hooks/scripts/intercept-git-commit.sh`.

After the merge both files live under `plugins/commit-tools/`. Every
internal absolute path reference needs updating.

### Plugin versions

Both new plugins start at **`1.0.0`**. The consolidation is a fresh
release of a new plugin name; carrying forward the highest contributing
plugin's version would be misleading. The marketplace version bumps to
**`2.0.0`** because the marketplace's plugin list changes are breaking
for anyone with the old plugins installed.

## Migration (clean break, v2.0.0)

### What breaks

Existing users with any of the four removed plugins installed
(`git-commit`, `clean-merge`, `task-decomposer`, `task-executor`) will
see those `/plugin install` references stop resolving once the
marketplace is updated. Their currently-cached plugin files keep
working until they refresh.

### Migration steps for users

Documented in CHANGELOG.md and a `MIGRATION-v2.md` at the repo root.
The user runs:

```
/plugin uninstall git-commit@jskswamy-plugins
/plugin uninstall clean-merge@jskswamy-plugins
/plugin uninstall task-decomposer@jskswamy-plugins
/plugin uninstall task-executor@jskswamy-plugins

/plugin install commit-tools@jskswamy-plugins
/plugin install craft@jskswamy-plugins
```

Settings or hooks that reference the old plugin namespace
(`git-commit:`, `clean-merge:`, etc. in any settings.json or external
script) need a one-line update to the new namespace.

### What does NOT break

- Bare command names (`/commit`, `/review-commits`, `/decompose`, etc.)
  continue to work after reinstallation under the new plugin names.
- All command behavior is byte-identical — only the package they ship
  in changes.
- Other plugins (`devenv`, `jot`, `sketch-note`, `typst-notes`,
  `guardrails`, `codebase`, `refactor`) are unaffected.

## Files changed

| File / directory | Action |
|------------------|--------|
| `plugins/git-commit/` | Move contents into `plugins/commit-tools/` via `git mv`, preserve history |
| `plugins/clean-merge/` | Move contents into `plugins/commit-tools/` via `git mv`, preserve history |
| `plugins/commit-tools/.claude-plugin/plugin.json` | New, version `1.0.0`, combined keywords |
| `plugins/commit-tools/README.md` | New, combined documentation |
| `plugins/task-decomposer/` | Move contents into `plugins/craft/` via `git mv`, preserve history |
| `plugins/task-executor/` | Move contents into `plugins/craft/` via `git mv`, preserve history |
| `plugins/craft/.claude-plugin/plugin.json` | New, version `1.0.0`, combined keywords |
| `plugins/craft/README.md` | New, combined documentation |
| Internal absolute paths in moved skills | Update every `plugins/git-commit/...` → `plugins/commit-tools/...`; `plugins/clean-merge/...` → `plugins/commit-tools/...`; `plugins/task-decomposer/...` → `plugins/craft/...`; `plugins/task-executor/...` → `plugins/craft/...` |
| Hook scripts (`intercept-git-commit.sh`) | Move with their plugin, update any internal path references |
| `.claude-plugin/marketplace.json` | Remove four old entries; add two new entries; bump `metadata.version` to `2.0.0` |
| `CHANGELOG.md` | Generate v2.0.0 section, prepend a `### Migration` block with the unstall/install steps |
| `MIGRATION-v2.md` | New, root-level migration doc with examples |
| `README.md` | Regenerate plugins section from the new marketplace.json |
| `CLAUDE.md` | Verify references — bare command names should remain unchanged |

## Testing strategy

- **Existing test suites move with their plugins.** The clean-merge
  test suite at `plugins/clean-merge/skills/review-commits/tests/`
  becomes `plugins/commit-tools/skills/review-commits/tests/`. All 7
  tests must still pass after the move.
- **Path-reference smoke test.** After the move, `grep -r
  'plugins/git-commit\|plugins/clean-merge\|plugins/task-decomposer\|plugins/task-executor'`
  across the entire repo must return zero matches outside CHANGELOG /
  MIGRATION docs.
- **Plugin install dry-run.** `/plugin install commit-tools@…` and
  `/plugin install craft@…` must resolve via the local marketplace
  (manual test before tagging).
- **Hook integrity.** `__GIT_COMMIT_PLUGIN__=1 git commit -m "test"`
  via the relocated hook script must still bypass correctly.
- **No behavior tests change.** This is a packaging move; if any test
  assertion changes, that's a bug in the move.

## Risks

- **Path references missed.** A skill or script that references
  `plugins/git-commit/...` by absolute path and is not caught by the
  grep would break silently at runtime. Mitigation: the smoke-test
  grep above runs as part of CI / before tagging.
- **Git history fragmentation.** `git mv` preserves rename detection
  but `git blame` across the move requires `--follow`. Acceptable —
  this is one-time pain.
- **Hook script path.** The git-commit plugin's hook is referenced from
  `.claude/settings.json` (or wherever it's installed). After the
  move, any installation that hard-codes the old path needs the new
  path. Documented in the migration guide.
- **User confusion if they install both old and new during the cutover
  window.** The clean break in v2.0.0 makes this impossible — old
  entries are removed in the same release that adds new ones, so
  there is no overlap window.

## Out of scope

- Behavior changes to any moved command, skill, or agent.
- Reorganizing the other six plugins.
- Aliases / deprecation shims for backward compatibility.
- Renaming individual commands.
- Splitting `craft` further (e.g. separating planning commands from
  execution commands) — that's a future possibility but not part of
  this reorg.
