---
name: apply-patch-workspace-root-paths
description: |
  Prevent misplaced or lost edits when apply_patch and exec_command use different working
  directories. Use when a patch reports success but the file is absent from the expected repo,
  when moving a file into or out of a repository, or when an exec_command workdir was assumed to
  affect apply_patch path resolution. Covers patch-root verification and safe cross-root moves.
author: Codex
version: 1.0.0
date: 2026-07-12
---

# Apply Patch Workspace-Root Paths

## Problem

`exec_command` can run with a per-call `workdir`, but that does not change the base directory used
by a later `apply_patch` tool call. Relative patch paths are resolved from the session's main
workspace root. A patch can therefore succeed while creating a file in a sibling directory rather
than the repository being inspected.

Cross-root `*** Move to:` patches are especially risky. A source outside the patch root may be
removed without the destination appearing where expected. A successful tool result is not proof
that both sides of a move landed correctly.

## Trigger Conditions

- `apply_patch` reports success, but `git status` shows no change.
- The new file appears in a parent or sibling `docs/` directory.
- A patch uses `../` segments or an external absolute source.
- A task moves a queue/runtime file into repository documentation.
- Recent shell commands used `exec_command(workdir=...)` and the patch assumes that directory.

## Solution

1. Establish both roots before patching:

   ```sh
   pwd
   git rev-parse --show-toplevel
   ```

2. Treat the turn/session working directory—not the most recent `exec_command.workdir`—as the
   base for every relative path passed to `apply_patch`.

3. Prefer repository-relative paths that explicitly include the repo directory when the session
   root is its parent. For example, use `my-repo/docs/note.md`, not `docs/note.md`.

4. Do not combine an external-source deletion and repository destination into one cross-root
   `*** Move to:` patch. Create and verify the destination first. Remove the source only after the
   destination exists and its content is complete.

5. Verify immediately after every path-sensitive patch:

   ```sh
   test -f /expected/destination
   test ! -e /unexpected/sibling/destination
   git -C /repo status --short
   ```

6. If the file landed under the session root but outside the repo, use a same-root `*** Move to:`
   patch with an unchanged context line to relocate it, then verify again.

## Verification

- The expected destination exists.
- No unintended sibling copy remains.
- `git status --short` in the intended repository lists the file.
- For a move, check the source separately rather than inferring its state from patch success.
- Run `git diff --check` before committing.

## Example

Session root is `/workspace`, while shell inspection runs with `workdir=/workspace/app`.

Incorrect patch destination:

```text
*** Add File: docs/assessment.md
```

This creates `/workspace/docs/assessment.md`.

Correct destination:

```text
*** Add File: app/docs/assessment.md
```

This creates `/workspace/app/docs/assessment.md`, which will appear in the app repository's
`git status`.

## Notes

- This is a tool-orchestration behavior, not a Git behavior.
- Never rely on a successful empty-looking tool payload alone; filesystem and Git verification are
  the source of truth.
- For cross-root archival, preserve the source until the destination has been independently
  verified. This makes a path-resolution mistake recoverable.
