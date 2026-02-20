#!/bin/bash
set -euo pipefail

# sentiment.sh — Classify sentiment of messages in a JSON array
# Output: {total, positive, negative, neutral, request, ratio}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--help] <json-file>

Classify sentiment of messages in a JSON array.

Arguments:
  <json-file>   JSON file: array of strings, or array of objects with "text"/"message"/"content" field

Options:
  --dry-run   Output sample result
  --help      Show this help message

Keywords:
  positive: 좋, 감사, 잘, 최고, 훌륭, 완벽, 만족, 고마, 도움, 유용
  negative: 안되, 문제, 에러, 불만, 오류, 실패, 버그, 안됨, 이상, 틀림
  request:  어떻게, 방법, 질문, 알려, 도와, 해주, 가능한가, 할 수, ?

Output: JSON {total, positive, negative, neutral, request, ratio}
EOF
}

DRY_RUN=false
FILE=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h) usage; exit 0 ;;
    --*) echo "Unknown flag: $arg" >&2; exit 1 ;;
    *) FILE="$arg" ;;
  esac
done

if $DRY_RUN; then
  cat <<'JSON'
{
  "total": 10,
  "positive": 4,
  "negative": 2,
  "neutral": 2,
  "request": 2,
  "ratio": {
    "positive": 0.4,
    "negative": 0.2,
    "neutral": 0.2,
    "request": 0.2
  }
}
JSON
  exit 0
fi

if [[ -z "$FILE" ]]; then
  echo '{"error": "No file specified"}' >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  python3 -c "import json; print(json.dumps({'error': 'File not found: ' + '$FILE'}))" >&2
  exit 1
fi

python3 - "$FILE" <<'PYEOF'
import json, sys

filepath = sys.argv[1]
with open(filepath, "r", encoding="utf-8") as f:
    data = json.load(f)

# Extract messages from various formats
messages = []
if isinstance(data, list):
    for item in data:
        if isinstance(item, str):
            messages.append(item)
        elif isinstance(item, dict):
            for key in ("text", "message", "content", "body"):
                if key in item:
                    messages.append(str(item[key]))
                    break
elif isinstance(data, dict) and "messages" in data:
    for item in data["messages"]:
        if isinstance(item, str):
            messages.append(item)
        elif isinstance(item, dict):
            for key in ("text", "message", "content", "body"):
                if key in item:
                    messages.append(str(item[key]))
                    break

POSITIVE = ["좋", "감사", "잘", "최고", "훌륭", "완벽", "만족", "고마", "도움", "유용"]
NEGATIVE = ["안되", "문제", "에러", "불만", "오류", "실패", "버그", "안됨", "이상", "틀림"]
REQUEST  = ["어떻게", "방법", "질문", "알려", "도와", "해주", "가능한가", "할 수", "?", "？"]

counts = {"positive": 0, "negative": 0, "neutral": 0, "request": 0}

for msg in messages:
    if not msg.strip():
        counts["neutral"] += 1
        continue
    if any(kw in msg for kw in NEGATIVE):
        counts["negative"] += 1
    elif any(kw in msg for kw in REQUEST):
        counts["request"] += 1
    elif any(kw in msg for kw in POSITIVE):
        counts["positive"] += 1
    else:
        counts["neutral"] += 1

total = len(messages)
ratio = {k: round(v / total, 2) if total > 0 else 0.0 for k, v in counts.items()}

print(json.dumps({
    "total": total,
    "positive": counts["positive"],
    "negative": counts["negative"],
    "neutral": counts["neutral"],
    "request": counts["request"],
    "ratio": ratio
}, ensure_ascii=False, indent=2))
PYEOF
