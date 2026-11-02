#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
if tmux has-session -t "$NECESSE_SESSION" 2>/dev/null; then
  echo 'Necesse session already running'; exit 0
fi
"$OPS_DIR/scripts/update.sh"
[[ -x "$NECESSE_INSTALL/StartServer-nogui.sh" ]] || { echo 'Server launcher not found' >&2; exit 1; }
mkdir -p "$(dirname "$NECESSE_LOG")"
touch "$NECESSE_LOG"
notify "🟡 Necesse server ${NECESSE_WORLD} is starting."
# tmux keeps stdin available for the game's console, including graceful 'stop'.
# tee receives pane output; log is also consumed by relay.py.
tmux new-session -d -s "$NECESSE_SESSION" -c "$NECESSE_INSTALL" \
  "./StartServer-nogui.sh -world '$NECESSE_WORLD' -port '$NECESSE_PORT' -slots '$NECESSE_SLOTS' -pausewhenempty '$NECESSE_PAUSE_WHEN_EMPTY' -logging 1"
tmux pipe-pane -t "$NECESSE_SESSION" -o "cat >> '$NECESSE_LOG'"
# Session alive is not proof that the game socket is ready. No false ready notice.
sleep 3
if ! tmux has-session -t "$NECESSE_SESSION" 2>/dev/null; then
  notify "🚨 Necesse server ${NECESSE_WORLD} exited during startup."
  exit 1
fi
echo "Necesse session started. Verify readiness in $NECESSE_LOG"
