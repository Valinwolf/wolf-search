#!/usr/bin/env bash

# Simply-Nord: Strict Overlay Build System (Refactored)
# Philosophy: Verify Env -> Stage -> Inject -> Build -> Export
# Version: 3.1 - "Reliable NPM Install" Edition

set -euo pipefail

REPO_PATH="${1:-$(cd "$(dirname "$0")" && pwd)}"
VANILLA_PATH="${2:-$REPO_PATH/searxng-vanilla}"
OUTPUT_PATH="${3:-$REPO_PATH/out}"

TEMP_BUILD_PATH="/tmp/simply-nord-build-workdir"
PYTHON_EXECUTABLE=""

write_log() {
    local step="$1"
    local message="$2"
    echo "[$step] $message"
}

check_dependencies() {
    write_log "PRE" "Verifying build environment..."

    if command -v python3 >/dev/null 2>&1; then
        PYTHON_EXECUTABLE="python3"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_EXECUTABLE="python"
    else
        echo "CRITICAL: Python not found."
        exit 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        echo "CRITICAL: Node.js/NPM not found."
        exit 1
    fi

    write_log "PRE" "  -> Build environment is OK."
}

echo
echo "========================================"
echo "Simply-Nord Theme Builder v3.1"
echo "========================================"
echo

# ==============================================================================
# STEP 0 & 1: PRE-FLIGHT & STAGING
# ==============================================================================

check_dependencies

write_log "0" "Setting up clean build workspace..."
rm -rf "$TEMP_BUILD_PATH"
mkdir -p "$TEMP_BUILD_PATH"

write_log "1" "Staging vanilla SearXNG source into workspace..."
cp -a "$VANILLA_PATH"/. "$TEMP_BUILD_PATH"

# ==============================================================================
# STEP 2: INJECT OVERRIDES
# ==============================================================================

write_log "2" "Injecting custom theme overrides..."

TEMPLATE_TARGET="$TEMP_BUILD_PATH/searx/templates/simple"
TEMPLATE_SOURCE="$REPO_PATH/src/crabx"

if [[ -d "$TEMPLATE_SOURCE" ]]; then
    cp -a "$TEMPLATE_SOURCE"/. "$TEMPLATE_TARGET"
fi

OVERRIDE_SOURCE_FILE="$REPO_PATH/src/nord-crab-overrides.less"
LESS_TARGET_DIR="$TEMP_BUILD_PATH/client/simple/src/less"
MAIN_LESS_FILE="$LESS_TARGET_DIR/style.less"

if [[ ! -f "$OVERRIDE_SOURCE_FILE" ]]; then
    echo "CRITICAL: Override file not found."
    exit 1
fi

cp "$OVERRIDE_SOURCE_FILE" "$LESS_TARGET_DIR"

cat <<EOF >> "$MAIN_LESS_FILE"

// --- Simply-Nord Theme Injection ---
@import "nord-crab-overrides.less";
EOF

# ==============================================================================
# STEP 3: SETUP DEPENDENCIES & BUILD
# ==============================================================================

write_log "3" "Setting up dependencies & Compiling..."

PYTHON_VENV_PATH="$TEMP_BUILD_PATH/.venv"
BUILD_DIR="$TEMP_BUILD_PATH/client/simple"

cleanup() {
    unset PYTHONPATH || true
    unset NODE_ENV || true
}

trap cleanup EXIT

try_build() {

    "$PYTHON_EXECUTABLE" -m venv "$PYTHON_VENV_PATH"

    PIP_EXE="$PYTHON_VENV_PATH/bin/pip"
    VENV_PYTHON="$PYTHON_VENV_PATH/bin/python"

    "$PIP_EXE" install -r "$TEMP_BUILD_PATH/requirements.txt"

    pushd "$BUILD_DIR" >/dev/null

    write_log "3" "  -> Ensuring NPM dependencies are installed..."
    npm install --quiet --no-audit --no-fund

    PYGMENTS_SCRIPT="$TEMP_BUILD_PATH/searxng_extra/update/update_pygments.py"

    export PYTHONPATH="$TEMP_BUILD_PATH"

    "$VENV_PYTHON" "$PYGMENTS_SCRIPT"

    write_log "3" "  -> Running full theme build..."

    export NODE_ENV=production

    npm run build

    popd >/dev/null

    write_log "3" "  -> Build process completed successfully."
}

if ! try_build; then
    echo "COMPILATION FAILED"
    exit 1
fi

# ==============================================================================
# STEP 4 & 5: EXPORT, CLEANUP, VERIFY
# ==============================================================================

write_log "4" "Exporting final assets..."

OUT_TEMPLATES="$OUTPUT_PATH/crabx"
OUT_STATIC="$OUTPUT_PATH/crabx-static"

rm -rf "$OUTPUT_PATH"

mkdir -p "$OUT_TEMPLATES"
mkdir -p "$OUT_STATIC"

cp -a "$TEMPLATE_TARGET"/. "$OUT_TEMPLATES"

CUSTOM_WORDMARK="$REPO_PATH/wordmark.min.svg"
OUT_WORDMARK="$OUT_TEMPLATES/searxng-wordmark.min.svg"

if [[ -f "$CUSTOM_WORDMARK" ]]; then
    cp "$CUSTOM_WORDMARK" "$OUT_WORDMARK"
fi

BUILD_OUTPUT="$TEMP_BUILD_PATH/searx/static/themes/simple"

if [[ -d "$BUILD_OUTPUT" ]]; then
    cp -a "$BUILD_OUTPUT"/. "$OUT_STATIC"
else
    echo "CRITICAL: Build output directory not found."
    exit 1
fi

CUSTOM_IMG_SOURCE="$REPO_PATH/img"
OUT_IMG_DIR="$OUT_STATIC/img"

if [[ -d "$CUSTOM_IMG_SOURCE" ]]; then
    rm -rf "$OUT_IMG_DIR"
    cp -a "$CUSTOM_IMG_SOURCE" "$OUT_IMG_DIR"
fi

write_log "5" "Cleaning up and Verifying..."

rm -rf "$TEMP_BUILD_PATH"

if [[ -f "$OUT_TEMPLATES/results.html" ]]; then
    write_log "5" "  -> Templates: OK"
else
    echo "VERIFICATION FAILED: 'results.html' missing."
    exit 1
fi

if compgen -G "$OUT_STATIC/sxng-ltr.min.css" > /dev/null; then
    write_log "5" "  -> Static Assets: OK"
else
    echo "VERIFICATION FAILED: 'sxng-ltr.min.css' missing."
    exit 1
fi

echo
echo "Build complete. Output is ready in '$OUTPUT_PATH'."
