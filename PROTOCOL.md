# PROTOCOL.md — Agent Knowledge Commit Rules

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
Low-risk changes are pushed directly to main by Kaizen:
- `eval-criteria.yaml` criteria additions / threshold adjustments
- `metrics/` data updates
- `findings/` report additions
- `recipes/` new versions

### Requires Jay's Approval
High-risk changes go through PR:
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
    {"date": "2026-02-20", "agent": "walter", "sessions": 5, "errors": 0, "escalations": 1}
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
