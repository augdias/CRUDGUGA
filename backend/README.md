# CRUDGUGA Backend

comando que rodou porque tem que ser com aspas
$Env:JASYPT_ENCRYPTOR_PASSWORD = "0qu2BLzXJXRQ0aJ6xQ7iXBw8z/Uz9p7r8hlbkB1iAhIOSSS9zxUp7qRyk3FwDmQO"
mvn "spring-boot:run" "-Dspring-boot.run.profiles=prod"

Backend didático em Spring Boot para gerenciamento de usuários, com autenticação básica, validação, tratamento de erros, paginação, ordenação e filtro por nome.

## Requisitos

- JDK 21
- Maven

## Stack

- Java 21
- Spring Boot (Web, Data JPA, Security, Validation, Test)
- H2 Database (modo arquivo)
- Spring Security com HTTP Basic
- JPA/Hibernate

## Como rodar

Na pasta `backend`:

```bash
mvn clean package
mvn spring-boot:run
```

Por padrão a API sobe em `http://localhost:8080`.

## Perfis de ambiente

O projeto usa perfis do Spring para separar configurações de desenvolvimento e produção.

- `dev` (padrão):
	- Banco H2 em arquivo (`jdbc:h2:file:./data/crudguga`).
	- Porta `8080`.
	- Console H2 habilitado.
- `prod`:
	- Banco PostgreSQL externo.
	- Porta `8081`.

### Configuração do perfil dev

O perfil `dev` é o padrão definido em `application.properties` (`spring.profiles.active=dev`).

Configurações em `src/main/resources/application-dev.yml`:

- Datasource H2 arquivo.
- `spring.jpa.hibernate.ddl-auto=update`.
- `spring.jpa.show-sql=true`.

Para subir usando o perfil dev (já é o padrão):

```bash
mvn spring-boot:run
```

### Configuração do perfil prod (PostgreSQL)

Configurações em `src/main/resources/application-prod.yml`:

- `spring.datasource.url` (padrão): `jdbc:postgresql://localhost:5433/crudguga`
- `spring.datasource.username` (padrão): `crudguga`
- `spring.datasource.password` (padrão): `crudguga`
- Lidos de variáveis de ambiente quando definidos:
	- `SPRING_DATASOURCE_URL`
	- `SPRING_DATASOURCE_USERNAME`
	- `SPRING_DATASOURCE_PASSWORD`
- `spring.jpa.hibernate.ddl-auto=validate` (recomendado para produção).

Para subir com o perfil `prod` apontando para um PostgreSQL:

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

Ou, após gerar o jar:

```bash
mvn clean package
java -jar target/backend-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod
```

#### Passo a passo local (PostgreSQL)

1. **Criar banco/usuário** (ajuste porta/credenciais conforme o seu Postgres):

	```bash
	psql -h localhost -p 5433 -U postgres
	CREATE USER crudguga WITH PASSWORD 'SUA_SENHA_FORTE';
	CREATE DATABASE crudguga OWNER crudguga;
	GRANT ALL PRIVILEGES ON DATABASE crudguga TO crudguga;
	```

2. **Configurar credenciais na aplicação**:
	- Opção rápida: editar `application-prod.yml` para refletir porta/usuário/senha reais.
	- Opção flexível: exportar variáveis antes de rodar (ex.):

		```powershell
		$Env:SPRING_DATASOURCE_URL="jdbc:postgresql://localhost:5433/crudguga"
		$Env:SPRING_DATASOURCE_USERNAME="crudguga"
		$Env:SPRING_DATASOURCE_PASSWORD="SUA_SENHA_FORTE"
		```

3. **Rodar o backend em modo prod** (porta padrão já é 8081):

	```powershell
mvn spring-boot:run "-Dspring-boot.run.profiles=prod"
	```

4. **Validar conexão**:
	- Acompanhe os logs até aparecer `Tomcat initialized with port 8081`.
	- Rode `SELECT * FROM usuarios;` no Postgres para garantir que a aplicação criou/leu dados.

#### (Opcional) Criptografando propriedades sensíveis com Jasypt

1. Gere o valor cifrado usando o plugin incluso no `pom.xml`:

	```powershell
	mvn -Djasypt.encryptor.password=MINHA_CHAVE_MESTRA ^
	    -Djasypt.plugin.value="SENHA_EM_TEXTO" ^
	    jasypt:encrypt
	```

	- O comando exibirá algo como `ENC(C0cP+F...==)` — copie tudo, incluindo `ENC(...)`.
	- Guardar a chave mestre (`MINHA_CHAVE_MESTRA`) em um cofre/variável de ambiente; ela não deve ir para o repositório.

2. Substitua o valor da propriedade (ex.: `spring.datasource.password`) por `ENC(...)` no `application-prod.yml`.

3. Sempre que rodar o backend, informe a chave mestre para que o Spring possa decifrar:

	```powershell
	$Env:JASYPT_ENCRYPTOR_PASSWORD="MINHA_CHAVE_MESTRA"
	mvn spring-boot:run "-Dspring-boot.run.profiles=prod"
	```

4. Para testar/alterar o valor cifrado, execute `mvn ... jasypt:decrypt` com a mesma chave mestre.

Enquanto a propriedade estiver em texto plano, o aplicativo continua funcionando normalmente; basta migrar para `ENC(...)` quando quiser esconder o segredo no arquivo.

## Autenticação

Todas as rotas são protegidas por HTTP Basic.

Usuário padrão (memória):

- **username**: `admin`
- **password**: `123456`

## Endpoints principais

Base: `http://localhost:8080`

### Criar usuário

- **POST** `/usuarios`
- Body (JSON):

```json
{
	"nome": "Guga",
	"senha": "123456"
}
```

- Respostas:
	- `201 Created` com corpo `UsuarioDTO` e header `Location` apontando para `/usuarios/{id}`
	- `400 Bad Request` para erros de validação (`nome`/`senha` em branco), com payload padronizado de erro

### Buscar usuário por ID

- **GET** `/usuarios/{id}`
- Respostas:
	- `200 OK` com `UsuarioDTO`
	- `404 Not Found` se não existir

### Atualizar usuário

- **PUT** `/usuarios/{id}`
- Body (JSON):

```json
{
	"nome": "Novo Nome",
	"senha": "novaSenha"  
}
```

- Regra: se `senha` for `null` ou em branco, a senha atual é mantida.
- Respostas:
	- `200 OK` com `UsuarioDTO` atualizado
	- `400 Bad Request` para erros de validação
	- `404 Not Found` se não existir

### Deletar usuário

- **DELETE** `/usuarios/{id}`
- Respostas:
	- `204 No Content` em caso de sucesso
	- `404 Not Found` se não existir

## Listagem com paginação, ordenação e filtro

### Endpoint

- **GET** `/usuarios`

### Parâmetros de query

Todos os parâmetros são opcionais:

- `page` (inteiro, default `0`)
	- Índice da página (zero-based).
- `size` (inteiro, default `10`)
	- Tamanho da página (quantidade de registros por página).
- `sortBy` (string, default `nome`)
	- Campo para ordenação. Exemplos: `nome`, `id`.
- `direction` (string, default `asc`)
	- Direção da ordenação: `asc` ou `desc`.
- `nome` (string, opcional)
	- Filtro por nome, usando `LIKE` case-insensitive (`containing ignore case`).
	- Quando informado, somente usuários cujo nome contém o valor de `nome` (ignorando maiúsculas/minúsculas) são retornados.

### Exemplos de uso

#### Página padrão

```http
GET /usuarios HTTP/1.1
Authorization: Basic YWRtaW46MTIzNDU2
```

Retorna a página 0 com até 10 usuários ordenados por `nome` ascendente.

#### Página específica com tamanho customizado

```http
GET /usuarios?page=1&size=5 HTTP/1.1
Authorization: Basic YWRtaW46MTIzNDU2
```

Retorna a página 1 com até 5 usuários por página.

#### Ordenação por nome descendente

```http
GET /usuarios?sortBy=nome&direction=desc HTTP/1.1
Authorization: Basic YWRtaW46MTIzNDU2
```

Retorna usuários ordenados pelo campo `nome` em ordem decrescente.

#### Ordenação por id crescente

```http
GET /usuarios?sortBy=id&direction=asc HTTP/1.1
Authorization: Basic YWRtaW46MTIzNDU2
```

#### Filtro por nome (contém, case-insensitive)

```http
GET /usuarios?nome=gu HTTP/1.1
Authorization: Basic YWRtaW46MTIzNDU2
```

Retorna apenas usuários cujo `nome` contém `"gu"`, ignorando maiúsculas/minúsculas, ainda respeitando paginação e ordenação.

#### Combinando paginação, ordenação e filtro

```http
GET /usuarios?page=0&size=5&sortBy=nome&direction=asc&nome=gu HTTP/1.1
Authorization: Basic YWRtaW46MTIzNDU2
```

### Estrutura de resposta paginada

A resposta de `GET /usuarios` é um `Page<UsuarioDTO>` serializado em JSON, com estrutura semelhante a:

```json
{
	"content": [
		{ "id": 1, "nome": "Guga" },
		{ "id": 2, "nome": "Gustavo" }
	],
	"totalElements": 2,
	"totalPages": 1,
	"size": 10,
	"number": 0,
	"first": true,
	"last": true,
	"numberOfElements": 2,
	"empty": false
}
```

## Tratamento de erros

Erros são retornados em um formato padronizado, por exemplo para validação:

```json
{
	"timestamp": "2024-01-01T12:34:56.789",
	"status": 400,
	"erro": "Erro de validacao",
	"mensagem": "nome: nao pode estar em branco; senha: nao pode estar em branco",
	"caminho": "/usuarios"
}
```

## Testes

Para rodar a suíte de testes (incluindo controller, service e cobertura de paginação/ordenacao/filtro):

```bash
mvn test
```

Os testes cobrem:
- CRUD básico de usuários
- Validação de campos e tratamento de erros
- Paginação simples
- Ordenação por `nome` (asc/desc)
- Filtro por `nome` (contém, case-insensitive) combinado com paginação/ordenacao.

## Smoke test web (frontend simples)

- A aplicação serve uma página estática em `src/main/resources/static/smoke-test.html`.
- Quando o backend estiver rodando (ex.: `http://localhost:8081`), acesse `http://localhost:8081/smoke-test.html`.
- Informe as credenciais de HTTP Basic (`admin` / `123456`) e clique em **Executar smoke test**.
- O script cria um usuário com timestamp, consulta pelo ID, lista a página padrão e apaga o registro, registrando cada passo em um log na própria página.
- Use esse fluxo como verificação rápida após subir o ambiente `prod` com PostgreSQL real.

## Checklist rápido (produção local)

1. **Banco pronto**: garanta que o Postgres está rodando (ex.: `localhost:5433`), com banco `crudguga` e usuário com permissão de leitura/escrita.
2. **Segredos carregados**: exporte `SPRING_DATASOURCE_*` e, se estiver usando senha cifrada, `JASYPT_ENCRYPTOR_PASSWORD` com a chave mestre.
3. **Build limpo**: rode `mvn clean package` para validar dependências e gerar o jar atualizado.
4. **Start em prod**: execute `mvn spring-boot:run -Dspring-boot.run.profiles=prod` (ou `java -jar ... --spring.profiles.active=prod`) e confira nos logs que o Tomcat abriu na porta `8081`.
5. **Smoke test**: acesse `http://localhost:8081/smoke-test.html`, informe `admin/123456` e valide se o CRUD completo passa.
6. **Monitoramento básico**: confira os logs do terminal buscando por `ERROR` e, no Postgres, execute `SELECT COUNT(*) FROM usuarios;` para garantir que os registros de teste foram aplicados.

### Relatório de cobertura (JaCoCo)

Para gerar e acessar o relatório de cobertura de código com JaCoCo:

1. Execute os testes (o plugin já está configurado no `pom.xml`):

	```bash
	mvn test
	```

2. Abra o arquivo HTML gerado em:

	- `target/site/jacoco/index.html`

Você pode abrir esse arquivo diretamente no navegador para visualizar a cobertura por pacote, classe e método.
```