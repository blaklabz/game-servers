#!/usr/bin/env python3
"""Send a plain operational message to a Discord webhook. No external packages."""
import json
import os
import sys
import urllib.request


def send(message, webhook=None):
    url = webhook or os.getenv('DISCORD_WEBHOOK_URL', '')
    if not url:
        print('Discord webhook unset; skipped:', message, file=sys.stderr)
        return False
    data = json.dumps({'content': message[:1900], 'allowed_mentions': {'parse': []}}).encode()
    req = urllib.request.Request(url, data=data, headers={
        'Content-Type': 'application/json', 'User-Agent': 'BlakLabz-Necesse-Relay/1.0'
    }, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=8) as response:
            return 200 <= response.status < 300
    except Exception as exc:
        print(f'Webhook delivery failed: {type(exc).__name__}: {exc}', file=sys.stderr)
        return False


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit('Usage: notify.py MESSAGE [unused]')
    sys.exit(0 if send(sys.argv[1]) else 1)
