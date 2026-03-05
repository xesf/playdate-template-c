#!/bin/bash
# convert_audio.sh
# Converts all audio files in Source/sounds/ to Playdate-compatible format:
#   - 16-bit signed PCM
#   - Mono (single channel)
#   - 11025 Hz sample rate
#
# pdc expects uncompressed 16-bit mono PCM WAV input.
# Pre-compressed (ADPCM) or stereo WAVs can cause issues on device.
#
# Requires: ffmpeg

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/../Source/sounds"

if ! command -v ffmpeg &> /dev/null; then
    echo "WARNING: ffmpeg not found, skipping audio conversion"
    exit 0
fi

CONVERTED=0

find "$SOUNDS_DIR" -name "*.wav" -type f | while read -r wav; do
    # Get format info
    INFO=$(ffmpeg -i "$wav" 2>&1 || true)

    NEEDS_CONVERT=1

    if [ "$NEEDS_CONVERT" -eq 1 ]; then
        echo "Converting: $wav"
        TMP="${wav}.tmp.wav"
        ffmpeg -y -i "$wav" -ac 1 -ar 11025 -acodec pcm_s16le "$TMP" 2>/dev/null
        mv "$TMP" "$wav"
        CONVERTED=$((CONVERTED + 1))
    fi
done

echo "Audio conversion complete."
