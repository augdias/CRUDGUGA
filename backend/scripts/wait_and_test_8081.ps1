param(
    [int]$TimeoutSeconds = 60,
    [int]$IntervalSeconds = 2,
    [string]$TargetHost = 'localhost',
    [int]$Port = 8081,
    [string]$User = 'admin',
    [string]$Password = '123456'
)

function Wait-ForPort {
    param($HostName, $Port, $TimeoutSeconds, $IntervalSeconds)

    $end = (Get-Date).AddSeconds($TimeoutSeconds)
    while((Get-Date) -lt $end) {
        $t = Test-NetConnection -ComputerName $HostName -Port $Port -WarningAction SilentlyContinue
        if ($t.TcpTestSucceeded) {
            Write-Host "Port $Port open on $HostName"
            return $true
        }
        Start-Sleep -Seconds $IntervalSeconds
    }
    return $false
}

# Cria pasta de logs se não existir
$logsDir = Join-Path -Path (Get-Location) -ChildPath 'logs'
if (-Not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir | Out-Null }

Write-Host "Aguardando porta $Port em $TargetHost por até $TimeoutSeconds segundos..."
$ok = Wait-ForPort -HostName $TargetHost -Port $Port -TimeoutSeconds $TimeoutSeconds -IntervalSeconds $IntervalSeconds
if (-not $ok) {
    Write-Host "Porta $Port não ficou disponível após $TimeoutSeconds segundos. Saindo com código 2." -ForegroundColor Yellow
    exit 2
}

# Executa os curls e salva resposta (inclui headers)
$apiUsuariosFile = Join-Path $logsDir 'api-usuarios.http'
$actuatorFile = Join-Path $logsDir 'actuator-health.http'

Write-Host "Executando curl para /api/usuarios ..."
try {
    $apiUrl = "http://${TargetHost}:${Port}/api/usuarios"
    $auth = "${User}:${Password}"
    & curl.exe -sS -u $auth $apiUrl -i | Out-File -FilePath $apiUsuariosFile -Encoding utf8
    Write-Host "Salvo: $apiUsuariosFile"
} catch {
    Write-Host "Falha ao executar curl /api/usuarios: $_" -ForegroundColor Red
}

Write-Host "Executando curl para /actuator/health ..."
try {
    $actuatorUrl = "http://${TargetHost}:${Port}/actuator/health"
    $auth = "${User}:${Password}"
    & curl.exe -sS -u $auth $actuatorUrl -i | Out-File -FilePath $actuatorFile -Encoding utf8
    Write-Host "Salvo: $actuatorFile"
} catch {
    Write-Host "Falha ao executar curl /actuator/health: $_" -ForegroundColor Red
}

Write-Host "Concluído. Arquivos gerados em: $logsDir"
exit 0
