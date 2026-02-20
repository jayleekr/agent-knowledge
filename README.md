# 🧠 Agent Knowledge Base

> AI 에이전트들의 공유 지식 저장소. 교훈, 발견, 개선 제안, 메트릭을 Git으로 관리.
> Powered by [OpenClaw](https://openclaw.ai) + Kaizen ♻️

## 구조

```
├── lessons/          # 에이전트별 교훈 (직접 커밋)
│   ├── mother.md     # Mother 🫶 — 총괄
│   ├── walter.md     # Walter 🤖 — 업무 전담
│   └── herald.md     # Herald 🔔 — 콘텐츠 전령
│
├── findings/         # Kaizen 분석 리포트
│   └── kaizen/       # 일별 AM/PM 리포트
│
├── proposals/        # 개선 제안
│   ├── pending/      # 승인 대기
│   └── applied/      # 적용 완료
│
├── recipes/          # Kaizen 프롬프트 버전 관리
│
├── metrics/          # 정량 데이터
│   ├── geo-trends.json
│   ├── agent-health.json
│   └── token-usage.json
│
├── shared/           # 에이전트 공용 리소스
│   ├── templates/    # 공용 템플릿
│   └── guidelines/   # 공용 가이드라인
│
└── creators/         # HypeProof Creator 기여 (확장용)
    └── README.md
```

## 누가 뭘 커밋하나?

| 주체 | 경로 | 빈도 |
|------|------|------|
| **Mother** 🫶 | `lessons/mother.md` | 수시 |
| **Walter** 🤖 | `lessons/walter.md` | 수시 |
| **Herald** 🔔 | `lessons/herald.md` | 수시 |
| **Kaizen** ♻️ | `findings/`, `proposals/`, `metrics/`, `recipes/` | 매일 2회 |
| **Creator** | `creators/{name}/` | 자유 |
| **Jay** | 어디든 | 승인/리뷰 |

## 커밋 컨벤션

```
<agent>: <type> — <description>

예시:
mother: lesson — Gateway 재시작 시 세션 끊김 주의
kaizen: finding — GEO 평균 점수 3일 연속 하락
kaizen: proposal — Herald 가이드 문구 개선 제안
walter: lesson — CCU2 빌드 시 manifest 순서 중요
herald: lesson — Creator 제출 시 frontmatter 누락 패턴
```

## 브랜치 전략

- `main` — 검증된 지식만
- `kaizen/proposals` — Kaizen 자동 제안 (PR로 리뷰)
- `creator/{name}` — Creator 기여 (PR로 머지)

## 보안 규칙

⚠️ **절대 커밋하지 않을 것:**
- API 키, 토큰, 비밀번호
- 회사 기밀 (Sonatus 내부 코드, 고객 정보)
- 개인정보 (이메일, 전화번호, 실명)
- openclaw.json 설정

Walter는 lessons에 **일반적 교훈만** 기록 (구체적 코드/설정 X).

## 확장 계획

1. **Phase 1** (현재): 에이전트 3인 + Kaizen 자동화
2. **Phase 2**: HypeProof Creator 참여 (PR 기반)
3. **Phase 3**: OpenClaw 커뮤니티 공유 (템플릿/가이드라인)

## 라이선스

MIT
