# MEMORY.md - Long-Term Memory

## Property

30-acre rural KY farm (Hopkinsville). Horse farm + fabrication lab + AI/energy testbed. UniFi Protect cameras. Home Assistant, pool/spa controller, relay boards.

## Animals

- **Dozer** — Boxer dog (fawn/brown, dark face mask). Only boxer on property.
- **Nona** — Percheron draft horse. Very large, solid black, NO white markings.
- **Cruella** — Black horse with white star/blaze on face.
- **Scooby** — Black horse with one white foot, no face markings.
- Unknown dog on property = immediate Telegram alert (threat to horses).

## Active Projects

- Steel roof trusses for barn
- Solar + battery system (Victron)
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

- OpenClaw on WSL2, systemd
- Ollama serving cloud-proxied models
- MCP servers via mcporter daemon
- Telegram bot active
- Animal Tracker cron logs to animal-sightings.jsonl

## OpenClaw Stability Notes

- Patches applied via ~/.openclaw/patches/apply-gateway-fixes.js
- After OpenClaw updates: re-run patches, verify compat config
