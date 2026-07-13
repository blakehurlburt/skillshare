# Updating CLAUDE.md with new preferences

If during skill creation the user reveals a preference that applies beyond this one skill (e.g. "always do X this way", "I never want Y", "prefer Z over W", a new project context, a new routing rule), update `~/.claude/CLAUDE.md`.

## Where things go

| Section | Put this here |
|---|---|
| **About me** | Facts about the user, projects, stack, deploy targets, process taste |
| **Workflow conventions** | Routing rules, complex-task flow, tool preferences, debugging/security shortcuts |
| **gstack state** | Non-obvious facts about the install (renames, detachment, composition) |
| **Skills installed** | Flat roster only — append `/<name>` alphabetically, no description |

## Rules

- **Don't duplicate frontmatter content** from any SKILL.md. If you find yourself describing what a skill does, stop — that lives in the skill itself.
- **Keep it terse.** CLAUDE.md loads into every session; every token is a recurring cost.
- **Prefer editing an existing section** over adding a new one.
- **If the preference is really one-off** about this specific skill, put it in the skill body's Notes section instead.
- **Confirm with the user before saving** if the edit is non-trivial (more than a one-line addition).
