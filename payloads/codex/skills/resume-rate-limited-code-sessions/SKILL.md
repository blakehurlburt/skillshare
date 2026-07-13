---
name: resume-rate-limited-code-sessions
description: |
  Safely automate resumption of local Claude Code and OpenAI Codex CLI sessions after
  usage-limit resets. Use when scanning Claude/Codex JSONL transcripts, identifying a
  terminal 429 or `usage_limit_exceeded` event, invoking `--resume` with a follow-up
  prompt, avoiding duplicate agent turns, or verifying that a resumed session actually
  produced new assistant output. Covers original Claude project cwd selection,
  claim-before-spawn at-most-once dispatch, reset parsing, and transcript-based outcomes.
author: Codex
version: 1.3.0
date: 2026-07-11
---

# Resume Rate-Limited Code Sessions

## Problem

Claude Code and Codex CLI can stop an otherwise resumable session at a usage-limit
boundary. A background utility can resume it after reset, but naive implementations have
three dangerous failure modes:

1. A historical quota record is mistaken for the terminal state.
2. A crash between spawning the CLI and recording success causes duplicate prompts.
3. The appended user prompt is mistaken for successful agent progress.

Provider transcript formats are external, version-sensitive inputs. Fail closed on
unknown actionable records.

## Context / Trigger Conditions

Use this guidance when:

- Claude JSONL contains an assistant API error with `apiErrorStatus: 429`,
  `error: "rate_limit"`, and a message such as `resets 1:30am
  (America/New_York)`.
- Codex JSONL contains an `event_msg/error` with
  `codex_error_info: "usage_limit_exceeded"` plus a preceding `token_count` rate-limit
  snapshot whose exhausted window has `used_percent >= 100` and `resets_at`.
- A utility needs to run `claude -p --resume <session-id> continue` or
  `codex exec resume <session-id> continue --json` unattended.
- Retrying after a crash might create a second agent turn with duplicate side effects.
- A resumed command exits successfully but it is unclear whether the agent actually
  continued.

## Solution

### 1. Require terminal provider evidence

- Inspect only top-level resumable transcripts, not Claude subagent JSONL files.
- Treat a limit as resumable only if it is the latest meaningful turn outcome.
- For Claude, require all three structured fields: API error marker, status 429, and
  `error == "rate_limit"`. Parse the named IANA timezone and choose the next matching
  local reset time after the error timestamp.
- For Codex, require the exact `usage_limit_exceeded` error and the current turn's latest
  structured exhausted rate-limit window. A quota percentage alone is not terminal
  evidence.
- Re-read and revalidate the transcript immediately before dispatch. Later activity
  cancels the candidate.

Use stat-read-stat or an equivalent stable-read check because providers append JSONL
concurrently.

### 2. Resume from the correct directory

Claude session discovery is project-scoped. Preserve the first valid `cwd` persisted in
the top-level transcript—the original project directory used to create the session. A
later record may name a nested checkout entered during the session and can cause
`--resume` lookup to miss the session.

Codex should likewise use the session metadata cwd. Never add permission-bypass,
sandbox-bypass, or hook-trust flags that were not part of the utility's contract.

### 2a. Preserve Claude terminal visibility

`claude -p --resume <local-session-id> continue` appends to the same local transcript,
but it is a separate headless process. It does not route that turn through an already
running Remote Control bridge, so the existing terminal and `claude.ai/code/session_...`
view may never display it.

When terminal-visible continuation is required:

1. Read `~/.claude/sessions/<pid>.json` and require an exact `sessionId` match, a PID
   matching the filename, `kind == "interactive"`, and `entrypoint == "cli"`.
2. Confirm the recorded PID is still the expected interactive Claude process and resolve
   its controlling TTY.
3. Confirm that TTY belongs to a supported visible terminal. On macOS Terminal.app, walk
   the process ancestry to Terminal.app and target the tab whose `tty` property matches.
4. Inject the literal prompt into that existing tab. Pass the TTY as an argv value to a
   fixed AppleScript; never interpolate session data into script source.
5. Re-resolve the same process and TTY identity after the durable database claim and
   before input. A missing or changed terminal identity after claim is ambiguous and must not be retried
   automatically.

Do not infer prompt readiness from a live TTY alone. Read the current visible Terminal
viewport and combine it with the registry's `status` and `waitingFor` fields:

- Normal idle prompt: send literal `continue`.
- Known rate-limit chooser: require combined visible option labels such as `Upgrade your
  plan` plus `Wait for limit to reset`, select the wait option in that exact tab, then
  re-read and require the normal prompt before sending `continue`.
- Login/upgrade, permission, busy, or unknown screen: send no input and notify or cancel
  as appropriate.

After every UI transition, revalidate session ID, PID, TTY, and screen state. On
Terminal.app, dynamic AppleScript tab references need a double dereference
(`contents of contents of targetTab`) to return viewport text; a single dereference can
return `tab 1 of window id ...` and silently defeat classification.

`bridgeSessionId` is optional. Its presence means the same turn can synchronize to the
existing browser Remote Control view; it is not required to type into the existing local
Terminal session. If no exact live Terminal session exists before claim, do not use a
headless fallback when visibility is a contract requirement. Leave the event pending,
notify once per event, and retry discovery on later scheduled scans.

At discovery time, require an exact interactive CLI registry record before creating a
Claude event. One-off queued or print-mode transcripts can contain real 429s but have no
live Terminal and must not generate `claude_terminal_unavailable` alerts.

### 3. Use at-most-once claim-before-spawn dispatch

Provider CLIs do not accept an external idempotency key, so exactly-once execution is
unavailable.

1. Derive a deterministic event key from provider, session ID, terminal event timestamp,
   reset timestamp, and canonical evidence.
2. In one durable transaction, change `pending -> claimed` only if the row is still
   pending.
3. Commit before spawning. Only the claimant may spawn.
4. Spawn directly with an argv array and `shell=False`.
5. After `Popen` returns a PID, persist `claimed -> dispatched`.
6. Retry only failures proven to happen before process creation.
7. Treat stale `claimed` or `dispatched` rows as ambiguous and never auto-retry them.

This chooses a possible missed prompt in the crash-before-spawn gap over duplicate agent
side effects.

### 4. Verify real assistant progress

Do not use subprocess exit code or transcript growth alone.

- Snapshot the pre-dispatch transcript fingerprint and latest normal assistant-output
  index.
- After the provider exits, wait for the transcript to stabilize.
- Interactive Terminal turns can take minutes before producing assistant output. Use a
  longer progress window (for example 15 minutes) than UI transition checks.
- Success requires a newer normal assistant/agent message or explicit task-completion
  record.
- A new user `continue` record alone is ambiguous, not success.
- A new terminal rate-limit event is an expected `reratelimited` outcome and may create a
  distinct future event key.
- Unknown API/actionable errors are ambiguous and should notify; do not classify them as
  progress.

### 5. Keep scheduled execution quiet and durable

- Serialize each scan/run with a per-user file lock.
- Persist scan cursors and event state in SQLite.
- On first discovery, ignore old, already-expired events unless the user explicitly
  targets the exact parsed session ID.
- For later unseen transcripts, compare file modification time with the persisted prior
  scan time so old copied files are not revived.
- Notify only unexpected or ambiguous outcomes. Record notification suppression only
  after delivery succeeds.

## Verification

Test these invariants with fake transcripts and commands before a live run:

1. A rate-limit record followed by normal activity is not a candidate.
2. The same event cannot be claimed by two workers.
3. A spawn failure can return to pending; a post-spawn uncertainty cannot.
4. Appending only a user `continue` does not report success.
5. A new normal assistant event does report success.
6. A second invocation leaves transcript fingerprint and `attempt_count` unchanged.
7. Claude resumes from the transcript's original project cwd.
8. Claude sessions both with and without Remote Control target their existing TTY; no
   `claude -p` process is spawned.
9. A missing live Terminal session leaves the event pending, sends one durable reminder,
   and succeeds on a later scan if that exact interactive session becomes available.
10. One-off rate-limited transcripts without an interactive CLI registry record create no
    event or notification.
11. A known rate-limit chooser transitions to the prompt before `continue`; login and
    unknown dialogs receive no keystrokes.
12. Assistant output arriving more than 30 seconds after `continue` still verifies within
    the interactive progress window.

For live acceptance, capture the transcript fingerprint, dispatch once after reset plus a
small grace period, then verify one exact user prompt and a later normal assistant record.

## Example

```text
pending --atomic claim--> claimed --Popen(pid)--> dispatched
   |                                              |
   | pre-spawn failure                            +--> succeeded
   +--------------------> pending                 +--> reratelimited
                                                  +--> ambiguous (no retry)
```

## Notes

- Transcript schemas and benign lifecycle event names can change. Add newly observed
  lifecycle records only after confirming they invalidate an older candidate and never
  count as verified assistant success by themselves.
- Claude Remote Control bridge IDs map browser-visible sessions to local transcript UUIDs.
  A local transcript append proves local continuation, Terminal injection proves visible
  terminal continuation, and a live bridge additionally synchronizes it to browser/mobile.
- Remote Control is not required for terminal-visible continuation. An exact local session
  UUID, live interactive Claude PID, controlling TTY, and unique Terminal.app tab are
  sufficient. Remote Control only adds browser/mobile synchronization.
- Resuming a local UUID without `--fork-session` does not fork the local transcript. The
  surprising behavior is transport separation: a headless process and the live Remote
  Control process can write the same conversation while only the latter owns browser sync.
- Preserve normal permission behavior. Stopping at a permission prompt after meaningful
  work is a successful safe resume, not a reason to bypass approval.

## References

- [Anthropic Remote Control documentation](https://code.claude.com/docs/en/remote-control)
- [Anthropic session management documentation](https://code.claude.com/docs/en/sessions)
- [Anthropic Claude Code CLI reference](https://code.claude.com/docs/en/cli-usage)
- [OpenAI Codex source at the verified protocol commit](https://github.com/openai/codex/tree/5c19155cbd93bfa099016e7487259f61669823ff)
- [OpenAI Codex auto-resume feature request documenting structured reset evidence](https://github.com/openai/codex/issues/21073)
