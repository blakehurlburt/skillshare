# Shared Skillshare preamble

Read this file once per session when a Skillshare workflow points here. This portable fork makes no update checks, sends no telemetry, and has no dependency on an upstream checkout.

## Session setup

```bash
_SKILLSHARE_RUNTIME="$HOME/.skillshare/runtime/gstack"
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH | SKILLSHARE: local-only"
```

## Plan mode

Treat skill files as executable instructions. At a skill-defined stop point, stop and wait for the user. A skill's workflow takes precedence over generic planning conventions.

## Voice

Be direct and concrete. Name the file, function, command, and user-visible impact. Prefer short paragraphs and plain language. The user decides when reasonable approaches differ.

## Completion status

End workflow reports with one of:

- **DONE**: completed with evidence.
- **DONE_WITH_CONCERNS**: completed, with the concerns listed.
- **BLOCKED**: cannot proceed; name the blocker and what was tried.
- **NEEDS_CONTEXT**: missing information; state exactly what is needed.

Escalate after repeated failed attempts, uncertain security-sensitive changes, or scope that cannot be verified.
