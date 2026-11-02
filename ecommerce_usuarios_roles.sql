-- ============================================================
-- USUÁRIOS E PERFIS DE ACESSO - MYSQL 8.0+
-- Banco: ecommerce
--
-- Execute com uma conta administrativa do MySQL.
-- Ajuste as senhas antes de executar em qualquer ambiente real.
-- ============================================================

USE ecommerce;

-- ------------------------------------------------------------
-- 1. CRIAÇÃO DOS ROLES (PERFIS)
-- ------------------------------------------------------------

CREATE ROLE IF NOT EXISTS
    'role_admin',
    'role_app',
    'role_readonly',
    'role_catalogo';


-- ------------------------------------------------------------
-- 2. PERMISSÕES DOS ROLES
-- ------------------------------------------------------------

-- Administrador: acesso completo somente ao banco ecommerce.
-- Não concede privilégios globais nem GRANT OPTION.
GRANT ALL PRIVILEGES
    ON ecommerce.*
    TO 'role_admin';


-- Aplicação: acesso CRUD às tabelas e execução de procedures.
-- Não possui permissões de DDL (CREATE, ALTER, DROP).
GRANT SELECT, INSERT, UPDATE, DELETE
    ON ecommerce.*
    TO 'role_app';

GRANT EXECUTE
    ON ecommerce.*
    TO 'role_app';


-- Somente leitura: permite consultas em todas as tabelas.
GRANT SELECT
    ON ecommerce.*
    TO 'role_readonly';


-- Catálogo: pode consultar categorias e gerenciar produtos.
-- Não pode excluir produtos, preservando o histórico de pedidos.
GRANT SELECT
    ON ecommerce.categorias
    TO 'role_catalogo';

GRANT SELECT, INSERT, UPDATE
    ON ecommerce.produtos
    TO 'role_catalogo';

-- Permite utilizar a procedure CRUD de produtos.
-- A procedure deve existir antes da concessão.
GRANT EXECUTE
    ON PROCEDURE ecommerce.sp_produtos_crud
    TO 'role_catalogo';


-- ------------------------------------------------------------
-- 3. CRIAÇÃO DOS USUÁRIOS
-- ------------------------------------------------------------
-- Host '%' permite conexão a partir de outros containers/máquinas.
-- Em produção, restrinja o host à origem necessária sempre que
-- possível.
--
-- Substitua todas as senhas de exemplo por senhas fortes e únicas.
-- CREATE USER IF NOT EXISTS não troca a senha de uma conta que
-- já existe.

CREATE USER IF NOT EXISTS 'ecommerce_admin'@'%'
    IDENTIFIED BY 'TROQUE_Admin_2026!';

CREATE USER IF NOT EXISTS 'ecommerce_app'@'%'
    IDENTIFIED BY 'TROQUE_App_2026!';

CREATE USER IF NOT EXISTS 'ecommerce_readonly'@'%'
    IDENTIFIED BY 'TROQUE_ReadOnly_2026!';

CREATE USER IF NOT EXISTS 'ecommerce_catalogo'@'%'
    IDENTIFIED BY 'TROQUE_Catalogo_2026!';


-- ------------------------------------------------------------
-- 4. ASSOCIAÇÃO DOS USUÁRIOS AOS ROLES
-- ------------------------------------------------------------

GRANT 'role_admin'
    TO 'ecommerce_admin'@'%';

GRANT 'role_app'
    TO 'ecommerce_app'@'%';

GRANT 'role_readonly'
    TO 'ecommerce_readonly'@'%';

GRANT 'role_catalogo'
    TO 'ecommerce_catalogo'@'%';


-- ------------------------------------------------------------
-- 5. DEFINIR ROLES PADRÃO
-- ------------------------------------------------------------
-- Faz com que o perfil seja ativado automaticamente no login.

SET DEFAULT ROLE 'role_admin'
    TO 'ecommerce_admin'@'%';

SET DEFAULT ROLE 'role_app'
    TO 'ecommerce_app'@'%';

SET DEFAULT ROLE 'role_readonly'
    TO 'ecommerce_readonly'@'%';

SET DEFAULT ROLE 'role_catalogo'
    TO 'ecommerce_catalogo'@'%';


-- ------------------------------------------------------------
-- 6. CONSULTAR PERMISSÕES
-- ------------------------------------------------------------

-- Ver permissões de cada perfil:
-- SHOW GRANTS FOR 'role_admin';
-- SHOW GRANTS FOR 'role_app';
-- SHOW GRANTS FOR 'role_readonly';
-- SHOW GRANTS FOR 'role_catalogo';

-- Ver permissões de cada usuário:
-- SHOW GRANTS FOR 'ecommerce_admin'@'%';
-- SHOW GRANTS FOR 'ecommerce_app'@'%';
-- SHOW GRANTS FOR 'ecommerce_readonly'@'%';
-- SHOW GRANTS FOR 'ecommerce_catalogo'@'%';

-- Ver roles disponíveis:
-- SELECT * FROM mysql.role_edges
-- WHERE TO_USER IN (
--     'ecommerce_admin',
--     'ecommerce_app',
--     'ecommerce_readonly',
--     'ecommerce_catalogo'
-- );


-- ------------------------------------------------------------
-- 7. REVOGAR ACESSO (EXEMPLOS)
-- ------------------------------------------------------------

-- Remover perfil de um usuário:
-- REVOKE 'role_app' FROM 'ecommerce_app'@'%';

-- Bloquear um usuário sem removê-lo:
-- ALTER USER 'ecommerce_app'@'%' ACCOUNT LOCK;

-- Desbloquear um usuário:
-- ALTER USER 'ecommerce_app'@'%' ACCOUNT UNLOCK;

-- Excluir um usuário:
-- DROP USER 'ecommerce_app'@'%';

-- Excluir um perfil (somente depois de revogá-lo dos usuários):
-- DROP ROLE 'role_app';
