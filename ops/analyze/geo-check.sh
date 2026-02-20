#!/bin/bash
set -euo pipefail

# geo-check.sh — Geo QA scoring for markdown files
# Output: {file, score, grade, findings, suggestions}

GEO_QA_SCRIPT="$HOME/CodeWorkspace/hypeproof/skills/hypeproof-writer/tools/geo_qa_local.py"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--help] <markdown-file>

Analyze a markdown file with geo QA scoring.

Arguments:
  <markdown-file>   Path to markdown file to analyze

Options:
  --dry-run   Output sample result without running analysis
  --help      Show this help message

Output: JSON {file, score, grade, findings: [], suggestions: []}
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
  "file": "sample.md",
  "score": 82,
  "grade": "B",
  "findings": [
    "Missing geo-specific local context in section 2",
    "Address format inconsistent with regional standard"
  ],
  "suggestions": [
    "Add local landmark references",
    "Use standard address format: 시/구/동"
  ]
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

# Try geo_qa_local.py --json first
if [[ -f "$GEO_QA_SCRIPT" ]]; then
  if RAW=$(python3 "$GEO_QA_SCRIPT" "$FILE" --json 2>/dev/null) && [[ -n "$RAW" ]]; then
    echo "$RAW" | python3 -c "
import json, sys
d = json.load(sys.stdin)
out = {
  'file': d.get('file', ''),
  'score': int(d.get('score', 0)),
  'grade': str(d.get('grade', 'N/A')),
  'findings': d.get('findings', []),
  'suggestions': d.get('suggestions', [])
}
print(json.dumps(out, ensure_ascii=False, indent=2))
" 2>/dev/null && exit 0
  fi

  # Fallback: parse text output
  RAW=$(python3 "$GEO_QA_SCRIPT" "$FILE" 2>/dev/null || echo "")
  python3 - "$FILE" "$RAW" <<'PYEOF'
import json, sys, re
filepath = sys.argv[1]
raw = sys.argv[2] if len(sys.argv) > 2 else ""
score_m = re.search(r'score[:\s]+([0-9]+)', raw, re.IGNORECASE)
grade_m = re.search(r'grade[:\s]+([A-F][+-]?)', raw, re.IGNORECASE)
score = int(score_m.group(1)) if score_m else 0
grade = grade_m.group(1) if grade_m else "N/A"
print(json.dumps({"file": filepath, "score": score, "grade": grade,
                   "findings": [], "suggestions": []}, ensure_ascii=False, indent=2))
PYEOF
  exit 0
fi

# geo_qa_local.py not found — built-in analysis
python3 - "$FILE" <<'PYEOF'
import json, sys, re

filepath = sys.argv[1]
with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

findings = []
suggestions = []
score = 70

if len(content) < 100:
    findings.append("Content too short for meaningful geo analysis")
    score -= 10

if not re.search(r'[가-힣]', content):
    findings.append("No Korean text detected")
    suggestions.append("Add Korean localized content")
else:
    score += 5

if re.search(r'[가-힣]+시\s*[가-힣]+구', content):
    score += 5
else:
    suggestions.append("Add explicit city/district address (시/구)")

if re.search(r'\d{5}', content):
    score += 5

if re.search(r'지하철|버스|역\b', content):
    score += 5
else:
    suggestions.append("Add public transportation directions")

score = max(0, min(100, score))

grade = "F"
for threshold, g in [(90, "A"), (80, "B"), (70, "C"), (60, "D")]:
    if score >= threshold:
        grade = g
        break

print(json.dumps({
    "file": filepath,
    "score": score,
    "grade": grade,
    "findings": findings,
    "suggestions": suggestions
}, ensure_ascii=False, indent=2))
PYEOF
