# kaizen-run

Run a full Kaizen cycle: collect → analyze → report → apply → push.

## Pipeline

### 1. Collect
```bash
ops/collect/submissions.sh
ops/collect/discord-messages.sh
ops/collect/session-logs.sh
ops/collect/cron-status.sh
```

### 2. Analyze
```bash
ops/analyze/geo-check.sh metrics/geo-trends.json
```

### 3. Report
Generate a findings report and save to:
```
findings/kaizen/{YYYY-MM-DD}-{period}.md
```
Use the format defined in PROTOCOL.md.

### 4. Apply (low-risk only)
```bash
# Update metrics with latest data
ops/apply/update-metrics.sh --file geo-trends --data '{...}'
ops/apply/update-metrics.sh --file agent-health --data '{...}'
ops/apply/update-metrics.sh --file token-usage --data '{...}'

# Update eval criteria if thresholds changed
ops/apply/update-eval.sh

# Update lessons if new insights found
ops/apply/update-lessons.sh
```

### 5. Push
```bash
ops/apply/push-knowledge.sh 'kaizen: {period} update — {date}'
```

## Notes
- High-risk changes (proposals/) require a PR — do NOT push directly
- Use `--dry-run` on each step to preview before applying
- If geo avg_score drops below 70, create a proposal in proposals/pending/
