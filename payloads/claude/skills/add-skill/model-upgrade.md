# Model upgrade procedure

Read this when a new Claude model is released and you want to update existing skills to use it.

## Why this exists

Claude Code's `model:` frontmatter field doesn't support aliasing — each skill hardcodes a literal model ID. When a new model drops, you'd otherwise have to remember every skill that references the old one.

## Current model buckets (kept in sync with `~/.claude/skills/add-skill/skill-template.md`)

| Bucket | Current model | Current effort |
|---|---|---|
| Planning / thinking / hard reasoning | `claude-opus-4-8` | `xhigh` |
| Coding | inherit (no `model:` field) | inherit |
| Mechanical rote work | `claude-opus-4-6` | `medium` |

When a new model is released, decide:
1. Does it become the new "planning" model? (Likely yes if it's the new top Opus.)
2. Does the previous planning model demote to "mechanical"?
3. Does the previous mechanical model retire entirely?

## Upgrade procedure

### Step 1: Audit current usage

```bash
# Find every skill using each model
for model in claude-opus-4-8 claude-opus-4-7 claude-opus-4-6; do
  echo "=== $model ==="
  grep -l "^model: $model" ~/.claude/skills/*/SKILL.md 2>/dev/null
done
```

### Step 2: Update the template + rubric first

Update the model bucket table in:
- `~/.claude/skills/add-skill/skill-template.md` (the optional-fields table under "Always set when applicable")
- `~/.claude/skills/add-skill/grading-rubric.md` (axis 4's bullet listing the bucket models)
- This file's bucket table above

This ensures `/add-skill` will use the new models for future skills.

### Step 3: Sed-replace in existing skills

For each bucket transition (old → new), replace the model line in every affected skill:

```bash
# Example: bumping planning bucket from 4-8 to 4-9
OLD_PLANNING="claude-opus-4-8"
NEW_PLANNING="claude-opus-4-9"
grep -l "^model: $OLD_PLANNING" ~/.claude/skills/*/SKILL.md | while read f; do
  sed -i.bak "s/^model: $OLD_PLANNING$/model: $NEW_PLANNING/" "$f"
  echo "updated $f"
done
# Remove backups after verifying
rm ~/.claude/skills/*/SKILL.md.bak
```

Do **not** sed-replace inside `~/.skillshare/runtime/gstack/` — the "don't edit gstack" rule applies here too. If a gstack skill needs a model override, create a wrapper alias instead.

### Step 4: Per-skill review

Not every skill should auto-bump. Walk the audit output and ask for each:
- Is this really a planning skill, or did I over-categorize it? Maybe it should demote to inherit (coding) or even drop to mechanical.
- Did the new model change cost or speed enough that I should re-think effort levels?

### Step 5: Test

Restart Claude Code and run one skill from each bucket on a trivial input. If anything errors with "unknown model," roll back the sed-replace for that bucket.

## Notes

- Effort levels (`low`, `medium`, `high`, `xhigh`, `max`) availability depends on model. A new model might add or remove levels — re-check the docs at https://code.claude.com/docs/en/model-config.
- If `inherit` is the right answer (skill should follow session model regardless of release cycle), drop the `model:` field entirely — that's the default behavior.
