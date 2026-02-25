#!/usr/bin/env bash
# setup-rust-lsp.sh — Configure rust-analyzer LSP for Copilot CLI
# Usage: bash setup-rust-lsp.sh
#
# This script:
#   1. Creates ~/.copilot/ if it doesn't exist
#   2. Writes (or merges) lsp-config.json with the rust-analyzer entry
#   3. Checks that rust-analyzer is available on PATH

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.copilot}"
LSP_CONFIG="$CONFIG_DIR/lsp-config.json"

RUST_LSP_ENTRY='{
    "lspServers": {
        "rust": {
            "command": "rust-analyzer",
            "args": [],
            "fileExtensions": {
                ".rs": "rust"
            }
        }
    }
}'

echo "=== Copilot CLI — rust-analyzer LSP setup ==="
echo ""

# Step 1: Create config directory
if [ ! -d "$CONFIG_DIR" ]; then
    echo "[1/3] Creating config directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
else
    echo "[1/3] Config directory exists: $CONFIG_DIR"
fi

# Step 2: Write or merge lsp-config.json
if [ ! -f "$LSP_CONFIG" ]; then
    echo "[2/3] Creating $LSP_CONFIG"
    echo "$RUST_LSP_ENTRY" > "$LSP_CONFIG"
elif grep -q '"rust"' "$LSP_CONFIG" 2>/dev/null; then
    echo "[2/3] $LSP_CONFIG already contains a 'rust' server entry — skipping"
    echo "       Review manually if /lsp test rust fails."
else
    echo "[2/3] $LSP_CONFIG exists but has no 'rust' entry."
    echo "       You need to manually add the rust server to lspServers:"
    echo ""
    echo '       "rust": {'
    echo '           "command": "rust-analyzer",'
    echo '           "args": [],'
    echo '           "fileExtensions": { ".rs": "rust" }'
    echo '       }'
    echo ""
fi

# Step 3: Check rust-analyzer
echo -n "[3/3] Checking rust-analyzer... "
if command -v rust-analyzer &>/dev/null; then
    echo "found: $(rust-analyzer --version 2>/dev/null || echo 'unknown version')"
else
    echo "NOT FOUND"
    echo ""
    echo "  Install via:  rustup component add rust-analyzer"
    echo "  Or download:  https://github.com/rust-lang/rust-analyzer/releases"
    exit 1
fi

echo ""
echo "Done. Verify in Copilot CLI with:"
echo "  /lsp show"
echo "  /lsp test rust"
