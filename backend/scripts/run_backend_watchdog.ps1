<#
run_backend_watchdog.ps1

Watchdog simples para rodar o JAR do backend em Windows PowerShell.
- Grava `backend.pid` com o PID atual.
- Reinicia automaticamente quando o processo termina.
- Redireciona stdout/stderr para `backend_run.log` quando possível.

Usage:
  # Defina variáveis de ambiente antes ou passe por parâmetros
  $env:APP_FRONTEND_ORIGIN = 'http://localhost:5173'
  $env:SPRING_DATASOURCE_PASSWORD = 'sua_senha'
  .\scripts\run_backend_watchdog.ps1

# Notes:
# - O script tenta construir o JAR se não existir em `target\`.
# - Recomendado rodar com `powershell -ExecutionPolicy Bypass -File .\scripts\run_backend_watchdog.ps1`
#>

param(
    [int]$Port = 8081,
    [int]$RestartDelaySeconds = 5
)

Set-StrictMode -Version Latest

function Write-Log($msg) {
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "$ts - $msg"
    Write-Host $line
    Add-Content -Path "$PSScriptRoot\..\backend_watchdog.log" -Value $line
}

# Ensure we're in repo root
$root = Resolve-Path "$PSScriptRoot\.." | Select-Object -ExpandProperty Path
Set-Location $root

$jar = Join-Path $root "target\backend-0.0.1-SNAPSHOT.jar"
$logFile = Join-Path $root "backend_run.log"
$pidFile = Join-Path $root "backend.pid"

if (-not (Test-Path $jar)) {
    Write-Log "JAR não encontrado em $jar — executando 'mvn -DskipTests package'"
    & mvn -DskipTests package
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Maven build falhou (exit $LASTEXITCODE). Saindo."
        exit 1
    }
}

function Kill-Port($port) {
    try {
        $lines = netstat -ano | Select-String ":$port\s"
        foreach ($l in $lines) {
            $parts = ($l -split '\s+') | Where-Object { $_ -ne '' }
            $pid = $parts[-1]
            if ($pid -match '^[0-9]+$') {
                Write-Log "Matando processo na porta $port (PID $pid)"
                Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Write-Log "Erro ao checar porta $port: $_"
    }
}

# Kill existing PID file process
if (Test-Path $pidFile) {
    try {
        $old = Get-Content $pidFile -ErrorAction SilentlyContinue
        if ($old -and ($old -match '^[0-9]+$')) {
            Write-Log "PID antigo encontrado: $old — tentando parar"
            Stop-Process -Id [int]$old -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Log "Falha ao parar PID antigo: $_"
    }
    Remove-Item $pidFile -ErrorAction SilentlyContinue
}

# Kill any process currently ocupying the port
Kill-Port -port $Port

Write-Log "Starting backend watchdog loop (port $Port)"

while ($true) {
    # Ensure environment variables are available to child
    $env:APP_FRONTEND_ORIGIN = $env:APP_FRONTEND_ORIGIN
    $env:SPRING_DATASOURCE_PASSWORD = $env:SPRING_DATASOURCE_PASSWORD
    $env:JASYPT_ENCRYPTOR_PASSWORD = $env:JASYPT_ENCRYPTOR_PASSWORD

    $args = @('-Dfile.encoding=UTF-8','-jar', $jar)
    Write-Log "Iniciando java $($args -join ' ')"

    try {
        # Try to start with output redirection (PowerShell 5+ supports these params)
        $proc = Start-Process -FilePath 'java' -ArgumentList $args -RedirectStandardOutput $logFile -RedirectStandardError $logFile -NoNewWindow -PassThru
    } catch {
        Write-Log "Start-Process com redirecionamento falhou: $_ — tentando sem redirecionamento"
        try {
            $proc = Start-Process -FilePath 'java' -ArgumentList $args -NoNewWindow -PassThru
        } catch {
            Write-Log "Falha ao iniciar java: $_"
            Write-Log "Aguardando $RestartDelaySeconds segundos antes de tentar novamente"
            Start-Sleep -Seconds $RestartDelaySeconds
            continue
        }
    }

    # Write PID file
    try {
        Set-Content -Path $pidFile -Value $proc.Id -Encoding ASCII
        Write-Log "Processo iniciado (PID $($proc.Id)). Gravado em $pidFile"
    } catch {
        Write-Log "Não foi possível gravar $pidFile: $_"
    }

    # Wait for process to exit
    try {
        Wait-Process -Id $proc.Id
        Write-Log "Processo $($proc.Id) finalizado unexpectedly. Checando logs..."
    } catch {
        Write-Log "Erro ao aguardar o processo $($proc.Id): $_"
    }

    # small delay before restart
    Write-Log "Aguardando $RestartDelaySeconds segundos antes de reiniciar"
    Start-Sleep -Seconds $RestartDelaySeconds
}