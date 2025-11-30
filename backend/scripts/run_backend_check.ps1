<#
run_backend_check.ps1

Verificações automáticas para o backend CRUDGUGA.

O que faz:
- Verifica variáveis de ambiente essenciais: `APP_FRONTEND_ORIGIN`, `SPRING_DATASOURCE_PASSWORD` ou `JASYPT_ENCRYPTOR_PASSWORD`.
- Verifica se o processo está escutando na porta (default 8081). Se sim, mostra PID e testa `/api/usuarios` e `/actuator/health`.
- Se não houver processo, opcionalmente inicia o watchdog (`scripts/start_watchdog_job.ps1`) e aguarda.
- Exibe últimas linhas de `backend_run.log`.

Uso:
  # Run with defaults (auto-start watchdog se backend não estiver rodando)
  powershell -ExecutionPolicy Bypass -File .\scripts\run_backend_check.ps1

  # Forçar não iniciar watchdog:
  powershell -ExecutionPolicy Bypass -File .\scripts\run_backend_check.ps1 -NoStart

Parâmetros:
  -Port (int)        : porta do backend (default 8081)
  -NoStart (switch)  : não iniciar watchdog se backend não rodar

#>

param(
  [int]$Port = 8081,
  [switch]$NoStart,
  [string]$ApiUser = 'admin',
  [string]$ApiPass = '123456',
  [switch]$RevealSecrets
)

Set-StrictMode -Version Latest

function Write-Info($m) { $t=(Get-Date).ToString('HH:mm:ss'); Write-Host "$t - $m" }

# garantir diretório raiz do backend
Set-Location (Resolve-Path "$PSScriptRoot\..")

Write-Info "Executando verificações do backend (porta $Port)"

# Check env vars
$frontendOrigin = $env:APP_FRONTEND_ORIGIN
$dsPass = $env:SPRING_DATASOURCE_PASSWORD
$jasypt = $env:JASYPT_ENCRYPTOR_PASSWORD

if (-not $frontendOrigin) { Write-Info "Aviso: APP_FRONTEND_ORIGIN não está definida." } else { Write-Info "APP_FRONTEND_ORIGIN=$frontendOrigin" }

# Print datasource/Jasypt values (masked by default)
function Mask($s) {
  if (-not $s) { return '' }
  if ($s.Length -le 6) { return ('*' * $s.Length) }
  return $s.Substring(0,2) + ('*' * ($s.Length - 4)) + $s.Substring($s.Length-2,2)
}

if (-not ($dsPass -or $jasypt)) {
  Write-Info "Aviso: Nem SPRING_DATASOURCE_PASSWORD nem JASYPT_ENCRYPTOR_PASSWORD foram definidas. O backend pode falhar ao iniciar."
} else {
  if ($dsPass) {
    if ($RevealSecrets) { Write-Info "SPRING_DATASOURCE_PASSWORD=$dsPass" } else { Write-Info "SPRING_DATASOURCE_PASSWORD=" + (Mask $dsPass) }
  } else { Write-Info "SPRING_DATASOURCE_PASSWORD not set" }
  if ($jasypt) {
    if ($RevealSecrets) { Write-Info "JASYPT_ENCRYPTOR_PASSWORD=$jasypt" } else { Write-Info "JASYPT_ENCRYPTOR_PASSWORD=" + (Mask $jasypt) }
  } else { Write-Info "JASYPT_ENCRYPTOR_PASSWORD not set" }
}

function Get-PortPid($port) {
  $lines = netstat -ano | Select-String ":$port\s"
  if (-not $lines) { return $null }
  $first = $lines[0].ToString()
  $parts = ($first -split '\s+') | Where-Object { $_ -ne '' }
  return $parts[-1]
}

$foundPid = Get-PortPid -port $Port
if ($foundPid) {
  Write-Info "Encontrado processo escutando em :$Port (PID $foundPid)"
  try {
    $proc = Get-Process -Id $foundPid -ErrorAction SilentlyContinue
    if ($proc) {
      $proc | Format-List Id,ProcessName,StartTime
      if ($proc.ProcessName -ieq 'java') {
        try {
          Set-Content -Path .\backend.pid -Value $foundPid -Encoding ASCII
          Write-Info "Gravado backend.pid = $foundPid"
        } catch {
          Write-Info ("Falha ao gravar backend.pid: {0}" -f $_)
        }
      } else {
        Write-Info "PID $foundPid não pertence a 'java' (processo: $($proc.ProcessName)). Não gravando backend.pid"
      }
    } else {
      Write-Info "Get-Process não retornou processo para PID $foundPid"
    }
  } catch {
    Write-Info ("Erro ao verificar processo PID {0}: {1}" -f $foundPid, $_)
  }
  # Test endpoints
  $userCred = "${ApiUser}:${ApiPass}"
  Write-Info "Testando GET /api/usuarios (Basic auth ${ApiUser}:****)"
  try {
    curl.exe -s -o .\.tmp_users.json -u $userCred -H "Origin: $frontendOrigin" "http://127.0.0.1:$Port/api/usuarios"
    $code = $LASTEXITCODE
    if ($code -eq 0) { Write-Info "Requisição /api/usuarios enviada (verificando conteúdo)"; Get-Content .\.tmp_users.json | Select-Object -First 200 | Write-Host } else { Write-Info "/api/usuarios request failed (curl exit $code)" }
  } catch { Write-Info ("Erro ao executar curl: {0}" -f $_) }

  Write-Info "Testando /actuator/health"
  try {
    curl.exe -s -o .\.tmp_health.json -u $userCred "http://127.0.0.1:$Port/actuator/health"
    if (Test-Path .\.tmp_health.json) { Get-Content .\.tmp_health.json | Select-Object -First 200 | Write-Host }
  } catch { Write-Info ("Erro ao testar actuator/health: {0}" -f $_) }

} else {
  Write-Info "Nenhum processo escutando em :$Port encontrado."
  if ($NoStart) { Write-Info "Parando — flag -NoStart passada."; exit 2 }
  # tentar iniciar watchdog
  if (Test-Path .\scripts\start_watchdog_job.ps1) {
    Write-Info "Iniciando watchdog via scripts/start_watchdog_job.ps1"
    try {
      Start-Process -FilePath 'powershell' -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','.\scripts\start_watchdog_job.ps1' -WindowStyle Hidden -PassThru | Out-Null
      Write-Info "Watchdog iniciado. Aguardando 8 segundos para a aplicação subir..."
      Start-Sleep -Seconds 8
      $foundPid = Get-PortPid -port $Port
      if ($foundPid) { Write-Info "Backend subiu (PID $foundPid)" } else { Write-Info "Após iniciar watchdog, backend ainda não responde na porta $Port" }
    } catch { Write-Info ("Falha ao iniciar watchdog: {0}" -f $_) }
  } else {
    Write-Info "start_watchdog_job.ps1 não encontrado — não foi possível iniciar automaticamente."
  }
}

# show backend logs tail
if (Test-Path .\backend_run.log) {
  Write-Info "Exibindo últimas 200 linhas de backend_run.log"
  try { Get-Content .\backend_run.log -Tail 200 -Encoding UTF8 | Write-Host } catch { Write-Info ("Erro ao ler backend_run.log: {0}" -f $_) }
} else { Write-Info "backend_run.log não encontrado." }

Write-Info "run_backend_check.ps1 finalizado"
