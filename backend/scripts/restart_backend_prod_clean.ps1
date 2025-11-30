Set-StrictMode -Version Latest

# restart_backend_prod_clean.ps1
# - Encerra processos java que contém o JAR do backend na linha de comando
# - Inicia o backend em profile 'prod' (herda JASYPT do ambiente atual)
# - Executa run_backend_check.ps1

Set-Location 'C:\JAVA\PROJETOS\CRUDGUGA\backend'

Write-Host "Searching for existing backend java processes..."
try {
  $procs = Get-CimInstance Win32_Process -Filter "CommandLine LIKE '%backend-0.0.1-SNAPSHOT.jar%'" -ErrorAction SilentlyContinue
} catch {
  Write-Host "Failed to query Win32_Process: $_"
  $procs = @()
}

if ($procs -and $procs.Count -gt 0) {
  foreach ($p in $procs) {
    Write-Host "Found backend process PID=$($p.ProcessId)";
    try {
      Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
      Write-Host "Stopped PID=$($p.ProcessId)"
    } catch { Write-Host "Failed to stop PID=$($p.ProcessId): $_" }
  }
} else {
  Write-Host "No existing backend java process found."
}

# Ensure prod profile
$env:SPRING_PROFILES_ACTIVE = 'prod'

# Start backend - outputs will go to backend_run.log
Write-Host 'Starting backend JAR (prod)...'
$start = Start-Process -FilePath 'java' -ArgumentList '-jar','target\\backend-0.0.1-SNAPSHOT.jar' -WorkingDirectory (Get-Location) -WindowStyle Hidden -PassThru
Write-Host "Started backend PID=$($start.Id)"

Start-Sleep -Seconds 8

Write-Host 'Running run_backend_check.ps1'
& .\scripts\run_backend_check.ps1
