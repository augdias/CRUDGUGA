<#
watchdog_backend.ps1
Monitora o backend JAR e reinicia se o processo terminar.
Uso:
  - Para checar status sem reiniciar:
      .\watchdog_backend.ps1 -CheckOnly
  - Para rodar em loop e reiniciar quando necessário:
      .\watchdog_backend.ps1 -DatasourcePassword 'suaSenha' -IntervalSeconds 10

O script escreve logs em `backend_watchdog.log` e grava PID atual em `backend.pid`.
#>
param(
    [switch]$CheckOnly = $false,
    [string]$Jar = "target\backend-0.0.1-SNAPSHOT.jar",
    [string]$Log = "backend_out.log",
    [string]$PidFile = "backend.pid",
    [int]$IntervalSeconds = 10,
    [int]$MaxRetries = 5,
    [Alias('DatasourcePassword')][string]$SpringPassword = $env:SPRING_DATASOURCE_PASSWORD,
    [string]$WorkingDir = (Get-Location).Path
)

$watchdogLog = Join-Path $WorkingDir 'backend_watchdog.log'
function Log {
    param($msg)
    $line = "$(Get-Date -Format o) - $msg"
    $line | Out-File -FilePath $watchdogLog -Append -Encoding utf8
    Write-Host $msg
}

function Get-BackendProcess {
    # tenta localizar processo java executando o JAR alvo
    $ps = Get-Process -Name java -ErrorAction SilentlyContinue
    if (-not $ps) { return $null }
    foreach ($p in $ps) {
        try {
            $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)").CommandLine
            if ($null -ne $cmd -and $cmd -match [Regex]::Escape($Jar)) {
                return @{ Id = $p.Id; Cmd = $cmd }
            }
        } catch { }
    }
    return $null
}

function Start-Backend {
    param($password)
    $tries = 0
    while ($tries -lt $MaxRetries) {
        $tries++
        Log "Starting backend attempt #$tries"
        $cmdLine = "set SPRING_PROFILES_ACTIVE=prod"
        if ($null -ne $password -and $password -ne '') {
            $escaped = $password -replace '"','' -replace '\\','\\\\'
            # use single quotes around password in the cmdline to avoid PowerShell escaping issues
            $cmdLine += " && java -jar $Jar --spring.profiles.active=prod --spring.datasource.password='$escaped' > $Log 2>&1"
        } else {
            $cmdLine += " && java -jar $Jar --spring.profiles.active=prod > $Log 2>&1"
        }
        $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $cmdLine -WorkingDirectory $WorkingDir -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 3
        $backend = Get-BackendProcess
        if ($backend) {
            Log "Started backend PID $($backend.Id)"
            $backend.Id | Out-File -FilePath $PidFile -Encoding ascii
            return $true
        }
        Log "Start attempt failed to produce backend process. Waiting before retry..."
        Start-Sleep -Seconds 2
    }
    Log "Failed to start backend after $MaxRetries attempts."
    return $false
}

# Check-only mode: report status and exit
$backend = Get-BackendProcess
if ($CheckOnly) {
    if ($backend) {
        Log "CHECK: backend running PID $($backend.Id)"
        exit 0
    } else {
        Log "CHECK: backend not running"
        exit 2
    }
}

# Monitor loop
Log "Watchdog started (Interval: $IntervalSeconds s). PID file: $PidFile"
while ($true) {
    $backend = Get-BackendProcess
    if (-not $backend) {
        Log "Backend not running; attempting restart."
        $ok = Start-Backend -password $SpringPassword
        if (-not $ok) {
            Log "Will retry in $IntervalSeconds seconds."
            Start-Sleep -Seconds $IntervalSeconds
            continue
        }
    } else {
        Log "Backend running PID $($backend.Id). Sleeping $IntervalSeconds s."
        Start-Sleep -Seconds $IntervalSeconds
    }
}
