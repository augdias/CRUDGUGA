<#
.SYNOPSIS
  Inicia o JAR do backend em background, aguarda a porta, executa health-checks e registra logs.

.DESCRIPTION
  Usa Start-Job para executar o JAR em background (nome do job: RunCrudGugaJar).
  Aguarda até a porta informada responder (timeout padrão 60s). Tenta primeiro /actuator/health
  (sem autenticação) e, se não existir, faz GET em /api/usuarios usando Basic Auth (admin:123456 por padrão).

.EXAMPLE
  .\check_backend.ps1

.PARAMETER JarPath
  Caminho para o JAR (padrão: target\backend-0.0.1-SNAPSHOT.jar)

#>

param(
    [string]$JarPath = ".\target\backend-0.0.1-SNAPSHOT.jar",
    [string]$Profile = 'prod',
    [int]$Port = 8081,
    [string]$DatasourceUrl = 'jdbc:postgresql://localhost:5433/crudguga',
    [string]$DbUser = 'crudguga',
    [string]$DbPassword = 'Davi091520@',
    [string]$LogFile = '.\backend_run.log',
    [int]$TimeoutSeconds = 60
)

function Stop-ExistingJob {
    $job = Get-Job -Name RunCrudGugaJar -ErrorAction SilentlyContinue
    if ($job) {
        Write-Output "Parando job existente RunCrudGugaJar (Id=$($job.Id))..."
        Stop-Job -Id $job.Id -ErrorAction SilentlyContinue
        Remove-Job -Id $job.Id -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
}

function Start-BackendJob {
    Write-Output "Iniciando JAR: $JarPath (profile=$Profile) em background, logs -> $LogFile"
    Start-Job -Name RunCrudGugaJar -ScriptBlock {
        Set-Location 'C:\\JAVA\\PROJETOS\\CRUDGUGA\\backend'
        $j = $using:JarPath
        $p = $using:Profile
        $ds = $using:DatasourceUrl
        $user = $using:DbUser
        $pwd = $using:DbPassword
        $log = $using:LogFile
        & 'java' -jar $j "--spring.profiles.active=$p" "--spring.datasource.url=$ds" "--spring.datasource.username=$user" "--spring.datasource.password=$pwd" > $log 2>&1
    } | Out-Null
}

function Wait-For-Port {
    param($Port, $TimeoutSeconds)
    Write-Output "Aguardando porta $Port ficar disponível (timeout ${TimeoutSeconds}s)..."
    $i = 0
    while ($i -lt $TimeoutSeconds) {
        if (Test-NetConnection -ComputerName 'localhost' -Port $Port -InformationLevel Quiet) {
            Write-Output "Porta $Port está aberta."
            return $true
        }
        Start-Sleep -Seconds 1
        $i++
    }
    Write-Output "TIMEOUT: porta $Port não respondeu em $TimeoutSeconds segundos."
    return $false
}

function Try-HealthCheck {
    param($Port)
    $healthUrl = "http://localhost:$Port/actuator/health"
    Write-Output "Tentando GET $healthUrl"
    try {
        $resp = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 5 -ErrorAction Stop
        Write-Output "Actuator health:"
        $resp | ConvertTo-Json -Depth 4
        return $true
    } catch {
        Write-Output "Actuator health indisponível, tentando /api/usuarios com Basic Auth..."
    }

    # Tenta /api/usuarios com Basic Auth
    $pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:123456"))
    $headers = @{ Authorization = "Basic $pair" }
    $url = "http://localhost:$Port/api/usuarios"
    try {
        $resp2 = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 10 -ErrorAction Stop
        Write-Output "GET /api/usuarios retornou:"
        $resp2 | ConvertTo-Json -Depth 6
        return $true
    } catch {
        Write-Output "Falha ao consultar /api/usuarios: $($_.Exception.Message)"
        return $false
    }
}

# Executa fluxo
Stop-ExistingJob
Start-BackendJob
if (-not (Wait-For-Port -Port $Port -TimeoutSeconds $TimeoutSeconds)) {
    Write-Output "Verifique o arquivo de log: $LogFile"
    Exit 1
}

$ok = Try-HealthCheck -Port $Port
Write-Output "\n--- Últimas 200 linhas do log ($LogFile) ---"
Get-Content -Path $LogFile -Tail 200 -ErrorAction SilentlyContinue

if ($ok) {
    Write-Output "Health-checks OK. Backend pronto."
    Exit 0
} else {
    Write-Output "Health-checks falharam. Verifique logs e a configuração do banco."
    Exit 2
}
