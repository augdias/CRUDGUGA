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
        Write-Err "Failed to kill PID $pid: $_"
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
$arg = "-jar `"$Jar`" --app.frontend.origin=http://localhost:5173"
$proc = Start-Process -FilePath 'java' -ArgumentList $arg -RedirectStandardOutput $Log -RedirectStandardError $Log -NoNewWindow -PassThru
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
    $health = curl.exe -s -u admin:123456 -H "Origin: http://localhost:5173" http://127.0.0.1:$Port/actuator/health -w "%{http_code}" -o $null
    if ($health -eq '200') { Write-Info "Health OK (200)"; exit 0 } else { Write-Err "Health check returned HTTP $health"; exit 4 }
} catch {
    Write-Err "Health request failed: $_"
    exit 5
}
