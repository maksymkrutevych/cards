#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LESSONS_DIR="$ROOT/curriculum/lessons/main"
INDEX_FILE="$LESSONS_DIR/index.json"

python3 - "$LESSONS_DIR" "$INDEX_FILE" <<'PY'
import glob
import json
import os
import sys

lessons_dir, index_file = sys.argv[1], sys.argv[2]

entries = []
for path in sorted(glob.glob(os.path.join(lessons_dir, "*.json"))):
    name = os.path.basename(path)
    if name == "index.json":
        continue
    with open(path, encoding="utf-8") as f:
        lesson = json.load(f)
    stem = os.path.splitext(name)[0]
    cefr = lesson.get("cefr") or {}
    timing = lesson.get("timing") or {}
    entries.append({
        "id": stem,
        "lessonId": lesson.get("lessonId"),
        "title": lesson.get("title") or stem,
        "trackId": lesson.get("trackId") or "main",
        "locale": lesson.get("locale") or "en-US",
        "cefr": cefr.get("lessonLevel"),
        "band": cefr.get("band"),
        "pairsCount": timing.get("pairsCount") or len(lesson.get("pairs") or []),
        "targetMinutes": timing.get("targetMinutes"),
    })

entries.sort(key=lambda e: (e.get("lessonId") is None, e.get("lessonId") or 0, e["id"]))

with open(index_file, "w", encoding="utf-8") as f:
    json.dump(entries, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"Updated {index_file} ({len(entries)} lessons)")
PY
