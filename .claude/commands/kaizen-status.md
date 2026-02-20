# kaizen-status

Run a quick Kaizen status check: submissions summary + cron job status.

## Steps

1. Run submissions collector (dry-run if no live data available):
   ```bash
   ops/collect/submissions.sh --dry-run
   ```

2. Run cron status checker:
   ```bash
   ops/collect/cron-status.sh --dry-run
   ```

3. Format and display the results:
   - **Submissions**: total, by_status breakdown, avg geo score
   - **Cron Jobs**: name, schedule, last run, status
   - Highlight any `status: "error"` or `status: "running"` cron jobs
   - Flag avg_geo_score below 70 as a warning

## Output Format

```
=== Kaizen Status — {date} ===

📊 Submissions
  Total: {total}
  Submitted: {submitted} | Pending: {pending} | Rejected: {rejected}
  Avg Geo Score: {avg_geo_score}

⏰ Cron Jobs
  {name}: {schedule} | Last: {lastRun} | {status}

{warnings if any}
```
