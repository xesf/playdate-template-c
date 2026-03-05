#!/usr/bin/env bash
# normalize_audio.sh
# Analyzes or normalizes all WAV files in Source/sounds/ to a target loudness.
#
# Usage:
#   ./normalize_audio.sh                     - Analyze: show current loudness of all files
#   ./normalize_audio.sh --target -16        - Normalize all files to -16 LUFS (EBU R128)
#   ./normalize_audio.sh --target -16 --dry  - Dry run: show what would change, no writes
#
# Output format is always Playdate-compatible: mono 16-bit PCM at 11025 Hz.
#
# Requires: ffmpeg

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/../Source/sounds"

TARGET_LUFS=""
DRY_RUN=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            TARGET_LUFS="$2"
            shift 2
            ;;
        --dry)
            DRY_RUN=1
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--target <lufs>] [--dry]"
            exit 1
            ;;
    esac
done

if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg not found. Install with: brew install ffmpeg"
    exit 1
fi

# ─── Collect all WAV files ───────────────────────────────────────────────────

WAV_FILES=()
while IFS= read -r -d '' wav; do
    WAV_FILES+=("$wav")
done < <(find "$SOUNDS_DIR" -name "*.wav" -type f -print0 | sort -z)

if [ ${#WAV_FILES[@]} -eq 0 ]; then
    echo "No WAV files found in $SOUNDS_DIR"
    exit 0
fi

# ─── Analyze mode ────────────────────────────────────────────────────────────

analyze_file() {
    local wav="$1"
    local rel="${wav#$SOUNDS_DIR/}"

    local raw
    raw=$(ffmpeg -i "$wav" -af "loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json" \
        -f null /dev/null 2>&1)

    local lufs peak lra
    lufs=$(echo "$raw" | awk -F'"' '/"input_i"/{print $4}')
    peak=$(echo "$raw" | awk -F'"' '/"input_tp"/{print $4}')
    lra=$(echo "$raw"  | awk -F'"' '/"input_lra"/{print $4}')

    printf "  %-45s  LUFS: %8s  TruePeak: %7s  LRA: %s\n" \
        "$rel" "${lufs:-?}" "${peak:-?}" "${lra:-?}"
}

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Audio Analyzer"
echo "  Sounds dir: $SOUNDS_DIR"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Group by subfolder
current_dir=""
for wav in "${WAV_FILES[@]}"; do
    dir=$(dirname "${wav#$SOUNDS_DIR/}")
    if [ "$dir" != "$current_dir" ]; then
        current_dir="$dir"
        echo "── $dir/ ──"
    fi
    analyze_file "$wav"
done

# ─── Normalize mode ──────────────────────────────────────────────────────────

if [ -z "$TARGET_LUFS" ]; then
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo "  To normalize all files to a target loudness, run:"
    echo "    $0 --target <lufs>      e.g. --target -16"
    echo "  Common values:"
    echo "    -14   Streaming (Spotify/Apple Music reference)"
    echo "    -16   Good balance for game SFX and music"
    echo "    -18   Quieter, more headroom for mixing"
    echo "    -23   Broadcast standard (EBU R128)"
    echo "────────────────────────────────────────────────────────────────"
    echo ""
    exit 0
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Normalizing all files to ${TARGET_LUFS} LUFS"
if [ "$DRY_RUN" -eq 1 ]; then
    echo "  DRY RUN — no files will be written"
fi
echo "════════════════════════════════════════════════════════════════"
echo ""

NORMALIZED=0
SKIPPED=0

for wav in "${WAV_FILES[@]}"; do
    rel="${wav#$SOUNDS_DIR/}"

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [dry] Would normalize: $rel"
        NORMALIZED=$((NORMALIZED + 1))
        continue
    fi

    echo "  Normalizing: $rel"
    TMP="${wav}.norm.wav"

    # Two-pass EBU R128 loudnorm for accurate results, output Playdate-compatible format
    ffmpeg -y -i "$wav" \
        -af "loudnorm=I=${TARGET_LUFS}:TP=-1.5:LRA=11" \
        -ac 1 -ar 11025 -acodec pcm_s16le \
        "$TMP" 2>/dev/null

    mv "$TMP" "$wav"
    NORMALIZED=$((NORMALIZED + 1))
done

echo ""
if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run complete. $NORMALIZED file(s) would be normalized."
else
    echo "Normalization complete. $NORMALIZED file(s) processed."
fi
