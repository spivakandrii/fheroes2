#!/bin/bash
# fheroes2 writes its log to stderr; keep the last run's log next to the game data.
DATA=/var/mobile/Media/fheroes2
APP="$(dirname "$0")"
mkdir -p "$DATA"
export TIMIDITY_CFG="$APP/files/timidity/timidity.cfg"
exec "$APP/fheroes2_bin" "$@" > "$DATA/fheroes2.log" 2>&1
