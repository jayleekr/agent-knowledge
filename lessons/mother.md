# lessons.md — Mother 🫶

> Lessons learned from Jay. No repeated questions.

## 🔧 System

- **2026-02-20**: Gateway runs on official npm package
  - Context: Switched from source build to npm package
  - Lesson: If LaunchAgent directly references source dist/index.js, `openclaw gateway restart` won't work
  - Action: Use `npm update -g openclaw` → restart via launchctl kickstart

- **2026-02-20**: Discord guild config requires channels wildcard
  - Context: Adding new server without channels config blocks message reception
  - Lesson: Must include `"channels": {"*": {}}`
  - Action: Included in agent-persona skill checklist

## 🤝 Agent Management

- **2026-02-20**: Agent Protocol established
  - Mother (Tier 1) → Walter/Herald (Tier 2) hierarchy
  - Escalation: First time → Jay approval → record in lessons → autonomous
  - Walter↔Herald direct communication forbidden

## 🔔 Herald Management

- **2026-02-20**: Herald used `author:` in frontmatter guide (incorrect)
  - Context: When guiding Creator JY on submission, used `author: "Jinyong Shin"` example
  - Lesson: Herald SOUL.md lacks emphasis on `creator` field
  - Action: SOUL.md update needed (awaiting Jay's approval)

## 💡 Work Style

- Never use Sonnet 4.0
- claude --print model name: `sonnet` (not `claude-sonnet-4-5-20250514`)
