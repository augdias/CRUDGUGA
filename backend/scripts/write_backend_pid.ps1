Set-StrictMode -Version Latest
Set-Location 'C:\JAVA\PROJETOS\CRUDGUGA\backend'

$port = 8081
Write-Host "Searching for process listening on port $port..."
$lines = netstat -ano | Select-String ":$port\s"
if ($lines -and $lines.Count -gt 0) {
    $first = $lines[0].ToString()
    $parts = ($first -split '\s+') | Where-Object { $_ -ne '' }
    $foundPid = $parts[-1]
    if ($foundPid -match '^[0-9]+$') {
        Set-Content -Path .\\backend.pid -Value $foundPid -Encoding ASCII
        Write-Host "WROTE PID $foundPid to backend.pid"
    } else {
        Write-Host "Could not parse PID from: $first"
    }
} else {
    Write-Host "No process found listening on port $port"
}
