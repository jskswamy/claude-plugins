# review-commits: branch-as-cluster + path-heuristic sub-clusters

**Plugin:** `clean-merge` — `review-commits` skill
**Date:** 2026-05-07
**Status:** Approved for implementation
**Bug report:** `clean-merge-review-commits-misses-cross-dir-clusters.md`

---

## Problem

`detect-clusters.sh` missed a 4-commit logical cluster on the
`process-compose-script-extraction` branch because each commit touched a
different `dev/<service>/` subdirectory. The path-prefix heuristic
requires a contiguous run of commits to share the *same* parent
directory; commits across `dev/netbox/`, `dev/telegraf/`, `dev/grafana/`,
and `process-compose.yaml` cannot satisfy that. The user had to manually
ask for the squash.

There is also a latent correctness bug in `prefix_of`: at exactly depth-3
(`dev/netbox/env`) the heuristic returns the *filename* as the prefix
rather than the parent directory, so even tight clusters of files all
under one subdirectory at that depth fail to match each other.

## Goal

Use the user's branch decision as the primary clustering signal: when
they branched off `main` to do a feature, that branch is the cluster.
The path-prefix heuristic still runs as a refinement, surfacing
high-confidence sub-clusters when the branch happens to contain two
distinct feature-shaped runs.

## Non-goals

- No new schema fields. Cluster proposals continue to map to existing
  `pick` + `fixup` action primitives in `plan.yaml`.
- No "wiring commit" detection (Fix 3 from the bug report). The branch
  heuristic subsumes that case.
- No semantic confirmation via codebase-memory-mcp for the branch
  heuristic. Existing path-cluster confirmation in
  `synthesizer-prompt.md` Step 4 continues to apply only to path
  candidates.
- No automatic cluster acceptance. The plan-review user gate is the
  decision point — the skill always presents and asks.

## Design

### Two detectors, separate single-purpose helpers

**`lib/detect-clusters.sh`** (existing, fixed) — path-prefix heuristic.
Finds high-confidence sub-clusters: contiguous runs whose commits all
share the same parent directory. `MIN_CLUSTER_SIZE` stays at 4.

**`lib/detect-branch-cluster.sh`** (new) — branch-as-cluster heuristic.
On any non-main / non-master branch with ≥2 commits in `$base..HEAD`,
emits the entire range as a single medium-confidence candidate. On
`main`/`master` or detached HEAD, emits nothing. On a branch with <2
commits, emits nothing.

Each helper has one responsibility and is independently testable.

### Detector outputs

```
detect-clusters.sh "$base"
  → 0..N lines, each: "<short-hash> <short-hash> <short-hash> ..."
  → semantics: high-confidence path candidates, oldest first per line

detect-branch-cluster.sh "$base"
  → 0..1 lines:        "<short-hash> <short-hash> ..."
  → semantics: medium-confidence whole-branch candidate, oldest first
```

Output formats match (space-separated short-hashes, oldest first per
line) so downstream code can consume them uniformly.

### Fix 1: dirname-based prefix in `detect-clusters.sh`

Replace the broken `awk -F/ 'NF>=3 {print $1"/"$2"/"$3}'` with `dirname`.
The prefix becomes the parent directory of each file, at any depth ≥ 1.
A cluster fires when every changed file in every commit of the run
shares the same `dirname`. Files at the repo root yield prefix `.` and
do not anchor a cluster (existing exclusion semantics preserved).

This corrects the depth-3 case (where the previous code emitted the
filename) and removes the special-case minimum depth.

### Combination in the synthesizer

`synthesizer-prompt.md` Step 4 runs both helpers and combines results.
Plan-review (Step 5 of `SKILL.md`) renders one of these forms:

**Both detectors fire** — present two options:

```
Cluster proposals for branch <name>:

  Option A (recommended, branch heuristic, medium confidence):
    Collapse all 4 commits into one
      pick   f3696d7  Extract netbox process-compose commands to scripts
      fixup  bc7a342  ↳ folded
      fixup  fd11711  ↳ folded
      fixup  c0cc5e8  ↳ folded

  Option B (path heuristic, high confidence):
    [list each path sub-cluster]

○ Accept Option A — collapse the whole branch
○ Accept Option B — collapse only the sub-clusters
○ Keep all as pick — don't collapse
○ Modify per-commit
```

**Only branch detector fires** (no path sub-clusters): present the
branch option as the recommended choice, with "no path-prefix
sub-clusters found" noted.

**Only path detector fires** (running on main, or branch detector
disabled): present the path sub-clusters as today's behavior.

**Neither fires** AND the range has ≥2 commits: surface the reasoning
(Fix 4 from the bug report):

```
No cluster proposals.
  Branch heuristic: skipped (on main/master)
  Path heuristic: no contiguous run of 4+ commits shares a parent directory.
```

This tells the user *why* nothing was proposed without forcing them to
read source code.

### Overlap handling

When the path detector's range is identical to the branch detector's
range, present only Option A (the broader framing). Don't double-count
the same collapse as two options.

When the path detector finds 2+ disjoint sub-clusters that together
don't cover the whole branch, present both Option A (whole branch,
medium) and Option B (the disjoint sub-clusters, high). The user picks.

### `MIN_CLUSTER_SIZE` rationale

- **Path heuristic:** stays at 4. The path heuristic is meant to detect
  *granular noise* within a feature — a 2-commit path-prefix run is
  more often "test + impl" than a noise pattern, and the branch
  detector now covers small feature branches anyway.
- **Branch heuristic:** 2. The plan-review gate is the safety net. A
  branch with 2 commits (TDD: test commit + impl commit) is a
  legitimate collapse candidate. Raising the threshold would filter the
  most common case.

## Files changed

| File | Change |
|------|--------|
| `plugins/clean-merge/skills/review-commits/lib/detect-clusters.sh` | Replace `prefix_of` body with `dirname`-based logic. Drop the depth ≥ 3 minimum. |
| `plugins/clean-merge/skills/review-commits/lib/detect-branch-cluster.sh` | **New.** Reads `$base`, checks branch name, emits range when on non-main with ≥2 commits. |
| `plugins/clean-merge/skills/review-commits/lib/synthesizer-prompt.md` | Step 4 runs both detectors. Document the two confidence levels and the overlap/disjoint combination rules. |
| `plugins/clean-merge/skills/review-commits/SKILL.md` | Step 5 plan-review section gains the two-option Option A / Option B render plus the "no cluster + reasoning" path. |
| `plugins/clean-merge/skills/review-commits/tests/test-detect-clusters.sh` | Add depth-3 fixture proving Fix 1 (4 files all under `dev/netbox/` cluster correctly). Add cross-dir fixture proving the path heuristic stays correctly silent (the branch heuristic is what catches it). |
| `plugins/clean-merge/skills/review-commits/tests/test-detect-branch-cluster.sh` | **New.** Cases: branch with 4 commits → one line emitted; on `main` → silent; branch with 1 commit → silent; detached HEAD → silent. |

## Testing strategy

- **`test-detect-clusters.sh` extension:** A repo with 4 commits all
  touching files under `dev/netbox/` (different filenames at depth 3)
  must now emit a cluster line. A repo matching the bug report
  (4 commits across `dev/netbox/`, `dev/telegraf/`, `dev/grafana/`,
  root `process-compose.yaml`) must still emit nothing — that's the
  branch heuristic's job, not the path heuristic's.
- **`test-detect-branch-cluster.sh`:** Build a real repo via `mk_repo`,
  exercise the four cases above, assert exact stdout.
- **No new end-to-end test for the rendering** — the SKILL.md Step 5
  changes are markdown that the main agent follows at runtime, similar
  to how the previous `review-commits-preserve-bodies` work treated the
  preview-render prose. The detectors themselves carry the testable
  behavior.

## Risks

- **Aggressive over-clustering on long-lived "kitchen sink" branches.**
  A branch with 30 unrelated commits would trigger a single
  branch-cluster proposal. Mitigation: medium confidence label, the
  user is always in the loop via plan-review, and the existing
  "Modify" / "Keep all as pick" options take one click.
- **`MIN_CLUSTER_SIZE=2` for branch is too aggressive.** A branch with
  exactly 2 unrelated commits (rare but possible) gets proposed for
  collapse. Same mitigation: user-gate.
- **Detached HEAD ambiguity.** If the user runs `/review-commits` from
  detached HEAD (e.g. mid-rebase), the branch detector emits nothing
  and the existing path-only flow runs. Documented as expected.

## Out of scope

- Configurable thresholds via `.claude/clean-merge.local.md` — keep
  defaults; revisit if user reports tuning need.
- Confidence-weighted ordering across multiple path sub-clusters —
  current alphabetic-by-first-hash ordering is fine.
- Cross-detector confirmation via codebase-memory-mcp — the existing
  path-cluster confirmation flow stays as-is.
