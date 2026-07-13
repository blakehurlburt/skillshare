---
name: runner-real-money-stall-handoff
description: |
  Diagnose the whiteout-survival runner when it stops advancing and repeatedly logs
  "real-money screen detected; resting this step (no taps)" followed by
  "runner stuck" and "operator-handoff: holding idle for operator". Use when the
  process is alive, OCR is still polling, but the runner is intentionally idling on a
  blocked in-game screen instead of making taps.
author: Codex
version: 1.0.0
date: 2026-07-12
---

# Runner Real-Money Stall Handoff

## Problem

The runner is not crashed. It is still alive, still calling OCR, but it has entered a
guarded idle state because it believes the current screen is a real-money / purchase
surface that should not be tapped through automatically.

## Context / Trigger Conditions

Use this skill when the runner log contains a sequence like:

- `real-money screen detected; resting this step (no taps)`
- repeated OCR polls with no forward action
- `runner stuck`
- `operator-handoff: holding idle for operator (no taps until the screen clears)`

Typical symptoms:

- `ps` shows `./runner` still running
- `tmux` session is alive
- log timestamps continue to advance
- the device screen does not change

## Solution

1. Treat this as an intentional pause, not a crash.
2. Check the latest log tail and confirm the handoff bundle path.
3. Inspect the current screen if you need to decide whether it can be cleared safely.
4. If the screen is a real-money / purchase prompt, leave the runner idle and handle
   it manually instead of forcing taps.
5. If the detector is wrong, clear the blocking UI or adjust the detector logic in the
   runner before restarting.

## Verification

The runner is in this state when all of the following are true:

- the process is still alive
- OCR requests continue
- no new mission/navigation actions are emitted
- the log explicitly says `operator-handoff: holding idle for operator`

## Example

```text
time=... level=WARN msg="real-money screen detected; resting this step (no taps)" step=18
time=... level=WARN msg="runner stuck" reason=frozen bundle=.../stuck.json steps=19
time=... level=WARN msg="operator-handoff: holding idle for operator (no taps until the screen clears)" step=18
```

## Notes

- Do not assume a hang just because progress stops. The runner may be waiting on a
  human decision by design.
- If this happens repeatedly on a screen that is not actually a purchase surface, the
  detector or OCR classification is likely too aggressive.
- The `stuck.json` bundle is the useful artifact for later diagnosis or replay.
