#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORDS_DIR="$ROOT/words"
INDEX_FILE="$WORDS_DIR/index.json"

python3 - "$WORDS_DIR" "$INDEX_FILE" <<'PY'
import glob
import json
import os
import sys

words_dir, index_file = sys.argv[1], sys.argv[2]

decks = sorted(
    os.path.splitext(os.path.basename(path))[0]
    for path in glob.glob(os.path.join(words_dir, "*.json"))
    if os.path.basename(path) != "index.json"
)

with open(index_file, "w", encoding="utf-8") as f:
    json.dump(decks, f, indent=2)
    f.write("\n")

print(f"Updated {index_file} ({len(decks)} decks)")
PY
