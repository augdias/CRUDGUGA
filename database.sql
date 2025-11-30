-- Criar database (rodar conectado como superuser, ex.: postgres)
CREATE DATABASE crudguga
  WITH 
    OWNER = crudguga
    ENCODING = 'UTF8'
    LC_COLLATE = 'pt_BR.UTF-8'
    LC_CTYPE = 'pt_BR.UTF-8'
    TEMPLATE = template0;

-- Opcional: criar usuário (caso ainda não exista)
CREATE USER crudguga WITH PASSWORD 'crudguga';

GRANT ALL PRIVILEGES ON DATABASE crudguga TO crudguga;

-- Conectar no banco crudguga antes de criar as tabelas
\c crudguga;

-- Criar tabela usuario
CREATE TABLE usuario (
    id      BIGSERIAL PRIMARY KEY,
    nome    VARCHAR(255) NOT NULL,
    senha   VARCHAR(255) NOT NULL
);

-- Índice opcional por nome para melhorar buscas por nome (filtro LIKE)
CREATE INDEX idx_usuario_nome ON usuario (nome);