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

- **2026-02-22**: isolated 크론 세션에서 sessions_list는 자기 세션만 보임
  - Context: Token tracker가 자기 토큰만 추적, 전체 시스템 사용량 누락
  - Lesson: isolated 크론에서 다른 에이전트 세션 조회 불가 (sessions_list 도구 제한)
  - Action: exec로 `openclaw sessions --active 1440 --json` CLI 호출하여 우회

- **2026-02-22**: openclaw.json 직접 수정 시 Gateway 크래시
  - Context: agents.list[].auth.order, channels.discord.dmEnabled 등 스키마에 없는 키 추가
  - Lesson: Zod strict() 검증으로 unknown key → 시작 실패
  - Action: 반드시 `openclaw config set` CLI 사용, SOUL.md에 보호 규칙 추가

- **2026-02-22**: 에이전트 간 텍스트 이름 호출은 무효
  - Context: "Herald, 진행하세요"라고 썼으나 Herald 트리거 안 됨 (2회 반복)
  - Lesson: allowBots 설정된 봇은 Discord 맨션(<@ID>)만 감지, 텍스트 이름 무시
  - Action: SOUL.md에 맨션 규칙 추가, content-nudge SKILL.md에도 반영
