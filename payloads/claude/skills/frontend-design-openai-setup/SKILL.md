---
name: frontend-design-openai-setup
description: |
  Set up OpenAI integration for frontend-design skill. Use when: (1) frontend-design
  skill fails silently, (2) API returns "insufficient_quota" error, (3) getting 401
  authentication errors, (4) OPENAI_API_KEY not found warnings. Covers environment
  configuration, billing verification, and debugging API connection issues.
author: Claude Code
version: 1.0.0
date: 2026-06-01
---

# Frontend Design Skill: OpenAI Integration Setup

## Overview

The **frontend-design** skill uses OpenAI's API to generate creative design concepts
and guidance. This skill is required for the design tool to generate AI-powered design
recommendations.

## Prerequisites

### 1. OpenAI API Key

**Get a key:**
1. Visit https://platform.openai.com/account/api-keys
2. Click "Create new secret key"
3. Copy the key (you'll only see it once)

**Configure in Claude Code:**

Add to `~/.claude/settings.json`:
```json
{
  "env": {
    "OPENAI_API_KEY": "sk-proj-your-actual-key-here"
  }
}
```

**Verify:**
```bash
echo $OPENAI_API_KEY  # Should show your key (truncated ok)
```

### 2. Active Billing

**The API key alone isn't enough—you must have active credits:**

1. Visit https://platform.openai.com/account/billing/overview
2. Check "Credits & usage"
3. If no credits available:
   - **Add payment method** (preferred)
   - Or **use free trial credits** (if still available for your account)

**Check billing status:**
```bash
# This will fail with "insufficient_quota" if billing isn't active
python3 -c "
import os
from openai import OpenAI
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
response = client.chat.completions.create(
    model='gpt-3.5-turbo',
    messages=[{'role': 'user', 'content': 'test'}],
    max_tokens=5
)
print('✓ Billing active')
"
```

## Common Issues & Solutions

### Issue: "insufficient_quota" Error (429)

**Error message:**
```
Error code: 429 - {'error': {'message': 'You exceeded your current quota,
please check your plan and billing details.', 'type': 'insufficient_quota'}}
```

**Root cause:** Account has no active credits or billing disabled

**Solution:**
1. Add payment method at https://platform.openai.com/account/billing/overview
2. Wait ~5-10 minutes for activation
3. Try again

### Issue: "OPENAI_API_KEY not found"

**Error message:**
```
openai.error.AuthenticationError: No API key provided
```

**Root cause:** Environment variable not set or Claude Code needs restart

**Solution:**
1. Verify key is in `~/.claude/settings.json`:
   ```bash
   grep OPENAI_API_KEY ~/.claude/settings.json
   ```
2. Restart Claude Code (close and reopen)
3. Try again

### Issue: 401 Unauthorized

**Error message:**
```
Error code: 401 - {'error': {'message': 'Incorrect API key provided', 'type': 'invalid_request_error'}}
```

**Root cause:** Invalid or expired API key

**Solution:**
1. Generate a new key at https://platform.openai.com/account/api-keys
2. Delete the old key (if you want to)
3. Update `~/.claude/settings.json` with new key
4. Restart Claude Code

## Setup Verification

Run this test to verify everything is configured correctly:

```bash
python3 << 'EOF'
import os
import sys

print("🧪 OpenAI Integration Verification")
print("=" * 60)

# Check environment variable
api_key = os.getenv('OPENAI_API_KEY')
if not api_key:
    print("❌ OPENAI_API_KEY not found in environment")
    print("   → Add to ~/.claude/settings.json under 'env'")
    sys.exit(1)
print(f"✓ OPENAI_API_KEY configured ({len(api_key)} chars)")

# Check package
try:
    from openai import OpenAI
    print("✓ OpenAI package installed")
except ImportError:
    print("❌ OpenAI package not installed")
    print("   → Run: pip3 install openai")
    sys.exit(1)

# Test API connection
try:
    client = OpenAI(api_key=api_key)
    response = client.chat.completions.create(
        model='gpt-3.5-turbo',
        messages=[{'role': 'user', 'content': 'Say OK'}],
        max_tokens=5
    )
    print("✓ API connection successful")
    print(f"✓ Model: {response.model}")
    print(f"✓ Tokens used: {response.usage.total_tokens}")
    print("\n✅ All systems operational!")
except Exception as e:
    error_str = str(e)
    if 'insufficient_quota' in error_str:
        print("❌ Insufficient quota (billing issue)")
        print("   → Add payment method at:")
        print("   → https://platform.openai.com/account/billing/overview")
    elif '401' in error_str:
        print("❌ Authentication failed (invalid key)")
        print("   → Generate new key at:")
        print("   → https://platform.openai.com/account/api-keys")
    else:
        print(f"❌ Error: {error_str}")
    sys.exit(1)
EOF
```

## Using the Frontend Design Skill

Once setup is complete, the frontend-design skill will be available:

```bash
# In Claude Code, invoke the skill
/frontend-design-frontend-design

# Describe what you want designed:
# "Create a logo for Miss Maddie, a music teacher for babies..."
```

The skill will use OpenAI to generate creative design concepts and recommendations.

## Cost & Usage

**Pricing:**
- `gpt-3.5-turbo`: ~$0.001 per 1K input tokens, ~$0.002 per 1K output tokens
- A typical design request uses 100-500 tokens

**Example costs:**
- Design concepts: ~$0.01-0.05 per request
- Multiple iterations: ~$0.10-0.50 per session

**Billing controls:**
- Set usage limits at https://platform.openai.com/account/billing/usage-limits
- Recommended: Set a low limit ($5-10) to avoid surprises

## Troubleshooting Workflow

If the design skill doesn't work:

1. **Run the verification script above** ← Start here
2. **Check error message** - Match to "Common Issues" section
3. **Verify billing** at OpenAI account dashboard
4. **Restart Claude Code** after making changes
5. **Test with Python script** before using the skill

## Notes

- The frontend-design skill is a plugin, so it gets updated independently
- This documentation covers the OpenAI integration layer needed to make it work
- If Claude Code restarts, the environment variable persists (stored in settings.json)
- For team projects, consider using `OPENAI_API_KEY` from CI/CD or shared secrets

## References

- [OpenAI API Keys](https://platform.openai.com/account/api-keys)
- [OpenAI Billing & Usage](https://platform.openai.com/account/billing/overview)
- [OpenAI Python Client](https://github.com/openai/openai-python)
- [OpenAI Error Codes](https://platform.openai.com/docs/guides/error-codes)
