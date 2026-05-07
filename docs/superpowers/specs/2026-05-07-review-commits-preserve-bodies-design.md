# review-commits: preserve commit message bodies

**Plugin:** `clean-merge` — `review-commits` skill
**Date:** 2026-05-07
**Status:** Approved for implementation
**Bug report:** `clean-merge-review-commits-drops-commit-body.md`

---

## Problem

When `review-commits` squashes commits via `fixup` or amends commit subjects
during a rebase, the body text of existing commit messages is silently
discarded. The resulting commits on `main` have subject-only messages even
when the original commits had rich body text explaining the why.

Four root causes (from the bug report):

1. The synthesizer reads commits via `git log --oneline`, which strips bodies.
2. Historical `git commit --amend -m "subject"` patterns replace the full
   message — the current `build-todo.sh` already uses `-F tmpfile`, so the
   *plumbing* is correct, but it is fed subject-only content because of #1.
3. `fixup` folds a commit's diff into the head commit and drops its message;
   no synthesis step folds those bodies into the surviving commit's body.
4. Plan review (Step 5) shows only subject lines, so the user cannot see
   what body text exists or what is about to be lost.

## Goal

The commit messages produced by `/review-commits` preserve the *why*
expressed in the original commit bodies — not by concatenating them
verbatim, but by having the synthesizer understand what each squashed
commit contributed and author one coherent body in the project's saved
commit style.

## Non-goals

- No changes to `plan-schema.md`. `new_message` and `fixup_target_message`
  are already multi-line `|` literal blocks; the bug is what the
  synthesizer writes into them, not the schema.
- No changes to `build-todo.sh` plumbing. It already writes message files
  and amends with `-F tmpfile`.
- No automated "did the LLM include a body" test. The plan-review preview
  is the human gate.
- No changes to the executor (`git rebase --exec` flow).

## Design

### 1. Synthesizer reads full bodies

Replace every `git log --oneline` in the planning phase with a
NUL-separated, record-terminated form that survives any printable subject
or body content:

```bash
git log --reverse --format='%H%x00%s%x00%b%x00---END---' "$base..HEAD"
```

Update `lib/synthesizer-prompt.md` Step 1 to add a `body:` field to the
in-memory per-commit record:

```yaml
hash: <abbrev>
subject: <original>
body: <original body, may be empty>
files: [...]
top_level_dirs: [...]
concern: <one-line>
change_type: feat|fix|refactor|docs|test|chore|style|build
suggested_action: pick|fixup|squash|drop|reword|edit
fixup_candidate_for: <hash or null>
unrelated: true|false
```

Layer 2's "test-with-impl" detection and Layer 3's symbol queries continue
to use `git diff-tree` / MCP calls — the body is for the *authoring* phase,
not the detection phase.

### 2. Synthesizer authors full messages

Update `lib/synthesizer-prompt.md` Step 5. Whenever the synthesizer emits
`new_message` or `fixup_target_message`, the value must be a complete
message (subject, blank line, body) written in the saved style, unless the
originals truly had nothing meaningful to say (subject-only TDD scaffolds —
in that case a subject-only message is correct).

The body is informed by:
- the original body of that commit, for `reword`
- the original bodies of every commit being folded, for cluster
  `pick` + `fixup`s and for any standalone `squash` / `fixup`

The synthesizer's job is to *understand* what each squashed commit
contributed and write one body explaining the collapsed change. It is not
a concatenator and not a paraphraser — it reads the originals as raw
material, then authors fresh prose in the saved style.

The first line continues to be validated by
`bash lib/style-check.sh "<subject>" "$STYLE_FILE"`. No body-level style
check is added.

### 3. Plan review shows body previews

Update SKILL.md Step 5's plan-review rendering. For any `pick` or `reword`
entry whose `new_message` has a body, show a short preview indented under
the subject:

```
pick   9e14e75  Add NetBoxClient interface, mock, and validation
                  Adds NetBoxClient as the testable boundary for all
                  NetBox HTTP calls. The mock is generated via…
fixup  3312c0b  ↳ folded into above
edit   a1b2c3d  Update auth handler  ← will split into 2
drop   f4e5d6c  Fix unrelated typo
```

Rules:
- Subject-only entries render as today (no extra lines).
- Preview is the first 2 wrapped lines of the body, max ~160 chars total,
  ellipsis if truncated.
- `fixup` / `drop` / `edit` entries do not get a body preview line — only
  `pick` and `reword` (the actions that carry `new_message`).

### 4. Drift safety net

`lib/revalidate.sh` already re-applies saved messages on subject drift.
Once Section 2 lands, the saved message files contain full subject + body,
so an auto-amend on drift naturally restores the body too. No revalidator
code change is expected; verification step only.

## Files changed

| File | Change |
|------|--------|
| `plugins/clean-merge/skills/review-commits/SKILL.md` | Update Step 4 (planning) command for reading commits; update Step 5 (plan review) rendering to include body previews |
| `plugins/clean-merge/skills/review-commits/lib/synthesizer-prompt.md` | Add `body:` to record shape (Step 1); rewrite Step 5 to require full subject + body in `new_message` / `fixup_target_message`, informed by original bodies |
| `plugins/clean-merge/skills/review-commits/lib/build-todo.sh` | No change expected (already uses `-F tmpfile`); confirm by reading |
| `plugins/clean-merge/skills/review-commits/lib/revalidate.sh` | No change expected; confirm by reading |
| `plugins/clean-merge/skills/review-commits/tests/test-build-todo.sh` | Extend with a fixture whose `new_message` contains a multi-line body; assert temp message file contains the full body |
| `plugins/clean-merge/skills/review-commits/tests/test-body-preservation.sh` | New end-to-end fixture: 3 commits with bodies → cluster collapse → assert resulting commit's `%B` contains the synthesizer-authored body |

## Testing strategy

- `test-build-todo.sh` extension proves the executor faithfully writes
  whatever body the plan provides into the temp file and into the final
  commit. This is the deterministic plumbing test.
- `test-body-preservation.sh` is an end-to-end test that constructs a real
  git repo, builds a hand-crafted `plan.yaml` containing a cluster with
  `new_message` body content, runs the rebase, and asserts the resulting
  commit's full message via `git log -1 --format=%B`.
- The synthesizer's *judgment* (does it produce a sensible body?) is not
  unit-tested. The plan-review preview is the human gate, and integration
  smoke is left to live runs against real branches.

## Risks

- **Body bloat.** If the synthesizer over-faithfully reproduces every TDD
  commit's body, the collapsed body becomes a changelog dump. Mitigation:
  the synthesizer-prompt explicitly says "understand and author fresh,"
  and the plan review preview lets the user see and reject.
- **Style drift in bodies.** No body-level style check exists. Mitigation:
  out of scope for this fix; the saved style file's "Examples" section is
  the de-facto guide and the user can reword via the existing flow.
- **Performance.** Reading full `%b` for every commit in a 30-commit branch
  adds modest token cost in the planning phase. Acceptable — planning is
  already the heavy phase.

## Out of scope

- Changing the saved style files to specify body conventions.
- Auto-amending bodies on drift (only subjects are revalidated).
- Multi-agent body synthesis (the v2 inline-main-agent path stays).
