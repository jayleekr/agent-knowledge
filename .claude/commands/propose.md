# propose

Create a new proposal in proposals/pending/.

## Usage

```
/propose <description>
```

`$ARGUMENTS` = proposal description (used as the title)

## Steps

1. Determine the next proposal ID:
   - Count existing files in `proposals/pending/` and `proposals/applied/`
   - Format: `PROP-{YYYYMMDD}-{NNN}` (NNN = zero-padded 3-digit sequence)
   - Use today's date

2. Create the proposal file at `proposals/pending/PROP-{date}-{NNN}.md`:

```markdown
# Proposal: {description}
- ID: PROP-{YYYYMMDD}-{NNN}
- 제안자: Kaizen ♻️
- 영향도: High | Med | Low
- 대상: {어떤 스킬/설정/워크플로우}
- 현재: {현재 상태}
- 제안: {변경 내용}
- 근거: {데이터/분석 기반 이유}
- 리스크: {잠재적 부작용}
```

3. Fill in the proposal details based on $ARGUMENTS and current context.

4. Report the created file path and ID.

## Notes
- Proposals require Jay's approval before being applied
- After approval, move to proposals/applied/ and update status
- High-risk proposals must go through PR (see PROTOCOL.md)
