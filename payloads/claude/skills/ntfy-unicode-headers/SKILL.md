---
name: ntfy-unicode-headers
description: |
  Fix for ntfy notifications silently failing when the Title (or any HTTP header)
  contains non-latin-1 characters like em dashes, smart quotes, or emoji. Use when:
  (1) requests/httpx raises UnicodeEncodeError: 'latin-1' codec can't encode character
  while POSTing to ntfy, (2) ntfy messages with plain titles deliver but "fancy" titles
  never arrive, (3) LLM-generated notification titles fail intermittently. Solution:
  encode non-latin-1 header values as RFC 2047 encoded-words (=?UTF-8?B?<base64>?=),
  which ntfy decodes natively. Message bodies are unaffected (sent as UTF-8 data).
author: Claude Code
version: 1.0.0
date: 2026-06-12
---

# ntfy Unicode Headers (RFC 2047)

## Problem
HTTP headers are latin-1. Putting an em dash (—), smart quote, or emoji into an
ntfy `Title`/`Tags`/`Actions` header makes `requests` raise
`UnicodeEncodeError: 'latin-1' codec can't encode character` before the request
is even sent. If the app catches send errors and retries/queues, the failure is
silent and looks like a delivery or auth problem — the misleading part: plain
titles work fine, so the token/topic gets blamed first.

LLM-generated titles make this near-certain to fire eventually: models love em
dashes.

## Context / Trigger Conditions
- `UnicodeEncodeError: 'latin-1' codec can't encode character '—'` (or
  similar) in `requests`/`urllib3`/`httpx` when POSTing to ntfy
- Some ntfy notifications arrive, others never do; the missing ones have
  punctuation-rich titles
- Notification titles come from an LLM or user input

## Solution
ntfy natively decodes RFC 2047 encoded-words in headers. Encode only when needed:

```python
import base64

def header_safe(value: str) -> str:
    """HTTP headers are latin-1; ntfy accepts RFC 2047 for anything beyond."""
    try:
        value.encode("latin-1")
        return value
    except UnicodeEncodeError:
        encoded = base64.b64encode(value.encode("utf-8")).decode("ascii")
        return f"=?UTF-8?B?{encoded}?="

headers["Title"] = header_safe(title)
```

The message body is unaffected — send it as UTF-8 bytes (`data=message.encode("utf-8")`),
no encoding tricks needed. Alternative: ntfy also accepts everything (title, tags,
actions) as a JSON body POSTed to the base URL with the topic inside the JSON,
which sidesteps header encoding entirely.

## Verification
Send a test with an em-dash title; it should arrive on the subscribed device with
the em dash rendered correctly (ntfy decodes the encoded-word server-side).
A plain-ASCII title must pass through unmodified.

## Notes
- Applies to ANY header you set: `Title`, `Tags`, `Click`, `Actions` labels.
- Don't strip/replace the characters (`.encode("ascii","replace")`) — RFC 2047
  preserves them and ntfy renders them properly.
- Same trap exists for any HTTP API that takes display text in headers.
- First observed in st(AI)nbrenner (2026-06-12): digest title with an em dash was
  retried 3x and queued; the assumed cause (missing NTFY_TOKEN) was wrong.

## References
- ntfy publish docs, "UTF-8 characters in headers": https://docs.ntfy.sh/publish/
- RFC 2047 (MIME encoded-words): https://datatracker.ietf.org/doc/html/rfc2047
