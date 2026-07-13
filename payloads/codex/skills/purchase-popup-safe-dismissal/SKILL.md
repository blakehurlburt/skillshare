---
name: purchase-popup-safe-dismissal
description: |
  Fix for Whiteout Survival purchase popups where the money guard should be a final
  veto on proposed taps, not a screen-level freeze. Use when `ScreenPurchase` blocks
  every tap even though the popup can be dismissed via a visible close X, Close/OK
  button, or a tap just outside the popup chrome. Keeps price, Buy, and Confirm taps
  refused while allowing safe dismissal actions chosen by the underlying behavior.
author: Codex
version: 1.1.0
date: 2026-07-12
---

# Purchase Popup Safe Dismissal

## Problem

The current real-money guard is too coarse. It correctly refuses the price/button area,
but it can also block harmless dismissal actions that are outside the popup or on the
popup's close chrome.

## Context / Trigger Conditions

Use this skill when:

- the runner classifies the screen as `ScreenPurchase`
- the logs show `real-money screen detected; resting this step (no taps)`
- the popup has a visible `X`, `Close`, `OK`, or similar dismissal control
- or the popup can be closed by tapping a neutral area outside the popup frame
- but the current code path denies every tap before the routine registry runs

## Solution

1. Move the money check to the tap selection boundary so it only vetoes a proposed
   tap, instead of short-circuiting the entire observation.
2. Keep `opsafe.TapAllowed` refusing price-bearing elements and other guarded labels.
3. Add a purchase-screen routine that can propose safe dismissal targets:
   - prefer an explicit close X / Close / OK target
   - only use an outside-popup tap if the popup bounds are known and the tap is
     provably outside the popup but still on-screen and away from other guarded regions
4. If no safe dismiss target is found, keep the current idle/hold behavior.
5. Add regression tests for:
   - purchase popup with close X
   - purchase popup with only Buy/price and no safe exit
   - neutral outside-popup dismissal, if that path is implemented

## Verification

The change is correct when:

- the buy button and price labels are still refused
- the runner can close a purchase popup via X or a safe outside tap
- ambiguous screens still fall back to idle rather than risking a spend tap

## Notes

- Do not let the safe-dismiss path include Confirm on spend/quit dialogs.
- If outside-popup dismissal is not geometrically reliable, omit it rather than guessing.
- The money guard stays in place as a last-mile safety check.
- If an outside point is represented as a synthetic OCR result for `TapAllowed`, give it a
  neutral `Text` value. Audit labels such as `"outside purchase popup"` contain the guarded
  `purchas` stem and will correctly veto the otherwise-safe geometry candidate.
- This should usually be implemented in the runner's purchase-screen decision path, not
  by weakening the general tap guard.
