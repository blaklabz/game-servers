param(
    [Parameter(Mandatory = $true)]
    [string]$WebhookUrl,

    [Parameter(Mandatory = $true)]
    [string]$Message
)

# Escape backslashes and double quotes in the message
$escaped = $Message -replace '\\','\\\\' -replace '"','\"'

# Build a simple one-line JSON string: {"content":"..."}
$json = "{""content"":""$escaped""}"

Write-Host "Sending to: $WebhookUrl"
Write-Host "JSON payload:"
Write-Host $json

Invoke-RestMethod -Uri $WebhookUrl -Method Post -ContentType 'application/json' -Body $json