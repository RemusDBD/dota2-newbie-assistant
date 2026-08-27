[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 1000)]
    [int]$HeroId,

    [ValidateRange(0, 1000)]
    [int]$OpponentHeroId = 0,

    [switch]$IncludeItemPopularity,

    [ValidateRange(5, 120)]
    [int]$TimeoutSec = 20
)

$ErrorActionPreference = "Stop"
$headers = @{
    "User-Agent" = "dota2-newbie-assistant/0.4.0 (OpenDota evidence lookup)"
}

$matchupsUri = "https://api.opendota.com/api/heroes/$HeroId/matchups"
$itemsUri = "https://api.opendota.com/api/heroes/$HeroId/itemPopularity"

$errors = @()
$matchups = @()
$itemPopularity = $null

try {
    $matchups = Invoke-RestMethod -Uri $matchupsUri -Headers $headers -TimeoutSec $TimeoutSec
}
catch {
    $errors += "OpenDota matchup lookup failed: $($_.Exception.Message)"
}

if ($IncludeItemPopularity) {
    try {
        $itemPopularity = Invoke-RestMethod -Uri $itemsUri -Headers $headers -TimeoutSec $TimeoutSec
    }
    catch {
        $errors += "OpenDota item-popularity lookup failed: $($_.Exception.Message)"
    }
}

$selectedMatchup = $null
if ($OpponentHeroId -gt 0) {
    $row = $matchups | Where-Object { [int]$_.hero_id -eq $OpponentHeroId } | Select-Object -First 1
    if ($null -ne $row) {
        $games = [int]$row.games_played
        $wins = [int]$row.wins
        $winRate = if ($games -gt 0) { [Math]::Round(($wins / $games) * 100, 2) } else { $null }
        $selectedMatchup = [ordered]@{
            opponentHeroId = $OpponentHeroId
            gamesPlayed = $games
            wins = $wins
            winRatePercent = $winRate
        }
    }
}

$result = [ordered]@{
    fetchedAtUtc = [DateTime]::UtcNow.ToString("o")
    provider = "OpenDota"
    heroId = $HeroId
    matchup = $selectedMatchup
    itemPopularity = $itemPopularity
    errors = $errors
    limitations = @(
        "The public endpoints are not automatically filtered to the configured Dota patch.",
        "The results are not automatically filtered by role, rank, or beginner bracket.",
        "Item popularity is observational and does not prove that an item causes wins."
    )
}

$result | ConvertTo-Json -Depth 100
