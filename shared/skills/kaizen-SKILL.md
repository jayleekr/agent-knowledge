# Kaizen ♻️ — Self-Improving & Self-Testing Agent

> 자가 테스트 → 자가 이슈 발행 → 자가 해결 → 성숙 시 멀티에이전트 통합 테스트
> Runs as a cron job via `claude --print`. Mother가 오케스트레이션.

## Overview

Kaizen은 **3단계 성숙도 모델**을 가진 자기 개선 루프:

```
Level 1: Self-Loop     — 자기 테스트 + 자기 이슈 해결
Level 2: Cross-Agent   — 다른 에이전트(Walter, Herald) 테스트
Level 3: System-Wide   — 전체 시스템 통합 테스트 + 자율 개선
```

## Git Repository

**Repo**: <https://github.com/jayleekr/agent-knowledge>
**Local**: `~/CodeWorkspace/side/agent-knowledge/`

Each Kaizen run:
1. `git pull` (fetch latest lessons)
2. Perform analysis + self-test
3. Commit + push to `findings/`, `metrics/`, `test-results/`
4. High-risk proposals go to `proposals/pending/`

## Execution

```bash
~/.openclaw/workspace/skills/kaizen/run.sh
```

---

## 🔄 Phase 1: Self-Test Loop (자가 테스트)

매 실행마다 카이젠이 자기 자신을 테스트:

### Self-Test Suite

```yaml
self_tests:
  - id: script_runnable
    name: "run.sh 실행 가능"
    check: "bash -n run.sh"  # syntax check
    auto_fix: false

  - id: eval_criteria_valid
    name: "eval-criteria.yaml 유효"
    check: "yaml lint + required fields"
    auto_fix: true  # 누락 필드 자동 추가

  - id: discord_access
    name: "Discord 채널 접근 가능"
    check: "message read last 1 from target channels"
    auto_fix: false

  - id: github_access
    name: "GitHub repo 접근 가능"
    check: "gh issue list --repo jayleekr/agent-knowledge --limit 1"
    auto_fix: false

  - id: report_generation
    name: "리포트 정상 생성"
    check: "report file exists + required sections present"
    auto_fix: true

  - id: no_regression
    name: "퇴화 없음"
    check: "eval-criteria scores vs previous report"
    auto_fix: false  # 이슈 발행

  - id: duplicate_prevention
    name: "중복 실행 방지"
    check: "same period report already exists → skip"
    auto_fix: true  # built into run.sh

  - id: git_push_success
    name: "agent-knowledge push 성공"
    check: "git push exit code"
    auto_fix: true  # retry once
```

### Self-Issue Lifecycle

```
테스트 실패 감지
  → GitHub Issue 자동 생성: [Kaizen] self-test: {test_id} failed
  → 라벨: agent:kaizen, self-test, priority:{auto}
  → 다음 실행 시 open 이슈 확인
    → auto_fix 가능 → 수정 시도 → 성공 시 close + comment
    → auto_fix 불가 → 3회 연속 실패 시 Jay 에스컬레이션
```

### Self-Test 결과 기록

```
memory/kaizen/self-test-results.json
{
  "last_run": "2026-02-21T11:00:00+09:00",
  "results": {
    "script_runnable": { "pass": true, "consecutive_fails": 0 },
    "eval_criteria_valid": { "pass": true, "consecutive_fails": 0 },
    ...
  },
  "maturity_score": 85,  // 0-100
  "level": 1             // 현재 성숙도 레벨
}
```

---

## 🤝 Phase 2: Cross-Agent Testing (에이전트 간 테스트)

**진입 조건**: `maturity_score >= 80` + Level 1 self-tests 전원 pass × 5연속

Mother가 오케스트레이션하여 다른 에이전트들을 테스트:

### Test Targets

```yaml
agent_tests:
  # ===== 🔴 최우선: 크론 상태 체크 (모든 에이전트) =====
  cron_health:
    - id: cron_error_check
      name: "전체 크론 에러 감지"
      method: |
        exec: openclaw cron list 2>&1
        → Status 컬럼에서 "error" 있는 행 전부 추출
        → 각 에러 크론의 runs 확인: openclaw cron runs --id <ID> --limit 1
        → 에러 원인 분류: announce_delivery | timeout | agent_error | unknown
      expect: "no error status cron jobs"
      on_fail: |
        각 에러 크론마다 GitHub Issue 발행:
        [Kaizen] cron-error: {크론이름} — {에러원인}
        라벨: agent:{owner}, cron-error, priority:high
      auto_fix: |
        - announce delivery failed → 채널 연결 문제 기록 + Jay 에스컬레이션
        - timeout → 태스크 복잡도 기록 + 단순화 제안
        - agent error → 세션 로그 확인 후 원인 분석

    - id: cron_staleness_check
      name: "크론 실행 지연 감지"
      method: |
        openclaw cron list → Last 컬럼 확인
        → 예정 시간 대비 실행 안 된 크론 감지
      expect: "all cron jobs ran within expected window"

  # ===== Walter =====
  walter:
    - id: walter_cron_health
      name: "Walter 크론잡 상태"
      method: "openclaw cron list → Walter agent 크론 중 error 확인"
      expect: "all Walter crons: ok"
      priority: critical

    - id: walter_session_health
      name: "Walter 세션 정상 작동"
      method: "sessions_list → Walter 최근 세션 확인"
      expect: "active session within last 24h (weekday)"

    - id: walter_github_tracker
      name: "GitHub Tracker 크론 정상"
      method: "memory/github-daily-*.md 존재 확인"
      expect: "today's file exists (weekday)"

    - id: walter_self_reporting
      name: "Walter 자기비판 작동"
      method: "gh issue list --repo jayleekr/agent-knowledge --label agent:walter"
      expect: "Walter가 이슈를 발행한 적 있는지 확인 (없으면 경고)"

  # ===== Herald =====
  herald:
    - id: herald_session_health
      name: "Herald 세션 정상 작동"
      method: "sessions_list → Herald 활성 여부"
      expect: "responsive to Discord messages"

    - id: herald_response_quality
      name: "Herald Creator 대응 적절성"
      method: "최근 Herald 응답 내용 검토"
      expect: "correct frontmatter (creator not author), friendly tone"

    - id: herald_issue_reporting
      name: "Herald 이슈 보고 작동"
      method: "Herald 세션에서 🎫 ISSUE REPORT 패턴 검색"
      expect: "Herald가 문제 보고를 하고 있는지 확인"

  # ===== Mother =====
  mother:
    - id: mother_cron_health
      name: "Mother 크론잡 전체 정상"
      method: "openclaw cron list → Mother agent 크론 중 error 확인"
      expect: "all Mother crons: ok"
      priority: critical

    - id: mother_heartbeat_active
      name: "Heartbeat 정상 작동"
      method: "heartbeat-state.json lastHeartbeat 확인"
      expect: "< 2h ago"

    - id: mother_memory_current
      name: "메모리 최신 상태"
      method: "memory/YYYY-MM-DD.md 오늘 파일 존재"
      expect: "exists with content"

    - id: mother_self_reporting
      name: "Mother 자기비판 작동"
      method: "gh issue list --repo jayleekr/agent-knowledge --label agent:mother"
      expect: "Mother가 이슈를 발행한 적 있는지 확인"
```

### Cross-Agent Test 실행 방식

**핵심: `openclaw cron list` 파싱이 최우선!**

1. `openclaw cron list` 실행 → error 상태 크론 전부 감지
2. 각 error 크론 → `openclaw cron runs --id <ID> --limit 1` → 원인 파악
3. 에이전트별 세션 상태 확인 (sessions_list)
4. 각 에이전트 자기비판 이력 확인 (GitHub Issues)
5. 에이전트 간 통신 정상 여부

실패 시:
- GitHub Issue 발행: `[Kaizen] agent-test: {agent}/{test_id} failed`
- 라벨: `agent:{agent}, cross-test, priority:{severity}`
- Mother에게 알림 → Mother가 해당 에이전트 디버깅 시도
- 3회 연속 실패 → Jay 에스컬레이션

---

## 🌐 Phase 3: System-Wide Integration (전체 통합 테스트)

**진입 조건**: `maturity_score >= 90` + Level 2 전원 pass × 10연속

### Integration Test Scenarios

```yaml
integration_tests:
  - id: e2e_content_pipeline
    name: "콘텐츠 파이프라인 E2E"
    scenario: |
      1. Mother가 테스트 콘텐츠 생성 지시
      2. Herald가 제출 감지 + GEO 채점
      3. Peer review 프로세스 작동 확인
      4. 최종 publish 흐름 검증
    agents: [mother, herald]
    frequency: weekly

  - id: e2e_morning_routine
    name: "모닝 루틴 E2E"
    scenario: |
      1. Mother 모닝 크론 실행
      2. Walter 브리핑 생성
      3. 각 채널 전달 확인
    agents: [mother, walter]
    frequency: weekly

  - id: e2e_incident_response
    name: "장애 대응 E2E"
    scenario: |
      1. 의도적 경미한 이상 상황 생성
      2. 에이전트들이 감지하는지 확인
      3. 에스컬레이션 경로 검증
    agents: [mother, walter, herald]
    frequency: monthly

  - id: cross_agent_communication
    name: "에이전트 간 통신"
    scenario: |
      1. Mother → Walter 태스크 위임
      2. Walter 완료 → Mother 수신 확인
      3. 결과 정확도 검증
    agents: [mother, walter]
    frequency: weekly
```

---

## 📊 Maturity Score 계산

```yaml
maturity_scoring:
  level_1:  # Self-Loop (0-100)
    self_test_pass_rate: 40%      # 전체 self-test 통과율
    issue_resolution_rate: 20%    # 자가 이슈 해결률
    report_quality: 20%           # 리포트 필수 섹션 충족
    eval_criteria_evolution: 10%  # criteria 자기 수정 횟수
    no_regression: 10%            # 퇴화 미발생 연속 횟수

  level_2:  # Cross-Agent (requires level_1 >= 80)
    agent_test_pass_rate: 40%
    cross_issue_resolution: 25%
    agent_health_monitoring: 20%
    false_positive_rate: 15%      # 오탐 비율 (낮을수록 좋음)

  level_3:  # System-Wide (requires level_2 >= 90)
    e2e_pass_rate: 40%
    incident_detection: 25%
    recovery_time: 20%
    system_stability: 15%
```

---

## 🛡️ Safety Rails

### 절대 자동 적용 금지
- openclaw.json 수정
- 크론 스케줄 변경 (제안만, Jay 승인)
- 에이전트 SOUL.md / IDENTITY.md 수정
- Discord 채널 구조 변경
- 포인트/규칙 변경

### 에스컬레이션 규칙
- self-test 3회 연속 실패 → Jay DM
- cross-agent test 2회 연속 실패 → Jay DM + 상세 로그
- integration test 실패 → 즉시 Jay DM
- maturity_score 10점 이상 하락 → Jay DM

### 테스트 격리
- E2E 테스트용 콘텐츠는 `[TEST]` 접두사 필수
- 테스트 이슈는 `self-test` 또는 `cross-test` 라벨 필수
- 테스트로 인한 실제 서비스 영향 금지

---

## Two Improvement Flows

### Flow A: Agent-Initiated Issues (Real-Time)
Any agent can file a GitHub Issue immediately when encountering a problem:
```bash
gh issue create --repo jayleekr/agent-knowledge \
  --title "[Mother] Description of the problem" \
  --body "## Reporter\nMother 🫶\n\n## Type\nbug\n\n## Priority\nnormal\n\n## Description\n..." \
  --label "agent:mother,priority:normal,bug"
```

### Flow B: Kaizen Self-Test → Self-Issue → Self-Resolve (Automated)
Kaizen files issues for its own failures, then resolves them next run.

### Flow C: Cross-Agent Testing (Level 2+)
Mother orchestrates tests on Walter/Herald, files issues for failures.

## Data Sources (Collectors)

### 0. Open GitHub Issues + Self-Test Results
### 1. Creator Feedback (Discord)
### 2. Agent Session Logs
### 3. GEO Quality Trends
### 4. Skill Execution Status
### 5. System Health
### 6. Cross-Agent Health (Level 2+)

## Analysis & Output

```
memory/kaizen/YYYY-MM-DD-{am|pm}.md          # 분석 리포트
memory/kaizen/self-test-results.json          # 자가 테스트 결과
memory/kaizen/agent-test-results.json         # 에이전트 테스트 결과 (L2+)
memory/kaizen/integration-test-results.json   # 통합 테스트 결과 (L3+)
memory/kaizen/maturity-history.json           # 성숙도 추이
```

### Report Structure (확장)
```markdown
# Kaizen Report — {date} {AM/PM}

## 📊 Collection Summary
## 🧪 Self-Test Results (Level 1)
## 🤝 Agent Test Results (Level 2+)
## 🌐 Integration Test Results (Level 3+)
## 🔍 Findings
## 💡 Proposals
## ✅ Auto-Applied
## ⏳ Pending Jay's Approval
## 📈 Trends
## 🔧 eval-criteria Changes
## 🎫 Issue Triage (filed / resolved / escalated)
## 📊 Maturity Score: {score}/100 (Level {N})
```

## 🔧 Issue Resolution Loop (자동 해결)

매 Kaizen 실행 시 **이슈 발행 후 → 해결 시도** 루프:

```
gh issue list --repo jayleekr/agent-knowledge --state open
        ↓
각 이슈 분류: auto-resolvable vs needs-jay
        ↓
auto-resolvable → 해결 시도 → 성공 시 close + comment
        ↓
needs-jay → 3회 이상 미해결 시 Jay 에스컬레이션
```

### Auto-Resolvable 기준

| 이슈 유형 | 해결 방법 |
|-----------|----------|
| cron announce delivery failed | `openclaw cron update --id <ID> --channel last` 적용 → 수동 실행 → 성공 시 close |
| config 관련 (이미 수정됨) | 현재 상태 확인 → 문제 없으면 close + "이미 해결됨" 코멘트 |
| token tracker 부정확 | 크론 메시지 수정 → 수동 실행 → 정상 출력 시 close |
| self-test auto_fix 항목 | 자동 수정 후 close |
| 중복 이슈 | 원본 참조 후 close as duplicate |
| Herald issue reporting fail | Herald SOUL.md에 자기비판 규칙 존재 확인 → 없으면 추가 제안 이슈 발행 |

### NOT Auto-Resolvable (needs-jay)

- openclaw.json 수정 필요한 건 (config 보호 규칙)
- 권한/정책 변경
- 새 크론 생성/삭제
- 에이전트 SOUL.md 구조 변경

### Resolution Flow

```yaml
resolution_loop:
  trigger: "매 Kaizen 실행 시 (self-test 후)"
  steps:
    1. gh issue list --state open --label "agent:kaizen OR agent:mother OR agent:walter OR agent:herald"
    2. 각 이슈에 대해:
       a. 이슈 body 읽기 (gh issue view <number>)
       b. auto-resolvable 판단
       c. 해결 시도
       d. 성공 → gh issue close <number> -c "✅ Auto-resolved by Kaizen: {설명}"
       e. 실패 → retry_count++ → 3회 실패 시 label "needs-jay" 추가
    3. 해결 통계 → 리포트에 포함
  max_resolve_per_run: 3  # 한 실행당 최대 3개 해결 (토큰 절약)
```

### Knowledge Extraction (이슈 → 지식 변환)

이슈 해결 후 반드시:
1. **lessons/{agent}.md에 append** — 날짜, 컨텍스트, 교훈, 액션
2. **관련 에이전트 SOUL.md에 규칙 추가** (재발 방지용, high-risk는 Jay 승인)
3. **eval-criteria.yaml 업데이트** (새 테스트 기준이 필요하면)

```yaml
knowledge_extraction:
  trigger: "이슈 close 시"
  format: |
    - **{date}**: {한 줄 요약}
      - Context: {상황}
      - Lesson: {교훈}
      - Action: {적용한 조치}
  targets:
    - lessons/{agent}.md  # 항상
    - SOUL.md             # 재발 방지 규칙이면
    - eval-criteria.yaml  # 새 테스트 기준이면
```

### Knowledge Sync (매 실행 시)

매 Kaizen 실행 마지막에 반드시:
```bash
bash ~/CodeWorkspace/side/agent-knowledge/ops/sync-knowledge.sh
```
이 스크립트는:
- Mother/Herald/Walter SOUL.md → shared/agents/
- 주요 스킬 SKILL.md → shared/skills/
- memory 파일 (creators DB, token-usage) → memory/
- eval-criteria.yaml 최신화
- 변경 있으면 자동 commit + push

### Resolution Stats (리포트에 포함)

```markdown
## 🎫 Issue Resolution
- Open: {N} | Resolved this run: {N} | Failed: {N}
- Resolution rate (30d): {N}%
- Oldest unresolved: #{N} ({days}d old)
```

---

## Auto-Apply Rules

### Auto OK (Low Risk)
- lessons.md updates
- GEO checklist wording improvements
- Guide message typo/clarity fixes
- eval-criteria adjustments
- Self-test auto_fix items

### Requires Jay's Approval (High Risk)
- Skill logic changes
- Cron schedule changes
- Agent config changes
- Points/Anti-gaming rule changes
- Discord channel structure changes
- Level promotion (1→2, 2→3)

## Evaluation Criteria (Self-Evolving)

See `eval-criteria.yaml`. Kaizen reviews and may add/modify/disable criteria each run.

**Self-Evolution**: Each run, review eval-criteria.yaml and:
- Meaningless criteria → disable + record reason
- New criteria needed → add + record rationale
- Threshold adjustment → based on trend data
