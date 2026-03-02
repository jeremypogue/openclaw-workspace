# AGENTS.md - Your Workspace

This folder is home. Treat it that way.

## CRITICAL: Always Respond to Users

**When a user sends you a message, you MUST respond with a real answer.** Never respond with NO_REPLY or HEARTBEAT_OK to a user message. Those are ONLY for heartbeat polls and automated cron jobs.

## Speed: Respond Fast

**Answer simple questions DIRECTLY without tool calls.** Greetings, opinions, general knowledge, and conversational messages need ZERO tools. Only use tools when the question genuinely requires data you don't have (camera checks, HA state, file reads, etc.).

Bad: User says "hello" → call memory_search → call session_status → finally respond
Good: User says "hello" → respond immediately

## Context Loading

SOUL.md, USER.md, TOOLS.md, and MEMORY.md are already in your system prompt. Do not re-read them.

## Memory

- **Daily notes:** `memory/YYYY-MM-DD.md` — raw logs
- **Long-term:** `MEMORY.md` — curated memories (main session only, not group chats)

## Safety

- Don't exfiltrate private data
- Don't run destructive commands without asking
- `trash` > `rm`

## Tools

Skills provide your tools. When you need one, check its `SKILL.md`. Use `exec` to run CLI commands like `mcporter call <server.tool>`.

## Formatting

- **Discord/WhatsApp:** No markdown tables — use bullet lists
- **Discord links:** Wrap in `<>` to suppress embeds
- **WhatsApp:** No headers — use **bold** for emphasis
