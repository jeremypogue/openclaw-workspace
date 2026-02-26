#!/bin/bash
# Session Cleanup — Three Oaks Farm
# Removes stale session transcripts and prunes sessions.json
# Called by cron every 2 hours

set -euo pipefail

SESS_DIR="/home/vision/.openclaw/agents/main/sessions"
ARCHIVE_DIR="$SESS_DIR/archive"
SESS_JSON="$SESS_DIR/sessions.json"
MAX_AGE_HOURS=4
CLEANED=0

mkdir -p "$ARCHIVE_DIR"

# Archive transcript files older than MAX_AGE_HOURS that aren't tiny
NOW_EPOCH=$(date +%s)
CUTOFF_EPOCH=$((NOW_EPOCH - MAX_AGE_HOURS * 3600))

for f in "$SESS_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    MOD_EPOCH=$(stat -c%Y "$f" 2>/dev/null || echo 0)
    if [ "$MOD_EPOCH" -lt "$CUTOFF_EPOCH" ]; then
        mv "$f" "$ARCHIVE_DIR/"
        CLEANED=$((CLEANED + 1))
    fi
done

# Also archive any transcript over 30KB (image-heavy)
for f in "$SESS_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    SIZE=$(stat -c%s "$f" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 30000 ]; then
        mv "$f" "$ARCHIVE_DIR/"
        CLEANED=$((CLEANED + 1))
    fi
done

# Prune sessions.json — keep entries from last MAX_AGE_HOURS + main
if [ -f "$SESS_JSON" ] && command -v jq &>/dev/null; then
    CUTOFF_MS=$(( (NOW_EPOCH - MAX_AGE_HOURS * 3600) * 1000 ))
    BEFORE=$(jq 'length' "$SESS_JSON")
    jq --argjson cutoff "$CUTOFF_MS" '
        to_entries |
        map(select(.key == "agent:main:main" or .value.updatedAt >= $cutoff)) |
        from_entries
    ' "$SESS_JSON" > "$SESS_JSON.tmp" && mv "$SESS_JSON.tmp" "$SESS_JSON"
    AFTER=$(jq 'length' "$SESS_JSON")
    PRUNED=$((BEFORE - AFTER))
else
    PRUNED=0
fi

# Clean up archive files older than 24 hours
find "$ARCHIVE_DIR" -name "*.jsonl" -mmin +1440 -delete 2>/dev/null || true

if [ "$CLEANED" -gt 0 ] || [ "$PRUNED" -gt 0 ]; then
    echo "Cleaned $CLEANED transcript(s), pruned $PRUNED session entries"
else
    echo "NO_ISSUES"
fi
