#!/usr/bin/env bash

TIMEOUT="$1"
LOG="$2"
CMD="$3"

cleanup() {
   pkill -9 Python
   pkill -9 python
}

runCmdWithTimeout() {
  (exec sh -c "$2") 2>>"$3" 1>/dev/null & pid=$!
  (sleep "$1" && kill -9 $pid) 2>/dev/null & watcher=$!
  if wait $pid || ex=$? >/dev/null; then
    pkill -P $watcher
    wait $watcher
    cleanup
    echo $((ex))
  else
    cleanup
    echo 129; fi
}

start_time=$SECONDS
res=$(runCmdWithTimeout "$TIMEOUT" "$CMD" "$LOG");
end_time=$SECONDS
diff=$((end_time - start_time))
echo -e "$(date '+%Y-%m-%d %H:%M:%S') (${diff} s) ${res} ${CMD}\n----" >> "$LOG"
