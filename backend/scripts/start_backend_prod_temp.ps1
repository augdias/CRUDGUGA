Set-StrictMode -Version Latest

# start_backend_prod_temp.ps1
# Inicia o backend no profile 'prod' usando variáveis de ambiente já definidas

Set-Location 'C:\JAVA\PROJETOS\CRUDGUGA\backend'
if (Get-ChildItem env:JASYPT_ENCRYPTOR_PASSWORD -ErrorAction SilentlyContinue) {
  Write-Host 'JASYPT_ENCRYPTOR_PASSWORD is set (not printing value)'
} else {
  Write-Host 'Warning: JASYPT_ENCRYPTOR_PASSWORD not set in this session'
}

$env:SPRING_PROFILES_ACTIVE = 'prod'

# Start java as background process (child inherits current environment)
$proc = Start-Process -FilePath 'java' -ArgumentList '-jar','target\\backend-0.0.1-SNAPSHOT.jar' -WorkingDirectory (Get-Location) -WindowStyle Hidden -PassThru
Write-Host "Started java PID=$($proc.Id)"

Start-Sleep -Seconds 8

# Run the existing check script
Write-Host 'Running run_backend_check.ps1...'
& .\scripts\run_backend_check.ps1
