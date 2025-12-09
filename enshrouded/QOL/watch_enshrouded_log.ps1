param(
    [Parameter(Mandatory = $true)]
    [string]$WebhookUrl
)

# Path to your Enshrouded log file
$LogPath = "C:\Users\enshrouded\Downloads\steamcmd\enshrouded_server\logs\enshrouded_server.log"

function Send-DiscordMessage {
    param(
        [string]$Text
    )

    # Escape backslashes and double quotes in the message
    $escaped = $Text -replace '\\','\\\\' -replace '"','\"'
    $json = "{""content"":""$escaped""}"

    try {
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType 'application/json' -Body $json | Out-Null
    }
    catch {
        # Uncomment for debugging:
        # Write-Host "Discord error: $_"
    }
}

Write-Host "Watching log: $LogPath"

# Track how many lines we've seen before
$lastLineCount = 0

while ($true) {

    if (-not (Test-Path $LogPath)) {
        # Log file not there yet (e.g., server not started)
        Start-Sleep -Seconds 5
        continue
    }

    # Read full log and count lines
    $lines = Get-Content -Path $LogPath
    $currentCount = $lines.Count

    # 🔴 Detect log reset / truncate (log shrank)
    if ($currentCount -lt $lastLineCount -and $lastLineCount -gt 0) {
        Send-DiscordMessage "The Server has issued a restart."
        $lastLineCount = 0
    }

    # Process only NEW lines
    if ($currentCount -gt $lastLineCount) {
        $newLines = $lines[$lastLineCount..($currentCount - 1)]

        foreach ($line in $newLines) {

            # --- SERVER STARTED ---
            # Example: [I 00:00:04,524] [Session] 'HostOnline' (up)!
            if ($line -like "*'HostOnline' (up)!*") {
                Send-DiscordMessage "The Server has started."
                continue
            }

            # --- PLAYER JOINED ---
            # Example: Player 'blaklabz' logged in with Permissions
            if ($line -match "Player '([^']+)' logged in with Permissions") {
                $player = $matches[1]
                Send-DiscordMessage "$player has joined the server."
                continue
            }

            # --- PLAYER LEFT ---
            # Example: [server] Remove Player 'blaklabz'
            if ($line -match "Remove Player '([^']+)'") {
                $player = $matches[1]
                Send-DiscordMessage "$player has left the server."
                continue
            }
        }
    }

    $lastLineCount = $currentCount
    Start-Sleep -Seconds 2
}