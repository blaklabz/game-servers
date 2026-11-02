#!/usr/bin/env python3
"""Best-effort Necesse console-log -> Discord events; join/leave patterns configurable.

The actual game log format can vary by release. Test with real log samples.
"""
import os
import re
import subprocess
import sys
import time
from pathlib import Path

from notify import send

JOIN = re.compile(os.getenv('NECESSE_JOIN_REGEX', r'(?i)\b(?P<player>[\w.\- ]{2,32}?) (?:has )?(?:joined|connected)(?: the server)?\b'))
LEAVE = re.compile(os.getenv('NECESSE_LEAVE_REGEX', r'(?i)\b(?P<player>[\w.\- ]{2,32}?) (?:has )?(?:left|disconnected)(?: the server)?\b'))
READY = re.compile(os.getenv('NECESSE_READY_REGEX', r'(?i)(?:server (?:is now )?(?:running|started|listening)|started server|server started on port)'))
LOG = Path(os.getenv('NECESSE_LOG', '/home/necesse/necesse-console.log'))
SESSION = os.getenv('NECESSE_SESSION', 'necesse')
WORLD = os.getenv('NECESSE_WORLD', 'BlakLabzFoundry')


def classify(line):
    # Prefer player join/leave only on lines with expected verbs; adjust after inspecting logs.
    for pattern, kind in ((JOIN, 'join'), (LEAVE, 'leave')):
        match = pattern.search(line)
        if match:
            name = match.group('player').strip(' :[]')
            # Discard likely generic log-prefix matches; inspect actual log to tune.
            if len(name) >= 2:
                return kind, name
    if READY.search(line):
        return 'ready', None
    return None


def session_alive():
    return subprocess.run(['tmux', 'has-session', '-t', SESSION],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def main():
    LOG.parent.mkdir(parents=True, exist_ok=True)
    LOG.touch(exist_ok=True)
    # Follow from EOF to avoid replaying old events on service restart.
    with LOG.open('r', encoding='utf-8', errors='replace') as handle:
        handle.seek(0, 2)
        ready_sent = False
        was_alive = session_alive()
        while True:
            line = handle.readline()
            if line:
                event = classify(line)
                if event:
                    kind, player = event
                    if kind == 'ready' and not ready_sent:
                        send(f'🟢 Necesse server {WORLD} is online.')
                        ready_sent = True
                    elif kind == 'join':
                        send(f'🟢 {player} has joined the Necesse server.')
                    elif kind == 'leave':
                        send(f'🔴 {player} has left the Necesse server.')
            else:
                alive = session_alive()
                if was_alive and not alive:
                    # Cannot distinguish a planned shutdown from a crash here.
                    # stop.sh sends the verified-shutdown message; no duplicate crash alert.
                    ready_sent = False
                was_alive = alive
                time.sleep(1)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
