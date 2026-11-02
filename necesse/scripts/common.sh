#!/usr/bin/env bash
set -euo pipefail
CONFIG_FILE="${NECESSE_CONFIG:-/home/necesse/.config/necesse-ops.env}"
if [[ -f "$CONFIG_FILE" ]]; then
  set -a; source "$CONFIG_FILE"; set +a
fi
: "${NECESSE_HOME:=/home/necesse}"
: "${NECESSE_INSTALL:=$NECESSE_HOME/server}"
: "${NECESSE_WORLD:=BlakLabzFoundry}"
: "${NECESSE_PORT:=14159}"
: "${NECESSE_SLOTS:=8}"
: "${NECESSE_SESSION:=necesse}"
: "${NECESSE_LOG:=$NECESSE_HOME/necesse-console.log}"
: "${NECESSE_STOP_TIMEOUT:=90}"
: "${NECESSE_STEAMCMD:=$NECESSE_HOME/steamcmd/steamcmd.sh}"
: "${NECESSE_PAUSE_WHEN_EMPTY:=1}"
OPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
notify() { python3 "$OPS_DIR/scripts/notify.py" "$1" "${2:-}" || true; }
