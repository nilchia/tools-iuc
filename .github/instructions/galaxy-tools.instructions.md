---
applyTo: "tools/**,data_managers/**,tool_collections/**,suites/**,deprecated/**,macros/**"
---

# Galaxy Tool Wrapper Review Guidance

Load the `tool-dev` skill (`.agents/skills/tool-dev/SKILL.md`) for Galaxy tool
wrapper rules and Cheetah conventions. These instructions add `tools-iuc`
specifics and clarify what NOT to flag. Do not approve changes automatically
and do not suppress genuine findings — the goal is fewer false positives, not
fewer comments.

## `tools-iuc` specifics — always check

- Suite `.shed.yml` `remote_repository_url` must use `tree/main` (this
  repository's default branch is `main`, not `master`).
- Version bumps: when `@TOOL_VERSION@` changes, `@VERSION_SUFFIX@` must be
  reset to `0`, and version-token-only diffs should be checked against upstream
  release notes before being treated as mechanical.
- On version bumps, review the whole tool directory — shared macros affect
  sibling wrappers absent from the diff.

## Existing conventions — do NOT flag these as problems

- `detect_errors="exit_code"`: do not ask to switch to
  `detect_errors="aggressive"`. Relying on non-zero exit codes is standard in
  `tools-iuc`; `aggressive` is only a workaround for upstream tools that fail
  with a zero exit code.
- `<xml>` macros wrapping a complete `<command>` or `<configfile>` with Cheetah
  inside CDATA work and are used in this repository (e.g.
  `tools/pal2nal/macros.xml`, `tools/multiqc/macros.xml`,
  `tools/circos/macros_conffiles.xml`). The `<token>` convention in the skill
  applies only to bare Cheetah fragments.
- Older tools using RST help, bare `name=` without `argument=`, or older
  profile versions predate current guidance — only raise these for new tools
  or when the touched lines are affected. Suggest modernization at most as a
  non-blocking note.
- `.lint_skip` / `.tt_skip` entries are deliberate; don't suggest deleting
  them without addressing the underlying issue.
- Test data over 1 MB may predate the guideline; flag only for new test data.

## Review style for this repository

- Anchor findings to the IUC standards or the `tool-dev` skill; explain the
  why in one sentence.
- Don't demand fixes for style that `planemo format` / `planemo lint` would
  settle — suggest running them instead.
- Distinguish clearly between required changes and optional suggestions, as
  `docs/guide_for_reviewers.md` requires.
- If a change is tool XML, note whether `planemo lint` and `planemo test`
  results were provided; missing test coverage for a new code path is a
  legitimate finding.
