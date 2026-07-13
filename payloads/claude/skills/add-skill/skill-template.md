# Skill template

## Frontmatter

```yaml
---
name: <kebab-case-name>
description: |
  <One paragraph optimized for semantic matching. Lead with the key use case
  (truncated at 1,536 chars). Include concrete trigger phrases the user is
  likely to say.>
---
```

### Optional fields — when to set each

**Always set when applicable:**

| Field | When to use | Example |
|---|---|---|
| `model` + `effort` | **Always make a deliberate call.** Three buckets: | |
| | Planning, thinking, hard reasoning, security audits, architecture review | `model: claude-opus-4-8` + `effort: xhigh` |
| | Coding | (omit — inherits from session) |
| | Easy mechanical work (run-these-commands-in-this-order, simple file edits) | `model: claude-opus-4-6` + `effort: medium` |
| `paths` | Skill is specific to one language or framework | iOS skills: `paths: "*.swift"` |
| `context: fork` | Skill reads many files or produces long intermediate output you don't need to keep in main context (audits, browser sessions, deep searches) | `context: fork` |

**Set when intent requires it:**

| Field | When to use |
|---|---|
| `disable-model-invocation: true` | Skill is destructive or expensive (deploys, commits, money) and should never auto-fire — only explicit `/name`. |
| `user-invocable: false` | Skill is a passive coach that should auto-match but never appear in the `/` menu. Default is `true`, so omit unless overriding. |
| `argument-hint` + `arguments` | Skill takes positional args from the slash invocation (e.g. `/deploy staging`). Skip if you prompt via AskUserQuestion instead. |

**Available but skip for now (documented so they're known options):**

| Field | Status |
|---|---|
| `agent` | No custom subagents defined — skip. |
| `hooks` | Skill-scoped lifecycle hooks. Documented for future use; none currently in play. |

## Body structure

Omit any section that doesn't apply. Keep total body short — content stays in context across turns once loaded, so every line is a recurring token cost.

```markdown
# <name>

## When to invoke

<Concrete situations. Skip if description already covers it.>

## Process

1. <imperative step>
2. <imperative step>
...

## Notes

<Gotchas, edge cases, cross-links to related skills.>
```

## Authoring rules

- **State what to do, not how or why.** Imperative voice ("read X", "ask Y", "write Z").
- **No backstory or explanation.** Trust Claude to know general programming concepts.
- **Use absolute paths** when referencing other files (`~/.claude/...`, not `~/.claude/...` or relative).
- **Kebab-case slash names.** Short, memorable, unambiguous.
- **Per-file size targets:** every `.md` file in the skill dir (SKILL.md and each ref file) should stay under 250 lines. The rubric deducts 1 point per file over 250 and 2 points per file over 500 — so a skill with multiple oversized files can lose all axis-2 points fast. If a ref file is getting long, split it further.
- **When using reference files, explicitly state when to load each one.** Add a "Reference files" table near the top of SKILL.md mapping each file to the workflow step or condition that triggers it, plus the rule "do not read a reference file until the workflow says to." Also call out the file by name in bold within the relevant workflow step. Without this, Claude will either load all refs upfront (wasting context) or skip them when needed.
- **Renaming a gstack skill** → don't edit gstack files. Create a wrapper SKILL.md in a new top-level dir that says "read and follow ~/.skillshare/runtime/gstack/<original>/SKILL.md by absolute path." Then remove the original `~/.claude/skills/<old-name>/` symlink dir.
