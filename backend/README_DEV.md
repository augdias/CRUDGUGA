# Backend - Dev Run Guide

Este arquivo descreve comandos e scripts úteis para desenvolver e rodar o backend localmente no Windows PowerShell.

Pré-requisitos
- Java 21 instalado e no PATH (`java -version`).
- Maven no PATH (`mvn -v`).
- Postgres em execução (conforme `docs/PG_SETUP.md`), usuário/banco `crudguga` configurado.

Variáveis importantes (PowerShell)
- `JASYPT_ENCRYPTOR_PASSWORD` — senha usada para desincriptar valores `ENC(...)` se aplicável.
- `SPRING_DATASOURCE_PASSWORD` — pode sobrescrever a senha embutida no YAML.
- `APP_FRONTEND_ORIGIN` ou propriedade `-Dapp.frontend.origin` — origem do frontend (ex.: `http://localhost:5173`).

Comandos comuns

1) Rodar com Maven (dev/prod profile)
```powershell
# define origin e executa em foreground (útil para debugging)
$env:APP_FRONTEND_ORIGIN = 'http://localhost:5173'
$mvnArgs = '--% -Dapp.frontend.origin=http://localhost:5173 -Dspring-boot.run.profiles=prod spring-boot:run'
mvn $mvnArgs
```

2) Empacotar e rodar o JAR (recomendado para execução persistente)
```powershell
mvn --% -Dspring-boot.run.profiles=prod package
java -jar .\target\backend-0.0.1-SNAPSHOT.jar --app.frontend.origin=http://localhost:5173
```

3) Rodar o script automático (mais prático)
```powershell
# executa o script que constrói e inicia o backend em background e verifica health
scripts\run_backend_persistent.ps1
```

Diagnóstico rápido
```powershell
# Verificar processo java
Get-Process java* | Format-Table Id,ProcessName,StartTime

# Verificar porta 8081
netstat -ano | findstr :8081

# Verificar logs (últimas 200 linhas)
Get-Content backend_run.log -Tail 200

# Testar API
curl.exe -v -u admin:123456 -H "Origin: http://localhost:5173" http://127.0.0.1:8081/api/usuarios
curl.exe -v -u admin:123456 -H "Origin: http://localhost:5173" http://127.0.0.1:8081/actuator/health
```

Observações de segurança
- Não deixe valores sensíveis em `application-prod.yml` em texto claro no repositório.
- Em dev, é aceitável sobrescrever via `SPRING_DATASOURCE_PASSWORD` ou `JASYPT_ENCRYPTOR_PASSWORD` no PowerShell.

Se quiser, eu crio um serviço Windows para manter o JAR em execução — peça se desejar essa automação.