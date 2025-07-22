#!/usr/bin/env bash

TIMEOUT="$1"
LOG="$2"
CMD="$3"
current_tty=$(ps -o tty= -p $$)

cleanup() {
    pkill -KILL -t $current_tty
    pkill -9 Python
    pkill -9 python
}

runCmdWithTimeout() {
  (exec sh -c "$2") 2>>"$3" 1>/dev/null & pid=$!
  (sleep "$1" && kill -HUP $pid) 2>/dev/null & watcher=$!
  if wait $pid || ex=$? >/dev/null; then
    pkill -HUP -P $watcher
    wait $watcher
    cleanup
    echo $((ex))
  else
    cleanup
    echo 129; fi
}

res=$(runCmdWithTimeout "$TIMEOUT" "$CMD" "$LOG");
echo -e "${res} ${CMD}\n----" >> $LOG
