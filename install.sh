#!/usr/bin/env bash
#
# K9-Claude-Framework installer (macOS/Linux)
#
# Installs the three commands for Claude Code and/or Codex CLI,
# depending on which are detected on the system.
#
# Claude Code: copies commands to ~/.claude/commands/ as .md files.
# Codex CLI:   creates ~/.agents/skills/<name>/SKILL.md for each command.
#
# Detection excludes Codex binaries cached inside ~/.claude/plugins/,
# since those are Claude Code plugin assets, not a standalone Codex install.
#
# Safe to re-run — each run backs up pre-existing files before overwriting.

set -euo pipefail

# ---- locate repo root and sanity-check inputs ---------------------

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="${SCRIPT_DIR}"

COMMANDS_SRC="${REPO_ROOT}/commands"
VERSION_FILE="${REPO_ROOT}/VERSION"

if [[ ! -d "${COMMANDS_SRC}" ]]; then
    echo "error: ${COMMANDS_SRC} not found. Run this from the repo root." >&2
    exit 1
fi
if [[ ! -f "${VERSION_FILE}" ]]; then
    echo "error: ${VERSION_FILE} not found. Run this from the repo root." >&2
    exit 1
fi

FRAMEWORK_VERSION="$(tr -d '[:space:]' < "${VERSION_FILE}")"

# ---- detect installed CLIs ----------------------------------------

INSTALL_CLAUDE=false
INSTALL_CODEX=false

# Claude Code: ~/.claude/ directory is created on first launch
if [[ -d "${HOME}/.claude" ]]; then
    INSTALL_CLAUDE=true
fi

# Codex CLI: ~/.codex/ config directory, OR a codex binary that is NOT
# inside ~/.claude/plugins/ (which is just a Claude Code plugin cache).
if [[ -d "${HOME}/.codex" ]]; then
    INSTALL_CODEX=true
elif command -v codex >/dev/null 2>&1; then
    codex_path="$(command -v codex)"
    if [[ "${codex_path}" != *"/.claude/plugins/"* ]]; then
        INSTALL_CODEX=true
    fi
fi

if [[ "${INSTALL_CLAUDE}" == "false" && "${INSTALL_CODEX}" == "false" ]]; then
    echo "error: Neither Claude Code (~/.claude/) nor Codex CLI (~/.codex/) detected." >&2
    echo "       Install at least one CLI before running this installer." >&2
    exit 1
fi

# ---- detect source (git remote + commit SHA if available) ---------

SOURCE_INFO="${REPO_ROOT}"
if command -v git >/dev/null 2>&1 && git -C "${REPO_ROOT}" rev-parse --git-dir >/dev/null 2>&1; then
    remote="$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || true)"
    sha="$(git -C "${REPO_ROOT}" rev-parse --short HEAD 2>/dev/null || true)"
    if [[ -n "${remote}" && -n "${sha}" ]]; then
        SOURCE_INFO="${remote}@${sha}"
    elif [[ -n "${sha}" ]]; then
        SOURCE_INFO="${REPO_ROOT}@${sha}"
    fi
fi

# ---- shared state -------------------------------------------------

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
TODAY="$(date +%Y-%m-%d)"
INSTALLED=()
BACKED_UP=()

# ---- install for Claude Code --------------------------------------

if [[ "${INSTALL_CLAUDE}" == "true" ]]; then
    COMMANDS_DST="${HOME}/.claude/commands"
    MARKER_FILE="${HOME}/.claude/.k9-framework-version"

    mkdir -p "${COMMANDS_DST}"

    for src in "${COMMANDS_SRC}"/*.md; do
        filename="$(basename "${src}")"
        dst="${COMMANDS_DST}/${filename}"

        if [[ -f "${dst}" ]]; then
            backup="${dst}.pre-k9-backup-${TIMESTAMP}"
            cp "${dst}" "${backup}"
            BACKED_UP+=("${backup}")
        fi

        cp "${src}" "${dst}"
        INSTALLED+=("${dst}")
    done

    cat > "${MARKER_FILE}" <<EOF
framework: K9-Claude-Framework
version: ${FRAMEWORK_VERSION}
installed: ${TODAY}
source: ${SOURCE_INFO}
EOF
fi

# ---- install for Codex CLI ----------------------------------------

if [[ "${INSTALL_CODEX}" == "true" ]]; then
    SKILLS_DIR="${HOME}/.agents/skills"
    MARKER_FILE="${HOME}/.codex/.k9-framework-version"

    mkdir -p "${SKILLS_DIR}"
    # ~/.codex/ may not exist on a fresh Codex install that hasn't been
    # launched yet; create it so the marker write succeeds.
    mkdir -p "${HOME}/.codex"

    for src in "${COMMANDS_SRC}"/*.md; do
        filename="$(basename "${src}")"
        skill_name="${filename%.md}"          # strip .md → init-project, etc.
        skill_dir="${SKILLS_DIR}/${skill_name}"
        skill_dst="${skill_dir}/SKILL.md"

        mkdir -p "${skill_dir}"

        if [[ -f "${skill_dst}" ]]; then
            backup="${skill_dst}.pre-k9-backup-${TIMESTAMP}"
            cp "${skill_dst}" "${backup}"
            BACKED_UP+=("${backup}")
        fi

        cp "${src}" "${skill_dst}"
        INSTALLED+=("${skill_dst}")
    done

    cat > "${MARKER_FILE}" <<EOF
framework: K9-Claude-Framework
version: ${FRAMEWORK_VERSION}
installed: ${TODAY}
source: ${SOURCE_INFO}
EOF
fi

# ---- summary ------------------------------------------------------

echo
echo "K9-Claude-Framework ${FRAMEWORK_VERSION} installed."
echo

if [[ "${INSTALL_CLAUDE}" == "true" ]]; then
    echo "  Claude Code → ~/.claude/commands/"
fi
if [[ "${INSTALL_CODEX}" == "true" ]]; then
    echo "  Codex CLI   → ~/.agents/skills/"
fi

echo
echo "Installed:"
for f in "${INSTALLED[@]}"; do
    echo "  ${f}"
done

if [[ ${#BACKED_UP[@]} -gt 0 ]]; then
    echo
    echo "Backed up (pre-existing files):"
    for f in "${BACKED_UP[@]}"; do
        echo "  ${f}"
    done
fi

echo
if [[ "${INSTALL_CLAUDE}" == "true" ]]; then
    echo "Marker written: ${HOME}/.claude/.k9-framework-version"
fi
if [[ "${INSTALL_CODEX}" == "true" ]]; then
    echo "Marker written: ${HOME}/.codex/.k9-framework-version"
fi

echo
echo "Next steps:"
if [[ "${INSTALL_CLAUDE}" == "true" ]]; then
    echo "  Claude Code — cd into any project and run /init-project."
fi
if [[ "${INSTALL_CODEX}" == "true" ]]; then
    echo "  Codex CLI   — cd into any project and invoke \$init-project (or /skills picker)."
fi
echo "  Already initialized? Try the check-init command to verify health."
