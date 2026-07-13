---
name: claude-idle-prompt-rc-footer
description: |
  Diagnose Claude Code Terminal sessions that are actually ready for input but fail a naive
  prompt detector because the visible prompt is followed by the RC footer (for example, a
  "/rc active" line) or contains a trailing non-breaking space. Use when a live Terminal tab
  shows the prompt, yet automation classifies the viewport as unknown or not prompt-ready.
author: Codex
version: 1.0.0
date: 2026-07-11
---

# Claude Idle Prompt With RC Footer

## Problem

Claude Code can be sitting at an interactive prompt while the viewport does not end with the
prompt character. The footer line for Remote Control (`/rc active`) and spacing artifacts can
push the prompt above the final line, so a simple `endswith("❯")` check fails.

## Context / Trigger Conditions

Use this skill when:

- A live Terminal tab is `idle` and should be safe to type into.
- `read_terminal_contents` shows a visible `❯` prompt, but the last line is an RC footer.
- The screen includes text like `⏵⏵ bypass permissions on ... /rc active`.
- The automation keeps leaving the event pending even though the session is clearly ready.

## Solution

1. Normalize the viewport string before classification.
2. Treat `\u00a0` as a regular space.
3. Consider the session prompt-ready if either:
   - the normalized screen really ends with `❯`, or
   - the screen contains a prompt line plus the RC footer.
4. Keep the rule narrow enough to only apply when the terminal is already known to be `idle`
   and not waiting on a dialog.

## Verification

- A live prompt with `/rc active` now classifies as prompt-ready.
- The recovery command is dispatched to the correct TTY.
- The terminal screen immediately reflects the injected text.

## Example

A Claude session displayed:

```text
❯ 
────────────────
  ⏵⏵ bypass permissions on ... /rc active
```

The fix was to accept this as prompt-ready instead of requiring the prompt to be the final
character in the viewport.

## Notes

- Do not broaden the rule to any screen with `❯`; keep the `idle`/no-waiting guard.
- This is a display-shape issue, not a session-state issue.
