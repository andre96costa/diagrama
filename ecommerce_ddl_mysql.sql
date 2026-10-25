-- DDL MySQL 8.0.16+ — E-commerce de pequeno porte
-- Execute em um banco MySQL vazio.

CREATE DATABASE IF NOT EXISTS ecommerce
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE ecommerce;

CREATE TABLE usuarios (
    id              INT NOT NULL AUTO_INCREMENT,
    nome            VARCHAR(100) NOT NULL,
    email           VARCHAR(100) NOT NULL,
    senha           VARCHAR(255) NOT NULL,
    cpf             VARCHAR(14) NULL,
    telefone        VARCHAR(20) NULL,
    data_cadastro   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_usuarios PRIMARY KEY (id),
    CONSTRAINT uq_usuarios_email UNIQUE (email),
    CONSTRAINT uq_usuarios_cpf UNIQUE (cpf)
) ENGINE=InnoDB;

CREATE TABLE enderecos (
    id              INT NOT NULL AUTO_INCREMENT,
    id_usuario      INT NOT NULL,
    cep             VARCHAR(10) NOT NULL,
    logradouro      VARCHAR(100) NOT NULL,
    numero          VARCHAR(10) NOT NULL,
    complemento     VARCHAR(50) NULL,
    bairro          VARCHAR(50) NOT NULL,
    cidade          VARCHAR(50) NOT NULL,
    estado          CHAR(2) NOT NULL,
    principal       BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_enderecos PRIMARY KEY (id),
    INDEX idx_enderecos_id_usuario (id_usuario),
    CONSTRAINT fk_enderecos_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE categorias (
    id              INT NOT NULL AUTO_INCREMENT,
    nome            VARCHAR(50) NOT NULL,
    descricao       TEXT NULL,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_categorias PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE produtos (
    id              INT NOT NULL AUTO_INCREMENT,
    nome            VARCHAR(100) NOT NULL,
    descricao       TEXT NULL,
    preco           DECIMAL(10,2) NOT NULL,
    estoque         INT NOT NULL DEFAULT 0,
    imagem_url      VARCHAR(255) NULL,
    categoria_id    INT NOT NULL,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_produtos PRIMARY KEY (id),
    INDEX idx_produtos_categoria_id (categoria_id),
    CONSTRAINT ck_produtos_preco CHECK (preco >= 0),
    CONSTRAINT ck_produtos_estoque CHECK (estoque >= 0),
    CONSTRAINT fk_produtos_categoria
        FOREIGN KEY (categoria_id) REFERENCES categorias(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE pedidos (
    id              INT NOT NULL AUTO_INCREMENT,
    id_usuario      INT NOT NULL,
    id_endereco     INT NOT NULL,
    numero_pedido   VARCHAR(20) NOT NULL,
    data_pedido     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          VARCHAR(20) NOT NULL DEFAULT 'pendente',
    valor_total     DECIMAL(10,2) NOT NULL DEFAULT 0,
    observacoes     TEXT NULL,
    forma_pagamento VARCHAR(50) NULL,
    CONSTRAINT pk_pedidos PRIMARY KEY (id),
    CONSTRAINT uq_pedidos_numero_pedido UNIQUE (numero_pedido),
    INDEX idx_pedidos_id_usuario (id_usuario),
    INDEX idx_pedidos_id_endereco (id_endereco),
    CONSTRAINT ck_pedidos_valor_total CHECK (valor_total >= 0),
    CONSTRAINT fk_pedidos_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuarios(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_pedidos_endereco
        FOREIGN KEY (id_endereco) REFERENCES enderecos(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE itens_pedido (
    id              INT NOT NULL AUTO_INCREMENT,
    id_pedido       INT NOT NULL,
    id_produto      INT NOT NULL,
    quantidade      INT NOT NULL,
    preco_unitario  DECIMAL(10,2) NOT NULL,
    preco_total     DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_itens_pedido PRIMARY KEY (id),
    INDEX idx_itens_pedido_id_pedido (id_pedido),
    INDEX idx_itens_pedido_id_produto (id_produto),
    CONSTRAINT ck_itens_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_itens_preco_unitario CHECK (preco_unitario >= 0),
    CONSTRAINT ck_itens_preco_total CHECK (preco_total >= 0),
    CONSTRAINT fk_itens_pedido_pedido
        FOREIGN KEY (id_pedido) REFERENCES pedidos(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_itens_pedido_produto
        FOREIGN KEY (id_produto) REFERENCES produtos(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE pagamentos (
    id              INT NOT NULL AUTO_INCREMENT,
    id_pedido       INT NOT NULL,
    tipo            VARCHAR(20) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pendente',
    valor           DECIMAL(10,2) NOT NULL,
    data_pagamento  TIMESTAMP NULL,
    transacao_id    VARCHAR(100) NULL,
    CONSTRAINT pk_pagamentos PRIMARY KEY (id),
    INDEX idx_pagamentos_id_pedido (id_pedido),
    CONSTRAINT ck_pagamentos_valor CHECK (valor >= 0),
    CONSTRAINT fk_pagamentos_pedido
        FOREIGN KEY (id_pedido) REFERENCES pedidos(id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE cupons (
    id              INT NOT NULL AUTO_INCREMENT,
    codigo          VARCHAR(50) NOT NULL,
    tipo            VARCHAR(20) NOT NULL,
    valor           DECIMAL(10,2) NOT NULL,
    validade_inicio DATE NOT NULL,
    validade_fim    DATE NOT NULL,
    ativo           BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_cupons PRIMARY KEY (id),
    CONSTRAINT uq_cupons_codigo UNIQUE (codigo),
    CONSTRAINT ck_cupons_valor CHECK (valor >= 0),
    CONSTRAINT ck_cupons_periodo CHECK (validade_fim >= validade_inicio)
) ENGINE=InnoDB;

CREATE TABLE pedido_cupom (
    id              INT NOT NULL AUTO_INCREMENT,
    id_pedido       INT NOT NULL,
    id_cupom        INT NOT NULL,
    CONSTRAINT pk_pedido_cupom PRIMARY KEY (id),
    CONSTRAINT uq_pedido_cupom UNIQUE (id_pedido, id_cupom),
    INDEX idx_pedido_cupom_id_cupom (id_cupom),
    CONSTRAINT fk_pedido_cupom_pedido
        FOREIGN KEY (id_pedido) REFERENCES pedidos(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pedido_cupom_cupom
        FOREIGN KEY (id_cupom) REFERENCES cupons(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;
