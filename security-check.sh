#!/bin/bash
# Security Check Script — Three Oaks Farm
# Checks person/vehicle/animal detection events across all cameras
# Reports only when notable events are found (for hourly cron use)
# For on-demand use, pass --full flag for expanded output

set -euo pipefail

FULL_MODE="${1:-}"
LOOKBACK_HOURS=1
REPORT=""
ALERTS=""
ANIMAL_REPORT=""
NOW_EPOCH=$(date +%s)

# Camera classifications
PERIMETER_CAMS="greenville_rd driveentry driveway front_yard front_door paddock5"
HOUSE_CAMS="back_door garage pool_patio patio_north spa pool backyard poolshack_north"
HORSE_CAMS="barn stalls stall1 stall2 stall3 paddock1 paddock2 overwatch pond"
DOG_CAMS="backyard front_yard patio_north pool_patio garage front_door back_door barn"

add_alert() { ALERTS="${ALERTS}${1}\n"; }
add_report() { REPORT="${REPORT}${1}\n"; }
add_animal() { ANIMAL_REPORT="${ANIMAL_REPORT}${1}\n"; }

# ── Person Detection History ──
PERSON_SENSORS=$(echo "binary_sensor.barn_person_detected,binary_sensor.stalls_person_detected,binary_sensor.stall1_person_detected,binary_sensor.stall2_person_detected,binary_sensor.stall3_person_detected,binary_sensor.paddock1_person_detected,binary_sensor.paddock2_person_detected,binary_sensor.paddock5_person_detected,binary_sensor.overwatch_person_detected,binary_sensor.pond_person_detected,binary_sensor.greenville_rd_person_detected,binary_sensor.driveentry_person_detected,binary_sensor.driveway_person_detected,binary_sensor.front_yard_person_detected,binary_sensor.front_door_person_detected,binary_sensor.back_door_person_detected,binary_sensor.garage_person_detected,binary_sensor.pool_patio_person_detected,binary_sensor.patio_north_person_detected,binary_sensor.spa_person_detected,binary_sensor.pool_person_detected,binary_sensor.backyard_person_detected,binary_sensor.poolshack_north_person_detected,binary_sensor.mower_storage_person_detected,binary_sensor.shop_ceiling1_person_detected")

PERSON_HISTORY=$(mcporter call ha-mcp.ha_get_history entity_ids="$PERSON_SENSORS" start_time="${LOOKBACK_HOURS}h" significant_changes_only=true 2>/dev/null || echo '[]')

# Count person detections per camera
PERSON_EVENTS=""
if command -v jq &>/dev/null && [ "$PERSON_HISTORY" != "[]" ]; then
    PERSON_EVENTS=$(echo "$PERSON_HISTORY" | jq -r '
        [.[] | .entity_id as $eid |
            ($eid | split(".")[1] | split("_person_detected")[0]) as $cam |
            [.states[]? | select(.state == "on")] |
            {camera: $cam, count: length, last: (if length > 0 then .[-1].last_changed else null end)}
        ] | [.[] | select(.count > 0)] | sort_by(-.count)[] |
        "\(.camera):\(.count):\(.last // "unknown")"
    ' 2>/dev/null || echo "")
fi

PERIMETER_ALERTS=0
TOTAL_PERSON_DETECTIONS=0

if [ -n "$PERSON_EVENTS" ]; then
    while IFS= read -r line; do
        CAM=$(echo "$line" | cut -d: -f1)
        COUNT=$(echo "$line" | cut -d: -f2)
        LAST=$(echo "$line" | cut -d: -f3-)
        TOTAL_PERSON_DETECTIONS=$((TOTAL_PERSON_DETECTIONS + COUNT))

        # Format last-seen time
        if [ "$LAST" != "unknown" ] && [ "$LAST" != "null" ]; then
            LAST_FMT=$(date -d "$LAST" '+%I:%M %p' 2>/dev/null || echo "$LAST")
        else
            LAST_FMT="unknown"
        fi

        # Check if perimeter camera
        if echo "$PERIMETER_CAMS" | grep -qw "$CAM"; then
            add_alert "  ⚠️ PERIMETER: ${CAM} — ${COUNT} person detection(s), last at ${LAST_FMT}"
            PERIMETER_ALERTS=$((PERIMETER_ALERTS + 1))
        else
            add_report "  👤 ${CAM} — ${COUNT} detection(s), last at ${LAST_FMT}"
        fi
    done <<< "$PERSON_EVENTS"
fi

# ── Vehicle Detection History ──
VEHICLE_SENSORS="binary_sensor.greenville_rd_vehicle_detected,binary_sensor.driveentry_vehicle_detected,binary_sensor.driveway_vehicle_detected,binary_sensor.front_yard_vehicle_detected,binary_sensor.front_door_vehicle_detected,binary_sensor.paddock5_vehicle_detected,binary_sensor.garage_vehicle_detected"

VEHICLE_HISTORY=$(mcporter call ha-mcp.ha_get_history entity_ids="$VEHICLE_SENSORS" start_time="${LOOKBACK_HOURS}h" significant_changes_only=true 2>/dev/null || echo '[]')

VEHICLE_EVENTS=""
if command -v jq &>/dev/null && [ "$VEHICLE_HISTORY" != "[]" ]; then
    VEHICLE_EVENTS=$(echo "$VEHICLE_HISTORY" | jq -r '
        [.[] | .entity_id as $eid |
            ($eid | split(".")[1] | split("_vehicle_detected")[0]) as $cam |
            [.states[]? | select(.state == "on")] |
            {camera: $cam, count: length, last: (if length > 0 then .[-1].last_changed else null end)}
        ] | [.[] | select(.count > 0)] | sort_by(-.count)[] |
        "\(.camera):\(.count):\(.last // "unknown")"
    ' 2>/dev/null || echo "")
fi

TOTAL_VEHICLE_DETECTIONS=0
if [ -n "$VEHICLE_EVENTS" ]; then
    while IFS= read -r line; do
        CAM=$(echo "$line" | cut -d: -f1)
        COUNT=$(echo "$line" | cut -d: -f2)
        LAST=$(echo "$line" | cut -d: -f3-)
        TOTAL_VEHICLE_DETECTIONS=$((TOTAL_VEHICLE_DETECTIONS + COUNT))

        if [ "$LAST" != "unknown" ] && [ "$LAST" != "null" ]; then
            LAST_FMT=$(date -d "$LAST" '+%I:%M %p' 2>/dev/null || echo "$LAST")
        else
            LAST_FMT="unknown"
        fi
        add_alert "  🚗 VEHICLE: ${CAM} — ${COUNT} detection(s), last at ${LAST_FMT}"
    done <<< "$VEHICLE_EVENTS"
fi

# ── Animal Tracking (from vision-identified sightings log) ──
SIGHTINGS_FILE="/home/vision/.openclaw/workspace/animal-sightings.jsonl"
LOOKBACK_EPOCH=$((NOW_EPOCH - LOOKBACK_HOURS * 3600))

HORSE_SIGHTINGS=""
DOG_SIGHTINGS=""

if [ -f "$SIGHTINGS_FILE" ] && [ -s "$SIGHTINGS_FILE" ] && command -v jq &>/dev/null; then
    # Get latest sighting per animal within the lookback window
    HORSE_ENTRIES=$(tail -200 "$SIGHTINGS_FILE" | jq -r --argjson cutoff "$LOOKBACK_EPOCH" '
        select(.species == "horse") |
        select((.ts | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) >= $cutoff) |
        "\(.animal):\(.camera):\(.confidence):\(.ts)"
    ' 2>/dev/null || echo "")

    DOG_ENTRIES=$(tail -200 "$SIGHTINGS_FILE" | jq -r --argjson cutoff "$LOOKBACK_EPOCH" '
        select(.species == "dog") |
        select((.ts | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) >= $cutoff) |
        "\(.animal):\(.camera):\(.confidence):\(.ts)"
    ' 2>/dev/null || echo "")

    ALERT_ENTRIES=$(tail -200 "$SIGHTINGS_FILE" | jq -r --argjson cutoff "$LOOKBACK_EPOCH" '
        select(.alert == true) |
        select((.ts | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) >= $cutoff) |
        "\(.animal):\(.camera):\(.ts)"
    ' 2>/dev/null || echo "")

    # Format horse sightings — show latest per named animal
    if [ -n "$HORSE_ENTRIES" ]; then
        # Deduplicate: keep last sighting per animal
        SEEN_HORSES=""
        while IFS= read -r line; do
            ANIMAL=$(echo "$line" | cut -d: -f1)
            CAM=$(echo "$line" | cut -d: -f2)
            CONF=$(echo "$line" | cut -d: -f3)
            TS=$(echo "$line" | cut -d: -f4-)
            if [ "$TS" != "unknown" ] && [ "$TS" != "null" ]; then
                LAST_FMT=$(date -d "$TS" '+%I:%M %p' 2>/dev/null || echo "$TS")
            else
                LAST_FMT="unknown"
            fi
            ANIMAL_DISPLAY=$(echo "$ANIMAL" | sed 's/^./\U&/')
            if ! echo "$SEEN_HORSES" | grep -qw "$ANIMAL"; then
                HORSE_SIGHTINGS="${HORSE_SIGHTINGS}  \xf0\x9f\x90\xb4 ${ANIMAL_DISPLAY} — ${CAM}, last seen ${LAST_FMT} (${CONF})\n"
                SEEN_HORSES="$SEEN_HORSES $ANIMAL"
            fi
        done <<< "$(echo "$HORSE_ENTRIES" | tac)"
    fi

    # Format dog sightings
    if [ -n "$DOG_ENTRIES" ]; then
        SEEN_DOGS=""
        while IFS= read -r line; do
            ANIMAL=$(echo "$line" | cut -d: -f1)
            CAM=$(echo "$line" | cut -d: -f2)
            CONF=$(echo "$line" | cut -d: -f3)
            TS=$(echo "$line" | cut -d: -f4-)
            if [ "$TS" != "unknown" ] && [ "$TS" != "null" ]; then
                LAST_FMT=$(date -d "$TS" '+%I:%M %p' 2>/dev/null || echo "$TS")
            else
                LAST_FMT="unknown"
            fi
            ANIMAL_DISPLAY=$(echo "$ANIMAL" | sed 's/^./\U&/')
            if ! echo "$SEEN_DOGS" | grep -qw "$ANIMAL"; then
                DOG_SIGHTINGS="${DOG_SIGHTINGS}  \xf0\x9f\x90\x95 ${ANIMAL_DISPLAY} — ${CAM}, last seen ${LAST_FMT} (${CONF})\n"
                SEEN_DOGS="$SEEN_DOGS $ANIMAL"
            fi
        done <<< "$(echo "$DOG_ENTRIES" | tac)"
    fi

    # Unknown dog alerts
    if [ -n "$ALERT_ENTRIES" ]; then
        while IFS= read -r line; do
            CAM=$(echo "$line" | cut -d: -f2)
            TS=$(echo "$line" | cut -d: -f3-)
            if [ "$TS" != "unknown" ] && [ "$TS" != "null" ]; then
                LAST_FMT=$(date -d "$TS" '+%I:%M %p' 2>/dev/null || echo "$TS")
            else
                LAST_FMT="unknown"
            fi
            add_alert "  \xe2\x9a\xa0\xef\xb8\x8f UNKNOWN DOG: ${CAM} at ${LAST_FMT}"
        done <<< "$ALERT_ENTRIES"
    fi
else
    # Fallback: query HA history directly if no sightings log available
    ANIMAL_SENSORS="binary_sensor.barn_animal_detected,binary_sensor.stalls_animal_detected,binary_sensor.stall1_animal_detected,binary_sensor.stall2_animal_detected,binary_sensor.stall3_animal_detected,binary_sensor.paddock1_animal_detected,binary_sensor.paddock2_animal_detected,binary_sensor.paddock5_animal_detected,binary_sensor.overwatch_animal_detected,binary_sensor.pond_animal_detected,binary_sensor.backyard_animal_detected,binary_sensor.front_yard_animal_detected,binary_sensor.patio_north_animal_detected,binary_sensor.pool_patio_animal_detected,binary_sensor.garage_animal_detected,binary_sensor.front_door_animal_detected,binary_sensor.back_door_animal_detected,binary_sensor.driveway_animal_detected,binary_sensor.driveentry_animal_detected,binary_sensor.mower_storage_animal_detected,binary_sensor.pool_animal_detected,binary_sensor.spa_animal_detected"

    ANIMAL_HISTORY=$(mcporter call ha-mcp.ha_get_history entity_ids="$ANIMAL_SENSORS" start_time="${LOOKBACK_HOURS}h" significant_changes_only=true 2>/dev/null || echo '[]')

    if command -v jq &>/dev/null && [ "$ANIMAL_HISTORY" != "[]" ]; then
        ANIMAL_EVENTS=$(echo "$ANIMAL_HISTORY" | jq -r '
            [.[] | .entity_id as $eid |
                ($eid | split(".")[1] | split("_animal_detected")[0]) as $cam |
                [.states[]? | select(.state == "on")] |
                {camera: $cam, count: length, last: (if length > 0 then .[-1].last_changed else null end)}
            ] | [.[] | select(.count > 0)] | sort_by(-.count)[] |
            "\(.camera):\(.count):\(.last // "unknown")"
        ' 2>/dev/null || echo "")

        if [ -n "$ANIMAL_EVENTS" ]; then
            while IFS= read -r line; do
                CAM=$(echo "$line" | cut -d: -f1)
                COUNT=$(echo "$line" | cut -d: -f2)
                LAST=$(echo "$line" | cut -d: -f3-)
                if [ "$LAST" != "unknown" ] && [ "$LAST" != "null" ]; then
                    LAST_FMT=$(date -d "$LAST" '+%I:%M %p' 2>/dev/null || echo "$LAST")
                else
                    LAST_FMT="unknown"
                fi
                if echo "$HORSE_CAMS" | grep -qw "$CAM"; then
                    HORSE_SIGHTINGS="${HORSE_SIGHTINGS}  \xf0\x9f\x90\xb4 ${CAM} — ${COUNT} animal detection(s), last at ${LAST_FMT}\n"
                fi
                if echo "$DOG_CAMS" | grep -qw "$CAM"; then
                    DOG_SIGHTINGS="${DOG_SIGHTINGS}  \xf0\x9f\x90\x95 ${CAM} — ${COUNT} animal detection(s), last at ${LAST_FMT}\n"
                fi
                add_animal "  \xf0\x9f\x90\xbe ${CAM} — ${COUNT} detection(s), last at ${LAST_FMT}"
            done <<< "$ANIMAL_EVENTS"
        fi
    fi
fi

# ── Build Output ──
HAS_ISSUES=false
OUTPUT=""

# Header
TIMESTAMP=$(date '+%I:%M %p %Z')
OUTPUT="🔒 SECURITY CHECK — ${TIMESTAMP}\n"
OUTPUT="${OUTPUT}━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

# Alerts section (perimeter people + vehicles)
if [ -n "$ALERTS" ]; then
    HAS_ISSUES=true
    OUTPUT="${OUTPUT}\n🚨 ALERTS\n"
    OUTPUT="${OUTPUT}${ALERTS}"
fi

# Person activity (non-alert)
if [ -n "$REPORT" ]; then
    OUTPUT="${OUTPUT}\n👤 PERSON ACTIVITY (${TOTAL_PERSON_DETECTIONS} total)\n"
    OUTPUT="${OUTPUT}${REPORT}"
fi

# Vehicles
if [ "$TOTAL_VEHICLE_DETECTIONS" -gt 0 ]; then
    HAS_ISSUES=true
fi

# Horse tracking
OUTPUT="${OUTPUT}\n🐴 HORSES\n"
if [ -n "$HORSE_SIGHTINGS" ]; then
    OUTPUT="${OUTPUT}${HORSE_SIGHTINGS}"
else
    OUTPUT="${OUTPUT}  No horse activity detected in last ${LOOKBACK_HOURS}h\n"
fi

# Dog tracking (Dozer)
OUTPUT="${OUTPUT}\n🐕 DOZER (Boxer)\n"
if [ -n "$DOG_SIGHTINGS" ]; then
    OUTPUT="${OUTPUT}${DOG_SIGHTINGS}"
else
    OUTPUT="${OUTPUT}  No dog activity detected in last ${LOOKBACK_HOURS}h\n"
fi

# Summary
if [ "$TOTAL_PERSON_DETECTIONS" -eq 0 ] && [ "$TOTAL_VEHICLE_DETECTIONS" -eq 0 ]; then
    OUTPUT="${OUTPUT}\n✅ All clear — no people or vehicles detected in last ${LOOKBACK_HOURS}h\n"
elif [ "$PERIMETER_ALERTS" -eq 0 ] && [ "$TOTAL_VEHICLE_DETECTIONS" -eq 0 ]; then
    OUTPUT="${OUTPUT}\n✅ No perimeter alerts — ${TOTAL_PERSON_DETECTIONS} person detection(s) in interior areas only\n"
fi

# ── Output Logic ──
if [ "$FULL_MODE" = "--full" ]; then
    # On-demand: always output everything
    echo -e "$OUTPUT"
elif [ "$HAS_ISSUES" = true ]; then
    # Hourly cron: only output if there are alerts
    echo -e "$OUTPUT"
else
    # Hourly cron: no issues, suppress output
    echo "NO_ISSUES"
fi
