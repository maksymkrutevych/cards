#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$(git -C "$ROOT" rev-parse --git-path hooks)"

mkdir -p "$HOOKS_DIR"
cp "$ROOT/scripts/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"
chmod +x "$ROOT/scripts/update-words-index.sh"

echo "Installed pre-commit hook → $HOOKS_DIR/pre-commit"
