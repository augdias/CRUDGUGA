param(
    [string]$JasyptPassword = $env:JASYPT_ENCRYPTOR_PASSWORD,
    [Alias("DatasourcePassword")][string]$SpringPassword = $env:SPRING_DATASOURCE_PASSWORD,
    [string]$Jar = "target\backend-0.0.1-SNAPSHOT.jar",
    [string]$Log = "backend_run.log",
    [int]$DelaySeconds = 6
)

# Creates a temporary batch that sets env vars and starts the jar so the child process
# receives the variables reliably under PowerShell 5.1 on Windows.
$batPath = Join-Path $env:TEMP "start_backend_prod_temp.bat"

$lines = @()
$lines += "@echo off"
$lines += "set SPRING_PROFILES_ACTIVE=prod"

# Enforce explicit datasource password to avoid reliance on ENC(...) in YAML
if ($null -eq $SpringPassword -or $SpringPassword -eq '') {
    Write-Warning "SPRING_DATASOURCE_PASSWORD not provided. Pass -DatasourcePassword '<senha>' or set the env var before running this script. Aborting start to avoid using encrypted value from application-prod.yml."
    return
} else {
    $escaped = $SpringPassword -replace '"',''
    $lines += "set SPRING_DATASOURCE_PASSWORD=$escaped"
    Write-Host "Using SPRING_DATASOURCE_PASSWORD from parameter/env (will override application-prod.yml)"
}

if ($null -ne $JasyptPassword -and $JasyptPassword -ne '') {
    $escaped2 = $JasyptPassword -replace '"',''
    $lines += "set JASYPT_ENCRYPTOR_PASSWORD=$escaped2"
} else {
    # If JASYPT not provided that's OK — SPRING_DATASOURCE_PASSWORD will be used instead
    Write-Host "JASYPT_ENCRYPTOR_PASSWORD not provided; relying on SPRING_DATASOURCE_PASSWORD override."
}
$cwd = (Get-Location).Path
$lines += "cd /d $cwd"
$lines += "echo Starting backend JAR..."
$javaCmd = "java -jar $Jar --spring.profiles.active=prod"
if ($null -ne $SpringPassword -and $SpringPassword -ne '') {
    $escapedCli = $SpringPassword -replace '"','' -replace '\\','\\\\'
    $javaCmd += " --spring.datasource.password=\"$escapedCli\""
}
$javaCmd += " > $Log 2>&1"
$lines += $javaCmd

# Write the batch file with ASCII encoding
$lines -join "\r\n" | Out-File -FilePath $batPath -Encoding ASCII -Force

Write-Host "Starting backend via temporary batch: $batPath"
Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $batPath -WorkingDirectory (Get-Location) -WindowStyle Hidden -PassThru | Out-Null
Start-Sleep -Seconds $DelaySeconds

# Run the check script to validate startup and write backend.pid
$check = Join-Path (Get-Location) 'scripts\run_backend_check.ps1'
if (Test-Path $check) {
    Write-Host "Running $check"
    & $check
} else {
    Write-Warning "run_backend_check.ps1 not found in scripts/. Run it manually to validate startup."
}

Remove-Item -Path $batPath -ErrorAction SilentlyContinue
