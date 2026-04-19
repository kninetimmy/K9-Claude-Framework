#!/usr/bin/env bash
#
# K9-Claude-Framework installer (macOS/Linux)
#
# Copies the three commands from ./commands/ into ~/.claude/commands/,
# backing up any pre-existing versions, and writes a framework marker
# at ~/.claude/.k9-framework-version.
#
# Safe to re-run — each run backs up what's already there before
# overwriting.

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

# ---- locate install target ----------------------------------------

CLAUDE_DIR="${HOME}/.claude"
COMMANDS_DST="${CLAUDE_DIR}/commands"
MARKER_FILE="${CLAUDE_DIR}/.k9-framework-version"

mkdir -p "${COMMANDS_DST}"

# ---- install each command file ------------------------------------

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
TODAY="$(date +%Y-%m-%d)"
INSTALLED=()
BACKED_UP=()

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

# ---- write framework marker ---------------------------------------

cat > "${MARKER_FILE}" <<EOF
framework: K9-Claude-Framework
version: ${FRAMEWORK_VERSION}
installed: ${TODAY}
source: ${SOURCE_INFO}
EOF

# ---- summary ------------------------------------------------------

echo
echo "K9-Claude-Framework ${FRAMEWORK_VERSION} installed."
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
echo "Marker written: ${MARKER_FILE}"
echo
echo "Next steps:"
echo "  cd into any project and run /init-project in a Claude Code session."
echo "  Already initialized? Try /check-init to verify health."
