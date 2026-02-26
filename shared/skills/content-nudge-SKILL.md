---
name: content-nudge
description: "HypeProof 칼럼 게시 후 크리에이터 참여 유도 시스템. 칼럼에 전문성 매칭 질문으로 크리에이터 참여 촉진. column-pipeline(칼럼 제작 넛지)과는 별도 역할."
updated: 2026-02-26
---

# Content Nudge — 칼럼 참여 유도 시스템

> **역할 구분**
> - `column-pipeline`: 칼럼 **제작** 넛지 (크리에이터에게 주제 제안 → 직접 쓰게 유도)
> - `content-nudge` (이 스킬): 칼럼 **게시 후** 참여 유도 (맨션 질문 → 토론 촉진)

## 플로우

```
칼럼 게시 완료 (#daily-research)
        ↓
크리에이터 맨션 (전문성 매칭 질문)
        ↓
리액션/답변 추적 → creators DB 업데이트
        ↓
축적된 관심사 → column-pipeline 넛지에 활용
```

## 맨션 규칙

### 크리에이터 맨션 (칼럼 완성 후)
1. **구체적 질문만** — "어떻게 생각하세요?" 금지
2. **전공 기반** — 그 사람만 답할 수 있는 질문
3. **부담 없는 톤** — 한두 줄 답변 OK 분위기
4. **로테이션** — 같은 사람에게 연속 맨션 금지 (최소 2일 간격)

### 질문 예시

```
@신진 님, MCP 보안 취약점 글인데 — 프론트엔드 쪽에서
서드파티 API 연동할 때 비슷한 리스크 느끼신 적 있어요?

@RyanKim 님, AI 코딩 도구 비교 글이에요 —
실제로 써보신 것 중 체감 차이가 컸던 게 뭐였어요?
```

## 크리에이터 DB

경로: `memory/hypeproof-creators.json`

### 필드
- `expertise`: 전공/강점 (매칭 키)
- `interests`: 리액션/대화에서 추출한 관심사
- `reactions`: 리액션 이력 `[{date, column, emoji}]`
- `articles`: 작성한 글 목록
- `nudgeHistory`: 맨션 이력 `[{date, column, question, responded}]`

### 업데이트 시점
- 칼럼 포스팅 후 맨션 시 → nudgeHistory 추가
- 리액션 감지 시 → reactions 추가, interests 갱신
- 답변 감지 시 → nudgeHistory.responded = true

## Herald 무응답 Nudge 시스템

> 이것은 **칼럼 참여 질문**에 대한 무응답 처리. column-pipeline의 **칼럼 제작 넛지**와는 별개.

### 에스컬레이션 단계

| 시점 | 액션 | 톤 |
|------|------|-----|
| **1시간** | 체크인 | 친근 — "혹시 의견 있으면 편하게!" |
| **6시간** | 리마인더 | 격려 — "한두 줄도 OK" |
| **24시간** | 마지막 넛지 | 이해 — "이번은 패스해도 돼!" |
| **24시간+** | 자동 클로즈 | 스레드 닫고 Kaizen 이슈 |

### 실행 규칙
1. **같은 스레드에서 Nudge** — DM 아닌 원래 스레드
2. **Nudge 간 최소 간격**: 1시간
3. **하루 최대 Nudge**: 크리에이터 1인당 2회
4. **야간 금지**: 23:00~08:00 KST
5. **연속 무응답 3회 → 2주 쿨다운**

### Kaizen 이슈 연동

무응답 24시간 초과 시:
```bash
gh issue create --repo jayleekr/agent-knowledge \
  --title "[Herald] 크리에이터 무응답: {username} — {column}" \
  --body "..." \
  --label "agent:herald,nudge:timeout,creator:{username}"
```

### Kaizen 학습 루프

Kaizen이 `nudge:timeout` + `nudge:success` 분석하여:
1. 크리에이터별 최적 Nudge 시간 학습
2. 질문 난이도 조절
3. 참여율 예측
4. 월간 리포트

## column-pipeline 연동

content-nudge에서 축적된 크리에이터 관심사/참여 데이터는 column-pipeline이 활용:
- **주제 제안 시**: 크리에이터의 interests + 최근 반응 주제 참고
- **넛지 타이밍**: Kaizen 학습 결과 반영
- **쿨다운 공유**: content-nudge 쿨다운 중인 크리에이터는 column-pipeline에서도 감안
