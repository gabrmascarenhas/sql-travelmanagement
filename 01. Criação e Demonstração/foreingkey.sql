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
