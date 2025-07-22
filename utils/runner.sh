#!/usr/bin/env bash

TIMEOUT="$1"
LOG="$2"
CMD="$3"

runCmdWithTimeout() {
  (eval "$2") 2>>"$3" 1>/dev/null & pid=$!
  (sleep "$1" && kill -HUP $pid) 2>/dev/null & watcher=$!
  if wait $pid || ex=$? >/dev/null; then
    pkill -HUP -P $watcher
    wait $watcher
    echo $((ex))
  else echo 129; fi
  exit 0;
}

res=$(runCmdWithTimeout "$TIMEOUT" "$CMD" "$LOG");
echo -e "${res} ${CMD}\n----" >> $LOG
