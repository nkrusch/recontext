#!/usr/bin/env bash

TOOL="$1"
SIZE="$2"
CMD="$3"

start=$(date +%s%N)
#{ time (exec sh -c "$CMD") ; } 2>&1 | tr '\n' ', ' | tr '\t' ' '
t_out=$(echo "$(time (exec sh -c "$CMD"))")
t_out="blahblah"
end=$(date +%s%N)
dur_ns=$((end_time - start_time))

echo "$TOOL,$SIZE,$start,$end,$dur_ns,$t_out"
