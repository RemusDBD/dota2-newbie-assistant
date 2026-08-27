[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\references\data")
)

$ErrorActionPreference = "Stop"
$targetDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null

$headers = @{
    "User-Agent" = "dota2-newbie-assistant/0.5.0 (OpenDota cache updater)"
}

$endpoints = [ordered]@{
    "hero-stats.json"     = "https://api.opendota.com/api/heroStats"
    "heroes.json"         = "https://api.opendota.com/api/constants/heroes"
    "items.json"          = "https://api.opendota.com/api/constants/items"
    "hero-abilities.json" = "https://api.opendota.com/api/constants/hero_abilities"
    "abilities.json"      = "https://api.opendota.com/api/constants/abilities"
}

$writtenFiles = @()

foreach ($entry in $endpoints.GetEnumerator()) {
    $destination = Join-Path $targetDirectory $entry.Key
    $temporary = "$destination.tmp"
    $response = Invoke-RestMethod -Uri $entry.Value -Headers $headers -TimeoutSec 30
    $json = $response | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($temporary, $json, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $destination -Force
    $writtenFiles += $entry.Key
}

$metadata = [ordered]@{
    fetchedAtUtc = [DateTime]::UtcNow.ToString("o")
    provider = "OpenDota"
    apiBase = "https://api.opendota.com/api"
    files = $writtenFiles
    scopeNote = "Public OpenDota snapshots; not automatically filtered to patch, role, rank, or beginner bracket."
}

$metadataPath = Join-Path $targetDirectory "cache-metadata.json"
$metadataJson = $metadata | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($metadataPath, $metadataJson, [System.Text.UTF8Encoding]::new($false))

$metadata | ConvertTo-Json -Depth 10
