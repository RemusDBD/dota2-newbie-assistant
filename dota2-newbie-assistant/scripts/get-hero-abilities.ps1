[CmdletBinding()]
param(
    [ValidateRange(0, 1000)]
    [int]$HeroId = 0,

    [string]$HeroName = "",

    [string]$DataDirectory = (Join-Path $PSScriptRoot "..\references\data")
)

$ErrorActionPreference = "Stop"

if ($HeroId -le 0 -and [string]::IsNullOrWhiteSpace($HeroName)) {
    throw "Provide -HeroId or -HeroName. HeroName accepts an OpenDota internal or English localized name, such as luna or Luna."
}

$heroStatsPath = Join-Path $DataDirectory "hero-stats.json"
$heroAbilitiesPath = Join-Path $DataDirectory "hero-abilities.json"
$abilitiesPath = Join-Path $DataDirectory "abilities.json"

foreach ($path in @($heroStatsPath, $heroAbilitiesPath, $abilitiesPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing cache file: $path. Run update-opendota-cache.ps1 first."
    }
}

$heroStats = Get-Content -Raw -Encoding UTF8 -LiteralPath $heroStatsPath | ConvertFrom-Json
$heroAbilityMap = Get-Content -Raw -Encoding UTF8 -LiteralPath $heroAbilitiesPath | ConvertFrom-Json
$abilityMap = Get-Content -Raw -Encoding UTF8 -LiteralPath $abilitiesPath | ConvertFrom-Json

$hero = if ($HeroId -gt 0) {
    $heroStats | Where-Object { [int]$_.id -eq $HeroId } | Select-Object -First 1
}
else {
    $normalizedName = $HeroName.Trim()
    $internalName = if ($normalizedName.StartsWith("npc_dota_hero_", [StringComparison]::OrdinalIgnoreCase)) {
        $normalizedName
    }
    else {
        "npc_dota_hero_$($normalizedName.ToLowerInvariant().Replace(' ', '_'))"
    }

    $heroStats | Where-Object {
        $_.name -ieq $normalizedName -or
        $_.name -ieq $internalName -or
        $_.localized_name -ieq $normalizedName
    } | Select-Object -First 1
}

if ($null -eq $hero) {
    throw "Hero not found in the current OpenDota cache."
}

$heroEntry = $heroAbilityMap.($hero.name)
if ($null -eq $heroEntry) {
    throw "Ability mapping not found for $($hero.name)."
}

$resolvedAbilities = foreach ($abilityId in $heroEntry.abilities) {
    if ($abilityId -eq "generic_hidden") {
        continue
    }

    $entry = $abilityMap.$abilityId
    [ordered]@{
        id = $abilityId
        name = $entry.dname
        description = $entry.desc
        behavior = $entry.behavior
        damageType = $entry.dmg_type
        targetTeam = $entry.target_team
        targetType = $entry.target_type
    }
}

$resolvedTalents = foreach ($talent in $heroEntry.talents) {
    $entry = $abilityMap.($talent.name)
    [ordered]@{
        tier = $talent.level
        id = $talent.name
        name = $entry.dname
    }
}

$result = [ordered]@{
    provider = "OpenDota cached constants"
    heroId = [int]$hero.id
    internalName = $hero.name
    localizedName = $hero.localized_name
    abilities = @($resolvedAbilities)
    talents = @($resolvedTalents)
    facets = @($heroEntry.facets)
    limitation = "Metadata helps verify names and descriptions; it does not establish the optimal leveling order or guarantee current-patch interactions."
}

$result | ConvertTo-Json -Depth 30
