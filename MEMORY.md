# MEMORY.md - Long-Term Memory

## Property

30-acre rural KY farm (Hopkinsville). Horse farm + fabrication lab + AI/energy testbed. 28 UniFi Protect cameras. Home Assistant, pool/spa controller, relay boards.

## Animals

- **Dozer** — Boxer dog (fawn/brown, dark face mask). Only boxer on property.
- **Nona** — Percheron draft horse. Very large, solid black, NO white markings.
- **Cruella** — Black horse with white star/blaze on face.
- **Scooby** — Black horse with one white foot, no face markings.
- Unknown dog on property = immediate Telegram alert (threat to horses).

## Active Projects

- Steel roof trusses (24ft span, 2x2 14ga tube, CNC-cut gussets)
- 75kW solar + 100kWh LiFePO4 battery (Victron, ITC optimization)
- Autonomous stall-cleaning robot
- Local AI ecosystem (Ollama, HA, MCP, edge devices)

## Technical Preferences

Imperial measurements (except steel thickness = metric). Code: Go, Python, JS. Linux CLI, Docker, offline-first. Edge-first architecture. No cloud dependency unless justified.

## Response Rules

1. Act as embedded co-engineer, not chatbot
2. Skip foundational explanations — exact specs, NEC refs, AWG sizing
3. Be concise — mobile and shop monitor friendly
4. Push back if technically incorrect
5. Account for hand stability (bilateral carpal tunnel, tremors)
6. Address him as "sir" when appropriate

## Infrastructure

- OpenClaw v2026.2.9 on WSL2, port 18789, systemd
- Ollama serving cloud-proxied models (qwen3-vl:235b-instruct-cloud)
- 6 MCP servers via mcporter daemon
- Telegram bot active
- Animal Tracker cron (every 10 min) logs to animal-sightings.jsonl

## OpenClaw Stability Notes

- Lane timeout patch applied to reply-DptDUVRg.js (prevents gateway deadlock)
- Compat config required for Ollama models (supportsStore/supportsDeveloperRole/supportsReasoningEffort: false, maxTokensField: max_tokens)
- After OpenClaw updates: re-run patches, verify compat config
