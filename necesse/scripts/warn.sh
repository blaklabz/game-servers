#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
case "${1:-}" in
  30) notify "⏳ Necesse server ${NECESSE_WORLD} shuts down in 30 minutes. Wrap up your adventures." ;;
  5) notify "⏳ Necesse server ${NECESSE_WORLD} shuts down in 5 minutes. Find somewhere safe." ;;
  *) echo 'Usage: warn.sh 30|5' >&2; exit 2 ;;
esac
