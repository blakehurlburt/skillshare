# Skill grading rubric

Score the drafted SKILL.md on each axis. For anything below the bar, propose a concrete tweak before saving. Present the grade table + tweaks to the user for approval.

## Axes

| # | Axis | Bar | How to check |
|---|---|---|---|
| 1 | **Description retrieval quality** | Lead with the key use case. Contains 3+ concrete trigger phrases the user is likely to actually say. Under 1,536 chars combined with `when_to_use`. | Read description aloud — would it match the prompts the user wrote when they asked for this skill? Generic words like "helps with" or "manages" are smells. |
| 2 | **Body leanness** (worth up to **2 points**, not 1) | **Per-file, not aggregate.** Each file in the skill dir (SKILL.md + every ref file) is checked independently. Start at 2 points. For each file >250 lines, subtract 1 point. For each file >500 lines, subtract 2 points. Floor at 0. Also check: imperative voice, no narration, no "why this matters" prose. | List every `.md` file in the skill dir with its line count. Apply deductions. Then scan for past tense, justifications, or backstory — propose deletions even if line count passes. |
| 3 | **Progressive disclosure** | Any reference content over ~30 lines lives in a separate `.md` file in the skill dir, loaded on demand. **If ref files exist**, SKILL.md has an explicit "Reference files" table mapping each file to its trigger step/condition, plus a rule like "do not read a reference file until the workflow says to." Each workflow step that needs a ref file calls it out by name in bold. | If the SKILL.md has a long table, multi-section reference, or template that isn't needed every activation, split it out. If refs exist but their loading isn't explicitly directed, Claude will either grab them all upfront or skip them entirely. |
| 4 | **Frontmatter fit** | Per the rules in `~/.claude/skills/add-skill/skill-template.md`: `model` + `effort` always deliberately chosen (planning → opus-4-8/xhigh, coding → inherit, mechanical → opus-4-6/medium); `paths` set for language-specific skills; `context: fork` considered for context-heavy work; `disable-model-invocation: true` set for destructive actions; `user-invocable: false` set for passive coaches. | Walk the rules. Each applicable field either gets a deliberate value or is correctly omitted. Other frontmatter fields not covered by the template are not graded either way. |
| 5 | **Absolute paths** | Every file reference in the body uses an absolute path. No `./`, no `~/`, no relative. | Grep the body for `./` and bare `~/` — replace with full `/Users/...` paths. |
| 6 | **Anti-pattern scan** | No speculative context. No duplication of CLAUDE.md content. Not a mega-skill (split if it does 3+ unrelated things). No bundled scripts that hit the network without flagging it. | Read each section asking: "would Claude already know this?" If yes, cut. |
| 7 | **Composition over duplication** | If functionality overlaps an existing skill, this one reads the other by absolute path rather than reimplementing. | Check Step 2's overlap results. If overlap was found and resolution was "new variant" or "combine," verify the body actually delegates. |
| 8 | **Trigger disambiguation** | If a sibling skill could plausibly fire on the same prompt, both descriptions are tight enough that the semantic matcher will route to the right one. | List 3 prompts that should fire this skill and 3 prompts that should fire a sibling. Check that each prompt unambiguously matches one description more strongly than the other. |
| 9 | **Failure-mode handling** | The body says what to do when something is ambiguous, missing, or fails — not just the happy path. | Look for "if ambiguous, ask", "if not found, ...", error-case branches. |

## Output format

Present to the user as a compact grade table. Axis 2 is the only multi-point axis; show its tier explicitly.

```
Axis                          Score   Notes / proposed tweak
1 Description retrieval       ✓
2 Body leanness               2/2     SKILL.md 80 | overlap.md 60 | template.md 120 — all under 250
3 Progressive disclosure      ✓
4 Frontmatter fit             ✗       Missing model+effort decision
...
TOTAL                         8/10
```

Then ask which tweaks to apply.

## Calibration

Max score: 10 (axes 1, 3–9 worth 1 each; axis 2 worth up to 2). A skill that scores 8+ is shippable. 5–7 is iterate-once. Under 5 — reconsider whether the skill is well-scoped or should be split / merged / cancelled.
