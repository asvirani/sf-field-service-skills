#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Salesforce Field Service Skills Installer for Claude Code
#
#  One-line install:
#
#    curl -sSL https://raw.githubusercontent.com/asvirani/sf-field-service-skills/main/install.sh | bash
#
#  Or with wget:
#
#    wget -qO- https://raw.githubusercontent.com/asvirani/sf-field-service-skills/main/install.sh | bash
#
# ============================================================

REPO="asvirani/sf-field-service-skills"
BRANCH="main"
CLONE_URL="https://github.com/$REPO.git"

SKILL_NAMES=(
    "sf-field-service-data-model"
    "sf-field-service-scheduling"
    "sf-field-service-mobile"
    "sf-fs-datacapture"
)

# -----------------------------------------------------------
#  Detect IDE skills directories
# -----------------------------------------------------------
TARGETS=()

if [ -d "$HOME/.claude" ]; then
    TARGETS+=("$HOME/.claude/skills")
fi

if [ -d "$HOME/.cursor" ]; then
    TARGETS+=("$HOME/.cursor/skills")
fi

if [ -d "$HOME/.windsurf" ]; then
    TARGETS+=("$HOME/.windsurf/skills")
fi

if [ ${#TARGETS[@]} -eq 0 ]; then
    TARGETS+=("$HOME/.claude/skills")
fi

# -----------------------------------------------------------
#  Check if running from local clone
# -----------------------------------------------------------
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    REAL_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$REAL_PATH/sf-field-service-data-model/SKILL.md" ]; then
        SCRIPT_DIR="$REAL_PATH"
    fi
fi

MODE="remote"
TMPDIR_CLONE=""
if [ -n "$SCRIPT_DIR" ]; then
    MODE="local"
else
    # Clone to temp directory (shallow, single branch)
    TMPDIR_CLONE=$(mktemp -d)
    if command -v git &>/dev/null; then
        if ! git clone --depth 1 --branch "$BRANCH" "$CLONE_URL" "$TMPDIR_CLONE" 2>/dev/null; then
            echo "ERROR: Failed to clone $CLONE_URL"
            rm -rf "$TMPDIR_CLONE"
            exit 1
        fi
        SCRIPT_DIR="$TMPDIR_CLONE"
    else
        echo "ERROR: git is required for remote install. Install git and try again."
        rm -rf "$TMPDIR_CLONE"
        exit 1
    fi
fi

# -----------------------------------------------------------
#  Install
# -----------------------------------------------------------
echo ""
echo "==========================================="
echo "  Salesforce Field Service Skills Installer"
echo "  ${#SKILL_NAMES[@]} skills for Claude Code"
echo "==========================================="
echo ""
echo "  Source: $( [ "$MODE" = "local" ] && echo "local ($SCRIPT_DIR)" || echo "github.com/$REPO" )"
echo "  Target: ${TARGETS[*]}"
echo ""

installed=0
skipped=0
total=${#SKILL_NAMES[@]}

for skill in "${SKILL_NAMES[@]}"; do
    src="$SCRIPT_DIR/$skill"

    if [ ! -f "$src/SKILL.md" ]; then
        echo "  WARN  $skill - SKILL.md not found, skipping"
        skipped=$((skipped + 1))
        continue
    fi

    for target_dir in "${TARGETS[@]}"; do
        dest="$target_dir/$skill"
        mkdir -p "$dest"
        # Copy skill contents (SKILL.md + references/)
        cp -R "$src/"* "$dest/"
        # Remove any non-skill files that came along
        rm -f "$dest/README.md" "$dest/LICENSE" 2>/dev/null || true
    done

    echo "  OK    $skill"
    installed=$((installed + 1))
done

# -----------------------------------------------------------
#  Cleanup
# -----------------------------------------------------------
if [ -n "$TMPDIR_CLONE" ]; then
    rm -rf "$TMPDIR_CLONE"
fi

echo ""
echo "-------------------------------------------"
echo "  Installed: $installed / $total skills"
if [ $skipped -gt 0 ]; then
    echo "  Skipped:   $skipped"
fi
echo ""
echo "  Installed to:"
for target_dir in "${TARGETS[@]}"; do
    echo "    $target_dir/"
done
echo "-------------------------------------------"
echo ""

if [ $installed -gt 0 ]; then
    echo "  Restart Claude Code to activate the new skills."
    echo ""
fi
