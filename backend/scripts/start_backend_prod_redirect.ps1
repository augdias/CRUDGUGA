Set-StrictMode -Version Latest

# start_backend_prod_redirect.ps1
Set-Location 'C:\JAVA\PROJETOS\CRUDGUGA\backend'
if (Get-ChildItem env:JASYPT_ENCRYPTOR_PASSWORD -ErrorAction SilentlyContinue) {
  Write-Host 'JASYPT_ENCRYPTOR_PASSWORD is present in environment (not printing)'
} else {
  Write-Host 'Warning: JASYPT_ENCRYPTOR_PASSWORD not present in environment'
}

$env:SPRING_PROFILES_ACTIVE = 'prod'

Write-Host 'Starting java with redirected output to backend_run.log'
$proc = Start-Process -FilePath 'java' -ArgumentList '-jar','target\\backend-0.0.1-SNAPSHOT.jar' -WorkingDirectory (Get-Location) -RedirectStandardOutput .\\backend_run.log -RedirectStandardError .\\backend_run.log -PassThru
Write-Host "Started java PID=$($proc.Id)"
Start-Sleep -Seconds 8
Write-Host 'Running run_backend_check.ps1'
& .\scripts\run_backend_check.ps1
