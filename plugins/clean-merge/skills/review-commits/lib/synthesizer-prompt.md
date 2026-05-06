# Synthesizer self-prompt

The main agent follows this checklist during the planning phase. There is no
separate synthesizer subagent in v2 — the same agent that runs the SKILL.md
flow runs these steps inline.

## Inputs

- `$base` — base SHA for the rebase
- `$WORKING_DIR` — directory to write `plan.yaml` to
- `$STYLE_FILE` — absolute path to `plugins/git-commit/styles/<style>.md`
- `$SEMANTIC_AVAILABLE` — `true` if codebase-memory-mcp is reachable AND
  the index is fresh; `false` otherwise

## Tools

- `git log`, `git show`, `git diff`, `git diff-tree` (read-only)
- Read: `$STYLE_FILE`, anything under `$WORKING_DIR`
- `bash plugins/clean-merge/skills/review-commits/lib/detect-clusters.sh "$base"`
- If `$SEMANTIC_AVAILABLE=true`: codebase-memory-mcp `search_graph`,
  `trace_path`, `get_architecture`

## Steps

1. **Read each commit in `$base..HEAD` oldest-to-newest.** For each, build a
   record in memory matching this shape:

   ```yaml
   hash: <abbrev>
   subject: <original>
   files: [...]
   top_level_dirs: [...]
   concern: <one-line>
   change_type: feat|fix|refactor|docs|test|chore|style|build
   suggested_action: pick|fixup|squash|drop|reword|edit
   fixup_candidate_for: <hash or null>
   unrelated: true|false
   ```

   Keep the records in memory; they don't need to be written to disk.

2. **Run hygiene Layers 1 and 2** as described in SKILL.md. Layer 1 detects
   introduce-then-fix subject pairs. Layer 2 flags non-atomic commits and
   test-with-impl pairs (commit B touches only test files for symbols
   introduced by commit A).

3. **Run hygiene Layer 3** if `$SEMANTIC_AVAILABLE=true`. Use
   codebase-memory-mcp to confirm or dismiss Layer 2's `non-atomic` flags
   via cluster membership and `trace_path`.

4. **Detect logical clusters.** Run:

   ```bash
   bash plugins/clean-merge/skills/review-commits/lib/detect-clusters.sh "$base"
   ```

   Each output line is a candidate cluster (space-separated short-hashes,
   oldest first). For each candidate:

   - Skip if any commit in the candidate is already flagged as a fixup
     target by Layer 1 (avoid double-counting).
   - If `$SEMANTIC_AVAILABLE=true`: collect the symbols defined or modified
     across all commits via `search_graph` per file, then check whether
     they all belong to the same architectural cluster. If yes, confirm
     with high confidence and use the cluster's module name as a hint when
     authoring the message. If the symbols span 2+ unrelated clusters,
     demote the candidate (do not propose a squash).
   - If `$SEMANTIC_AVAILABLE=false`: propose with medium confidence; the
     plan-review prompt should flag the lower confidence.

5. **Read `$STYLE_FILE` in full.** The "Subject Line Rules" and "Examples"
   sections are the contract. Author messages in this style for:
   - every action that is `reword` or `squash` (existing v1 behavior)
   - the first commit of each confirmed cluster (new v2 behavior)
   The first line must pass
   `bash lib/style-check.sh "<subject>" "$STYLE_FILE"`.

6. **Emit `plan.yaml` to `$WORKING_DIR/plan.yaml`** matching
   `lib/plan-schema.md`. Cluster collapse uses `pick` on the first commit
   (with `new_message`) and `fixup` on the rest, per `plan-schema.md`'s
   "Logical clustering" section.

7. **Reply with a one-line summary and action counts** before handing off
   to the plan-review user gate.
