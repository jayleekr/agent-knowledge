# 🧠 Agent Knowledge Base

> Shared knowledge repository for AI agents. Manages lessons, findings, proposals, and metrics via Git.
> Powered by [OpenClaw](https://openclaw.ai) + Kaizen ♻️

## Self-Improvement Loop

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Kaizen ♻️ Self-Improvement Loop                  │
│                     (Cron: 11:00 AM / 19:00 PM)                    │
└─────────────────────────────────────────────────────────────────────┘

  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
  │ Mother🫶 │   │Walter 🤖│   │Herald 🔔│   │Creators 👥│
  │          │   │          │   │          │   │           │
  │ Session  │   │ Session  │   │ Discord  │   │ Feedback  │
  │ Logs     │   │ Logs     │   │ Threads  │   │ Messages  │
  └────┬─────┘   └────┬─────┘   └────┬─────┘   └─────┬─────┘
       │               │              │                │
       └───────────────┴──────┬───────┴────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │  1. COLLECT         │
                    │                    │
                    │  • Session errors   │
                    │  • Discord feedback │
                    │  • GEO scores       │
                    │  • Cron job status   │
                    │  • Token usage       │
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │  2. ANALYZE         │
                    │                    │
                    │  • Pattern detection│
                    │  • Trend comparison │
                    │  • eval-criteria    │
                    │    self-review      │
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │  3. CLASSIFY        │
                    │                    │
                    │  Low Risk?──►Auto  │
                    │  High Risk?──►PR   │
                    └────┬──────────┬────┘
                         │          │
              ┌──────────▼──┐  ┌───▼────────────┐
              │ 4a. AUTO    │  │ 4b. PROPOSE     │
              │ APPLY       │  │                 │
              │             │  │ proposals/      │
              │ • lessons/  │  │  pending/*.md   │
              │ • metrics/  │  │                 │
              │ • eval-     │  │ ──► Jay Reviews │
              │   criteria  │  │ ──► Approve/    │
              │ • findings/ │  │     Reject      │
              └──────┬──────┘  └───┬─────────────┘
                     │             │
                     └──────┬──────┘
                            │
                  ┌─────────▼──────────┐
                  │  5. COMMIT & PUSH   │
                  │                    │
                  │  git add -A        │
                  │  git commit -m     │
                  │   'kaizen: ...'    │
                  │  git push origin   │
                  │   main             │
                  └─────────┬──────────┘
                            │
                  ┌─────────▼──────────┐
                  │  GitHub Repository  │
                  │  agent-knowledge    │
                  │                    │
                  │  findings/kaizen/  │ ◄── Reports accumulate
                  │  metrics/*.json    │ ◄── Trends build up
                  │  proposals/        │ ◄── Jay reviews PRs
                  │  lessons/*.md      │ ◄── Agents learn
                  └─────────┬──────────┘
                            │
                            │  Next Kaizen run pulls latest
                            │
                  ┌─────────▼──────────┐
                  │  git pull --rebase  │──► Back to Step 1
                  │  (start of next    │
                  │   Kaizen cycle)    │
                  └────────────────────┘
```

### Agent Lesson Flow (Continuous)

```
  Agent encounters problem
          │
          ▼
  Resolves it (or escalates to Jay)
          │
          ▼
  Records in lessons/{agent}.md
          │
          ▼
  git commit & push to agent-knowledge
          │
          ▼
  Next Kaizen run reads updated lessons
          │
          ▼
  Cross-references with other agents' lessons
          │
          ▼
  Detects patterns ──► Proposes systemic improvements
```

### Eval-Criteria Evolution

```
  eval-criteria.yaml (v1)
          │
          ▼
  Kaizen evaluates each criterion
          │
          ├── Metric meaningless? ──► Disable + record reason
          ├── New signal found?   ──► Add criterion + rationale
          └── Threshold off?      ──► Adjust based on 7-day trend
          │
          ▼
  eval-criteria.yaml (v1 → v2 → v3 ...)
  (version history tracked in Git)
```

## Structure

```
├── lessons/          # Per-agent lessons (direct commits)
│   ├── mother.md     # Mother 🫶 — Orchestrator
│   ├── walter.md     # Walter 🤖 — Work specialist
│   └── herald.md     # Herald 🔔 — Content herald
│
├── findings/         # Kaizen analysis reports
│   └── kaizen/       # Daily AM/PM reports
│
├── proposals/        # Improvement proposals
│   ├── pending/      # Awaiting approval
│   └── applied/      # Applied
│
├── recipes/          # Kaizen prompt version control
│
├── metrics/          # Quantitative data
│   ├── geo-trends.json
│   ├── agent-health.json
│   └── token-usage.json
│
├── shared/           # Shared agent resources
│   ├── templates/    # Shared templates
│   └── guidelines/   # Shared guidelines
│
└── creators/         # HypeProof Creator contributions (extensible)
    └── README.md
```

## Who Commits What?

| Actor | Path | Frequency |
|-------|------|-----------|
| **Mother** 🫶 | `lessons/mother.md` | As needed |
| **Walter** 🤖 | `lessons/walter.md` | As needed |
| **Herald** 🔔 | `lessons/herald.md` | As needed |
| **Kaizen** ♻️ | `findings/`, `proposals/`, `metrics/`, `recipes/` | Twice daily |
| **Creator** | `creators/{name}/` | Open |
| **Jay** | Anywhere | Approval/review |

## Commit Convention

```
<agent>: <type> — <description>

Examples:
mother: lesson — Watch for session disconnects on Gateway restart
kaizen: finding — GEO average score declining 3 days straight
kaizen: proposal — Suggest Herald guide wording improvement
walter: lesson — Manifest order matters in CCU2 builds
herald: lesson — Creator submissions often missing frontmatter
```

## Branch Strategy

- `main` — Verified knowledge only
- `kaizen/proposals` — Kaizen auto-proposals (reviewed via PR)
- `creator/{name}` — Creator contributions (merged via PR)

## Security Rules

⚠️ **Never commit:**
- API keys, tokens, passwords
- Company secrets (Sonatus internal code, customer info)
- Personal information (emails, phone numbers, real names)
- openclaw.json config

Walter records **general lessons only** in lessons (no specific code/config).

## Expansion Plan

1. **Phase 1** (current): 3 agents + Kaizen automation
2. **Phase 2**: HypeProof Creator participation (PR-based)
3. **Phase 3**: OpenClaw community sharing (templates/guidelines)

## License

MIT
