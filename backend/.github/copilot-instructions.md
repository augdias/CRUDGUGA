 
# Copilot Instructions — CRUDGUGA Backend (resumo prático)

Documento curto com as convenções que um agente/AI deve seguir ao editar o backend Java (Spring Boot).

**Visão Geral**
- Monólito REST em Spring Boot (Java 21). Domínio principal: usuários. Código segue padrão `controller` → `service` → `repository` → `entity`.

**Arquivos/locais-chave (exemplos)**
- Constantes de rota: `src/main/java/com/crudguga/backend/config/ApiPaths.java` (use `USUARIOS`, `USUARIOS_ID`, `ROLE_ADMIN`).
- Global error handling: `src/main/java/com/crudguga/backend/config/GlobalExceptionHandler.java` e `config/MensagensErro.java`.
- Security: `src/main/java/com/crudguga/backend/config/SecurityConfig.java` (HTTP Basic em memória: `admin`/`123456`, CSRF desabilitado no perfil dev).
- Exemplos: `src/main/java/com/crudguga/backend/controller/UsuarioController.java`, `service/UsuarioService.java`, `repository/UsuarioRepository.java`.

**Regras essenciais para mudanças de código**
- Nunca expor entidades JPA diretamente nas respostas: use DTOs (`UsuarioDTO`, `UsuarioRequestDTO`).
- Controllers recebem `@RequestBody @Valid` DTOs; valide com anotações `jakarta.validation`.
- Para criação (`POST`): seguir `ResponseEntity.created(location).body(dto)` e apontar `Location` para `.../{id}`.
- Paginação/ordenção: siga o padrão do projeto — query params `page`, `size`, `sortBy`, `direction`; construir `Pageable` com `PageRequest.of(...)` e devolver `Page<DTO>` mapeado a partir do repositório.
- Filtros paginados: use delegação controller → service → repository; repositório deve expor métodos como `findByNomeContainingIgnoreCase(String, Pageable)`.

**Tratamento de erros**
- Use `GlobalExceptionHandler` + `ErroResponse`. Não crie handlers redundantes para as mesmas exceções.
- Ao lançar erros no `service`, prefira exceções padrão (Spring/JPA) ou `RuntimeException`; evite retornar `null` (use `Optional`).

**Segurança e testes**
- Segurança: não troque o mecanismo (Basic auth em memória), a menos que toda a equipe concorde.
- Testes de controller usam `@WithMockUser(username = "admin", roles = ROLE_ADMIN)` — replique isso nos novos testes de controller.

**Build / run / testes**
- Build: `mvn clean package`
- Rodar local (dev profile): `mvn spring-boot:run` (o `application.properties` ativa `dev` por padrão).
- Testes: `mvn test` (JaCoCo disponível em `target/site/jacoco/index.html`).

**Boas práticas específicas do repo**
- Entidades não usam Lombok — escrever getters/setters manualmente se necessário.
- Ao atualizar senha em `UsuarioService.atualizar`, preserve a senha existente quando o DTO trouxer senha `null` ou vazia.
- Reutilize constantes de `ApiPaths` ao construir `@RequestMapping`/`@GetMapping` etc.

Seções de referência rápida (onde olhar):
- Controllers: `src/main/java/com/crudguga/backend/controller/` (ex.: `UsuarioController.java`)
- Services: `src/main/java/com/crudguga/backend/service/`
- Repositories: `src/main/java/com/crudguga/backend/repository/`
- Config: `src/main/java/com/crudguga/backend/config/` (`ApiPaths.java`, `SecurityConfig.java`, `GlobalExceptionHandler.java`)

Peça feedback: se alguma área precisar de mais exemplos (ex.: padrão exato de DTOs, testes unitários ou patchs prontos), diga qual seção quer expandir.
