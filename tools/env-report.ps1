# Which change is on which environment? (Windows version of tools/env_report.py)
# Called by: tools\db report [env ...]
# Reads Flyway's history from each environment (read-only) and prints a Markdown
# table: one row per change, one column per environment.
# Works with Windows PowerShell 5.1 and PowerShell 7.
param([Parameter(Mandatory = $true)][string]$EnvList)   # e.g. "dev qa uat prod"
$Envs = @($EnvList -split '[,\s]+' | Where-Object { $_ })

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Get-FlywayInfo([string]$envName) {
    if ($env:OS -eq 'Windows_NT') {
        $out = & cmd /c "tools\db.cmd info $envName `"-outputType=json`"" 2>$null
    } else {
        $out = & bash tools/db.sh info $envName -outputType=json 2>$null
    }
    $text = ($out | Out-String)
    $start = $text.IndexOf('{')
    if ($start -lt 0) { return $null }
    try { $data = $text.Substring($start) | ConvertFrom-Json } catch { return $null }
    if ($data.error) { return $null }
    return $data
}

function Get-Cell($m) {
    $state = [string]$m.state
    $day = ''
    $when = $m.installedOnUTC
    if ($when -is [datetime]) { $day = $when.ToUniversalTime().ToString('yyyy-MM-dd') }
    elseif ($when) { $day = ([string]$when).Substring(0, 10) }
    switch -Regex ($state) {
        '^(Success|Baseline)$'                  { return "OK $day" }
        '^Out of Order$'                        { return "OK $day (late)" }
        '^(Ignored \(Baseline\)|Below Baseline)$' { return 'baseline' }
        '^Pending$'                             { return 'PENDING' }
        '^Outdated$'                            { return 'CHANGED - not applied' }
        '^Failed$'                              { return 'FAILED' }
        '^Missing'                              { return 'applied, file removed' }
        '^Future'                               { return 'newer than Git' }
    }
    if ($state) { return $state } else { return '-' }
}

function Get-Rows($data) {
    $rows = @{}
    foreach ($m in $data.migrations) {
        $state = [string]$m.state
        $version = [string]$m.version
        if ($version) {
            $key = "V:$version"
            $label = "V$version  $($m.description)"
            $num = 0L; [void][long]::TryParse($version, [ref]$num)
            $sort = '0 ' + $num.ToString('D20')
            if ($rows.ContainsKey($key) -and -not $m.installedOnUTC) { continue }
        } else {
            if ($state -eq 'Superseded') { continue }
            $key = "R:$($m.description)"
            $label = "R  $($m.description)"
            $sort = "1 $($m.description)"
        }
        $rows[$key] = @{ Sort = $sort; Label = $label; Cell = (Get-Cell $m) }
    }
    return $rows
}

$perEnv = [ordered]@{}
foreach ($e in $Envs) {
    [Console]::Error.WriteLine(">> Reading $e ...")
    $data = Get-FlywayInfo $e
    if ($data) { $perEnv[$e] = Get-Rows $data } else { $perEnv[$e] = $null }
}

$labels = @{}
foreach ($rows in $perEnv.Values) {
    if ($rows) { foreach ($k in $rows.Keys) { $labels[$k] = $rows[$k] } }
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('## Which change is on which environment')
$lines.Add('')
$lines.Add('Generated ' + (Get-Date -Format 'yyyy-MM-dd HH:mm') + ' by `tools\db report`.')
$lines.Add('')
$lines.Add('| Change | ' + ($Envs -join ' | ') + ' | Same everywhere |')
$lines.Add('|---|' + ('---|' * $Envs.Count) + '---|')
foreach ($k in ($labels.Keys | Sort-Object { $labels[$_].Sort })) {
    $cells = @()
    foreach ($e in $Envs) {
        $rows = $perEnv[$e]
        if ($null -eq $rows) { $cells += 'unreachable' }
        elseif ($rows.ContainsKey($k)) { $cells += $rows[$k].Cell }
        else { $cells += '-' }
    }
    # Compare reachable environments only, without dates ("OK <date>" = applied).
    $kinds = @($cells | Where-Object { $_ -ne 'unreachable' } | ForEach-Object { ($_ -split ' ')[0] } | Select-Object -Unique)
    if ($kinds.Count -le 1) { $same = 'yes' } else { $same = '**NO**' }
    $lines.Add('| ' + $labels[$k].Label + ' | ' + ($cells -join ' | ') + " | $same |")
}
$lines.Add('')
foreach ($e in $Envs) {
    $rows = $perEnv[$e]
    if ($null -eq $rows) {
        $lines.Add("- **$e**: could not connect (check conf/env/$e.conf and the password)")
        continue
    }
    $cells = @($rows.Values | ForEach-Object { $_.Cell })
    $pending = @($cells | Where-Object { $_ -eq 'PENDING' -or $_ -eq 'CHANGED - not applied' }).Count
    $failed = @($cells | Where-Object { $_ -eq 'FAILED' }).Count
    if ($pending -eq 0 -and $failed -eq 0) { $status = 'up to date' }
    else {
        $status = "$pending change(s) waiting"
        if ($failed) { $status += ", $failed FAILED" }
    }
    $lines.Add("- **$e**: $status")
}
$lines | ForEach-Object { Write-Output $_ }
