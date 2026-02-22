#!/bin/bash
# sync-knowledge.sh — Mother workspace → agent-knowledge repo 동기화
# Kaizen 실행 시 호출

set -e
REPO=~/CodeWorkspace/side/agent-knowledge
WORKSPACE=~/.openclaw/workspace

# 1. lessons & memory 싱크
cp -f "$WORKSPACE/memory/hypeproof-creators.json" "$REPO/memory/" 2>/dev/null || true
cp -f "$WORKSPACE/memory/token-usage.md" "$REPO/memory/" 2>/dev/null || true

# 2. 스킬 설정 싱크 (SKILL.md만, 스크립트 제외)
mkdir -p "$REPO/shared/skills"
for skill in kaizen content-nudge herald-ops; do
  if [ -f "$WORKSPACE/skills/$skill/SKILL.md" ]; then
    cp -f "$WORKSPACE/skills/$skill/SKILL.md" "$REPO/shared/skills/$skill-SKILL.md"
  fi
done

# 3. 에이전트 SOUL/IDENTITY 싱크
mkdir -p "$REPO/shared/agents"
cp -f "$WORKSPACE/SOUL.md" "$REPO/shared/agents/mother-SOUL.md" 2>/dev/null || true
cp -f "$WORKSPACE/IDENTITY.md" "$REPO/shared/agents/mother-IDENTITY.md" 2>/dev/null || true

# Herald & Walter workspace
for agent in herald walter; do
  ws="$HOME/.openclaw/workspace-$agent"
  if [ -f "$ws/SOUL.md" ]; then
    cp -f "$ws/SOUL.md" "$REPO/shared/agents/${agent}-SOUL.md"
  fi
done

# 4. eval-criteria 싱크
cp -f "$WORKSPACE/skills/kaizen/eval-criteria.yaml" "$REPO/eval-criteria.yaml" 2>/dev/null || true

# 5. git commit + push (변경 있을 때만)
cd "$REPO"
git add -A
if ! git diff --cached --quiet; then
  git commit -m "sync: knowledge files from workspace $(date +%Y-%m-%d\ %H:%M)"
  git push
  echo "SYNCED"
else
  echo "NO_CHANGES"
fi
