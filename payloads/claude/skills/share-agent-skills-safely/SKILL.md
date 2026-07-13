---
name: share-agent-skills-safely
description: |
  Package a mixed personal Claude Code or Codex skill collection into a public, portable
  repository. Use when some skills are customized forks while others are pristine upstream
  installs, when local skills contain absolute paths or bundled runtimes, or when a one-line
  installer must be safe for nontechnical users. Covers provenance classification, immutable
  archive pins and checksums, subset selection, sanitization, attribution, and remote smoke tests.
author: Codex
version: 1.1.0
date: 2026-07-13
---

# Share Agent Skills Safely

## Problem

A personal skill directory is not automatically a redistributable package. It commonly mixes:

- original or substantially modified skills that should be bundled;
- pristine third-party skills that should remain owned and updated upstream;
- symlinks, nested repositories, machine-specific paths, caches, and compiled files;
- shared runtimes with updater, telemetry, or undeclared dependency behavior.

Copying the whole directory can republish code unnecessarily, leak local details, break on another
machine, or leave a beginner with an installer that works only on the author's computer.

## Trigger Conditions

Use this skill when:

- publishing a Claude Code, Codex, or compatible agent-skill collection;
- separating modified forks from unmodified installed skills;
- removing a direct runtime dependency on the original fork source;
- offering opt-in groups, individual skills, or exclusions;
- sharing selected workflow preferences from an `AGENTS.md` or `CLAUDE.md`;
- supporting a copy-paste command such as `bash -c "$(curl ...)"`.

## Solution

### 1. Build a provenance inventory

Classify every skill before copying it:

| Classification | Packaging action |
|---|---|
| Original or materially modified | Bundle the reviewed files |
| Pristine upstream install | Fetch from upstream during setup |
| Shared local runtime | Bundle only the required, detached runtime |
| Machine-specific or private | Exclude or replace with a documented placeholder |

Resolve symlinks before classification. A symlink can hide a stale target, a nested repository, or
a dependency that will disappear on a friend's machine.

### 2. Preserve upstream ownership without a live dependency

For pristine third-party skills, download an immutable archive during setup:

1. Pin a full commit revision, not a mutable branch or release alias.
2. Record the archive URL, revision, SHA-256, and license in a manifest.
3. Verify the checksum before extracting.
4. Install only the required subdirectory.
5. Keep the upstream project out of the published payload.

This avoids republishing an untouched local copy while keeping installation reproducible.

### 3. Detach modified forks deliberately

For customized forks:

- include the applicable license and a concise third-party notice;
- remove nested `.git` directories, dependency caches, build outputs, and unused source;
- replace absolute home-directory paths with portable runtime discovery;
- remove upstream update checks and remote telemetry unless explicitly part of the product;
- retain only helpers actually referenced by bundled skills;
- audit and trim dependencies after detaching the runtime.

After trimming, compare runtime imports with the package manifest. A required module can appear to
work only because an unrelated package supplies it transitively. Build from a clean Git archive or
fresh checkout with no pre-existing dependency directory; a build in the working tree can be
silently supported by stale or transitive packages.

Attribution does not require a runtime dependency on the original repository.

### 4. Design installation around user choices

Offer both an interactive path and scriptable flags:

- target agent: Claude Code, Codex, or both;
- named groups for common use cases;
- individual skill selection;
- exclusions that override group selections;
- an optional profile block, clearly separate from skills;
- dry-run and list modes;
- timestamped backups before replacing existing directories.

Text-only groups should not force users to install build tools required by browser or document
helpers.

### 5. Treat every executed download as code

Pin versions and verify checksums for upstream skill archives and bootstrap installers. Refuse to
execute or extract on mismatch. Use HTTPS explicitly when SSH access has not been authorized.

When supporting a piped Bash installer, do not assume `BASH_SOURCE[0]` exists:

```bash
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
else
  script_dir="$(pwd -P)"
fi
```

### 6. Test the package, not just the source tree

Automate checks for:

- manifest-to-payload consistency;
- valid skill frontmatter;
- no nested repositories or symlinks;
- no personal paths, credentials, or obvious secrets;
- complete licenses and attribution;
- pinned revisions and checksums;
- direct runtime imports declared as direct dependencies;
- shell syntax and executable bits;
- subset installation into a temporary home;
- idempotent profile merging;
- dependency advisories and a full helper build.

After publishing, run the exact README copy-paste command from the remote raw URL in a fresh
temporary home. Local execution cannot reveal raw-host propagation or piped-script behavior.

## Verification

The package is ready when:

- every skill has an explicit provenance and install strategy;
- pristine upstream skills are absent from the bundled payload;
- no personal paths, secrets, nested repositories, or broken symlinks remain;
- all executed downloads are immutable or checksum-verified;
- security audit and full runtime build pass;
- group, individual, exclusion, dry-run, and profile paths behave as documented;
- the published one-line installer succeeds without warnings in a clean home;
- the Git remote uses the authorized transport.

## Example

A collection contains a customized review workflow, an unmodified learning skill, and a forked
browser runtime. Bundle the review workflow and detached browser files with attribution. Configure
setup to fetch the learning skill from its upstream commit archive after verifying SHA-256. Put
review in `core`, browser in an optional `browser` group, and expose `--exclude browser`.
Finally, install `core` from the published raw installer into a temporary home and verify the
agent discovers the expected files.

## Notes

- A public repository is a release boundary even when intended only for friends.
- Do not infer that two same-named skills are identical; compare content or provenance.
- Dependency removal should be followed by both an advisory audit and the real build.
- A successful installer exit is insufficient if stderr contains warnings that confuse beginners.
