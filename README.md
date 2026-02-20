# 🧠 Agent Knowledge Base

> Shared knowledge repository for AI agents. Manages lessons, findings, proposals, and metrics via Git.
> Powered by [OpenClaw](https://openclaw.ai) + Kaizen ♻️

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
