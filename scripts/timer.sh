#!/usr/bin/env bash

LOG="$1"
TOOL="$2"
SIZE="$3"
CMD="$4"

utc_now() { python3 -c 'import time; print(int(time.time() * 1000))'; }

START=$(utc_now)
start_time=$SECONDS
(exec sh -c "$CMD") 1>/dev/null 2>> "$LOG"
end_time=$SECONDS
END=$(utc_now)

diff=$((end_time - start_time))
echo -e "$(date '+%Y-%m-%d %H:%M:%S') (${diff} s) 0 ${CMD}\n----" >> "$LOG"

DIFF=$(echo "$END - $START" | bc)
echo "$TOOL","$SIZE","$START","$END","$DIFF"
