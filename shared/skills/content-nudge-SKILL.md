---
name: content-nudge
description: "HypeProof 칼럼 포스팅 후 크리에이터 맞춤 맨션 질문 시스템. Mother가 칼럼 올린 뒤 크리에이터 DB 기반으로 전공 매칭된 2~3명에게 맨션+맞춤질문. 리액션/답변 추적하여 DB 업데이트."
---

# Content Nudge — 칼럼 참여 유도 시스템

## 플로우

```
Mother 리서치 → #daily-research에 리서치만 쌓기 (맨션 없음)
        ↓
#content-pipeline에 "콘텐츠 시드" 포스트 + Jay 맨션
  (앵글 후보 제시 + 의견 유도)
        ↓
Jay 응답 → Herald가 칼럼 작성
        ↓
칼럼 완성 후 크리에이터 맨션 (전문성 매칭 질문)
        ↓
리액션/답변 추적 → creators DB 업데이트
        ↓
축적된 관심사로 글쓰기 유도 (Herald DM)
```

## 맨션 규칙

### 콘텐츠 시드 포스트 (content-pipeline)
1. **반드시 Herald(@1472187695835910236)를 맨션** — Herald가 Jay 응답을 감지하려면 맨션 필수
2. **Jay 맨션 + Herald 맨션** 둘 다 포함 — "Jay가 앵글 고르면 Herald가 칼럼 작성"
3. **리서치 원문은 링크로만** — #daily-research 메시지 URL 참조, 내용 복붙 금지

### Herald 태스크 전달 (Jay 응답 후)
1. **한 메시지에 모든 컨텍스트 포함** — 승인/지시/리서치링크/앵글을 분산하지 말 것
2. **구체적 태스크 목록** — "진행하세요"가 아니라 1,2,3 단계로 명시
3. **리서치 원문 링크 포함** — Herald가 별도 탐색 안 해도 되게

**템플릿:**
```
<@Herald> 칼럼 초안 작성 승인 완료. 지금 바로 진행해.

**태스크:**
1. 콘텐츠 시드: {시드 내용 or 링크}
2. 앵글: {선택된 앵글}
3. 리서치 원문: {daily-research 메시지 링크}
4. 기존 칼럼 스타일 참고해서 초안 작성
5. 자체 GEO QA 채점 후 이 채널에 초안 제출
```

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

## Mother 칼럼 크론 통합

Daily Research 크론 (`8a39c1f9`) 결과물에서:
1. 칼럼 후보 자동 선별 (주 2~3회)
2. 칼럼 작성 → 웹사이트 배포
3. #daily-research 포스팅
4. **content-nudge 실행** → 맨션 질문

## Herald 역할 (Phase 2)

축적된 DB 기반으로:
- 리액션 3회 이상 + 미작성 크리에이터에게 DM
- "이 주제로 칼럼 써보시겠어요? Mother가 초안 잡아드려요"
- 하루 1~2명, 로테이션
