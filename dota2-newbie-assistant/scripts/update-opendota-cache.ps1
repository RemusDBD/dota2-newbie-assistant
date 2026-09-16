[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\references\data"),
    [ValidatePattern('^\d+\.\d+[a-z]?$')]
    [string]$Patch = '7.41f'
)

$ErrorActionPreference = "Stop"
$targetDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null

$headers = @{
    "User-Agent" = "dota2-newbie-assistant/0.9.2 (data cache updater)"
}

$endpoints = [ordered]@{
    "hero-stats.json"     = "https://api.opendota.com/api/heroStats"
    "heroes.json"         = "https://api.opendota.com/api/constants/heroes"
    "items.json"          = "https://api.opendota.com/api/constants/items"
    "hero-abilities.json" = "https://api.opendota.com/api/constants/hero_abilities"
    "abilities.json"      = "https://api.opendota.com/api/constants/abilities"
    "heroes-schinese.json" = "https://www.dota2.com/datafeed/herolist?language=schinese"
    "items-schinese.json"   = "https://www.dota2.com/datafeed/itemlist?language=schinese"
    "patchnotes-$Patch-schinese.json" = "https://www.dota2.com/datafeed/patchnotes?version=$Patch&language=schinese"
}

$writtenFiles = @()

foreach ($entry in $endpoints.GetEnumerator()) {
    $destination = Join-Path $targetDirectory $entry.Key
    $temporary = "$destination.tmp"
    $response = Invoke-RestMethod -Uri $entry.Value -Headers $headers -TimeoutSec 30
    if ($entry.Key -like 'patchnotes-*' -and
        (-not $response.success -or $response.patch_number -ne $Patch -or -not $response.patch_timestamp)) {
        throw "Valve did not return a verified patch payload for $Patch."
    }
    $json = $response | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($temporary, $json, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $destination -Force
    $writtenFiles += $entry.Key
}

$metadata = [ordered]@{
    fetchedAtUtc = [DateTime]::UtcNow.ToString("o")
    provider = "OpenDota + Valve Dota 2 datafeed"
    providers = @("OpenDota", "Valve Dota 2 datafeed")
    apiBases = @("https://api.opendota.com/api", "https://www.dota2.com/datafeed")
    files = $writtenFiles
    configuredPatch = $Patch
    patchNotesSource = $endpoints["patchnotes-$Patch-schinese.json"]
    constantsPatchVerified = $false
    constantsNote = "Fresh downloads do not guarantee current-patch constants. Official patch notes override conflicting OpenDota values; never label heroStats as patch-filtered."
    scopeNote = "Public OpenDota snapshots plus Valve Simplified Chinese hero and item names; statistics are not automatically filtered to patch, role, rank, or beginner bracket."
}

$metadataPath = Join-Path $targetDirectory "cache-metadata.json"
$metadataJson = $metadata | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($metadataPath, $metadataJson, [System.Text.UTF8Encoding]::new($false))

$metadata | ConvertTo-Json -Depth 10
