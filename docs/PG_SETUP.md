# Postgres setup para CRUDGUGA

Este documento descreve passos rápidos para criar o usuário e o banco `crudguga` localmente com `psql`, e como testar a conexão e executar o backend no perfil `prod`.

1) Verifique a porta do seu Postgres
- Por padrão o Postgres usa `5432`. O `application-prod.yml` do projeto referencia `5433` — escolha uma:
  - usar porta 5432 (mais provável) — recomendação: use 5432 e atualize `SPRING_DATASOURCE_URL` abaixo
  - ou alterar o `application-prod.yml` para apontar para 5432

2) Script SQL (arquivo `scripts/create_pg_crudguga.sql`)
- O arquivo `scripts/create_pg_crudguga.sql` já foi adicionado ao repositório e contém:

```
CREATE USER crudguga WITH PASSWORD 'crudguga';
CREATE DATABASE crudguga OWNER crudguga;
GRANT ALL PRIVILEGES ON DATABASE crudguga TO crudguga;
```

3) Executar o script com `psql` (PowerShell)
- Se você souber a senha do superuser `postgres`, exporte temporariamente:

```powershell
$Env:PGPASSWORD="SENHA_DO_SUPERUSER"
psql -h localhost -p 5432 -U postgres -f .\scripts\create_pg_crudguga.sql
```

- Se sua instalação usar autenticação sem senha (ident), apenas rode:

```powershell
psql -h localhost -p 5432 -U postgres -f .\scripts\create_pg_crudguga.sql
```

4) Testar conexão com o usuário criado
```powershell
$Env:PGPASSWORD="crudguga"
psql -h localhost -p 5432 -U crudguga -d crudguga -c "\dt"
```

5) Configurar backend para usar o banco (modo temporário via variáveis de ambiente)
- No PowerShell (sessão atual):
```powershell
$Env:SPRING_DATASOURCE_URL="jdbc:postgresql://localhost:5432/crudguga"
$Env:SPRING_DATASOURCE_USERNAME="crudguga"
$Env:SPRING_DATASOURCE_PASSWORD="crudguga"

# Rodar em modo prod
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```
- Alternativamente, ajuste `src/main/resources/application-prod.yml` diretamente (não recomendado em produção):

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/crudguga
    username: crudguga
    password: crudguga
```

6) Notas de segurança e produção
- Não deixe senhas em texto no repositório. Use variáveis de ambiente ou Jasypt para produção.
- Se for necessário que o Postgres ouça na porta `5433` (conforme `application-prod.yml` atual), altere `5432` para `5433` nos comandos acima ou ajuste `application-prod.yml`.

Se quiser, eu posso:
- Gerar o comando pronto substituindo a porta por `5433` (se seu Postgres já roda nessa porta).
- Rodar localmente os comandos via terminal aqui (não posso executar no seu computador; você precisa rodar localmente). 

---
Arquivo criado por AI: `scripts/create_pg_crudguga.sql` contém os comandos SQL originais para criação do usuário e banco.
