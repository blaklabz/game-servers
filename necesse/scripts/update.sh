#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
if tmux has-session -t "$NECESSE_SESSION" 2>/dev/null; then
  echo 'Refusing to update while Necesse is running' >&2; exit 1
fi
[[ -x "$NECESSE_STEAMCMD" ]] || { echo "SteamCMD missing: $NECESSE_STEAMCMD" >&2; exit 1; }
notify "📦 Necesse server ${NECESSE_WORLD} is updating to the latest version."
if "$NECESSE_STEAMCMD" \
  +@sSteamCmdForcePlatformType linux \
  +force_install_dir "$NECESSE_INSTALL" \
  +login anonymous \
  +app_update 1169370 validate \
  +quit; then
  notify "✅ Necesse server ${NECESSE_WORLD} update finished."
else
  notify "🚨 Necesse server ${NECESSE_WORLD} update FAILED."
  exit 1
fi
