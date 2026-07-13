---
name: security
description: |
  Composite security review. Runs gstack's CSO (Chief Security Officer) infrastructure-first audit AND VibeSec's bug-bounty vulnerability hunt, then synthesizes one report.

  USE THIS SKILL whenever any of the following come up — these are the merged triggers from /cso and VibeSec, which no longer activate individually:

  - "security audit", "security review", "security check", "security scan"
  - "check for vulnerabilities", "vulnerability scan", "vuln check", "any vulns"
  - "OWASP", "OWASP review", "OWASP Top 10"
  - "STRIDE", "threat model", "threat modeling", "pentest", "pentest review"
  - "CSO review", "CSO mode", "see-so", "see so" (voice aliases)
  - "is this safe to ship", "is this safe", "before I deploy", "ready to deploy"
  - "secure code", "secure web app", "secure my app", "security best practices"
  - "check for IDOR", "auth check", "auth review", "permission check"
  - "hardcoded secrets", "leaked keys", "API key exposed"
  - User working on any web application and asking for safety/review
  - About to share/deploy a project, especially to Render or anything friend-accessible
  - Just landed a feature touching auth, user data, payments, file upload, admin endpoints

  Covers infrastructure (secrets archaeology, dependency supply chain, CI/CD, LLM/AI security), OWASP Top 10, STRIDE threat modeling, AND concrete bug-bounty patterns (IDOR, hardcoded keys, missing authn/authz, weak admin endpoints, SQL injection, XSS, SSRF, exposed client-bundle secrets).
model: Codex-opus-4-8
effort: xhigh
context: fork
---

# security

Composite security review. Runs gstack's `/cso` methodology and VibeSec's coaching back-to-back, then synthesizes one report. **These two skills no longer activate individually — `/security` is the single entry point for all security work.**

## When to invoke

Match against any of the trigger phrases in the description above, OR proactively when:
- User is about to deploy, share, or ship something
- User asks any variant of "is this safe?"
- A diff touches authentication, authorization, user data, payments, file upload, admin paths, or anything that handles secrets
- User is building a web application and hasn't had a security pass yet

## Process

1. **Scope it.** Identify what to review:
   - Whole branch diff? A specific file or directory? The deployed surface area? The dependency tree?
   - If ambiguous, ask via AskUserQuestion (single question, 2–3 options).

2. **Phase 1 — CSO pass (infrastructure + threat model).**
   - Read and follow the instructions in `~/.skillshare/runtime/lib/cso/SKILL.md`
   - Treat its preamble, mode selection (daily/comprehensive), OWASP Top 10 + STRIDE methodology, and reporting format as the active instructions for this phase
   - Capture findings, severities, and recommended fixes

3. **Phase 2 — VibeSec pass (concrete vuln patterns).**
   - Read and follow the instructions in `~/.skillshare/runtime/lib/vibesec/SKILL.md`
   - This catches the bug-bounty patterns: IDOR, hardcoded secrets, missing authn/authz on sensitive endpoints, weak admin passwords, exposed API keys in client bundles, SQL injection, XSS, SSRF, etc.
   - Capture findings here too

4. **Synthesize one report.** Combined findings grouped by severity (Critical / High / Medium / Low / Info). For each:
   - Source (CSO threat model vs. VibeSec pattern match — or both)
   - Where (file:line)
   - Why it matters
   - Concrete fix

5. **Offer to fix.** Ask if the user wants Codex to apply fixes now, file them as TODOs, or just review.

## Notes

- Don't dedupe overlapping findings silently — surface once but cite both sources (higher confidence signal).
- If the project is local-only / never deployed, scale back: skip hostile-user threat modeling, focus VibeSec on dependency/import risks.
- For deployed-to-Render projects shared with friends, treat exposed admin paths and unauthenticated mutation endpoints as Critical.
- VibeSec lives at `~/.skillshare/runtime/lib/vibesec/` (moved out of `~/.codex/skills/` so it stops auto-firing as a separate skill). The `/cso` SKILL.md still lives at `~/.skillshare/runtime/gstack/cso/SKILL.md` but is no longer registered as a top-level skill.
