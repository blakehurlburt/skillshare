---
name: add-skill
description: |
  Deliberately create a new Claude Code skill from a workflow or recurring pattern, with overlap protection, quality grading, and user-preference enforcement. Differs from /claudeception (which auto-extracts debugging discoveries) — this is user-initiated. Use when the user says "add a skill", "make a new skill", "create a skill for X", "turn this into a slash command", "I want a skill that does Y", or "let's codify this".
model: claude-opus-4-8
effort: xhigh
---

# add-skill

## Always apply

- **Absolute paths** when referencing other files from a skill body.
- **Compose, don't duplicate.** If similar to an existing skill, prefer one composite that reads others by path.
- **Don't edit `~/.skillshare/runtime/gstack/*`** — treat as read-only. Customize via a wrapper in a new top-level dir.
- **CLAUDE.md roster is flat** — frontmatter is the source of truth for what a skill does.
- **Trigger-optimized descriptions** — write for semantic retrieval, not human readability. Include concrete trigger phrases.

User context (deploy targets, stack, process taste) lives in `~/.claude/CLAUDE.md`. Don't duplicate it here.

## Reference files (load on demand)

| File | When to read it |
|---|---|
| `~/.claude/skills/add-skill/interrogation.md` | Step 1, only if the user's request is genuinely underspecified and you need question-design help |
| `~/.claude/skills/add-skill/overlap-options.md` | Step 3, only if Step 2's overlap check found a conflicting skill |
| `~/.claude/skills/add-skill/skill-template.md` | Step 4, every time, before drafting the SKILL.md |
| `~/.claude/skills/add-skill/grading-rubric.md` | Step 6, every time, to grade the draft before saving |
| `~/.claude/skills/add-skill/claude-md-update.md` | Step 8, only if new user preferences emerged during the conversation |
| `~/.claude/skills/add-skill/model-upgrade.md` | Only when the user says a new Claude model was released and asks to update existing skills — not part of the normal creation workflow |

Do not read a reference file until the workflow says to. Loading them prematurely wastes context.

## Workflow

1. **Interrogate.** If the user's request is underspecified (fewer than 3 of: clear name, clear trigger phrases, clear input, clear output, clear failure mode), stop and ask via AskUserQuestion. Don't draft from a vague brief — vague skills end up generic and don't fire reliably. Specifically establish:
   - What does it do, in one sentence?
   - When should it fire? Concrete trigger phrases the user would actually say.
   - Manual-only (`/name`) or also auto-activate on matching prompts?
   - What's the input? What's the output?
   - Bucket: planning/thinking, coding (inherit), or mechanical?
   - Any failure modes the user knows about (e.g. "fail gracefully if X is missing")?

   Ask at most 3 questions in one AskUserQuestion call. Pick the ones with the highest leverage given what's already known.

1a. **Look for an existing implementation.** Before drafting, check if someone has already built this:
   - Ask the user: "Do you know of a public repo / blog post / video that describes this skill? If so, paste the link." If yes, clone from there instead of writing from scratch (precedent: `/claudeception` was cloned from `blader/Claudeception`, gstack itself).
   - Known good sources to consider: `anthropics/skills` (Anthropic's bundled examples), `garrytan/gstack` (the install we already have), `blader/Claudeception` (cross-session memory), search Anthropic's blog at https://www.anthropic.com/engineering for skill patterns.
   - If nothing exists, proceed with drafting from scratch — but cite this conclusion so the user knows you looked.

2. **Overlap check.** Run:
   ```bash
   for f in ~/.claude/skills/*/SKILL.md ~/.skillshare/runtime/gstack/*/SKILL.md ~/.skillshare/runtime/lib/*/SKILL.md; do
     [ -f "$f" ] || continue
     echo "=== $(basename $(dirname "$f")) ==="
     awk '/^---$/{c++;next} c==1{print}' "$f" | grep -E '^(name|description):' | head -3
   done
   ```
   Also grep for keyword overlap on the new skill's likely triggers.

3. **If overlap found** → **read `~/.claude/skills/add-skill/overlap-options.md`** and present options via AskUserQuestion. Do not silently pick. If no overlap, skip this step.

4. **Draft the SKILL.md.** **Read `~/.claude/skills/add-skill/skill-template.md`** for the frontmatter spec, optional fields, body structure, and authoring rules. Then draft.

5. **Self-review against the rubric.** **Read `~/.claude/skills/add-skill/grading-rubric.md`** and score the draft on each axis. For any axis scoring below the bar, propose a concrete tweak. Present the grade + proposed tweaks to the user. Apply tweaks the user approves.

6. **Save** the final version to `~/.claude/skills/<name>/SKILL.md`.

7. **Update CLAUDE.md roster** — append `/<name>` alphabetically to the "Skills installed" line in `~/.claude/CLAUDE.md`. No description.

8. **If new preferences emerged** during the conversation → **read `~/.claude/skills/add-skill/claude-md-update.md`** and update CLAUDE.md's relevant section. If no new preferences, skip this step.

9. **Tell the user to restart Claude Code.**

## Notes

- If creating an alias for a gstack skill, follow the `/brainstorm` / `/second-opinion` pattern: wrapper that delegates by absolute path, then remove the original `~/.claude/skills/<old-name>/` so the old slash command no longer resolves.
