# Documento de Requisitos – Sistema de cadastro de usuarios

Sou iniciante em JAVA e desejo aprender e me tornar um excelente profissional, por isso preciso que voce seja meu instrutor a partir de agora me ajudando a entender a visão da arquitetura e suas funcionalidades,
no desenvolvimento de aplicativos em JAVA e springboot.
Vamos desenvolver um aplicativo em Java com Spring Boot com banco sqlite para rodar em windows e android.
Organização do projeto deve ser uma organização com uma arquitetura de camadas simples, aquele básico que mostra que você realmente sabe o que tá fazendo, que você sabe
organizar um código, que não é um código todo jogado, mas que se em algum momento alguem pedir para você explicar esse código, você vai conseguir explicar tranquilamente.

## Visão Geral

| Item              | Descrição |
|-------------------|-----------|
| Nome do Sistema   | CRUDGUGA  |
| Objetivo          | Gerenciar um cadastro de usuarios |
| Tecnologias       | Java 21 (JDK 21), Spring Boot, Spring Web, Spring Data JPA, Spring Security, H2, Lombok, Maven |
| Público-alvo      | Usuários internos (usuarios, administradores) |

## Requisitos Funcionais

### Autenticação e Usuário

| ID     | Nome                              | Descrição                                                                                         | Prioridade |
|--------|-----------------------------------|---------------------------------------------------------------------------------------------------|------------|
| RF-001 | Autenticação HTTP Basic           | O sistema deve exigir autenticação HTTP Basic para acesso aos endpoints protegidos.              | Alta       |
| RF-002 | Perfil de teste sem restrições    | No profile `test`, a segurança deve permitir acesso livre para facilitar testes automatizados.  | Média      |

### Gestão de Usuários

| ID     | Nome                     | Descrição                                                                                             | Entradas                                    | Saídas                        | Regra/Observação                                       | Prioridade |
|--------|--------------------------|-------------------------------------------------------------------------------------------------------|---------------------------------------------|-------------------------------|--------------------------------------------------------|------------|
| RF-010 | Cadastro de Usuários     | Permitir cadastrar um novo Usuários.                                                                  | JSON com `nome`.                            | JSON com `id` e `nome`.       | `nome` obrigatório; `id` gerado automaticamente.       | Alta       |
| RF-011 | Listagem de Usuários     | Permitir listar todos os Usuários cadastrados.                                                        | Nenhuma                                     | Lista JSON de categorias.     | Deve retornar todas as categorias existentes.          | Alta       |

## Requisitos Não Funcionais

| ID      | Nome             | Descrição                                                                                                      | Prioridade |
|---------|------------------|----------------------------------------------------------------------------------------------------------------|------------|
| RNF-001 | Plataforma        | O backend deve ser desenvolvido em Java com Spring Boot.                                                       | Alta       |
| RNF-002 | Persistência      | O sistema deve utilizar banco H2 em memória para desenvolvimento/testes e Spring Data JPA para acesso a dados. | Alta       |
| RNF-003 | Segurança         | Endpoints protegidos devem usar Spring Security com HTTP Basic (exceto no profile de teste).                   | Alta       |
| RNF-004 | API RESTful       | A comunicação deve ser via HTTP, com JSON como formato padrão; endpoints devem declarar `consumes/produces`.   | Alta       |
| RNF-005 | Tratamento de erros | O sistema deve retornar códigos HTTP adequados (200/201, 400, 401, 404, 500 apenas em erros inesperados).     | Média      |

## Modelo de Dados (Resumo)

### Usuários

| Atributo | Tipo  | Descrição                             |
|----------|-------|---------------------------------------|
| id       | Long  | Identificador único, gerado pelo BD.  |
| nome     | String| Nome do Usuário  (obrigatório).       |
| senha    | String| senha do Usuário (obrigatório).       |

## Casos de Uso (Resumo)

| ID   | Nome                               | Atores              | Descrição Resumida                                                                                 |
|------|------------------------------------|---------------------|----------------------------------------------------------------------------------------------------|
| UC-01| Cadastrar Usuários                 | Usuário autenticado | Envia `POST /usuarios` com JSON e recebe usuario criada com `id`.                                |
| UC-01| Alterar Usuários                   | Usuário autenticado | Envia `PUT /usuarios/Id` com JSON e recebe usuario criada com `id` e 'nome'.                       |
| UC-01| Excluir Usuários                   | Usuário autenticado | Envia `DELETE /usuarios/id` com JSON e recebe confirmacao.                                |
| UC-02| Listar String| Nome do Usuários (obrigatório).      | Usuário autenticado | Envia `GET /usuarios` e recebe lista de usuarios.                                             |
