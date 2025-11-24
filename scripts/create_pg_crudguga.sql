-- Script para criar usuário e banco 'crudguga' no PostgreSQL
-- Execute como superuser (ex.: psql -U postgres -f create_pg_crudguga.sql)

CREATE USER crudguga WITH PASSWORD 'crudguga';
CREATE DATABASE crudguga OWNER crudguga;
GRANT ALL PRIVILEGES ON DATABASE crudguga TO crudguga;

-- Fim
