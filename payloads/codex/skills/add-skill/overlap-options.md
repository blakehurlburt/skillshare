# Overlap resolution options

When the overlap check finds an existing skill with similar triggers or domain, ask the user which option to take via AskUserQuestion. Do not silently pick.

| Option | When to pick | What to do |
|---|---|---|
| **Combine** | New skill is a superset, or both naturally chain | Create one composite that calls into both by absolute path. Move the subsumed skill(s) to `~/.skillshare/runtime/lib/<name>/` so they stop auto-firing. Precedent: `/security` ← `/cso` + VibeSec. |
| **Replace** | New skill obsoletes the old one entirely | Move old to `~/.skillshare/runtime/lib/_archived/<name>/`. |
| **Clarify triggers** | Both are legitimately distinct but descriptions overlap | Tighten the `description:` fields of both so the semantic matcher routes correctly. Don't write the new skill until this is done. |
| **New variant** | Same domain, different trigger conditions | Write the new skill, add `See also: /<other-skill>` cross-links in both bodies' Notes sections. |
| **Cancel** | Existing skill already covers it | Don't write. Maybe edit the existing skill's description to make it more discoverable. |

## How to disable a skill without deletion

Move the skill dir from `~/.claude/skills/<name>/` to `~/.skillshare/runtime/lib/<name>/`. The SKILL.md is still readable by other skills via absolute path but is no longer indexed by Claude Code, so it stops auto-firing and disappears from the slash menu.
