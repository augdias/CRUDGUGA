<#
script: scripts/run_backend_persistent.ps1
Descrição: Mata PID que usa a porta (8081), empacota com Maven, inicia o JAR em background, redireciona logs, aguarda porta e checa /actuator/health.
Uso: powershell -ExecutionPolicy Bypass -File .\scripts\run_backend_persistent.ps1
#>
param(
    [string]$Profile = 'prod',
    [int]$Port = 8081,
    [string]$Jar = '.\target\backend-0.0.1-SNAPSHOT.jar',
    [string]$Log = '.\backend_run.log',
    [int]$WaitSeconds = 30
)

# Optional overrides (can also be provided via environment variables)
[string]$AppFrontendOrigin = $env:APP_FRONTEND_ORIGIN,
[string]$AppFrontendOrigin = $env:APP_FRONTEND_ORIGIN,
[string]$JasyptPassword = $env:JASYPT_ENCRYPTOR_PASSWORD,
[string]$DbPassword = $env:SPRING_DATASOURCE_PASSWORD,
[string]$PidFile = '.\backend.pid'

# Ensure JVM uses UTF-8 to avoid mojibake in logs
if (-not $env:JAVA_TOOL_OPTIONS) {
    $env:JAVA_TOOL_OPTIONS = '-Dfile.encoding=UTF-8'
    Write-Info "Set JAVA_TOOL_OPTIONS=$env:JAVA_TOOL_OPTIONS"
} else {
    Write-Info "JAVA_TOOL_OPTIONS already set: $env:JAVA_TOOL_OPTIONS"
}

function Write-Info([string]$msg) { Write-Host "[INFO] $msg" }
function Write-Err([string]$msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

Write-Info "Checking for process listening on port $Port..."
$net = netstat -ano | findstr ":$Port " 2>$null
if ($net) {
    $parts = $net -split '\s+' | Where-Object { $_ -ne '' }
    $pid = $parts[-1]
    Write-Info "Found PID $pid using port $Port - attempting to stop it"
    try {
        taskkill /PID $pid /F | Out-Null
        Start-Sleep -Seconds 1
        Write-Info "Killed PID $pid"
    } catch {
        # avoid variable parsing issues inside double-quoted strings
        $err = $_
        Write-Err ("Failed to kill PID {0}: {1}" -f $pid, $err)
    }
} else {
    Write-Info "No process found on port $Port"
}

Write-Info "Building project with Maven (profile=$Profile)..."
$mvnCmd = "mvn --% -Dspring-boot.run.profiles=$Profile package"
Invoke-Expression $mvnCmd
if ($LASTEXITCODE -ne 0) { Write-Err "Maven build failed (exit code $LASTEXITCODE)"; exit 1 }

if (-not (Test-Path $Jar)) { Write-Err "Jar not found at path: $Jar"; exit 2 }

# start process in background redirecting stdout/stderr to log
Write-Info "Starting jar: $Jar (logs -> $Log)"
if ($AppFrontendOrigin) { Write-Info "Using app.frontend.origin=$AppFrontendOrigin"; $appArg = "--app.frontend.origin=$AppFrontendOrigin" } else { $appArg = "" }

# Export environment variables for the child process (child inherits current env)
if ($JasyptPassword) { $env:JASYPT_ENCRYPTOR_PASSWORD = $JasyptPassword; Write-Info "Exported JASYPT_ENCRYPTOR_PASSWORD to environment" }
if ($DbPassword) { $env:SPRING_DATASOURCE_PASSWORD = $DbPassword; Write-Info "Exported SPRING_DATASOURCE_PASSWORD to environment" }

$argList = @()
# ensure file.encoding JVM option is passed before -jar (defensive)
if ($env:JAVA_TOOL_OPTIONS -and ($env:JAVA_TOOL_OPTIONS -notlike '*file.encoding*')) {
    $argList += $env:JAVA_TOOL_OPTIONS
} elseif (-not $env:JAVA_TOOL_OPTIONS) {
    $argList += '-Dfile.encoding=UTF-8'
}
if ($appArg -ne "") { $argList += $appArg }
$argList += "-jar"; $argList += $Jar

$proc = Start-Process -FilePath 'java' -ArgumentList $argList -RedirectStandardOutput $Log -RedirectStandardError $Log -NoNewWindow -PassThru
try {
    # write pid file for monitoring
    $pid = $proc.Id
    Set-Content -Path $PidFile -Value $pid -Encoding ASCII
    Write-Info "Started java (PID $pid), pid saved to $PidFile"
} catch {
    Write-Err "Failed to write pid file: $_"
}
Start-Sleep -Seconds 1

# wait for port
Write-Info "Waiting for port $Port to be available (timeout ${WaitSeconds}s)..."
$ok = $false
for ($i=0; $i -lt $WaitSeconds; $i++) {
    if (Test-NetConnection -ComputerName '127.0.0.1' -Port $Port -InformationLevel Quiet) { $ok = $true; break }
    Start-Sleep -Seconds 1
}
if (-not $ok) {
    Write-Err "Timeout waiting for port $Port. Check $Log for details."
    exit 3
}
Write-Info "Port $Port is listening. Performing health check..."
try {
    $originHeader = if ($AppFrontendOrigin) { $AppFrontendOrigin } else { 'http://localhost:5173' }
    $health = curl.exe -s -u admin:123456 -H ("Origin: {0}" -f $originHeader) http://127.0.0.1:$Port/actuator/health -w "%{http_code}" -o $null
    if ($health -eq '200') { Write-Info "Health OK (200)"; exit 0 } else { Write-Err "Health check returned HTTP $health"; exit 4 }
    } catch {
        $err = $_
        Write-Err ("Health request failed: {0}" -f $err)
        exit 5
    }
