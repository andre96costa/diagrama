-- ============================================================
-- Melhorias de índices e CRUD de produtos
-- Compatível com MySQL 8.0.16+
-- Execute depois do DDL original (e dentro do banco ecommerce).
-- ============================================================

USE ecommerce;

-- ------------------------------------------------------------
-- 1. ÍNDICES
-- Os índices simples substituídos são removidos para evitar
-- redundância. Os novos índices compostos também atendem às FKs.
-- ------------------------------------------------------------

ALTER TABLE produtos
    ADD INDEX idx_produtos_categoria_ativo (categoria_id, ativo),
    ADD INDEX idx_produtos_nome (nome),
    ADD FULLTEXT INDEX ft_produtos_busca (nome, descricao);

ALTER TABLE produtos
    DROP INDEX idx_produtos_categoria_id;

ALTER TABLE categorias
    ADD INDEX idx_categorias_ativo_nome (ativo, nome);

ALTER TABLE enderecos
    ADD INDEX idx_enderecos_usuario_principal (id_usuario, principal);

ALTER TABLE enderecos
    DROP INDEX idx_enderecos_id_usuario;

ALTER TABLE pedidos
    ADD INDEX idx_pedidos_usuario_data (id_usuario, data_pedido),
    ADD INDEX idx_pedidos_status_data (status, data_pedido);

ALTER TABLE pedidos
    DROP INDEX idx_pedidos_id_usuario;

ALTER TABLE cupons
    ADD INDEX idx_cupons_ativo_validade (ativo, validade_inicio, validade_fim);


-- ------------------------------------------------------------
-- 2. PROCEDURE: CRUD DE PRODUTOS
--
-- Ações:
--   INSERIR  - cadastra um produto e retorna o ID criado.
--   ATUALIZAR - atualiza os campos do produto informado.
--   EXCLUIR  - exclui fisicamente; pode ser impedido pela FK
--              caso o produto já esteja em itens_pedido.
--   BUSCAR   - consulta um produto pelo ID.
--   LISTAR   - lista produtos, com filtros opcionais.
--
-- Para LISTAR:
--   p_categoria_id = NULL -> todas as categorias
--   p_ativo = NULL         -> produtos ativos e inativos
--
-- Para INSERIR:
--   p_ativo = NULL         -> assume TRUE
--
-- Para ATUALIZAR:
--   os campos obrigatórios devem ser informados;
--   descricao e imagem_url podem ser NULL para limpar os campos;
--   p_ativo = NULL mantém o valor atual.
-- ------------------------------------------------------------

DROP PROCEDURE IF EXISTS sp_produtos_crud;

DELIMITER $$

CREATE PROCEDURE sp_produtos_crud(
    IN p_acao          VARCHAR(10),
    IN p_id            INT,
    IN p_nome          VARCHAR(100),
    IN p_descricao     TEXT,
    IN p_preco         DECIMAL(10,2),
    IN p_estoque       INT,
    IN p_imagem_url    VARCHAR(255),
    IN p_categoria_id  INT,
    IN p_ativo         BOOLEAN
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_acao VARCHAR(10);

    SET v_acao = UPPER(TRIM(p_acao));

    CASE v_acao

        -- CADASTRAR
        WHEN 'INSERIR' THEN

            IF p_nome IS NULL OR TRIM(p_nome) = '' THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'O nome do produto é obrigatório.';
            END IF;

            IF p_preco IS NULL OR p_preco < 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'O preço deve ser informado e maior ou igual a zero.';
            END IF;

            IF p_estoque IS NULL OR p_estoque < 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'O estoque deve ser informado e maior ou igual a zero.';
            END IF;

            IF p_categoria_id IS NULL THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'A categoria do produto é obrigatória.';
            END IF;

            INSERT INTO produtos (
                nome,
                descricao,
                preco,
                estoque,
                imagem_url,
                categoria_id,
                ativo
            ) VALUES (
                TRIM(p_nome),
                p_descricao,
                p_preco,
                p_estoque,
                p_imagem_url,
                p_categoria_id,
                COALESCE(p_ativo, TRUE)
            );

            SELECT
                LAST_INSERT_ID() AS id,
                'Produto cadastrado com sucesso.' AS mensagem;


        -- ATUALIZAR
        WHEN 'ATUALIZAR' THEN

            IF p_id IS NULL THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'O ID do produto é obrigatório.';
            END IF;

            SELECT COUNT(*)
              INTO v_existe
              FROM produtos
             WHERE id = p_id;

            IF v_existe = 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Produto não encontrado.';
            END IF;

            IF p_nome IS NULL OR TRIM(p_nome) = '' THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'O nome do produto é obrigatório.';
            END IF;

            IF p_preco IS NULL OR p_preco < 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'O preço deve ser informado e maior ou igual a zero.';
            END IF;

            IF p_estoque IS NULL OR p_estoque < 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'O estoque deve ser informado e maior ou igual a zero.';
            END IF;

            IF p_categoria_id IS NULL THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'A categoria do produto é obrigatória.';
            END IF;

            UPDATE produtos
               SET nome         = TRIM(p_nome),
                   descricao    = p_descricao,
                   preco        = p_preco,
                   estoque      = p_estoque,
                   imagem_url   = p_imagem_url,
                   categoria_id = p_categoria_id,
                   ativo        = COALESCE(p_ativo, ativo)
             WHERE id = p_id;

            SELECT
                p_id AS id,
                'Produto atualizado com sucesso.' AS mensagem;


        -- EXCLUIR FISICAMENTE
        WHEN 'EXCLUIR' THEN

            IF p_id IS NULL THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'O ID do produto é obrigatório.';
            END IF;

            SELECT COUNT(*)
              INTO v_existe
              FROM produtos
             WHERE id = p_id;

            IF v_existe = 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Produto não encontrado.';
            END IF;

            DELETE FROM produtos
             WHERE id = p_id;

            SELECT
                p_id AS id,
                'Produto excluído com sucesso.' AS mensagem;


        -- BUSCAR POR ID
        WHEN 'BUSCAR' THEN

            IF p_id IS NULL THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'O ID do produto é obrigatório.';
            END IF;

            SELECT
                p.id,
                p.nome,
                p.descricao,
                p.preco,
                p.estoque,
                p.imagem_url,
                p.categoria_id,
                c.nome AS categoria,
                p.ativo
            FROM produtos p
            INNER JOIN categorias c
                ON c.id = p.categoria_id
            WHERE p.id = p_id;


        -- LISTAR COM FILTROS OPCIONAIS
        WHEN 'LISTAR' THEN

            SELECT
                p.id,
                p.nome,
                p.descricao,
                p.preco,
                p.estoque,
                p.imagem_url,
                p.categoria_id,
                c.nome AS categoria,
                p.ativo
            FROM produtos p
            INNER JOIN categorias c
                ON c.id = p.categoria_id
            WHERE
                (p_categoria_id IS NULL OR p.categoria_id = p_categoria_id)
                AND
                (p_ativo IS NULL OR p.ativo = p_ativo)
            ORDER BY p.nome ASC;


        ELSE
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Ação inválida. Utilize INSERIR, ATUALIZAR, EXCLUIR, BUSCAR ou LISTAR.';

    END CASE;
END$$

DELIMITER ;


-- ------------------------------------------------------------
-- 3. EXEMPLOS DE UTILIZAÇÃO
-- ------------------------------------------------------------

-- Cadastrar produto:
-- CALL sp_produtos_crud(
--     'INSERIR', NULL, 'Teclado Mecânico',
--     'Teclado mecânico ABNT2', 299.90, 15,
--     NULL, 1, TRUE
-- );

-- Atualizar produto de ID 1:
-- CALL sp_produtos_crud(
--     'ATUALIZAR', 1, 'Teclado Mecânico RGB',
--     'Teclado mecânico ABNT2 com iluminação RGB',
--     349.90, 20, NULL, 1, TRUE
-- );

-- Buscar produto:
-- CALL sp_produtos_crud(
--     'BUSCAR', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL
-- );

-- Listar todos:
-- CALL sp_produtos_crud(
--     'LISTAR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
-- );

-- Listar somente produtos ativos:
-- CALL sp_produtos_crud(
--     'LISTAR', NULL, NULL, NULL, NULL, NULL, NULL, NULL, TRUE
-- );

-- Listar produtos ativos de uma categoria:
-- CALL sp_produtos_crud(
--     'LISTAR', NULL, NULL, NULL, NULL, NULL, NULL, 1, TRUE
-- );

-- Excluir produto:
-- CALL sp_produtos_crud(
--     'EXCLUIR', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL
-- );

-- Pesquisa textual FULLTEXT (exemplo separado):
-- SELECT id, nome, preco
-- FROM produtos
-- WHERE MATCH(nome, descricao)
--       AGAINST ('teclado mecanico' IN NATURAL LANGUAGE MODE);
