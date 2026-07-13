#!/usr/bin/env bash
set -euo pipefail

REPO_SLUG="blakehurlburt/skillshare"
REPO_BRANCH="main"
CLAUDECEPTION_URL="https://github.com/blader/Claudeception/archive/62dbb91d1183a866b5cf40079265c825b2695843.tar.gz"
CLAUDECEPTION_SHA="b10e950267117a023ce56d3ef838b709b22ed17a32be598044ad2bcaf25f89dd"
VIBESEC_URL="https://github.com/BehiSecc/VibeSec-Skill/archive/0590993b35ad51961f65a4d01cf1196dfead05bb.tar.gz"
VIBESEC_SHA="96cc2a93824e557b9a472cc9e9876f22b9dc9f143520fcf831d8e1b59c7b0049"
BUN_VERSION="1.3.10"
BUN_INSTALL_SHA="bab8acfb046aac8c72407bdcce903957665d655d7acaa3e11c7c4616beae68dd"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P || pwd -P)"
WORK_DIR=""
DOWNLOAD_DIR=""
AGENT=""
GROUPS_CSV=""
SKILLS_CSV=""
EXCLUDES_CSV=""
ASSUME_YES=0
DRY_RUN=0
LIST_ONLY=0

cleanup() {
  if [ -n "$DOWNLOAD_DIR" ] && [ -d "$DOWNLOAD_DIR" ]; then
    rm -rf "$DOWNLOAD_DIR"
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Skillshare installer

  ./install.sh                         Interactive setup
  ./install.sh --agent both --groups core,planning
  ./install.sh --agent codex --skills investigate,review
  ./install.sh --all --exclude ios --profile --yes

Options:
  --agent claude|codex|both   Installation target (default: interactive, or both with --yes)
  --groups LIST               Comma-separated groups
  --skills LIST               Add individual skills
  --exclude LIST              Comma-separated group or skill names to skip
  --all                       Select every skill group except the optional profile
  --profile                   Merge the solo-dev profile into AGENTS.md/CLAUDE.md
  --list                      List groups and exit
  --dry-run                   Show the intended selection without changing files
  --yes                       Accept defaults and dependency prompts
  --help                      Show this help
EOF
}

append_csv() {
  current="$1"
  addition="$2"
  if [ -z "$current" ]; then
    printf '%s' "$addition"
  elif [ -z "$addition" ]; then
    printf '%s' "$current"
  else
    printf '%s,%s' "$current" "$addition"
  fi
}

csv_has() {
  list="$1"
  needle="$2"
  old_ifs="$IFS"
  IFS=','
  for item in $list; do
    if [ "$item" = "$needle" ]; then
      IFS="$old_ifs"
      return 0
    fi
  done
  IFS="$old_ifs"
  return 1
}

all_groups="core planning browser documents context safety ios field-notes profile"
all_skill_groups="core planning browser documents context safety ios field-notes"
all_skills="add-skill investigate review security second-opinion claudeception brainstorm autoplan browse connect-chrome design-review make-pdf context-save context-restore freeze guard unfreeze ios-qa ios-fix ios-design-review ios-sync ios-clean apply-patch-workspace-root-paths claude-idle-prompt-rc-footer frontend-design-openai-setup notify-cmd-shell-quoting ntfy-unicode-headers purchase-popup-safe-dismissal resume-rate-limited-code-sessions runner-real-money-stall-handoff sleep-tolerant-launchd-scanner virtiofs-mutable-state-safety"

skills_for_group() {
  case "$1" in
    core) echo "add-skill investigate review security second-opinion claudeception" ;;
    planning) echo "brainstorm autoplan" ;;
    browser) echo "browse connect-chrome design-review" ;;
    documents) echo "make-pdf" ;;
    context) echo "context-save context-restore" ;;
    safety) echo "freeze guard unfreeze" ;;
    ios) echo "ios-qa ios-fix ios-design-review ios-sync ios-clean" ;;
    field-notes) echo "apply-patch-workspace-root-paths claude-idle-prompt-rc-footer frontend-design-openai-setup notify-cmd-shell-quoting ntfy-unicode-headers purchase-popup-safe-dismissal resume-rate-limited-code-sessions runner-real-money-stall-handoff sleep-tolerant-launchd-scanner virtiofs-mutable-state-safety" ;;
    profile) echo "" ;;
    *) return 1 ;;
  esac
}

is_known() {
  haystack="$1"
  needle="$2"
  known_old_ifs="$IFS"
  IFS=' '
  for item in $haystack; do
    if [ "$item" = "$needle" ]; then
      IFS="$known_old_ifs"
      return 0
    fi
  done
  IFS="$known_old_ifs"
  return 1
}

list_groups() {
  cat <<'EOF'
Available groups

  core         Everyday skill creation, debugging, review, security, and second opinions (default)
  planning     Brainstorming and automatic plan review
  browser      Browser control and live design QA
  documents    Markdown-to-PDF generation
  context      Save and restore working context
  safety       Freeze, guard, and unfreeze edit scope
  ios          SwiftUI device QA and debugging
  field-notes  Narrow troubleshooting playbooks from real projects
  profile      Optional solo-developer AGENTS.md/CLAUDE.md preferences

Use --skills NAME,NAME for individual selection and --exclude NAME,NAME to skip a group or skill.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent)
      [ "$#" -ge 2 ] || { echo "--agent needs a value" >&2; exit 2; }
      AGENT="$2"
      shift 2
      ;;
    --groups)
      [ "$#" -ge 2 ] || { echo "--groups needs a value" >&2; exit 2; }
      GROUPS_CSV="$(append_csv "$GROUPS_CSV" "$2")"
      shift 2
      ;;
    --skills)
      [ "$#" -ge 2 ] || { echo "--skills needs a value" >&2; exit 2; }
      SKILLS_CSV="$(append_csv "$SKILLS_CSV" "$2")"
      shift 2
      ;;
    --exclude)
      [ "$#" -ge 2 ] || { echo "--exclude needs a value" >&2; exit 2; }
      EXCLUDES_CSV="$(append_csv "$EXCLUDES_CSV" "$2")"
      shift 2
      ;;
    --all)
      GROUPS_CSV="$(echo "$all_skill_groups" | tr ' ' ',')"
      shift
      ;;
    --profile)
      GROUPS_CSV="$(append_csv "$GROUPS_CSV" "profile")"
      shift
      ;;
    --yes|-y)
      ASSUME_YES=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --list)
      LIST_ONLY=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ "$LIST_ONLY" -eq 1 ]; then
  list_groups
  exit 0
fi

if [ ! -f "$SCRIPT_DIR/manifest.json" ]; then
  command -v curl >/dev/null 2>&1 || { echo "curl is required for one-line setup." >&2; exit 1; }
  command -v tar >/dev/null 2>&1 || { echo "tar is required for one-line setup." >&2; exit 1; }
  DOWNLOAD_DIR="$(mktemp -d)"
  echo "Downloading Skillshare..."
  curl -fsSL --retry 3 "https://github.com/$REPO_SLUG/archive/refs/heads/$REPO_BRANCH.tar.gz" -o "$DOWNLOAD_DIR/skillshare.tar.gz"
  tar -xzf "$DOWNLOAD_DIR/skillshare.tar.gz" -C "$DOWNLOAD_DIR"
  SCRIPT_DIR="$(find "$DOWNLOAD_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
fi

if [ "$ASSUME_YES" -eq 1 ]; then
  [ -n "$AGENT" ] || AGENT="both"
  [ -n "$GROUPS_CSV" ] || [ -n "$SKILLS_CSV" ] || GROUPS_CSV="core"
else
  if [ -z "$AGENT" ]; then
    echo "Where should the skills be installed?"
    echo "  1) Claude Code and Codex (recommended)"
    echo "  2) Claude Code only"
    echo "  3) Codex only"
    printf "Choice [1]: "
    read -r choice
    case "${choice:-1}" in
      1) AGENT="both" ;;
      2) AGENT="claude" ;;
      3) AGENT="codex" ;;
      *) echo "Invalid choice." >&2; exit 2 ;;
    esac
  fi
  if [ -z "$GROUPS_CSV" ] && [ -z "$SKILLS_CSV" ]; then
    list_groups
    printf "Groups to install, comma-separated [core]: "
    read -r GROUPS_CSV
    GROUPS_CSV="${GROUPS_CSV:-core}"
  fi
fi

case "$AGENT" in
  claude|codex|both) ;;
  *) echo "Invalid agent: $AGENT" >&2; exit 2 ;;
esac

for group in $(printf '%s' "$GROUPS_CSV" | tr ',' ' '); do
  is_known "$all_groups" "$group" || { echo "Unknown group: $group" >&2; exit 2; }
done
for skill in $(printf '%s' "$SKILLS_CSV" | tr ',' ' '); do
  is_known "$all_skills" "$skill" || { echo "Unknown skill: $skill" >&2; exit 2; }
done
for excluded in $(printf '%s' "$EXCLUDES_CSV" | tr ',' ' '); do
  if ! is_known "$all_groups $all_skills" "$excluded"; then
    echo "Unknown exclusion: $excluded" >&2
    exit 2
  fi
done

SELECTED=""
NEEDS_RUNTIME=0
NEEDS_BUILD=0
INSTALL_PROFILE=0

add_selected() {
  name="$1"
  csv_has "$EXCLUDES_CSV" "$name" && return 0
  csv_has "$SELECTED" "$name" || SELECTED="$(append_csv "$SELECTED" "$name")"
}

for group in $(printf '%s' "$GROUPS_CSV" | tr ',' ' '); do
  csv_has "$EXCLUDES_CSV" "$group" && continue
  if [ "$group" = "profile" ]; then
    INSTALL_PROFILE=1
    continue
  fi
  case "$group" in
    core|planning|browser|documents|context|safety|ios) NEEDS_RUNTIME=1 ;;
  esac
  case "$group" in
    planning|browser|documents|context) NEEDS_BUILD=1 ;;
  esac
  for skill in $(skills_for_group "$group"); do
    add_selected "$skill"
  done
done
for skill in $(printf '%s' "$SKILLS_CSV" | tr ',' ' '); do
  add_selected "$skill"
  case "$skill" in
    add-skill|investigate|review|security|second-opinion|brainstorm|autoplan|browse|connect-chrome|design-review|make-pdf|context-save|context-restore|freeze|guard|unfreeze|ios-qa|ios-fix|ios-design-review|ios-sync|ios-clean) NEEDS_RUNTIME=1 ;;
  esac
  case "$skill" in
    brainstorm|autoplan|browse|connect-chrome|design-review|make-pdf|context-save|context-restore) NEEDS_BUILD=1 ;;
  esac
done

if [ -z "$SELECTED" ] && [ "$INSTALL_PROFILE" -eq 0 ]; then
  echo "Nothing selected."
  exit 0
fi

echo
echo "Agent target: $AGENT"
echo "Skills: ${SELECTED:-none}"
[ "$INSTALL_PROFILE" -eq 1 ] && echo "Profile: solo-dev"
[ "$NEEDS_BUILD" -eq 1 ] && echo "Compiled helpers: required"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run complete; no files changed."
  exit 0
fi

STATE_ROOT="$HOME/.skillshare"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$STATE_ROOT/backups/$STAMP"
mkdir -p "$STATE_ROOT" "$BACKUP_ROOT"

replace_dir() {
  source_dir="$1"
  destination="$2"
  backup_name="$3"
  mkdir -p "$(dirname "$destination")"
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    mkdir -p "$(dirname "$BACKUP_ROOT/$backup_name")"
    mv "$destination" "$BACKUP_ROOT/$backup_name"
  fi
  cp -R "$source_dir" "$destination"
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "A SHA-256 tool (shasum or sha256sum) is required." >&2
    return 1
  fi
}

fetch_archive() {
  label="$1"
  url="$2"
  expected="$3"
  output_parent="$4"
  mkdir -p "$output_parent"
  archive="$output_parent/$label.tar.gz"
  extract="$output_parent/$label-extracted"
  echo "Downloading pinned $label source..." >&2
  curl -fsSL --retry 3 "$url" -o "$archive"
  actual="$(sha256_file "$archive")"
  if [ "$actual" != "$expected" ]; then
    echo "$label archive checksum mismatch; refusing to install." >&2
    exit 1
  fi
  mkdir -p "$extract"
  tar -xzf "$archive" -C "$extract"
  find "$extract" -mindepth 1 -maxdepth 1 -type d | head -n 1
}

if [ "$NEEDS_RUNTIME" -eq 1 ]; then
  replace_dir "$SCRIPT_DIR/runtime/gstack" "$STATE_ROOT/runtime/gstack" "runtime/gstack"
  replace_dir "$SCRIPT_DIR/runtime/lib" "$STATE_ROOT/runtime/lib" "runtime/lib"
  mkdir -p "$STATE_ROOT/runtime/_shared"
  cp "$SCRIPT_DIR/runtime/_shared/preamble.md" "$STATE_ROOT/runtime/_shared/preamble.md"
fi

TEMP_EXTERNAL="$(mktemp -d)"
if csv_has "$SELECTED" "security"; then
  vibesec_source="$(fetch_archive "vibesec" "$VIBESEC_URL" "$VIBESEC_SHA" "$TEMP_EXTERNAL")"
  replace_dir "$vibesec_source" "$STATE_ROOT/runtime/lib/vibesec" "runtime/lib/vibesec"
fi

install_bundled_skill() {
  target_agent="$1"
  skill="$2"
  if [ "$target_agent" = "claude" ]; then
    skill_root="$HOME/.claude/skills"
  else
    skill_root="$HOME/.codex/skills"
  fi
  source_dir="$SCRIPT_DIR/payloads/$target_agent/skills/$skill"
  [ -d "$source_dir" ] || { echo "Missing bundled skill: $target_agent/$skill" >&2; exit 1; }
  replace_dir "$source_dir" "$skill_root/$skill" "$target_agent/skills/$skill"
  touch "$skill_root/$skill/.skillshare-managed"
}

install_claudeception() {
  target_agent="$1"
  source_dir="$2"
  if [ "$target_agent" = "claude" ]; then
    skill_root="$HOME/.claude/skills"
  else
    skill_root="$HOME/.codex/skills"
  fi
  replace_dir "$source_dir" "$skill_root/claudeception" "$target_agent/skills/claudeception"
  rm -rf "$skill_root/claudeception/.git" "$skill_root/claudeception/.claude"
  if [ "$target_agent" = "codex" ]; then
    find "$skill_root/claudeception" -type f -name 'SKILL.md' | while IFS= read -r file; do
      sed -e 's/Claude Code/Codex/g' -e 's#\.claude/skills#.codex/skills#g' "$file" > "$file.skillshare-tmp"
      mv "$file.skillshare-tmp" "$file"
    done
  fi
  touch "$skill_root/claudeception/.skillshare-managed"
}

merge_profile() {
  target_agent="$1"
  if [ "$target_agent" = "claude" ]; then
    config_file="$HOME/.claude/CLAUDE.md"
  else
    config_file="$HOME/.codex/AGENTS.md"
  fi
  mkdir -p "$(dirname "$config_file")"
  touch "$config_file"
  if grep -q '^<!-- skillshare:solo-dev:start -->$' "$config_file"; then
    echo "Profile already present in $config_file; leaving the user's copy unchanged."
    return 0
  fi
  {
    printf '\n<!-- skillshare:solo-dev:start -->\n'
    cat "$SCRIPT_DIR/profiles/solo-dev.md"
    printf '\n<!-- skillshare:solo-dev:end -->\n'
  } >> "$config_file"
}

CLAUDECEPTION_SOURCE=""
if csv_has "$SELECTED" "claudeception"; then
  CLAUDECEPTION_SOURCE="$(fetch_archive "claudeception" "$CLAUDECEPTION_URL" "$CLAUDECEPTION_SHA" "$TEMP_EXTERNAL")"
fi

for target_agent in claude codex; do
  if [ "$AGENT" != "both" ] && [ "$AGENT" != "$target_agent" ]; then
    continue
  fi
  if [ -n "$SELECTED" ]; then
    skill_root="$HOME/.$target_agent/skills"
    mkdir -p "$skill_root"
    replace_dir "$SCRIPT_DIR/payloads/$target_agent/skills/_shared" "$skill_root/_shared" "$target_agent/skills/_shared"
  fi
  for skill in $(printf '%s' "$SELECTED" | tr ',' ' '); do
    if [ "$skill" = "claudeception" ]; then
      install_claudeception "$target_agent" "$CLAUDECEPTION_SOURCE"
    else
      install_bundled_skill "$target_agent" "$skill"
    fi
  done
  [ "$INSTALL_PROFILE" -eq 1 ] && merge_profile "$target_agent"
done

if [ "$NEEDS_BUILD" -eq 1 ]; then
  if ! command -v bun >/dev/null 2>&1; then
    install_bun=0
    if [ "$ASSUME_YES" -eq 1 ]; then
      install_bun=1
    else
      echo
      echo "The selected browser/document helpers need Bun to compile their local binaries."
      printf "Install Bun from https://bun.sh now? [Y/n]: "
      read -r answer
      case "${answer:-Y}" in
        y|Y|yes|YES) install_bun=1 ;;
      esac
    fi
    if [ "$install_bun" -eq 1 ]; then
      bun_installer="$TEMP_EXTERNAL/bun-install.sh"
      curl -fsSL --retry 3 https://bun.sh/install -o "$bun_installer"
      actual_bun_sha="$(sha256_file "$bun_installer")"
      if [ "$actual_bun_sha" != "$BUN_INSTALL_SHA" ]; then
        echo "Bun installer checksum mismatch; refusing to run it." >&2
        exit 1
      fi
      BUN_VERSION="$BUN_VERSION" bash "$bun_installer"
      export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
      export PATH="$BUN_INSTALL/bin:$PATH"
    else
      echo "Skills were installed, but compiled helpers are not ready. Install Bun and run:"
      echo "  ~/.skillshare/runtime/gstack/build-shareable.sh"
      exit 0
    fi
  fi
  "$STATE_ROOT/runtime/gstack/build-shareable.sh"
fi

rm -rf "$TEMP_EXTERNAL"
echo
echo "Skillshare setup complete. Restart Claude Code or Codex so it can discover the new skills."
if find "$BACKUP_ROOT" -mindepth 1 -print -quit | grep -q .; then
  echo "Existing files were backed up to: $BACKUP_ROOT"
else
  rmdir "$BACKUP_ROOT" 2>/dev/null || true
fi
