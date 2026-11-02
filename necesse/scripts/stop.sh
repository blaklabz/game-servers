#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
if ! tmux has-session -t "$NECESSE_SESSION" 2>/dev/null; then
  echo 'Necesse is already stopped'; exit 0
fi
notify "🟠 Necesse server ${NECESSE_WORLD} is shutting down and saving."
tmux send-keys -t "$NECESSE_SESSION" -l 'stop'
tmux send-keys -t "$NECESSE_SESSION" Enter
for ((i=0; i<NECESSE_STOP_TIMEOUT; i++)); do
  if ! tmux has-session -t "$NECESSE_SESSION" 2>/dev/null; then
    notify "🛑 Necesse server ${NECESSE_WORLD} has stopped (graceful shutdown verified)."
    exit 0
  fi
  sleep 1
done
notify "🚨 Necesse server ${NECESSE_WORLD} did NOT stop within ${NECESSE_STOP_TIMEOUT}s; manual intervention required."
echo 'Graceful stop timed out; refusing to kill server to protect saves.' >&2
exit 1
