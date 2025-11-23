# Projeto CRUDGUGA — Análise rápida (Backend + Frontend)

Data: 22 de novembro de 2025

Objetivo: documentar o que já foi construído no backend e no frontend, apontar inconsistências observadas e listar próximos passos priorizados.

**Sumário**
- Backend: monólito Spring Boot (Java 21) com CRUD de usuários, paginação, validação, testes e segurança HTTP Basic.
- Frontend: React + Vite (React 19), SPA simples com login (HTTP Basic) e dashboard de usuários.
- Principais gaps encontrados: modelo divergente (frontend envia `email` mas backend não o persiste), URL/API hardcoded no frontend, e CORS configurado apenas para uma origem fixa.

---

## Backend — o que existe (arquivos/funcionalidade)
- Entrypoint: `src/main/java/com/crudguga/backend/CrudGugaApplication.java`
- Configs:
  - `src/main/java/com/crudguga/backend/config/ApiPaths.java` — constantes de rota (`USUARIOS`, `USUARIOS_ID`) e `ROLE_ADMIN`.
  - `src/main/java/com/crudguga/backend/config/SecurityConfig.java` — Spring Security com HTTP Basic em memória (`admin`/`123456`), `csrf` desabilitado.
  - `src/main/java/com/crudguga/backend/config/WebConfig.java` — CORS: permite `http://192.168.100.44:5174` apenas e métodos `GET,POST,PUT,DELETE,OPTIONS` (usa `allowCredentials(true)`).
  - `src/main/java/com/crudguga/backend/config/GlobalExceptionHandler.java` + `MensagensErro.java` — padronização de erros em `ErroResponse`.
- Domínio e DTOs:
  - `src/main/java/com/crudguga/backend/entity/Usuario.java` — campos: `id`, `nome`, `senha` (sem `email`).
  - `src/main/java/com/crudguga/backend/dto/UsuarioRequestDTO.java` — `nome`, `senha` com `@NotBlank`.
  - `src/main/java/com/crudguga/backend/dto/UsuarioDTO.java` — `id`, `nome`.
  - `ErroResponse.java` — formato padronizado de erro.
- Camadas:
  - Controller: `UsuarioController.java` — endpoints para CRUD e listagem paginada `/api/usuarios` (usa `Pageable` com `page,size,sortBy,direction` e filtro `nome`).
  - Service: `UsuarioService.java` — orquestra `UsuarioRepository` e converte para `UsuarioDTO`; lógica para preservar senha ao atualizar.
  - Repository: `UsuarioRepository.java` — `JpaRepository<Usuario,Long>` com `findByNomeContainingIgnoreCase(String, Pageable)`.
- Testes:
  - `src/test/java/.../UsuarioControllerTest.java` — testes integrados com `@SpringBootTest` e `@AutoConfigureMockMvc`; usam `@WithMockUser(username = "admin", roles = ROLE_ADMIN)` e cobrem CRUD, validação, paginação, ordenação e filtro.
- README do backend contém instruções de `dev`/`prod`, perfis, porta padrão `8080` (dev) e `8081` (prod) e instruções para Jasypt.

Observações importantes no backend:
- Entidade `Usuario` NÃO tem campo `email` — o backend não persiste email. DTOs também não expõem email.
- CORS é restrita a `http://192.168.100.44:5174` (frontend hardcoded origin), o que explica por que o frontend está apontando para `192.168.100.44`.
- Segurança exige autenticação para todas as rotas; `WebConfig` permite `allowCredentials(true)` (necessário para envio de Basic Auth via fetch com credenciais).

---

## Frontend — o que existe (arquivos/funcionalidade)
- Ferramenta / versão: `package.json` — Vite + React 19.
- Entrypoint: `frontend/index.html` e `src/main.jsx`.
- UI: `src/App.jsx` (App único):
  - Login simples: inputs `username` + `password`, envia Basic Auth nas requisições.
  - Após login com sucesso (faz GET em `/api/usuarios` com credenciais): mostra Dashboard com lista de usuários.
  - Operações: listar usuários, criar usuário (form com `nome`, `email`, `senha`), deletar usuário.
  - O fetch usa URLs hardcoded `http://192.168.100.44:8081/api/usuarios` e concatena `Authorization: Basic ...` nos headers.
  - Tratamento de resposta paginada: quando o backend retorna `Page<UsuarioDTO>`, o código faz `setUsers(Array.isArray(data.content) ? data.content : data);` — isto indica que o código espera `data.content` numa resposta paginada.
- Estilos: `src/App.css`, `src/index.css`.

Observações importantes no frontend:
- Base API e origem estão hardcoded para `192.168.100.44:8081` e a origem CORS permitida no backend é `http://192.168.100.44:5174`. Isso funciona em seu ambiente atual, mas é frágil (não é portável).
- O formulário de criação envia `email` no body JSON: `{ nome, email, senha }`, porém o backend ignora `email` (DTO não possui campo). Isto causa discrepância entre UX e persistência; o usuário achará que o email foi salvo quando não foi.
- Não há gerenciamento de variáveis de ambiente (ex.: `VITE_API_URL`) nem proxy dev configurado no Vite.

---

## Divergências e riscos
1. Modelo de dados desalinhado: frontend envia `email` mas backend não persiste. Decisão requerida: **remover o campo email do frontend** ou **adicionar `email` no backend (entity + dto + migration/testes)**.
2. Configuração de URL/API hardcoded: usar env var (`VITE_API_URL`) ou proxy dev para facilitar desenvolvimento e deploy.
3. CORS e origens: `WebConfig` permite apenas `http://192.168.100.44:5174`. Se frontend for servido de outra origem, será preciso atualizar `allowedOrigins` ou parametrizar via config.
4. Autenticação enviada como Basic no frontend — aceitável para PoC, mas para produção considerar fluxo diferente (tokens) ou HTTPS e armazenamento seguro das credenciais.
5. Testes: backend tem boa cobertura; frontend não tem testes (nenhum arquivo de teste encontrado). Considerar adicionar testes de integração/CI.

---

## Prioridade: próximos passos recomendados (curto prazo)
1. Corrigir o descompasso `email` (ALTA): decidir e implementar — duas opções:
   - Backend: adicionar `email` em `Usuario` + `UsuarioRequestDTO` + `UsuarioDTO` + ajustar testes (repositório DB, migrations se necessário).
   - OU Frontend: remover campo `email` do formulário e UI, e remover referências.
   Recomendo: alinhar com o objetivo do produto; se o e-mail for necessário, implemente no backend.

2. Externalizar a base URL do API (ALTA): mudar frontend para usar `import.meta.env.VITE_API_URL` com fallback local. Atualizar `vite.config.js` / `.env` e substituir URLs hardcoded em `App.jsx`.

3. Ajustar CORS para ser parametrizável (MÉDIO): em `WebConfig` ler uma propriedade `app.frontend.origin` (application-dev.yml) ou permitir `http://localhost:5173/` + a origin dev. Evitar origin hardcode.

4. Validar preflight / OPTIONS com Spring Security (MÉDIO): atualmente `SecurityConfig` + `WebConfig` devem permitir `OPTIONS` com `allowCredentials(true)`; testes manuais com `curl -X OPTIONS` podem confirmar preflight. Se ocorrer 401, ajustar `SecurityConfig` para permitir `OPTIONS` sem autenticação.

5. Adicionar env var para credenciais de admin nos testes/documentação (BAIXA): manter `admin/123456` em memória para dev, mas documentar como mudar.

6. (Opcional) Adicionar testes frontend (low): E2E com Playwright / Cypress ou testes unitários com React Testing Library para validar fluxo de login, listagem e criação.

---

## Tarefas de implementação imediatas (pistas de código)
- Para usar `VITE_API_URL` no frontend:
  - `package.json` scripts continuam iguais; criar `.env.local` com `VITE_API_URL=http://localhost:8081`.
  - Em `src/App.jsx`, substituir `'http://192.168.100.44:8081/api/usuarios'` por `${import.meta.env.VITE_API_URL}/api/usuarios`.

- Para adicionar `email` no backend (exemplo mínimo):
  - `Usuario.java` — adicionar `private String email;` + getter/setter + coluna no schema (ou migration manual se Postgres).
  - `UsuarioRequestDTO` e `UsuarioDTO` — adicionar campo `email` e ajustar construtores/getters/setters.
  - `UsuarioService.criar` — setEmail(dto.getEmail()) e mapear no retorno.
  - Atualizar testes em `UsuarioControllerTest` para enviar email e verificar persistência.

- Para parametrizar CORS (`WebConfig`): ler `@Value("${app.frontend.origin:http://localhost:5173}")` e usar no `allowedOrigins`.

---

## Checklist para validar depois de mudanças
- [ ] Frontend usa `VITE_API_URL` e funciona em `npm run dev` (ou `pnpm`/`npm` conforme preferir).
- [ ] Backend persiste `email` se essa for a escolha, ou frontend não envia email (se optar por remover).
- [ ] CORS permite origens necessárias e preflight OPTIONS retorna 200 sem exigir auth.
- [ ] Testes backend ainda passam (`mvn test`) após mudanças.
- [ ] Adicionar testes frontend básicos (opcional).

---

Se quiser, eu prossigo com as seguintes ações imediatas (diga qual prefere):
- A) Gerar patch no frontend substituindo URLs por `VITE_API_URL` + criar `.env.example` e instruções.  
- B) Gerar patch no backend para adicionar campo `email` em `Usuario` + DTOs + testes atualizados.  
- C) Ajustar `WebConfig` para leitura de origem via propriedade e dar patch em `application-dev.yml`.
- D) Um PR que aplica A + C (melhor fluxo dev), mantendo backend sem email por enquanto.

Escolha uma opção (A/B/C/D) ou peça um mix. Posso aplicar os patches automaticamente aqui no workspace e rodar os testes backend (`mvn test`) se desejar.
