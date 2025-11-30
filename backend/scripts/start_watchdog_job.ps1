Set-StrictMode -Version Latest

Set-Location 'C:\JAVA\PROJETOS\CRUDGUGA\backend'

Write-Host "Starting watchdog job..."
$job = Start-Job -ScriptBlock {
    Set-Location 'C:\JAVA\PROJETOS\CRUDGUGA\backend'
    $env:APP_FRONTEND_ORIGIN = 'http://localhost:5173'
    $env:SPRING_DATASOURCE_PASSWORD = 'Davi091520@'
    & '.\scripts\run_backend_watchdog.ps1'
}

Write-Host "JOB_STARTED ID=$($job.Id)"
Get-Job -Id $job.Id | Format-List *
