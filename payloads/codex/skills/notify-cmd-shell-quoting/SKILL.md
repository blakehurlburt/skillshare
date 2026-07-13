---
name: notify-cmd-shell-quoting
description: |
  Fix for escalation or wrapper commands that are launched through `sh -c` and fail when the
  configured command path contains spaces. Use when a `notify-cmd`, launchd ProgramArguments,
  or similar shell-out returns exit 127 with errors like `sh: /Volumes/My: No such file or
  directory`, or when a Claude/Sonnet triager never starts because the shell splits the path.
  Also covers the companion pattern where non-ntfy sinks should run first and ntfy should carry
  the human-facing summary plus an inspect breadcrumb for the agent session.
author: Codex
version: 1.2.0
date: 2026-07-10
---

# notify-cmd shell quoting

## Problem

A command sink is configured with an absolute path or command string that contains spaces.
The code launches it through `sh -c`, so the shell splits the path into multiple words.
The wrapper never runs, and the operator reports a misleading `exit status 127`.

## Context / Trigger Conditions

Use this skill when you see one of these:

- `sh: /Volumes/My: No such file or directory`
- `exit status 127` from a command sink
- a `notify-cmd` or `command` sink that works in tests but fails in the live config
- a launchd `ProgramArguments` entry is correct, but the downstream shell-out still breaks

This is most common when the configured command is a path under a mount point or folder name
with spaces.

## Solution

1. Treat the command boundary as untrusted shell input.
2. Prefer an argv-based exec path over `sh -c` when possible.
3. If you must use `sh -c`, quote the command string as a single shell token before passing it in.
4. Keep the wrapper path simple and stable. Put the shell logic in the wrapper script, not in the
   config string.
5. If ntfy is paired with an agent sink, run the agent sink first and render the ntfy body from
   the attempt results so the human sees whether the agent succeeded, failed, and how to inspect
   the session if it succeeded.
6. Distinguish three lifecycle states in wording and telemetry:
   - **launch acknowledged**: the wrapper returned zero after spawning the detached agent;
   - **agent completed**: the detached process reached its final turn and exited;
   - **work resolved**: the agent actually fixed, committed, or successfully handed off the issue.
   A zero exit from a detaching wrapper proves only the first state.
7. Give each state an inspect path that survives it. A tmux attach command works only while the
   session is running; retain a per-episode log for inspection after the session exits. If the
   agent sends its own final ntfy, treat that as a separate completion notification rather than
   conflating it with the operator's initial launch notification.

## Verification

- Re-run the command sink with a path containing spaces.
- Confirm the wrapper starts and produces its expected log output.
- Confirm there is no `sh: /Volumes/My: No such file or directory` line in the operator log.
- Confirm the initial notification says the agent was launched, not that its work succeeded.
- Confirm the final agent output is persisted to a log after its tmux session disappears.

## Example

Bad:

```sh
NOTIFY_CMD=/Volumes/My Shared Files/VM_shared_folder/.../scripts/notify_claude.sh
```

Good:

```sh
NOTIFY_CMD="/Volumes/My Shared Files/VM_shared_folder/.../scripts/notify_claude.sh"
```

Or better, avoid shell parsing entirely and execute the wrapper directly with argv.

## Notes

- A successful unit test for the command sink does not prove the live config is safe if the
  tested command string lacks spaces.
- `exit 127` is a shell symptom, not proof that the target binary is missing.
- If the wrapper itself spawns a detached agent, keep that detachment inside the wrapper so the
  operator can return promptly.
- When you add an inspect breadcrumb, prefer a stable session/log convention derived from the
  episode id so the ntfy text stays deterministic.
- A tmux session normally ceases to exist when its command finishes, so `tmux attach` is a live
  progress view, while the log is the durable post-completion record.
