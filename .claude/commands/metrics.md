# metrics

Show the latest entries from all metrics files.

## Steps

1. Read each metrics file:
   - `metrics/geo-trends.json`
   - `metrics/agent-health.json`
   - `metrics/token-usage.json`

2. For each file, extract the latest entry from the `daily` array (sorted by date descending).

3. Display a formatted summary:

```
=== Metrics Snapshot — {latest_date} ===

📈 Geo Trends
  Date: {date}
  Avg Score: {avg_score}
  Submissions: {submissions} | Published: {published}

🤖 Agent Health
  Date: {date}
  Agent: {agent} | Sessions: {sessions} | Errors: {errors} | Escalations: {escalations}

💰 Token Usage
  Date: {date}
  Agent: {agent} | Input: {input_tokens} | Output: {output_tokens} | Cost: ${cost_usd}

Total estimated cost today: ${total_cost}
```

4. Flag any anomalies:
   - avg_score < 70: geo warning
   - errors > 0: health warning
   - cost_usd > 5.00: cost warning

## Notes
- Metrics are updated by Kaizen via `ops/apply/update-metrics.sh`
- Format defined in PROTOCOL.md
