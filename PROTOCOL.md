# PROTOCOL.md — Agent Knowledge 커밋 규칙

## 커밋 권한

### 직접 Push (main)
- **Mother**: `lessons/mother.md`, `shared/`
- **Walter**: `lessons/walter.md`
- **Kaizen**: `findings/`, `metrics/`, `recipes/`, `eval-criteria.yaml`

### PR 필수
- **Kaizen → proposals/**: PR 생성 → Jay 리뷰 (높은 리스크)
- **Herald**: `lessons/herald.md` (보안상 PR 권장)
- **Creator**: `creators/{name}/` → PR → Jay 또는 Mother 리뷰

### 자동 적용 (Kaizen)
낮은 리스크 변경은 Kaizen이 직접 main에 push:
- `eval-criteria.yaml` 항목 추가/threshold 조정
- `metrics/` 데이터 업데이트
- `findings/` 리포트 추가
- `recipes/` 새 버전 추가

### Jay 승인 필요
높은 리스크 변경은 PR로:
- `proposals/pending/` → PR → 승인 후 `proposals/applied/`로 이동
- `shared/guidelines/` 변경
- `PROTOCOL.md` 변경

## 파일 규칙

### lessons/{agent}.md
```markdown
# lessons.md — {Agent} {Emoji}

## {카테고리}
- **{날짜}**: {교훈 내용}
  - 상황: {무슨 일이 있었는지}
  - 교훈: {배운 것}
  - 적용: {앞으로 어떻게 할 것인지}
```

### findings/kaizen/{date}-{period}.md
Kaizen SKILL.md의 리포트 형식 따름.

### proposals/pending/{id}.md
```markdown
# Proposal: {제목}
- ID: PROP-{YYYYMMDD}-{NNN}
- 제안자: Kaizen ♻️
- 영향도: High | Med | Low
- 대상: {어떤 스킬/설정/워크플로우}
- 현재: {현재 상태}
- 제안: {변경 내용}
- 근거: {데이터/분석 기반 이유}
- 리스크: {잠재적 부작용}
```

## 충돌 방지

- 각 에이전트는 **자기 파일만** 수정
- Kaizen은 **자기 디렉토리만** 수정
- 공용 파일(`shared/`, `PROTOCOL.md`)은 PR로만

## 메트릭 포맷

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
