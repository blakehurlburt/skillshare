---
name: sleep-tolerant-launchd-scanner
description: |
  Diagnose missed or delayed background retries in a macOS launchd scanner after laptop sleep,
  brief power loss, or reboot. Use when a due event is not being retried for far longer than the
  logical reset window because the LaunchAgent scans too infrequently, the installed plist still
  has an old StartInterval, or the on-disk config and loaded plist are out of sync.
author: Codex
version: 1.0.0
date: 2026-07-11
---

# Sleep-Tolerant Launchd Scanner

## Problem

A launchd-backed retry loop can look healthy while still missing timely recoveries after the
laptop sleeps, loses power, or restarts. The code that decides whether an event is due may be
correct, but the agent only runs on its schedule. If that schedule is too coarse, the next retry
can be delayed by almost the full interval.

## Context / Trigger Conditions

Use this skill when:

- A macOS `LaunchAgent` is responsible for periodic scanning or retrying.
- The user reports "it should have retried by now" after sleep, shutdown, or a brief power loss.
- The installed plist still contains an old `StartInterval`.
- The on-disk config changed, but the loaded LaunchAgent was not reinstalled.
- The retry decision is gated by app state, so reducing the scan interval is safe.

## Solution

1. Verify the installed plist `StartInterval` and the app config value that feeds it.
2. If the daemon is supposed to recover quickly from downtime, shorten the scan heartbeat.
3. Keep the internal due check unchanged so a shorter heartbeat only improves latency, not
   correctness.
4. Update the persisted config file if it is the source of truth for reinstall.
5. Reinstall or reload the LaunchAgent so the live plist matches the new interval.
6. Confirm the plist now reflects the expected interval and `RunAtLoad` is still enabled.

## Verification

- The plist `StartInterval` matches the intended retry cadence.
- The config file and rendered plist agree.
- A manual `install` or reload rewrites the live agent.
- Focused tests covering plist rendering pass.

## Example

A project used a 3600-second scan interval and missed Claude retry opportunities after brief
laptop downtime. The fix was to change the default to 300 seconds, update the existing config
file, and reinstall the LaunchAgent so future wake-ups catch due work within minutes instead of
waiting nearly an hour.

## Notes

- Do not confuse "event is not due yet" with "agent has not scanned recently enough."
- A shorter scan interval is usually the correct fix when the scan itself is lightweight and the
  actual dispatch logic still enforces reset time.
- If the loaded plist is stale, changing only the source code is not enough.
