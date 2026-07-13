---
name: virtiofs-mutable-state-safety
description: |
  Diagnose and prevent corruption of append-heavy runtime state on UTM/VirtioFS or similar
  host/guest shared folders. Use when JSONL/log files gain NUL bytes, grep treats a text log as
  binary or returns no matches, fsync/atomic status writes fail with ENOTTY, or screenshot corpora
  grow without bound under paths such as VM_shared_folder or My Shared Files. Covers VM-local
  storage defaults, absolute-path guards for relative paths, bounded frame retention, and incident
  evidence promotion.
author: Codex
version: 1.0.0
date: 2026-07-12
---

# VirtioFS Mutable State Safety

## Problem

Some host/guest shared mounts are suitable for source code but unreliable for mutable runtime
state. Append-mode writes can inject NUL bytes, fsync-based publication can fail, and high-rate
frame capture can consume the shared disk indefinitely. The resulting audit trail may look empty
because text tools classify the corrupted file as binary.

## Context / Trigger Conditions

Use this skill when one or more of these occur:

- JSONL or log files contain unexpected `\x00` bytes.
- `grep` reports a text file as binary or silently yields no useful matches.
- Atomic status publication or `fsync` fails with `ENOTTY` on a shared checkout.
- A long-running screenshot corpus grows without retention under a shared mount.
- A path guard recognizes absolute shared paths but a relative output path still writes beneath
  the shared current working directory.

## Solution

1. Keep source code on the shared mount, but default all mutable runtime state to a guest-local
   directory under the user's home directory, such as `~/app-state` or `~/app-corpus`.
2. Reject explicit shared-mount destinations at the state-opening boundary, before creating or
   opening append files.
3. Check both the supplied path and `filepath.Abs(path)`. A lexical check of `out/run` cannot see
   that the process current directory is itself under `VM_shared_folder`.
4. Keep the shared-mount detector centralized so journals, status files, and corpora apply the
   same rule.
5. Bound high-rate frame capture with a live ring. Before eviction, copy frames referenced by an
   incident/stuck bundle into a non-evicting evidence directory and write those promoted paths into
   the bundle.
6. Prune old run directories by age, but only delete names that match the application's exact
   timestamp/run-ID format. Leave unrelated directories untouched.
7. Keep process logs guest-local too. Moving the corpus alone does not protect a `tee -a` target
   that still lives on the shared mount.

## Verification

- Test absolute shared paths and relative paths resolved from a shared working directory.
- Test that the state constructor rejects those paths before opening its append file.
- Write more frames than the ring limit and assert only the newest frames remain.
- Create an incident bundle and assert its promoted frames remain outside the live ring.
- Create old, recent, and non-run directories; assert pruning removes only the old timestamped run.
- Run the service using its normal launcher and confirm the published state/corpus path is guest-local.

## Example

```go
func LooksLikeSharedFolder(path string) bool {
	looksShared := func(candidate string) bool {
		p := strings.ToLower(candidate)
		return strings.Contains(p, "vm_shared_folder") ||
			strings.Contains(p, "my shared files")
	}
	if looksShared(path) {
		return true
	}
	abs, err := filepath.Abs(path)
	return err == nil && looksShared(abs)
}
```

Use the check at the constructor that opens `steps.jsonl` or another durable stream, not only in
CLI flag parsing. That protects callers and tests that bypass the command entrypoint.

## Notes

- Do not delete an existing large shared corpus as part of a code fix unless the user explicitly
  authorizes data removal. Stop future growth first and report the existing data separately.
- A mutex protects threads in one process; it does not solve cross-process append interleaving or
  faulty mount semantics.
- Keep retention and evidence preservation separate: the ring controls routine volume, while
  promotion makes incident artifacts durable.
