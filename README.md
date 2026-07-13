# Skillshare

A portable collection of Claude Code and OpenAI Codex skills for solo developers and small personal projects. Pick a few skills or install the full collection through one guided setup.

This is an independently maintained fork. Modified gstack components are included locally with attribution; setup does not clone, track, or update from the gstack repository.

## Easiest setup

Open Terminal and paste:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/blakehurlburt/skillshare/main/install.sh)"
```

The installer asks whether you use Claude Code, Codex, or both, then lets you choose skill groups. The default `core` group is a good starting point.

If you prefer to inspect everything before running it:

```bash
git clone https://github.com/blakehurlburt/skillshare.git
cd skillshare
./install.sh
```

Restart Claude Code or Codex after setup.

## Choose only what you want

| Group | What it adds |
| --- | --- |
| `core` | Skill creation, root-cause debugging, code review, security review, second opinions, and Claudeception |
| `planning` | Brainstorming and automatic CEO/design/engineering/DX plan review |
| `browser` | Fast browser control, a browser shell, and live design QA |
| `documents` | Markdown-to-PDF generation |
| `context` | Save and restore working context |
| `safety` | Freeze, guard, and unfreeze editing scope |
| `ios` | SwiftUI device QA, debugging, design review, sync, and cleanup |
| `field-notes` | Narrow troubleshooting playbooks learned from real projects |
| `profile` | Optional solo-developer preferences for AGENTS.md or CLAUDE.md |

Examples:

```bash
# Core plus planning, installed for both agents
./install.sh --agent both --groups core,planning

# Two individual skills for Codex
./install.sh --agent codex --skills investigate,review

# Everything except iOS and two narrow field notes
./install.sh --all --exclude ios,purchase-popup-safe-dismissal,runner-real-money-stall-handoff --yes

# Preview a selection without changing files
./install.sh --agent claude --groups browser,documents --dry-run

# See the available groups
./install.sh --list
```

Selections are additive. Existing skill directories are moved into timestamped backups under `~/.skillshare/backups/` before replacement.

## Optional workflow profile

The shareable parts of Blake's AGENTS.md are available as the `profile` group:

```bash
./install.sh --agent both --profile
```

The installer appends a clearly marked block to `~/.codex/AGENTS.md` and/or `~/.claude/CLAUDE.md`. It never overwrites the rest of the file, and a second run leaves an existing profile block unchanged. The source template is [profiles/solo-dev.md](profiles/solo-dev.md), so it is easy to edit before installing.

## What setup changes

- Bundled Codex skills go to `~/.codex/skills/`.
- Bundled Claude Code skills go to `~/.claude/skills/`.
- Shared, non-indexed runtime files go to `~/.skillshare/runtime/`.
- Backups go to `~/.skillshare/backups/`.
- No updater is installed, and the fork has no remote telemetry path.

The `planning`, `browser`, `documents`, and `context` groups use local compiled helpers. If Bun is missing, interactive setup asks before downloading Bun's official installer. The installer and Bun version are pinned, and the script is SHA-256 verified before it runs. Noninteractive `--yes` setup accepts that dependency installation. You can decline, install Bun yourself, and later run:

```bash
~/.skillshare/runtime/gstack/build-shareable.sh
```

## Third-party skills

Unmodified third-party projects are not copied into this repository. When selected, setup downloads revision-pinned HTTPS archives, verifies their SHA-256 checksums, and installs them locally:

- Claudeception is installed when selected in `core` or by name.
- VibeSec is installed as a non-indexed dependency of `/security`.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for revisions, licenses, and gstack attribution.

## Maintenance

The machine-readable catalog is [manifest.json](manifest.json). Repository checks validate the catalog, payloads, installer behavior, portability, and provenance:

```bash
python3 -m unittest discover -s tests -v
```

If you use pre-commit:

```bash
pre-commit install
```

## Platform notes

The installer supports macOS and Linux, including WSL, with Bash, curl, tar, and a SHA-256 utility. The text-only skill groups do not require Bun. Some iOS and browser capabilities naturally require macOS or their underlying local tools.

## License

Original Skillshare work is MIT licensed. The detached gstack-derived subset retains Garry Tan's MIT notice. Downloaded third-party projects keep their own licenses. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
