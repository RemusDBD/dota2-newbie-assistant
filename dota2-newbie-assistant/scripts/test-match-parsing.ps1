# Offline behavioral tests: no OpenDota requests are sent.
$ErrorActionPreference = 'Stop'
$helper = Join-Path $PSScriptRoot 'ensure-match-parsed.ps1'
$basic = '{"match_id":123,"players":[{"hero_id":8,"player_slot":0}]}' | ConvertFrom-Json
$parsed = '{"match_id":123,"version":21,"players":[{"hero_id":8,"player_slot":0,"gold_t":[0,400],"purchase_log":[{"time":60,"key":"boots"}]}]}' | ConvertFrom-Json
function Assert($Condition, $Message) { if (-not $Condition) { throw $Message } }
function Invoke-RestMethod {
    param($Method, $Uri, $Headers, $TimeoutSec)
    $testState.calls.Add("$Method $Uri")
    if ($Method -eq 'Post') {
        if ($testState.scenario -eq 'reject') { throw '429 Too Many Requests' }
        if ($testState.scenario -eq 'invalid') { return [pscustomobject]@{ job = @{} } }
        return [pscustomobject]@{ job = [pscustomobject]@{ jobId = 42 } }
    }
    if ($Uri -like '*/matches/*') {
        $testState.reads++
        if ($testState.scenario -eq 'poll_error') { throw 'network timeout' }
        if ($testState.scenario -in @('success', 'resume')) { return $parsed }
        if ($testState.scenario -eq 'integration' -and $testState.reads -gt 1) { return $parsed }
        return $basic
    }
    if ($testState.scenario -eq 'failed') { return [pscustomobject]@{ state = 'failed' } }
    return $null
}
function Start-Sleep { param($Milliseconds) } # Fast deterministic happy paths; timeout uses the real stopwatch.
foreach ($case in @('already', 'version_only', 'timeline_only', 'skip', 'success', 'resume', 'reject', 'invalid', 'poll_error', 'failed', 'timeout', 'integration')) {
    $testState = @{ scenario = $case; calls = $null; reads = 0 }
    $testState.calls = [Collections.Generic.List[string]]::new()
    $testState.reads = 0
    $options = @{ Match = $basic; MatchId = 123; MaxWaitSec = 1; PollIntervalSec = 1 }
    if ($case -eq 'already') { $options.Match = $parsed }
    if ($case -eq 'version_only') { $options.Match = '{"version":21,"players":[{"hero_id":8}]}' | ConvertFrom-Json }
    if ($case -eq 'timeline_only') { $options.Match = '{"players":[{"hero_id":8,"gold_t":[0,400]}]}' | ConvertFrom-Json }
    if ($case -eq 'skip') { $options.SkipParse = $true }
    if ($case -eq 'resume') { $options.ParseJobId = '42' }
    if ($case -eq 'integration') {
        $review = & (Join-Path $PSScriptRoot 'get-match-review-data.ps1') -MatchId 123 -HeroId 8 -ParseWaitSec 1 6>$null | ConvertFrom-Json
        Assert ($review.parse.status -eq 'parsed' -and $review.dataStatus -eq 'parsed') 'Integration did not use parsed data.'
        Assert ($review.purchaseTimeline.Count -eq 1 -and $review.economyTimeline.Count -eq 2) 'Refreshed timelines missing.'
    }
    else {
        $result = & $helper @options 6>$null
        $expected = switch ($case) {
            'already' { 'already_parsed' }; 'version_only' { 'already_parsed' }; 'timeline_only' { 'already_parsed' }
            'skip' { 'skipped' }; 'success' { 'parsed' }; 'resume' { 'parsed' }
            'reject' { 'request_failed' }; 'invalid' { 'request_failed' }; 'poll_error' { 'poll_failed' }
            'failed' { 'failed' }; 'timeout' { 'timeout' }
        }
        Assert ($result.parse.status -eq $expected) "$case returned $($result.parse.status), expected $expected; error=$($result.parse.error)"
        if ($case -in @('success', 'resume')) { Assert ($result.match.version -eq 21) 'Stale match returned.' }
        if ($case -in @('reject', 'poll_error')) { Assert ($null -ne $result.parse.error) 'Error was lost.' }
        if ($case -eq 'timeout') { Assert ($result.match.version -ne 21) 'Missing job was mistaken for parsed data.' }
    }
    $posts = @($testState.calls | Where-Object { $_ -like 'Post *' }).Count
    $expectedPosts = if ($case -in @('already', 'version_only', 'timeline_only', 'skip', 'resume')) { 0 } else { 1 }
    Assert ($posts -eq $expectedPosts) "$case submitted $posts requests; expected $expectedPosts"
    if ($case -in @('already', 'version_only', 'timeline_only', 'skip')) { Assert ($testState.calls.Count -eq 0) 'Unnecessary request.' }
    Write-Output "PASS $case"
}
