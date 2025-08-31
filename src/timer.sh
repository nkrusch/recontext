#!/usr/bin/env bash

TOOL="$1"
SIZE="$2"
CMD="$3"

utc_now() { python3 -c 'import time; print(int(time.time() * 1000))'; }

START=$(utc_now)
(exec sh -c "$CMD")
END=$(utc_now)
DIFF=$(echo "$END - $START" | bc)
echo "$TOOL","$SIZE","$START","$END","$DIFF"
