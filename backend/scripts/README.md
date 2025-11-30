Scripts de suporte para iniciar e monitorar o backend (Windows PowerShell)

Files:
- `start_backend_prod.ps1` : inicia o JAR via batch temporário garantindo que o processo filho receba variáveis de ambiente. Aceita `-DatasourcePassword` (recomenda-se passá-la) e `-JasyptPassword`.
- `wait_and_test_8081.ps1` : aguarda a porta 8081 abrir e salva respostas de `/api/usuarios` e `/actuator/health` em `logs/`.
- `watchdog_backend.ps1` : monitora o processo do backend e reinicia quando cair. Use `-CheckOnly` para checar status sem reiniciar.

Exemplos de uso:

1) Iniciar backend (prod) via script existente:

```powershell
# Passando a senha do datasource explicitamente (evita dependência em application-prod.yml ENC(...))
.\scripts\start_backend_prod.ps1 -DatasourcePassword 'Davi091520@' -JasyptPassword $env:JASYPT_ENCRYPTOR_PASSWORD
```

2) Rodar watchdog em modo checagem:

```powershell
.\scripts\watchdog_backend.ps1 -CheckOnly
```

3) Rodar watchdog para monitorar e reiniciar (mantê-lo rodando em uma sessão PowerShell):

```powershell
.\scripts\watchdog_backend.ps1 -DatasourcePassword 'Davi091520@' -IntervalSeconds 10
```

Logs/artefatos:
- `backend_out.log` : saída do backend quando iniciado pelo script.
- `backend_run.log` : (antigo) usado por alguns scripts.
- `backend_watchdog.log` : log do watchdog.
- `backend.pid` : pid atual gravado pelo watchdog quando iniciar o backend.

Observações de segurança:
- Evite commitar credenciais no repositório. Considere usar variáveis de ambiente do sistema ou ferramentas de segredo.
