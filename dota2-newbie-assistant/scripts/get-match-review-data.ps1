[CmdletBinding(DefaultParameterSetName = "ByName")]
param(
    [Parameter(Mandatory = $true)]
    [long]$MatchId,

    [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
    [string]$HeroName,

    [Parameter(Mandatory = $true, ParameterSetName = "ById")]
    [ValidateRange(1, 1000)]
    [int]$HeroId,

    [ValidateRange(5, 120)]
    [int]$TimeoutSec = 30,

    [ValidateRange(1, 600)]
    [int]$ParseWaitSec = 180,

    [ValidatePattern('^[1-9][0-9]*$')]
    [string]$ParseJobId,

    [switch]$SkipParse,

    [string]$DataDirectory = (Join-Path $PSScriptRoot "..\references\data")
)

$ErrorActionPreference = "Stop"

if ($MatchId -le 0) {
    throw "MatchId must be a positive Dota 2 match ID."
}

function Normalize-HeroToken {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    return ($Value.Trim().ToLowerInvariant() -replace "[\s_\-\.']", "")
}

function Convert-ToClock {
    param([AllowNull()]$Seconds)

    if ($null -eq $Seconds) {
        return $null
    }

    $numericSeconds = [int]$Seconds
    $sign = if ($numericSeconds -lt 0) { "-" } else { "" }
    $absolute = [Math]::Abs($numericSeconds)
    return "{0}{1}:{2:00}" -f $sign, [Math]::Floor($absolute / 60), ($absolute % 60)
}

function Get-TimelineValue {
    param(
        [AllowNull()]$Timeline,
        [int]$Minute
    )

    if ($null -eq $Timeline) {
        return $null
    }

    $values = @($Timeline)
    if ($Minute -lt 0 -or $Minute -ge $values.Count) {
        return $null
    }

    return $values[$Minute]
}

function Get-PropertyArray {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return
    }

    foreach ($value in @($property.Value)) {
        if ($null -ne $value) {
            $value
        }
    }
}

function Test-PropertyArrayAvailable {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    return @(Get-PropertyArray -Object $Object -Name $Name).Count -gt 0
}

function Get-MapProperties {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return
    }

    $property.Value.PSObject.Properties
}

function Convert-ToOutputArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return ,([object[]]::new(0))
    }

    return ,([object[]]@($Value))
}

function Get-ObjectValueSum {
    param([AllowNull()]$Object)

    if ($null -eq $Object) {
        return 0
    }

    $sum = 0
    foreach ($property in $Object.PSObject.Properties) {
        if ($null -ne $property.Value) {
            $sum += [int]$property.Value
        }
    }
    return $sum
}

function Get-ObjectPropertyCount {
    param([AllowNull()]$Object)

    if ($null -eq $Object) {
        return 0
    }

    return @($Object.PSObject.Properties).Count
}

function Test-IsRadiant {
    param($Player)

    if ($null -ne $Player.isRadiant) {
        return [bool]$Player.isRadiant
    }

    return ([int]$Player.player_slot -lt 128)
}

$localizedHeroesPath = Join-Path $DataDirectory "heroes-schinese.json"
$localizedItemsPath = Join-Path $DataDirectory "items-schinese.json"
$openDotaItemsPath = Join-Path $DataDirectory "items.json"

foreach ($path in @($localizedHeroesPath, $localizedItemsPath, $openDotaItemsPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing cache file: $path. Run update-opendota-cache.ps1 first."
    }
}

$localizedHeroResponse = Get-Content -Raw -Encoding UTF8 -LiteralPath $localizedHeroesPath | ConvertFrom-Json
$localizedItemResponse = Get-Content -Raw -Encoding UTF8 -LiteralPath $localizedItemsPath | ConvertFrom-Json
$openDotaItems = Get-Content -Raw -Encoding UTF8 -LiteralPath $openDotaItemsPath | ConvertFrom-Json

$heroes = @($localizedHeroResponse.result.data.heroes)
$localizedItems = @($localizedItemResponse.result.data.itemabilities)

$heroById = @{}
$heroByInternalName = @{}
foreach ($hero in $heroes) {
    $heroById[[string][int]$hero.id] = $hero
    $heroByInternalName[[string]$hero.name] = $hero
}

$itemById = @{}
$itemByKey = @{}
foreach ($item in $localizedItems) {
    $key = ([string]$item.name) -replace "^item_", ""
    $itemById[[string][int]$item.id] = $item
    $itemByKey[$key] = $item
}

$openDotaItemByKey = @{}
foreach ($property in $openDotaItems.PSObject.Properties) {
    $openDotaItemByKey[$property.Name] = $property.Value
}

$commonAliases = @{
    "am" = "npc_dota_hero_antimage"
    "pa" = "npc_dota_hero_phantom_assassin"
    "tb" = "npc_dota_hero_terrorblade"
    "ck" = "npc_dota_hero_chaos_knight"
    "dk" = "npc_dota_hero_dragon_knight"
    "od" = "npc_dota_hero_obsidian_destroyer"
    "ta" = "npc_dota_hero_templar_assassin"
    "尸王" = "npc_dota_hero_undying"
    "火猫" = "npc_dota_hero_ember_spirit"
    "蓝猫" = "npc_dota_hero_storm_spirit"
    "紫猫" = "npc_dota_hero_void_spirit"
    "土猫" = "npc_dota_hero_earth_spirit"
    "屠夫" = "npc_dota_hero_pudge"
    "钢背" = "npc_dota_hero_bristleback"
    "刚背" = "npc_dota_hero_bristleback"
    "大圣" = "npc_dota_hero_monkey_king"
    "猴王" = "npc_dota_hero_monkey_king"
    "飞机" = "npc_dota_hero_gyrocopter"
    "电魂" = "npc_dota_hero_razor"
    "敌法" = "npc_dota_hero_antimage"
    "小黑" = "npc_dota_hero_drow_ranger"
    "小鱼" = "npc_dota_hero_slark"
    "大鱼" = "npc_dota_hero_slardar"
    "火枪" = "npc_dota_hero_sniper"
    "拍拍" = "npc_dota_hero_ursa"
    "白牛" = "npc_dota_hero_spirit_breaker"
    "大牛" = "npc_dota_hero_elder_titan"
    "冰魂" = "npc_dota_hero_ancient_apparition"
    "冰女" = "npc_dota_hero_crystal_maiden"
    "火女" = "npc_dota_hero_lina"
    "影刺" = "npc_dota_hero_phantom_assassin"
}

function Resolve-HeroInput {
    if ($PSCmdlet.ParameterSetName -eq "ById") {
        return $heroById[[string]$HeroId]
    }

    $trimmed = $HeroName.Trim()
    $aliasKey = $trimmed.ToLowerInvariant()
    if ($commonAliases.ContainsKey($aliasKey)) {
        return $heroByInternalName[$commonAliases[$aliasKey]]
    }

    $token = Normalize-HeroToken $trimmed
    return $heroes | Where-Object {
        $internalName = [string]$_.name
        $shortInternalName = $internalName -replace "^npc_dota_hero_", ""
        (Normalize-HeroToken $_.name_loc) -eq $token -or
        (Normalize-HeroToken $_.name_english_loc) -eq $token -or
        (Normalize-HeroToken $internalName) -eq $token -or
        (Normalize-HeroToken $shortInternalName) -eq $token
    } | Select-Object -First 1
}

function Resolve-ItemByKey {
    param([AllowNull()][string]$Key)

    if ([string]::IsNullOrWhiteSpace($Key)) {
        return $null
    }

    $localized = $itemByKey[$Key]
    $fallback = $openDotaItemByKey[$Key]
    return [ordered]@{
        key = $Key
        name = if ($null -ne $localized -and -not [string]::IsNullOrWhiteSpace([string]$localized.name_loc)) { [string]$localized.name_loc } elseif ($null -ne $fallback) { [string]$fallback.dname } else { $Key }
        englishName = if ($null -ne $localized) { [string]$localized.name_english_loc } elseif ($null -ne $fallback) { [string]$fallback.dname } else { $null }
        itemId = if ($null -ne $localized) { [int]$localized.id } elseif ($null -ne $fallback) { [int]$fallback.id } else { $null }
    }
}

function Resolve-ItemById {
    param([AllowNull()]$Id)

    if ($null -eq $Id -or [int]$Id -le 0) {
        return $null
    }

    $localized = $itemById[[string][int]$Id]
    if ($null -ne $localized) {
        return [ordered]@{
            itemId = [int]$localized.id
            key = ([string]$localized.name) -replace "^item_", ""
            name = [string]$localized.name_loc
            englishName = [string]$localized.name_english_loc
        }
    }

    $fallbackProperty = $openDotaItems.PSObject.Properties | Where-Object { [int]$_.Value.id -eq [int]$Id } | Select-Object -First 1
    return [ordered]@{
        itemId = [int]$Id
        key = if ($null -ne $fallbackProperty) { $fallbackProperty.Name } else { $null }
        name = if ($null -ne $fallbackProperty) { [string]$fallbackProperty.Value.dname } else { "Item $Id" }
        englishName = if ($null -ne $fallbackProperty) { [string]$fallbackProperty.Value.dname } else { $null }
    }
}

function Get-HeroDisplay {
    param([int]$Id)

    $hero = $heroById[[string]$Id]
    if ($null -eq $hero) {
        return [ordered]@{
            heroId = $Id
            name = "Hero $Id"
            englishName = $null
            internalName = $null
        }
    }

    return [ordered]@{
        heroId = [int]$hero.id
        name = [string]$hero.name_loc
        englishName = [string]$hero.name_english_loc
        internalName = [string]$hero.name
    }
}

$headers = @{
    "User-Agent" = "dota2-newbie-assistant/0.9.0 (OpenDota match review)"
}
$matchUri = "https://api.opendota.com/api/matches/$MatchId"

try {
    $match = Invoke-RestMethod -Uri $matchUri -Headers $headers -TimeoutSec $TimeoutSec
}
catch {
    throw "OpenDota match lookup failed for $MatchId`: $($_.Exception.Message)"
}

if ($null -eq $match -or @($match.players).Count -eq 0) {
    throw "OpenDota returned no player data for match $MatchId."
}
if ([long]$match.match_id -ne $MatchId) {
    throw "OpenDota returned a different match ID for $MatchId."
}

$resolvedHero = Resolve-HeroInput
if ($null -eq $resolvedHero) {
    $matchHeroNames = foreach ($player in @($match.players)) {
        (Get-HeroDisplay -Id ([int]$player.hero_id)).name
    }
    throw "Hero '$HeroName' was not recognized. Match heroes: $($matchHeroNames -join ', ')."
}

$players = @($match.players)
$selectedPlayer = $null
$selectedIndex = -1
for ($index = 0; $index -lt $players.Count; $index++) {
    if ([int]$players[$index].hero_id -eq [int]$resolvedHero.id) {
        $selectedPlayer = $players[$index]
        $selectedIndex = $index
        break
    }
}

if ($null -eq $selectedPlayer) {
    $matchHeroNames = foreach ($player in $players) {
        (Get-HeroDisplay -Id ([int]$player.hero_id)).name
    }
    throw "Hero '$([string]$resolvedHero.name_loc)' is not in match $MatchId. Match heroes: $($matchHeroNames -join ', ')."
}

$parseOptions = @{ Match = $match; MatchId = $MatchId; Headers = $headers; TimeoutSec = $TimeoutSec; MaxWaitSec = $ParseWaitSec; SkipParse = $SkipParse }
if (-not [string]::IsNullOrWhiteSpace($ParseJobId)) { $parseOptions.ParseJobId = $ParseJobId }
$parseResult = & (Join-Path $PSScriptRoot 'ensure-match-parsed.ps1') @parseOptions
$match = $parseResult.match
$players = @($match.players)
$selectedIndex = -1
for ($index = 0; $index -lt $players.Count; $index++) {
    if ([int]$players[$index].hero_id -eq [int]$resolvedHero.id) { $selectedIndex = $index; break }
}
if ($selectedIndex -lt 0) { throw 'Selected hero is missing from refreshed match data.' }
$selectedPlayer = $players[$selectedIndex]
$selectedIsRadiant = Test-IsRadiant $selectedPlayer
$selectedWon = if ($selectedIsRadiant) { [bool]$match.radiant_win } else { -not [bool]$match.radiant_win }
$purchaseLog = @(Get-PropertyArray -Object $selectedPlayer -Name "purchase_log")
$selectedGoldTimeline = @(Get-PropertyArray -Object $selectedPlayer -Name "gold_t")
$selectedXpTimeline = @(Get-PropertyArray -Object $selectedPlayer -Name "xp_t")
$selectedLastHitTimeline = @(Get-PropertyArray -Object $selectedPlayer -Name "lh_t")
$selectedDenyTimeline = @(Get-PropertyArray -Object $selectedPlayer -Name "dn_t")
$radiantGoldAdvantageTimeline = @(Get-PropertyArray -Object $match -Name "radiant_gold_adv")
$radiantXpAdvantageTimeline = @(Get-PropertyArray -Object $match -Name "radiant_xp_adv")
$matchTeamfights = @(Get-PropertyArray -Object $match -Name "teamfights")
$matchObjectives = @(Get-PropertyArray -Object $match -Name "objectives")
$buybackLog = @(Get-PropertyArray -Object $selectedPlayer -Name "buyback_log")
$abilityUpgradeIds = @(Get-PropertyArray -Object $selectedPlayer -Name "ability_upgrades_arr")
$hasPurchaseTimeline = $purchaseLog.Count -gt 0
$hasEconomyTimeline = $selectedGoldTimeline.Count -gt 0
$hasLastHitTimeline = $selectedLastHitTimeline.Count -gt 0
$hasTeamfights = $matchTeamfights.Count -gt 0
$hasObjectives = $matchObjectives.Count -gt 0
$hasVisionLogs = (Test-PropertyArrayAvailable -Object $selectedPlayer -Name "obs_log") -or (Test-PropertyArrayAvailable -Object $selectedPlayer -Name "sen_log")
$dataStatus = if ($hasPurchaseTimeline -or $hasEconomyTimeline) { "parsed" } else { "basic" }

$checkpointMinutes = @(5, 10, 15, 20, 25, 30, 40, 50, 60)
$durationMinutes = if ($null -ne $match.duration) { [Math]::Floor([int]$match.duration / 60) } else { 0 }
$checkpoints = foreach ($minute in $checkpointMinutes) {
    if (-not ($hasEconomyTimeline -or $hasLastHitTimeline -or $radiantGoldAdvantageTimeline.Count -gt 0 -or $radiantXpAdvantageTimeline.Count -gt 0)) {
        continue
    }

    if ($minute -gt $durationMinutes) {
        continue
    }

    $selectedGold = Get-TimelineValue -Timeline $selectedGoldTimeline -Minute $minute
    $overallGoldValues = foreach ($player in $players) {
        $value = Get-TimelineValue -Timeline $player.gold_t -Minute $minute
        if ($null -ne $value) { [int]$value }
    }
    $teamGoldValues = foreach ($player in $players) {
        if ((Test-IsRadiant $player) -ne $selectedIsRadiant) { continue }
        $value = Get-TimelineValue -Timeline $player.gold_t -Minute $minute
        if ($null -ne $value) { [int]$value }
    }

    $radiantGoldAdvantage = Get-TimelineValue -Timeline $radiantGoldAdvantageTimeline -Minute $minute
    $radiantXpAdvantage = Get-TimelineValue -Timeline $radiantXpAdvantageTimeline -Minute $minute

    [ordered]@{
        minute = $minute
        selectedGold = $selectedGold
        selectedXp = Get-TimelineValue -Timeline $selectedXpTimeline -Minute $minute
        selectedLastHits = Get-TimelineValue -Timeline $selectedLastHitTimeline -Minute $minute
        selectedDenies = Get-TimelineValue -Timeline $selectedDenyTimeline -Minute $minute
        selectedGoldRankOverall = if ($null -ne $selectedGold -and @($overallGoldValues).Count -gt 0) { 1 + @($overallGoldValues | Where-Object { $_ -gt [int]$selectedGold }).Count } else { $null }
        selectedGoldRankTeam = if ($null -ne $selectedGold -and @($teamGoldValues).Count -gt 0) { 1 + @($teamGoldValues | Where-Object { $_ -gt [int]$selectedGold }).Count } else { $null }
        selectedTeamGoldAdvantage = if ($null -eq $radiantGoldAdvantage) { $null } elseif ($selectedIsRadiant) { [int]$radiantGoldAdvantage } else { -[int]$radiantGoldAdvantage }
        selectedTeamXpAdvantage = if ($null -eq $radiantXpAdvantage) { $null } elseif ($selectedIsRadiant) { [int]$radiantXpAdvantage } else { -[int]$radiantXpAdvantage }
    }
}

$economyTimeline = @()
if ($hasEconomyTimeline -or $hasLastHitTimeline) {
    $timelineLength = @(
        $selectedGoldTimeline.Count,
        $selectedXpTimeline.Count,
        $selectedLastHitTimeline.Count,
        $selectedDenyTimeline.Count,
        $radiantGoldAdvantageTimeline.Count,
        $radiantXpAdvantageTimeline.Count
    ) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

    for ($minute = 0; $minute -lt [int]$timelineLength; $minute++) {
        $radiantGoldAdvantage = Get-TimelineValue -Timeline $radiantGoldAdvantageTimeline -Minute $minute
        $radiantXpAdvantage = Get-TimelineValue -Timeline $radiantXpAdvantageTimeline -Minute $minute
        $economyTimeline += [ordered]@{
            minute = $minute
            gold = Get-TimelineValue -Timeline $selectedGoldTimeline -Minute $minute
            xp = Get-TimelineValue -Timeline $selectedXpTimeline -Minute $minute
            lastHits = Get-TimelineValue -Timeline $selectedLastHitTimeline -Minute $minute
            denies = Get-TimelineValue -Timeline $selectedDenyTimeline -Minute $minute
            selectedTeamGoldAdvantage = if ($null -eq $radiantGoldAdvantage) { $null } elseif ($selectedIsRadiant) { [int]$radiantGoldAdvantage } else { -[int]$radiantGoldAdvantage }
            selectedTeamXpAdvantage = if ($null -eq $radiantXpAdvantage) { $null } elseif ($selectedIsRadiant) { [int]$radiantXpAdvantage } else { -[int]$radiantXpAdvantage }
        }
    }
}

$purchaseTimeline = foreach ($purchase in $purchaseLog) {
    $item = Resolve-ItemByKey -Key ([string]$purchase.key)
    [ordered]@{
        timeSeconds = [int]$purchase.time
        time = Convert-ToClock $purchase.time
        key = $item.key
        name = $item.name
        englishName = $item.englishName
        itemId = $item.itemId
    }
}

$finalItems = foreach ($slotName in @("item_0", "item_1", "item_2", "item_3", "item_4", "item_5", "backpack_0", "backpack_1", "backpack_2", "item_neutral", "item_neutral2")) {
    $property = $selectedPlayer.PSObject.Properties[$slotName]
    if ($null -eq $property -or $null -eq $property.Value -or [int]$property.Value -le 0) {
        continue
    }
    $item = Resolve-ItemById -Id $property.Value
    [ordered]@{
        slot = $slotName
        itemId = $item.itemId
        key = $item.key
        name = $item.name
        englishName = $item.englishName
    }
}

$lineup = for ($index = 0; $index -lt $players.Count; $index++) {
    $player = $players[$index]
    $isRadiant = Test-IsRadiant $player
    $hero = Get-HeroDisplay -Id ([int]$player.hero_id)
    [ordered]@{
        playerIndex = $index
        side = if ($isRadiant) { "Radiant" } else { "Dire" }
        heroId = $hero.heroId
        hero = $hero.name
        englishHero = $hero.englishName
        kills = $player.kills
        deaths = $player.deaths
        assists = $player.assists
        level = $player.level
        lastHits = $player.last_hits
        denies = $player.denies
        goldPerMinute = $player.gold_per_min
        xpPerMinute = $player.xp_per_min
        netWorth = $player.net_worth
        heroDamage = $player.hero_damage
        towerDamage = $player.tower_damage
        heroHealing = $player.hero_healing
        lane = $player.lane
        laneRole = $player.lane_role
        teamfightParticipation = $player.teamfight_participation
        minute10 = [ordered]@{
            gold = Get-TimelineValue -Timeline $player.gold_t -Minute 10
            xp = Get-TimelineValue -Timeline $player.xp_t -Minute 10
            lastHits = Get-TimelineValue -Timeline $player.lh_t -Minute 10
            denies = Get-TimelineValue -Timeline $player.dn_t -Minute 10
        }
    }
}

$teamfights = for ($fightIndex = 0; $fightIndex -lt $matchTeamfights.Count; $fightIndex++) {
    $fight = $matchTeamfights[$fightIndex]
    $fightPlayers = @($fight.players)
    $selectedFight = if ($selectedIndex -ge 0 -and $selectedIndex -lt $fightPlayers.Count) { $fightPlayers[$selectedIndex] } else { $null }
    $alliedDeaths = 0
    $enemyDeaths = 0
    $alliedDamage = 0
    $enemyDamage = 0

    for ($index = 0; $index -lt $fightPlayers.Count; $index++) {
        $sameTeam = (Test-IsRadiant $players[$index]) -eq $selectedIsRadiant
        if ($sameTeam) {
            $alliedDeaths += [int]$fightPlayers[$index].deaths
            $alliedDamage += [int]$fightPlayers[$index].damage
        }
        else {
            $enemyDeaths += [int]$fightPlayers[$index].deaths
            $enemyDamage += [int]$fightPlayers[$index].damage
        }
    }

    $selectedKills = if ($null -ne $selectedFight) { Get-ObjectValueSum $selectedFight.killed } else { 0 }
    $abilityUseKinds = if ($null -ne $selectedFight) { Get-ObjectPropertyCount $selectedFight.ability_uses } else { 0 }
    $itemUseKinds = if ($null -ne $selectedFight) { Get-ObjectPropertyCount $selectedFight.item_uses } else { 0 }
    $hasRecordedContribution = $null -ne $selectedFight -and (
        [int]$selectedFight.damage -gt 0 -or
        [int]$selectedFight.healing -gt 0 -or
        [int]$selectedFight.deaths -gt 0 -or
        $selectedKills -gt 0 -or
        $abilityUseKinds -gt 0 -or
        $itemUseKinds -gt 0
    )

    [ordered]@{
        index = $fightIndex
        startSeconds = [int]$fight.start
        start = Convert-ToClock $fight.start
        endSeconds = [int]$fight.end
        end = Convert-ToClock $fight.end
        totalDeaths = $fight.deaths
        alliedDeaths = $alliedDeaths
        enemyDeaths = $enemyDeaths
        alliedDamage = $alliedDamage
        enemyDamage = $enemyDamage
        selectedHero = [ordered]@{
            hasRecordedContribution = $hasRecordedContribution
            damage = if ($null -ne $selectedFight) { $selectedFight.damage } else { $null }
            healing = if ($null -ne $selectedFight) { $selectedFight.healing } else { $null }
            kills = $selectedKills
            deaths = if ($null -ne $selectedFight) { $selectedFight.deaths } else { $null }
            buybacks = if ($null -ne $selectedFight) { $selectedFight.buybacks } else { $null }
            goldDelta = if ($null -ne $selectedFight) { $selectedFight.gold_delta } else { $null }
            xpDelta = if ($null -ne $selectedFight) { $selectedFight.xp_delta } else { $null }
            abilityUseKinds = $abilityUseKinds
            itemUseKinds = $itemUseKinds
        }
    }
}

$objectives = foreach ($objective in $matchObjectives) {
    [ordered]@{
        timeSeconds = $objective.time
        time = Convert-ToClock $objective.time
        type = $objective.type
        unit = $objective.unit
        key = $objective.key
        team = $objective.team
        playerSlot = if ($null -ne $objective.player_slot) { $objective.player_slot } else { $objective.slot }
        killer = $objective.killer
        value = $objective.value
    }
}

$killedBy = foreach ($property in @(Get-MapProperties -Object $selectedPlayer -Name "killed_by")) {
    $internalName = [string]$property.Name
    $hero = $heroByInternalName[$internalName]
    [ordered]@{
        hero = if ($null -ne $hero) { [string]$hero.name_loc } else { $internalName }
        englishHero = if ($null -ne $hero) { [string]$hero.name_english_loc } else { $null }
        count = [int]$property.Value
    }
}

$damageReceived = foreach ($property in @(Get-MapProperties -Object $selectedPlayer -Name "damage_inflictor_received")) {
    [ordered]@{
        source = [string]$property.Name
        amount = [int]$property.Value
    }
}

$limitations = @(
    "This is a structured-data review, not a video or frame-by-frame replay review.",
    "OpenDota fields may be absent even when a match exists; missing timelines must not be inferred from final stats.",
    "Teamfight records show parsed contribution, not the player's intent, camera, exact route, or teleport availability.",
    "The specified hero selects the analysis target and does not establish who controlled that hero."
)
if ($dataStatus -eq "basic") {
    $limitations += "This match has basic result data only; precise purchase timing, minute-by-minute economy, and turning-point analysis are unavailable."
}

$result = [ordered]@{
    schemaVersion = "1.0"
    fetchedAtUtc = [DateTime]::UtcNow.ToString("o")
    provider = "OpenDota"
    source = $matchUri
    dataStatus = $dataStatus
    parse = $parseResult.parse
    availability = [ordered]@{
        purchaseTimeline = $hasPurchaseTimeline
        economyTimeline = $hasEconomyTimeline
        lastHitTimeline = $hasLastHitTimeline
        teamfights = $hasTeamfights
        objectives = $hasObjectives
        visionLogs = $hasVisionLogs
    }
    match = [ordered]@{
        matchId = [long]$match.match_id
        startTimeUtc = if ($null -ne $match.start_time) { [DateTimeOffset]::FromUnixTimeSeconds([long]$match.start_time).UtcDateTime.ToString("o") } else { $null }
        durationSeconds = $match.duration
        duration = Convert-ToClock $match.duration
        providerPatchId = $match.patch
        radiantWin = $match.radiant_win
        radiantScore = $match.radiant_score
        direScore = $match.dire_score
        gameMode = $match.game_mode
        lobbyType = $match.lobby_type
        region = $match.region
        parsedVersion = $match.version
    }
    selectedHero = [ordered]@{
        heroId = [int]$resolvedHero.id
        hero = [string]$resolvedHero.name_loc
        englishHero = [string]$resolvedHero.name_english_loc
        internalName = [string]$resolvedHero.name
        side = if ($selectedIsRadiant) { "Radiant" } else { "Dire" }
        won = $selectedWon
        kills = $selectedPlayer.kills
        deaths = $selectedPlayer.deaths
        assists = $selectedPlayer.assists
        level = $selectedPlayer.level
        lastHits = $selectedPlayer.last_hits
        denies = $selectedPlayer.denies
        goldPerMinute = $selectedPlayer.gold_per_min
        xpPerMinute = $selectedPlayer.xp_per_min
        netWorth = $selectedPlayer.net_worth
        heroDamage = $selectedPlayer.hero_damage
        towerDamage = $selectedPlayer.tower_damage
        heroHealing = $selectedPlayer.hero_healing
        goldSpent = $selectedPlayer.gold_spent
        lane = $selectedPlayer.lane
        laneRole = $selectedPlayer.lane_role
        teamfightParticipation = $selectedPlayer.teamfight_participation
        observersPlaced = if ($null -ne $selectedPlayer.obs_placed) { $selectedPlayer.obs_placed } else { $selectedPlayer.observers_placed }
        sentriesPlaced = $selectedPlayer.sen_placed
        observerWardsPurchased = $selectedPlayer.purchase_ward_observer
        sentryWardsPurchased = $selectedPlayer.purchase_ward_sentry
        creepsStacked = $selectedPlayer.creeps_stacked
        campsStacked = $selectedPlayer.camps_stacked
        buybacks = $buybackLog.Count
        abilityUpgradeIds = $abilityUpgradeIds
        killedBy = Convert-ToOutputArray $killedBy
        damageReceivedBySource = Convert-ToOutputArray ($damageReceived | Sort-Object amount -Descending)
        finalItems = Convert-ToOutputArray $finalItems
    }
    checkpoints = Convert-ToOutputArray $checkpoints
    economyTimeline = Convert-ToOutputArray $economyTimeline
    purchaseTimeline = Convert-ToOutputArray $purchaseTimeline
    teamfights = Convert-ToOutputArray $teamfights
    objectives = Convert-ToOutputArray $objectives
    lineup = Convert-ToOutputArray $lineup
    limitations = $limitations
}

$result | ConvertTo-Json -Depth 100
