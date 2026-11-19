
-- Cenário 2 | Sistema de Viagens
-- MySQL 8.0.16+ (para aplicação das restrições CHECK).
-- Execute em um banco novo. O script não apaga estruturas existentes.

CREATE DATABASE IF NOT EXISTS sistema_viagens CHARACTER SET utf8mb4;
USE sistema_viagens;

-- 1. Tabelas principais e cadastros de apoio

CREATE TABLE viagem (
    id_viagem INT AUTO_INCREMENT PRIMARY KEY,
    nome_ferias VARCHAR(150) NOT NULL,
    data_inicial DATE NOT NULL,
    data_final DATE NOT NULL,
    CONSTRAINT chk_viagem_periodo CHECK (data_final >= data_inicial)
) ENGINE=InnoDB;

CREATE TABLE pessoa (
    id_pessoa INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    sexo VARCHAR(20) NOT NULL,
    data_nascimento DATE NOT NULL,
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    complemento VARCHAR(100),
    bairro VARCHAR(100) NOT NULL,
    cep VARCHAR(20) NOT NULL,
    cidade VARCHAR(120) NOT NULL,
    estado VARCHAR(80) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE necessidade_especial (
    id_necessidade INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE cidade (
    id_cidade INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    estado_regiao VARCHAR(80),
    pais VARCHAR(80) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE tipo_ponto_turistico (
    id_tipo_ponto INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE ponto_turistico (
    id_ponto INT AUTO_INCREMENT PRIMARY KEY,
    id_cidade INT NOT NULL,
    id_tipo_ponto INT NOT NULL,
    nome VARCHAR(150) NOT NULL,
    horario VARCHAR(100),
    preco DECIMAL(12,2),
    localizacao VARCHAR(255) NOT NULL COMMENT 'Coordenadas ou link do mapa',
    idade_minima SMALLINT NOT NULL COMMENT '0 representa classificação livre',
    CONSTRAINT chk_ponto_preco CHECK (preco >= 0),
    CONSTRAINT chk_ponto_idade CHECK (idade_minima >= 0)
) ENGINE=InnoDB;

CREATE TABLE recurso_acessibilidade (
    id_recurso INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE tipo_despesa (
    id_tipo_despesa INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE moeda (
    id_moeda INT AUTO_INCREMENT PRIMARY KEY,
    codigo CHAR(3) NOT NULL UNIQUE,
    descricao VARCHAR(80) NOT NULL
) ENGINE=InnoDB;

-- 2. Contatos, relacionamentos e movimentações

CREATE TABLE telefone_pessoa (
    id_pessoa INT NOT NULL,
    telefone VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_pessoa, telefone)
) ENGINE=InnoDB;

CREATE TABLE email_pessoa (
    id_pessoa INT NOT NULL,
    email VARCHAR(150) NOT NULL,
    PRIMARY KEY (id_pessoa, email)
) ENGINE=InnoDB;

CREATE TABLE participacao_viagem (
    id_viagem INT NOT NULL,
    id_pessoa INT NOT NULL,
    PRIMARY KEY (id_viagem, id_pessoa)
) ENGINE=InnoDB;

CREATE TABLE pessoa_necessidade (
    id_pessoa INT NOT NULL,
    id_necessidade INT NOT NULL,
    PRIMARY KEY (id_pessoa, id_necessidade)
) ENGINE=InnoDB;

CREATE TABLE ponto_recurso_acessibilidade (
    id_ponto INT NOT NULL,
    id_recurso INT NOT NULL,
    PRIMARY KEY (id_ponto, id_recurso)
) ENGINE=InnoDB;

CREATE TABLE despesa (
    id_despesa INT AUTO_INCREMENT PRIMARY KEY,
    id_viagem INT NOT NULL,
    id_tipo_despesa INT NOT NULL,
    id_moeda INT NOT NULL,
    descricao VARCHAR(255),
    valor DECIMAL(12,2) NOT NULL,
    taxa_conversao_brl DECIMAL(12,6) NOT NULL,
    data_compra DATE NOT NULL,
    data_hora_utilizacao DATETIME NOT NULL,
    link_servico VARCHAR(1000),
    telefone_contato VARCHAR(30),
    email_contato VARCHAR(254),
    arquivo_comprovante VARCHAR(1000) COMMENT 'Caminho ou URL do arquivo',
    CONSTRAINT chk_despesa_valor CHECK (valor >= 0),
    CONSTRAINT chk_despesa_taxa CHECK (taxa_conversao_brl > 0)
) ENGINE=InnoDB;

CREATE TABLE atividade (
    id_atividade INT AUTO_INCREMENT PRIMARY KEY,
    id_viagem INT NOT NULL,
    id_ponto INT NULL,
    descricao VARCHAR(255) NOT NULL,
    data_hora_inicio DATETIME NOT NULL,
    data_hora_fim DATETIME NOT NULL,
    CONSTRAINT chk_atividade_periodo CHECK (data_hora_fim > data_hora_inicio)
) ENGINE=InnoDB;

-- Chaves estrangeiras

ALTER TABLE ponto_turistico
    ADD CONSTRAINT fk_ponto_cidade FOREIGN KEY (id_cidade) REFERENCES cidade (id_cidade),
    ADD CONSTRAINT fk_ponto_tipo FOREIGN KEY (id_tipo_ponto) REFERENCES tipo_ponto_turistico (id_tipo_ponto);

ALTER TABLE telefone_pessoa
    ADD CONSTRAINT fk_telefone_pessoa FOREIGN KEY (id_pessoa) REFERENCES pessoa (id_pessoa);

ALTER TABLE email_pessoa
    ADD CONSTRAINT fk_email_pessoa FOREIGN KEY (id_pessoa) REFERENCES pessoa (id_pessoa);

ALTER TABLE participacao_viagem
    ADD CONSTRAINT fk_participacao_viagem FOREIGN KEY (id_viagem) REFERENCES viagem (id_viagem),
    ADD CONSTRAINT fk_participacao_pessoa FOREIGN KEY (id_pessoa) REFERENCES pessoa (id_pessoa);

ALTER TABLE pessoa_necessidade
    ADD CONSTRAINT fk_pessoa_necessidade_pessoa FOREIGN KEY (id_pessoa) REFERENCES pessoa (id_pessoa),
    ADD CONSTRAINT fk_pessoa_necessidade_necessidade FOREIGN KEY (id_necessidade) REFERENCES necessidade_especial (id_necessidade);

ALTER TABLE ponto_recurso_acessibilidade
    ADD CONSTRAINT fk_ponto_recurso_ponto FOREIGN KEY (id_ponto) REFERENCES ponto_turistico (id_ponto),
    ADD CONSTRAINT fk_ponto_recurso_recurso FOREIGN KEY (id_recurso) REFERENCES recurso_acessibilidade (id_recurso);

ALTER TABLE despesa
    ADD CONSTRAINT fk_despesa_viagem FOREIGN KEY (id_viagem) REFERENCES viagem (id_viagem),
    ADD CONSTRAINT fk_despesa_tipo FOREIGN KEY (id_tipo_despesa) REFERENCES tipo_despesa (id_tipo_despesa),
    ADD CONSTRAINT fk_despesa_moeda FOREIGN KEY (id_moeda) REFERENCES moeda (id_moeda);

ALTER TABLE atividade
    ADD CONSTRAINT fk_atividade_viagem FOREIGN KEY (id_viagem) REFERENCES viagem (id_viagem),
    ADD CONSTRAINT fk_atividade_ponto FOREIGN KEY (id_ponto) REFERENCES ponto_turistico (id_ponto);

-- Quantidade de pessoas: contagem em participacao_viagem.
-- Valor em BRL: valor * taxa_conversao_brl. Para despesa em BRL, use taxa 1.
-- Duração: diferença entre data_hora_fim e data_hora_inicio.
-- A aplicação deve validar datas de atividades contra o período da viagem
-- e a taxa 1 contra o código da moeda. CHECK valida apenas a própria linha.
-- Considere um ponto sem recurso quando o cadastro estiver completo
-- e não houver vínculo em ponto_recurso_acessibilidade.
