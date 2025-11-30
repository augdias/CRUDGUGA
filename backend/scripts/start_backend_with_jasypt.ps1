Set-StrictMode -Version Latest

# start_backend_with_jasypt.ps1
# Creates a temporary batch file that sets JASYPT and starts the backend via cmd (so redirection works)

Set-Location 'C:\JAVA\PROJETOS\CRUDGUGA\backend'
$j = $env:JASYPT_ENCRYPTOR_PASSWORD
if (-not $j) {
  Write-Host 'JASYPT_ENCRYPTOR_PASSWORD is not set in this PowerShell session. Aborting.'; exit 1
}

$batchPath = Join-Path (Get-Location) 'start_backend_prod_tmp.cmd'
$batchContent = @(
  "@echo off",
  "set JASYPT_ENCRYPTOR_PASSWORD=%JASYPT_ENCRYPTOR_PASSWORD%",
  "set SPRING_PROFILES_ACTIVE=prod",
  "cd /d %~dp0",
  "java -jar target\\backend-0.0.1-SNAPSHOT.jar > backend_run.log 2>&1"
) -join "`r`n"

# We'll write the batch file with the JASYPT value injected via a temporary environment wrapper
# To avoid exposing the secret in the file unnecessarily, we'll set it via cmd /c "set JASYPT=... && ..."
# But for simplicity and reliability we'll write the batch file with the secret value (local file) and remove it after start.

$batchContentWithSecret = "@echo off`r`nset JASYPT_ENCRYPTOR_PASSWORD=$j`r`nset SPRING_PROFILES_ACTIVE=prod`r`ncd /d %~dp0`r`njava -jar target\\backend-0.0.1-SNAPSHOT.jar > backend_run.log 2>&1"

try {
  $batchContentWithSecret | Out-File -FilePath $batchPath -Encoding ASCII -Force
  Write-Host "Wrote batch file: $batchPath"
  Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $batchPath -WorkingDirectory (Get-Location) -WindowStyle Hidden -PassThru | Out-Null
  Start-Sleep -Seconds 8
  Write-Host 'Running run_backend_check.ps1'
  & .\scripts\run_backend_check.ps1
} finally {
  if (Test-Path $batchPath) {
    try { Remove-Item $batchPath -Force } catch { Write-Host "Could not remove temp batch: $_" }
  }
}
