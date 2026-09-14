[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]$Match,
    [Parameter(Mandatory = $true)][ValidateRange(1, [long]::MaxValue)][long]$MatchId,
    [hashtable]$Headers = @{},
    [ValidateRange(5, 120)][int]$TimeoutSec = 30,
    [ValidateRange(1, 600)][int]$MaxWaitSec = 180,
    [ValidateRange(1, 60)][int]$PollIntervalSec = 10,
    [ValidatePattern('^[1-9][0-9]*$')][string]$ParseJobId,
    [switch]$SkipParse
)

$ErrorActionPreference = 'Stop'
function Test-MatchParsed($Data) {
    if ($null -ne $Data.version -and [int]$Data.version -gt 0) { return $true }
    foreach ($player in @($Data.players)) {
        if (@($player.gold_t).Count -gt 0 -and $null -ne $player.gold_t) { return $true }
        if (@($player.purchase_log).Count -gt 0 -and $null -ne $player.purchase_log) { return $true }
    }
    return $false
}

$parse = [ordered]@{ status = 'already_parsed'; jobId = $ParseJobId; submitted = $false; waitedSeconds = 0; error = $null }
if (Test-MatchParsed $Match) { return [pscustomobject]@{ match = $Match; parse = $parse } }
if ($SkipParse) {
    $parse.status = 'skipped'
    return [pscustomobject]@{ match = $Match; parse = $parse }
}

$timer = [Diagnostics.Stopwatch]::StartNew()
try {
    if ([string]::IsNullOrWhiteSpace($ParseJobId)) {
        $parse.status = 'request_failed'
        Write-Information '该局尚未解析，正在向 OpenDota 提交录像解析。' -InformationAction Continue
        $response = Invoke-RestMethod -Method Post -Uri "https://api.opendota.com/api/request/$MatchId" -Headers $Headers -TimeoutSec $TimeoutSec
        if ([string]$response.job.jobId -notmatch '^[1-9][0-9]*$') { throw 'OpenDota did not return a valid parse job ID.' }
        $parse.jobId = [string]$response.job.jobId
        $parse.submitted = $true
    }
    $parse.status = 'waiting'
    Write-Information "等待 OpenDota 解析任务 $($parse.jobId)，本次最多等待 $MaxWaitSec 秒。" -InformationAction Continue
    while ($timer.Elapsed.TotalSeconds -lt $MaxWaitSec) {
        $remaining = $MaxWaitSec - $timer.Elapsed.TotalSeconds
        Start-Sleep -Milliseconds ([int]([Math]::Min($PollIntervalSec, $remaining) * 1000))
        # A missing job is not proof of success: always verify fresh match data.
        $fresh = Invoke-RestMethod -Method Get -Uri "https://api.opendota.com/api/matches/$MatchId" -Headers $Headers -TimeoutSec $TimeoutSec
        if ($null -ne $fresh -and [long]$fresh.match_id -eq $MatchId -and @($fresh.players).Count -gt 0) {
            $Match = $fresh
            if (Test-MatchParsed $Match) { $parse.status = 'parsed'; break }
        }
        if ($timer.Elapsed.TotalSeconds -ge $MaxWaitSec) { break }
        $job = Invoke-RestMethod -Method Get -Uri "https://api.opendota.com/api/request/$($parse.jobId)" -Headers $Headers -TimeoutSec $TimeoutSec
        if ($null -ne $job -and ($job.state -eq 'failed' -or $job.status -eq 'failed')) {
            $parse.status = 'failed'
            $parse.error = 'OpenDota reported a failed parse job.'
            break
        }
    }
    if ($parse.status -eq 'waiting') { $parse.status = 'timeout' }
}
catch {
    if ($parse.status -ne 'request_failed') { $parse.status = 'poll_failed' }
    $parse.error = $_.Exception.Message
}
finally {
    $timer.Stop()
    $parse.waitedSeconds = [Math]::Round($timer.Elapsed.TotalSeconds, 1)
}
return [pscustomobject]@{ match = $Match; parse = $parse }
