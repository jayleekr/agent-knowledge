---
name: herald-ops
description: Herald 🔔 운영 관리. Herald agent 설정, 채널 관리, GEO QA 파이프라인, Creator 온보딩, 트러블슈팅 시 사용. Herald 관련 설정 변경, 장애 대응, 콘텐츠 파이프라인 운영 시 트리거.
---

# Herald 🔔 Operations

## 아키텍처

- **Agent**: Herald (OpenClaw multi-agent)
- **모델**: Sonnet 4.5
- **Workspace**: `~/.openclaw/agents/herald/workspace/` (workspace-herald)
- **Guild**: HypeProof Lab (`1457738053895328004`)
- **봇 Discord ID**: `1472187695835910236`

## 채널 구성

| 채널 | ID | 용도 |
|------|-----|------|
| #content-pipeline | `1471863670718857247` | GEO 콘텐츠 제출/QA |
| #creative-workshop | `1471863673885556940` | 크리에이티브 작업 |
| #공지사항 | `1458308725529120769` | 공지 발행 |

## 도구 제한 (화이트리스트)

```
allow: Read, web_fetch, message, memory_search, memory_get, image
```

exec, Write, Edit, gateway, cron, sessions_send, sessions_spawn 모두 차단.

## GEO QA 파이프라인

```
Creator 제출 → Herald 자동 분석 → 피드백 제공
    ↓ (수정 필요 시)
Creator 수정 → 재제출 → Herald 재분석
    ↓ (70점+ 통과)
Mother(main agent) 최종 승인
```

## Creator 온보딩

1. Discord HypeProof Lab 서버 초대
2. Creator 역할 부여
3. #content-pipeline 채널 안내 및 제출 프로토콜 설명

## 세션 관리

- **채널당 1세션**: 모든 유저가 공유하는 단일 세션
- 세션 키 예: `agent:herald:discord:guild:1471863670718857247`
- 개인별 대화 분리 없음 — 채널 맥락으로 구분

## 채널 추가/제거

1. `openclaw.json` → herald account의 `guilds.channels`에 채널 ID 추가/제거
2. `bindings`에 해당 채널-herald 매핑 추가/제거
3. SIGUSR1 리로드: `kill -USR1 $(pgrep -f "openclaw gateway")`

## 트러블슈팅: Herald 미응답

```bash
# 1. 로그 확인
tail -50 ~/.openclaw/logs/*.log | grep -E "herald|ROUTE|PREFLIGHT"

# 2. channelConfig 확인 — 해당 채널이 herald account guilds에 포함?
grep -A5 "1471863670718857247" ~/.openclaw/openclaw.json

# 3. binding 확인 — agent: herald 매핑 존재?
grep -B2 -A5 '"herald"' ~/.openclaw/openclaw.json | grep -A5 binding

# 4. 세션 상태 확인
cat ~/.openclaw/agents/herald/sessions/sessions.json | node -p "JSON.stringify(JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')),null,2)"
```

체크리스트:
- [ ] Herald bot이 해당 채널에 메시지 읽기 권한 있음
- [ ] account guilds.channels에 채널 ID 포함
- [ ] bindings에 채널-herald 매핑 존재
- [ ] preflight 로그에 차단 없음
- [ ] 세션이 stale하지 않음 (deliveryContext 정상)

## 콘텐츠 제출 프로토콜

현재: Creator가 #content-pipeline에 직접 제출 → Herald 분석.

향후: Writer Agent 연동 시
```
Writer Agent 초안 작성 → #content-pipeline 제출 → Herald QA → 피드백 루프 → 통과 → Mother 승인 → 발행
```

---

## 📋 Mother ↔ Herald 승인 프로토콜

### 전체 흐름

```
Herald: Peer Review 완료 (2/2 APPROVE)
  ↓ sessions_send → agent:main:main
Herald → Mother: [발행 승인 요청] SUB-{id} ...
  ↓ Mother 자동 검증 (GEO ≥ 70, 2 APPROVE)
Mother: /approve SUB-{id} 또는 /reject SUB-{id} [사유]
  ↓ scripts/approval_handler.py 실행
  ↓ 승인 시: scripts/publish_content.py 실행
Mother → Herald: [발행 승인 완료] SUB-{id} APPROVED
  ↓ sessions_send → agent:herald:discord:guild:...
Herald: 스레드에 승인 알림 + status 업데이트
```

### Herald → Mother 승인 요청 수신

Mother가 Herald로부터 `[발행 승인 요청]` 메시지를 수신하면:

1. **자동 파싱**: `scripts/approval_handler.py`로 메시지 파싱
2. **자동 검증**:
   - GEO Score ≥ 70 확인
   - Peer Review 2명(또는 Fast-track 1명) APPROVE 확인
3. **자동 승인 조건 충족 시**:
   - `scripts/publish_content.py` 실행 (콘텐츠 발행)
   - Herald에게 승인 결과 전달
   - #공지사항에 발행 알림
4. **자동 승인 조건 미충족 시**:
   - Mother(Jay)에게 수동 판단 요청
   - Jay가 `/approve` 또는 `/reject` 결정

### Mother → Herald 결과 전달

```bash
# 승인 전달
sessions_send target="agent:herald:discord:guild:1457738053895328004" \
  message="[발행 승인 완료] SUB-{id} APPROVED"

# 거절 전달
sessions_send target="agent:herald:discord:guild:1457738053895328004" \
  message="[발행 거절] SUB-{id} REJECTED | 사유: {reason}"
```

### /approve, /reject 명령어 처리 (Mother 측)

Mother가 메시지에서 다음 명령어를 감지하면 처리:

- `/approve SUB-{id}` → 승인 프로세스 실행
- `/reject SUB-{id} [사유]` → 거절 + Herald에 사유 전달

### 발행 자동화 (승인 후)

승인 시 `scripts/publish_content.py`가 실행:
1. 콘텐츠를 `~/CodeWorkspace/hypeproof/web/src/content/columns/ko/`에 저장
2. frontmatter 자동 생성
3. `git add + commit + push`
4. Notion Points DB에 발행 포인트 50P 적립
5. Discord #공지사항(`1458308725529120769`)에 발행 알림
