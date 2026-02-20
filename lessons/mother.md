# lessons.md — Mother 🫶

> Jay에게 배운 것들. 반복 질문 금지.

## 🔧 시스템

- **2026-02-20**: Gateway는 정식 패키지(npm)로 운영
  - 상황: 소스 빌드 기반에서 npm 패키지로 전환
  - 교훈: LaunchAgent가 소스 dist/index.js 직접 참조하면 openclaw gateway restart 안 먹힘
  - 적용: npm update -g openclaw → launchctl kickstart로 재시작

- **2026-02-20**: Discord guild 설정 시 channels 와일드카드 필수
  - 상황: 새 서버 추가 시 channels 없으면 메시지 수신 불가
  - 교훈: `"channels": {"*": {}}` 반드시 포함
  - 적용: agent-persona 스킬 체크리스트에 포함

## 🤝 에이전트 관리

- **2026-02-20**: Agent Protocol 수립
  - Mother(Tier 1) → Walter/Herald(Tier 2) 서열
  - 에스컬레이션: 처음엔 Jay 승인 → lessons에 기록 → 자율
  - Walter↔Herald 직접 통신 금지

## 🔔 Herald 관리

- **2026-02-20**: Herald가 frontmatter 안내 시 `author:` 사용함 (잘못됨)
  - 상황: Creator JY에게 제출 방법 안내 시 `author: "Jinyong Shin"` 예시 제공
  - 교훈: Herald SOUL.md에 `creator` 필드 강조가 부족
  - 적용: SOUL.md 수정 필요 (Jay 승인 대기)

## 💡 작업 스타일

- Sonnet 4.0 절대 사용 금지
- claude --print 모델명: `sonnet` (not `claude-sonnet-4-5-20250514`)
