# MEMORY.md - Long-Term Memory

_Curated knowledge and context. Updated over time._

---

## Property & Facility

30-acre rural Kentucky property (Hopkinsville, KY). Pennyrile Electric Cooperative / TVA territory. Functions as working horse farm, advanced fabrication lab, and sovereign AI/energy infrastructure testbed.

**Primary Bay:** Honeycomb LEDs, two engine hoists, multiple weld stations, gas heater, air reels, security camera monitors. New Holland C332 skid steer fits inside. Custom 350lb/leaf shop doors (self-fabricated).

**Secondary Bay:** Eastwood CNC/plasma table (220V), hydraulic press, chop saw, drill press, vise, steel stock storage. Mezzanine above with equipment lift, floor jack, creepers, multiple tool chests.

**Heavy Equipment:** New Holland C332 skid steer with hydraulic attachments (metric-to-standard conversion completed on hydraulic fittings).

---

## Active Projects

- **Steel roof trusses:** 24ft span agricultural building for horse stalls. 2x2 14ga square tubing, 2.5mm gusset plates (CNC-cut). Fermorel MTC 200 Pro, .030 flux core wire, .035 tips.
- **75kW solar installation:** Residential + farm LLC. TVA/Pennyrile interconnection. 400-amp combination meter panels. >50kW regulatory navigation. Custom 4" C-channel racking (longer spans). ~30 panels mounted and holding in heavy wind. Upgrading electrical services.
- **Energy storage:** 100kWh+ LiFePO4 battery system. Victron ecosystem. ITC optimization. Four-year ROI target.
- **Autonomous stall-cleaning robot:** Sensor fusion, fail-safes, torque optimization, edge-first architecture.
- **Local AI ecosystem:** Ollama on local GPU, Home Assistant integration, UniFi Protect analytics, voice wake word "Vision", mmWave presence sensors, LoRaWAN asset tracking, edge devices, automated recovery scripts, MCP protocol integration, Shelly Gen4 Zigbee relays, pool/spa controllers.
- **CNC/plasma operations:** Eastwood Versa-Cut 4x4 table, Eastwood Versa-Cut 40 plasma (220V), Autodesk Fusion 360 CAD/CAM. Cutting gusset plates for truss fabrication.

---

## Equipment & Inventory

**Welder:** Fermorel MTC 200 Pro. .030 flux core wire, .035 tips. Vevor ancillary equipment.

**Steel Inventory:** Sourced via Fort Campbell contractor connection at 60-75% off retail. Stock includes 1046 12ga plate, 2x2 14ga tube (26ft), 4" C-channel 3/16" (20ft), 2" angle 3/16" (20ft).

**Automation/Smart Home:** UniFi Protect cameras (28), UniFi network devices (30), Home Assistant, Shelly Gen4 Zigbee relays, local LLM servers, MCP protocol integration, pool/spa controllers, relay-controlled devices.

---

## Technical Preferences

| Domain | Standard |
|---|---|
| General measurement | Imperial (amps, AWG, inches, feet, psi) |
| Steel thickness | Metric (mm) |
| CNC/plasma/welder settings | Metric where applicable |
| Electrical references | NEC article numbers, exact conductor sizing, breaker coordination |
| Code | Go (primary), Python, JavaScript, Fusion 360 scripting |
| Infrastructure | Linux CLI, Docker, containerized deployment, offline-first |
| Architecture | Edge-first, local compute, no cloud dependency unless strategically justified |

---

## Tax & Financial

R&D credits, ITC (Investment Tax Credit) positioning, REAP grant positioning, depreciation modeling (Section 179 / bonus / MACRS), expense categorization rigor (capital vs. current), four-year ROI targeting on infrastructure investments. RSU vestings from Fifth Third Bancorp are part of the financial picture.

---

## Core Design Philosophy

- **Systems that don't fail silently** — every component must report its state
- **Sovereignty** — local LLMs, local automation, local solar, local compute
- **Precision** — clean wiring, deterministic behavior, edge-first architectures
- **Over-engineered, cost-effective** — long-term ROI, multi-generational infrastructure value
- **Engineer it correctly the first time** — no band-aids, no duct tape solutions
- **Offline-first** — no cloud dependency unless strategically justified and failure-tolerant

---

## Dev Environment

- Windows + WSL2 (SSH connectivity issues noted)
- Go (primary language), Python, JavaScript
- Autodesk Fusion 360 for CAD/CAM
- Docker preferred for deployment
- OpenClaw v2026.2.9 on WSL2 with systemd
- Ollama v0.16.3 serving cloud-proxied models
- MCP Bridge with 161 tools (Home Assistant, UniFi Protect/Network, Pool Controller, etc.)

---

## Infrastructure Notes (2026-02-25)

- OpenClaw gateway on port 18789, LAN-bound, token auth
- Ollama running via systemd (ollama user), models served via ollama.com cloud proxy
- Current model: qwen3.5:397b-cloud (single model, all purposes)
- OnePlus 13 paired as operator+node (voice assistant via openclaw-assistant app)
- Telegram bot active (token in config)
- Daily status report cron job at 7am CST
- 6 MCP servers: unifi-protect, unifi-network, ha-mcp, pool-controller, relay-equipment-manager (x2), mcporter daemon

---

## Response Rules (How to Talk to Jeremy)

1. Act as embedded co-engineer, not a chatbot
2. Skip foundational explanations — give exact specs, NEC refs, menu paths, AWG sizing, parameter values, torque specs
3. Default to offline-first thinking
4. Assume he prefers building over buying
5. Provide cost/ROI framing with tax classification context
6. Think in redundancy — warn about hidden failure modes
7. Push back if something is technically incorrect
8. Account for hand stability in all technique discussions
9. Prefer containerized deployment (Docker)
10. Think five steps ahead about failure modes and integration
11. Be concise — mobile and shop monitor friendly
12. Address him as "sir" when appropriate
