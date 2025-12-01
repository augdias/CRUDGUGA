# TODOs do Repositório

Exportado em: 24 de novembro de 2025
Fonte: ferramenta de gerenciamento interno `manage_todo_list`

- [x] **Criar DB e usuário Postgres**
  - Executar SQL para criar usuário `crudguga`, banco `crudguga` e definir proprietário.

- [ ] **Subir Postgres via Docker (opcional)**
  - Comando Docker para rodar um container Postgres na porta 5433 com usuário/senha `crudguga`.

- [x] **Atualizar application-prod.yml / env vars**
  - Mostrar como configurar `SPRING_DATASOURCE_*` no PowerShell e no `application-prod.yml`.

- [x] **Testar conexão**
  - Usar `psql` para verificar conexão com `crudguga` em `localhost:5433` e listar tabelas (`\\dt`).

- [x] **Executar backend com profile prod**
  - Rodar o backend (Maven ou JAR) apontando para Postgres em localhost:5433 usando as variáveis de ambiente.

- [x] **Testar API GET /api/usuarios**
  - Iniciar backend em background e executar GET em `/api/usuarios` com Basic Auth `admin:123456`.

- [ ] **Iniciar frontend (dev)**
  - Startar `frontend` com `VITE_API_URL=http://localhost:8081` para testar integração.

- [x] **Parar processo 8081 e reiniciar JAR**
  - Identificar processo que ocupa a porta 8081, pará-lo, iniciar JAR em background e testar GET /api/usuarios.

- [x] **Criar script PowerShell `scripts/check_backend.ps1`**
  - Script para iniciar o JAR, aguardar porta, verificar health e salvar logs.

- [-] **Abrir PR com alterações**
  - Criar branch remoto, push e abrir PR para `feat/frontend-api-config` -> `main` com o PR body preparado.

- [ ] **Adicionar reviewers ao PR**
  - Encontrar o PR para `feat/frontend-api-config` e adicionar os reviewers GitHub fornecidos usando `gh pr edit --add-reviewer`.

---

Observações:
- O item marcado `[-]` indica um estado especial no TODO original (não-booleano). Verificar se deseja convertê-lo para `[]` ou `x`.
- Posso atualizar este arquivo com timestamps de conclusão automaticamente se você quiser habilitar isso.
