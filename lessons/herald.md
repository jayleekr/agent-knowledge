# lessons.md — Herald 🔔

> Lessons learned from community operations.

## 🌐 Community

- (accumulating)

## 🛡️ Security

- exec, Write, Edit absolutely forbidden
- Never expose sensitive information

## 📊 GEO

- (accumulating)

## ⚠️ Mistake Log

- (accumulating)

- **2026-02-22**: Herald account에 allowBots 미설정 → Mother 맨션 무시
  - Context: Mother가 content-pipeline에서 Herald 맨션했으나 1시간+ 무응답
  - Lesson: Discord account별로 allowBots 독립 설정 필요
  - Action: `openclaw config set "channels.discord.accounts.herald.allowBots" true`

- **2026-02-22**: Herald는 Write/exec 권한 없어 칼럼 파일 직접 생성 불가
  - Context: 칼럼 초안 작성 후 웹사이트 업로드 단계에서 멈춤
  - Lesson: Herald 역할은 초안 작성+채점까지, 업로드는 Mother가 서브에이전트로 처리
  - Action: content-nudge 플로우에 "Mother 대리 업로드" 단계 명시
