# PROTOCOL.md — Agent Knowledge Commit & Issue Rules

## Two Improvement Flows

### Flow A: Agent-Initiated Issues (Real-Time)
Agents file GitHub Issues **immediately** when they encounter problems or spot improvements.
Kaizen triages open issues during its scheduled runs.

### Flow B: Kaizen Batch Collection (Scheduled)
Kaizen collects data from Discord, session logs, metrics, and eval-criteria twice daily.
Produces findings, applies low-risk fixes, and files proposals for high-risk changes.

```
┌─ Flow A: Real-Time ─────────────────────────────────┐
│                                                      │
│  Agent encounters problem                            │
│       │                                              │
│       ▼                                              │
│  gh issue create                                     │
│  (label: agent:{name}, priority:{level})             │
│       │                                              │
│       ├── auto-fixable? ──► Kaizen picks up          │
│       └── needs-jay?    ──► Jay reviews              │
│                                                      │
└──────────────────────────────────────────────────────┘

┌─ Flow B: Batch ──────────────────────────────────────┐
│                                                      │
│  Kaizen cron (11:00 AM / 19:00 PM)                   │
│       │                                              │
│       ▼                                              │
│  Collect → Analyze → Classify                        │
│       │                                              │
│       ├── Low risk  ──► Auto-apply + close issues    │
│       └── High risk ──► File proposal + tag Jay      │
│                                                      │
│  Also: triage open agent-filed issues                │
│       │                                              │
│       ├── Can fix? ──► Fix + close issue              │
│       └── Can't?   ──► Add comment + keep open       │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## Issue Filing Rules

### Who Can File Issues

| Agent | Labels | When to File |
|-------|--------|--------------|
| **Mother** 🫶 | `agent:mother` | System issues, cross-agent coordination problems, config gaps |
| **Walter** 🤖 | `agent:walter` | Work workflow issues, tool failures, process improvements |
| **Herald** 🔔 | `agent:herald` | Creator experience issues, content pipeline gaps, GEO problems |
| **Kaizen** ♻️ | `agent:kaizen` | Trend-based findings, metric anomalies, eval-criteria proposals |

### Issue Format

```bash
gh issue create \
  --repo jayleekr/agent-knowledge \
  --title "[Mother] Gateway restart drops active sessions" \
  --body "## Reporter\nMother 🫶\n\n## Type\nbug\n\n## Priority\nurgent\n\n## Description\n..." \
  --label "agent:mother,priority:urgent,bug"
```

### Priority Guidelines

| Priority | When | Examples |
|----------|------|---------|
| `urgent` | Blocking work or causing data loss | Gateway down, session corruption, security issue |
| `normal` | Should fix soon but not blocking | Tool failure pattern, guide confusion, metric drift |
| `low` | Nice to have | Wording improvement, new eval criterion, minor UX |

### Auto-Fixable Tag

Add `auto-fixable` label when Kaizen can resolve it without Jay:
- Lesson updates, guide wording, eval-criteria tuning, metric fixes
- **Do NOT tag as auto-fixable**: skill logic, cron schedule, config, security changes

## Kaizen Issue Triage (Each Run)

During each scheduled run, Kaizen:
1. `gh issue list --label "auto-fixable" --state open` → attempt fix → close with comment
2. `gh issue list --state open` → add analysis comment if relevant data found
3. File new issues for findings that don't match existing open issues
4. Close stale issues (>14 days, no activity, overtaken by events)

## Commit Permissions

### Direct Push (main)
- **Mother**: `lessons/mother.md`, `shared/`
- **Walter**: `lessons/walter.md`
- **Kaizen**: `findings/`, `metrics/`, `recipes/`, `eval-criteria.yaml`

### PR Required
- **Kaizen → proposals/**: Create PR → Jay reviews (high risk)
- **Herald**: `lessons/herald.md` (PR recommended for security)
- **Creator**: `creators/{name}/` → PR → Jay or Mother review

### Auto-Apply (Kaizen)
Low-risk changes pushed directly to main:
- `eval-criteria.yaml` criteria additions / threshold adjustments
- `metrics/` data updates
- `findings/` report additions
- `recipes/` new versions

### Requires Jay's Approval
High-risk changes via PR:
- `proposals/pending/` → PR → after approval, move to `proposals/applied/`
- `shared/guidelines/` changes
- `PROTOCOL.md` changes

## File Format

### lessons/{agent}.md
```markdown
# lessons.md — {Agent} {Emoji}

## {Category}
- **{date}**: {lesson content}
  - Context: {what happened}
  - Lesson: {what was learned}
  - Action: {how to apply going forward}
```

### findings/kaizen/{date}-{period}.md
Follow the report format from Kaizen SKILL.md.

### proposals/pending/{id}.md
```markdown
# Proposal: {title}
- ID: PROP-{YYYYMMDD}-{NNN}
- Proposer: Kaizen ♻️
- Impact: High | Med | Low
- Target: {which skill/config/workflow}
- Current State: {current state}
- Proposed Change: {change details}
- Rationale: {data/analysis-based reasoning}
- Risk: {potential side effects}
- Related Issues: #{issue_number}
```

## Conflict Prevention

- Each agent modifies **only its own files**
- Kaizen modifies **only its own directories**
- Shared files (`shared/`, `PROTOCOL.md`) via PR only

## Metrics Format

### metrics/geo-trends.json
```json
{
  "daily": [
    {"date": "2026-02-20", "avg_score": 72, "submissions": 3, "published": 1}
  ]
}
```

### metrics/agent-health.json
```json
{
  "daily": [
    {"date": "2026-02-20", "agent": "walter", "sessions": 5, "errors": 0, "escalations": 1, "issues_filed": 0}
  ]
}
```

### metrics/token-usage.json
```json
{
  "daily": [
    {"date": "2026-02-20", "agent": "main", "input_tokens": 50000, "output_tokens": 10000, "cost_usd": 1.20}
  ]
}
```
