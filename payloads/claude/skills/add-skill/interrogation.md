# Interrogation patterns for underspecified skill requests

Use when the user says "add a skill" without enough detail to produce a good skill. The default mode is to ask up-front rather than draft something generic.

## Heuristic: how specified is it?

Count how many of these the user gave you:

1. **Trigger phrases** — concrete words/intents that should fire the skill
2. **Process** — what steps the skill performs
3. **Inputs** — what the user provides
4. **Outputs** — what the skill produces
5. **Bucket** — planning/coding/mechanical
6. **Failure modes** — what to do when things go wrong

- **5+ given** → proceed with drafting, no questions needed
- **3-4 given** → ask 1 high-leverage question
- **0-2 given** → ask 2-3 questions before drafting

## High-leverage questions (pick top 2-3 for the user's situation)

**When triggers are vague:**
> "What would you actually type that should fire this skill? Give me 2-3 example sentences."

**When the process is fuzzy:**
> "Walk me through what the skill should do step by step. The example you're thinking of is fine."

**When the bucket is unclear:**
> "Is this more planning/thinking work (high effort, opus-4-8), normal coding (inherits session model), or mechanical (run-these-commands-in-order)?"

**When manual vs auto isn't stated:**
> "Should this auto-fire when the prompt matches, or only when I explicitly type /name?"

**When there might be a public source:**
> "Do you know of an existing repo, blog post, or video that already describes this? I'd rather fork from a known-good source than write blindly."

## Anti-patterns

- **Don't ask everything at once.** AskUserQuestion is for 1-3 questions max. If you need more, ask the first batch, get answers, then ask the next.
- **Don't ask questions you can answer yourself.** If the trigger is obvious from the user's framing, don't waste a question slot on it.
- **Don't draft "to show what I mean" before getting answers.** Drafting biases the user's answers toward what you wrote.
- **Don't accept "you decide".** If the user genuinely doesn't care, default to: planning/thinking bucket, auto-invocable, single SKILL.md file, no ref files yet. Tell them the defaults you picked.

## When to suggest cloning instead

If the skill the user describes sounds like:
- A debugging-memory loop → suggest `blader/Claudeception` (already installed as `/claudeception`)
- An engineering team workflow (CEO, eng manager, designer, QA, security) → suggest `garrytan/gstack` (already installed in fragments)
- Web scraping / structured browsing → suggest the Firecrawl plugin (already installed)
- A common pattern (testing, deployment, docs) → check `anthropics/skills` first

If a known source exists, clone the relevant repo's SKILL.md as the starting point rather than writing from scratch. The fork will still go through the rubric grading in Step 5.
