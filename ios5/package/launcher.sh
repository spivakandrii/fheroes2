#!/bin/bash
# fheroes2 writes its log to stderr; keep the last run's log next to the game data.
DATA=/var/mobile/Media/fheroes2
mkdir -p "$DATA"
exec "$(dirname "$0")/fheroes2_bin" "$@" > "$DATA/fheroes2.log" 2>&1
