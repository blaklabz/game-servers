param(
    [Parameter(Mandatory = $true)]
    [string]$WebhookUrl
)

$ProcessName = "enshrouded_server"

function Send-DiscordMessage {
    param([string]$Text)

    $escaped = $Text -replace '\\','\\\\' -replace '"','\"'
    $body = "{""content"":""$escaped""}"
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType 'application/json' -Body $body | Out-Null
}

Write-Host "Continuous watcher for process: $ProcessName"

$wasRunning = $false

while ($true) {
    $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

    if ($proc -and -not $wasRunning) {
        $wasRunning = $true
        # Optional: uncomment if you want a "started" message too
        # Send-DiscordMessage "Enshrouded server process STARTED on $env:COMPUTERNAME at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')."
    }
    elseif (-not $proc -and $wasRunning) {
        $wasRunning = $false
        Send-DiscordMessage "The Server has stopped."
    }

    Start-Sleep -Seconds 5
}