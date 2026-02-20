# lessons

Show lessons learned for an agent (or all agents).

## Usage

```
/lessons [agent_name]
```

`$ARGUMENTS` = agent name (optional; default: show all)

## Steps

1. If `$ARGUMENTS` is provided and non-empty:
   - Read `lessons/{agent}.md`
   - Display its contents with formatting

2. If `$ARGUMENTS` is empty or "all":
   - Read all files in `lessons/`
   - Display each with a header separator

## Available Agents

- `herald` → lessons/herald.md
- `mother` → lessons/mother.md
- `walter` → lessons/walter.md

## Output Format

```
=== Lessons: {agent} ===
{file contents}

=== Lessons: {agent2} ===
{file contents}
```

## Notes
- Each agent owns their own lessons file (see PROTOCOL.md)
- New lessons are added by the owning agent directly to main (or via PR for Herald)
