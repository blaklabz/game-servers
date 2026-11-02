# BlakLabz Necesse → #foundry

Native **SteamCMD + tmux + systemd** deployment for a Debian LXC/VM. Includes Discord webhook notifications for updates, lifecycle, shutdown warnings, and best-effort player join/leave log events. No Docker needed. This package **does not alter Gamekeeper**.

## Requirements

- Debian LXC/VM, ~2 vCPU, 4 GB RAM, 10–20 GB disk suggested.
- UDP **14159** forwarded as appropriate; no need to expose the webhook relay.
- `tmux`, `curl`, `tar`, `python3`, SteamCMD 32-bit runtime libraries.
- A **Discord webhook created in #foundry**. Keep its URL secret.

## Install (on a fresh Debian guest)

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y tmux curl ca-certificates python3 tar lib32gcc-s1 lib32stdc++6
sudo useradd -m -s /bin/bash necesse  # skip if already exists
sudo -u necesse mkdir -p /home/necesse/steamcmd /home/necesse/.config
sudo -u necesse bash -c 'cd /home/necesse/steamcmd && curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar xz'
# Copy the contents of this repository to /opt/necesse-ops, preserving scripts/ and systemd/.
sudo mkdir -p /opt/necesse-ops
sudo cp -a ./. /opt/necesse-ops/  # run from extracted necesse-foundry directory
sudo chmod +x /opt/necesse-ops/scripts/*.sh
sudo cp /opt/necesse-ops/necesse.env.example /home/necesse/.config/necesse-ops.env
sudo chown necesse:necesse /home/necesse/.config/necesse-ops.env
sudo chmod 600 /home/necesse/.config/necesse-ops.env
sudo nano /home/necesse/.config/necesse-ops.env  # set DISCORD_WEBHOOK_URL
sudo cp /opt/necesse-ops/systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable necesse.service necesse-relay.service
sudo systemctl start necesse-relay.service
sudo systemctl start necesse.service
```

**IMPORTANT:** If using `sudo cp -a ./ /opt/necesse-ops/`, create `/opt/necesse-ops` first and execute from the extracted repo root; alternatively clone/copy directly to `/opt/necesse-ops`. Check `ls /opt/necesse-ops/scripts/start.sh` before proceeding.

The SteamCMD app ID is **1169370**, and `StartServer-nogui.sh` supports `-world`, `-port`, `-slots`, `-pausewhenempty`. First startup may take several minutes. Server saves and configs live under `/home/necesse/.config/Necesse/`; back them up.

## Operational commands

```bash
sudo systemctl start necesse
sudo systemctl stop necesse  # sends 'stop' to the console, waits for verified exit
sudo systemctl status necesse necesse-relay --no-pager
sudo -u necesse tmux attach -t necesse  # Ctrl+B then D to detach; DO NOT type Ctrl+C
sudo -u necesse /opt/necesse-ops/scripts/warn.sh 30
sudo -u necesse /opt/necesse-ops/scripts/warn.sh 5
sudo -u necesse /opt/necesse-ops/scripts/update.sh # ONLY when stopped
sudo -u necesse tail -n 100 /home/necesse/necesse-console.log
```

**Do not power off the Proxmox guest until `systemctl stop necesse` completes successfully.** The game does **not** save on SIGTERM. If stop times out, investigate manually; do not force-kill or power off. A 4 AM Proxmox hard stop could bypass this safety: configure Gamekeeper to request a graceful guest shutdown and verify it, and ensure Proxmox shutdown timeout accommodates saving. Guest shutdown must invoke systemd ExecStop.

## Webhook behavior

- Start: updating, update success/failure, starting; ready notification **only if a matching log line is observed**.
- Shutdown: start saving, verified stopped; timeout warning if not stopped.
- Warning script: 30 and 5 minutes (wire to Gamekeeper or timers, but not both).
- Player join/leave: **heuristic regex patterns**; test with actual game logs. No chat mirroring.
- The relay follows `/home/necesse/necesse-console.log` from EOF. Its first launch should happen before the game starts. After restarting the relay, old events are not replayed.
- On server updates, `tmux pipe-pane` writes console output. Test actual event wording before relying on joins/leaves. Console readiness regex may require adjustment.
- No claims of crash detection: if unexpected process exit occurs, service can remain `active (exited)` because tmux is external to systemd. Future hardening: watchdog/service supervision.

## Gamekeeper integration

Register the new guest as `necesse` with its Proxmox VM/CT ID and on-demand policy in your existing Gamekeeper configuration (not included). Map the 30- and 5-minute warnings to `warn.sh` **only if your existing Gamekeeper warning hooks can run commands on the guest**. Otherwise send equivalent #foundry webhook messages directly from Gamekeeper. Preserve Gamekeeper's existing verified stop behavior. Do not create a competing 4 AM timer until integration is confirmed.

## Local tests

```bash
python3 -m unittest discover -s tests -v
```

## Known limitations / next steps

1. **Verify real player-event log format.** The included regex is a starting point, not guaranteed to match Necesse's log lines. Provide redacted log samples and tune it.
2. **Startup readiness**: notification depends on a real matching console line; verify on first run.
3. **Shutdown**: console `stop` is required. Confirm behavior in your installed server build before putting it under Gamekeeper.
4. **World name** should contain simple letters/digits to avoid shell quoting issues in the tmux command.
5. **SteamCMD update on every start** may add startup delay. If preferred, move updates to a separate maintenance window once lifecycle is stable.
6. **Systemd active status** indicates start wrapper succeeded, not necessarily continued game-process health. Monitor actual tmux session and game readiness before advertising server as up.
