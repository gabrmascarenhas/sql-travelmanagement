  -- Execute depois de creation.sql e population.sql.
  USE sistema_viagens;

  -- 1. Cada tabela deve aparecer com status OK.
  SELECT tabela, esperado, encontrado,
        CASE WHEN encontrado = esperado THEN 'OK' ELSE 'DIVERGENTE' END AS status
  FROM (
      SELECT 'necessidade_especial' AS tabela, 9 AS esperado, COUNT(*) AS encontrado FROM necessidade_especial
      UNION ALL
      SELECT 'recurso_acessibilidade' AS tabela, 9 AS esperado, COUNT(*) AS encontrado FROM recurso_acessibilidade
      UNION ALL
      SELECT 'tipo_ponto_turistico' AS tabela, 9 AS esperado, COUNT(*) AS encontrado FROM tipo_ponto_turistico
      UNION ALL
      SELECT 'tipo_despesa' AS tabela, 9 AS esperado, COUNT(*) AS encontrado FROM tipo_despesa
      UNION ALL
      SELECT 'moeda' AS tabela, 9 AS esperado, COUNT(*) AS encontrado FROM moeda
      UNION ALL
      SELECT 'cidade' AS tabela, 45 AS esperado, COUNT(*) AS encontrado FROM cidade
      UNION ALL
      SELECT 'ponto_turistico' AS tabela, 45 AS esperado, COUNT(*) AS encontrado FROM ponto_turistico
      UNION ALL
      SELECT 'viagem' AS tabela, 45 AS esperado, COUNT(*) AS encontrado FROM viagem
      UNION ALL
      SELECT 'pessoa' AS tabela, 45 AS esperado, COUNT(*) AS encontrado FROM pessoa
      UNION ALL
      SELECT 'participacao_viagem' AS tabela, 1000 AS esperado, COUNT(*) AS encontrado FROM participacao_viagem
      UNION ALL
      SELECT 'despesa' AS tabela, 1000 AS esperado, COUNT(*) AS encontrado FROM despesa
      UNION ALL
      SELECT 'atividade' AS tabela, 1000 AS esperado, COUNT(*) AS encontrado FROM atividade
      UNION ALL
      SELECT 'telefone_pessoa' AS tabela, 45 AS esperado, COUNT(*) AS encontrado FROM telefone_pessoa
      UNION ALL
      SELECT 'email_pessoa' AS tabela, 45 AS esperado, COUNT(*) AS encontrado FROM email_pessoa
      UNION ALL
      SELECT 'pessoa_necessidade' AS tabela, 22 AS esperado, COUNT(*) AS encontrado FROM pessoa_necessidade
      UNION ALL
      SELECT 'ponto_recurso_acessibilidade' AS tabela, 72 AS esperado, COUNT(*) AS encontrado FROM ponto_recurso_acessibilidade
  ) AS contagem
  ORDER BY tabela;

  -- 2. Cinco viagens com participantes e despesas, sem multiplicar linhas.
  SELECT v.nome_ferias, p.participantes, d.despesas, d.total_brl
  FROM viagem AS v
  JOIN (
      SELECT id_viagem, COUNT(*) AS participantes
      FROM participacao_viagem GROUP BY id_viagem
  ) AS p ON p.id_viagem = v.id_viagem
  JOIN (
      SELECT id_viagem, COUNT(*) AS despesas,
            ROUND(SUM(valor * taxa_conversao_brl), 2) AS total_brl
      FROM despesa GROUP BY id_viagem
  ) AS d ON d.id_viagem = v.id_viagem
  ORDER BY v.id_viagem
  LIMIT 5;

  -- 3. Agenda da primeira viagem, incluindo atividades sem ponto turístico.
  SELECT v.nome_ferias, a.descricao, a.data_hora_inicio, a.data_hora_fim,
        COALESCE(p.nome, 'Sem ponto turístico') AS ponto
  FROM atividade AS a
  JOIN viagem AS v ON v.id_viagem = a.id_viagem
  LEFT JOIN ponto_turistico AS p ON p.id_ponto = a.id_ponto
  WHERE v.id_viagem = 1
  ORDER BY a.data_hora_inicio, a.id_atividade
  LIMIT 5;

  -- 4. Exemplos de conversão de despesas em moeda estrangeira.
  SELECT d.descricao, m.codigo AS moeda, d.valor,
        d.taxa_conversao_brl, ROUND(d.valor * d.taxa_conversao_brl, 2) AS valor_brl
  FROM despesa AS d
  JOIN moeda AS m ON m.id_moeda = d.id_moeda
  WHERE m.codigo <> 'BRL'
  ORDER BY d.id_despesa
  LIMIT 5;

  -- 5. Estrutura do banco.
  SELECT DATABASE() AS banco_atual;
  SHOW TABLES;

  -- Colunas, tipos, nulabilidade, valores padrão e AUTO_INCREMENT.
  SELECT TABLE_NAME AS tabela, COLUMN_NAME AS coluna, COLUMN_TYPE AS tipo,
        IS_NULLABLE AS aceita_nulo, COLUMN_DEFAULT AS valor_padrao, EXTRA
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
  ORDER BY TABLE_NAME, ORDINAL_POSITION;

  -- Chaves primárias, únicas e estrangeiras, incluindo chaves compostas.
  SELECT tc.TABLE_NAME AS tabela, tc.CONSTRAINT_TYPE AS tipo,
        tc.CONSTRAINT_NAME AS restricao, k.ORDINAL_POSITION AS posicao,
        k.COLUMN_NAME AS coluna, k.REFERENCED_TABLE_NAME AS tabela_referenciada,
        k.REFERENCED_COLUMN_NAME AS coluna_referenciada
  FROM information_schema.TABLE_CONSTRAINTS AS tc
  JOIN information_schema.KEY_COLUMN_USAGE AS k
    ON k.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
  AND k.TABLE_SCHEMA = tc.TABLE_SCHEMA
  AND k.TABLE_NAME = tc.TABLE_NAME
  AND k.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
  WHERE tc.TABLE_SCHEMA = DATABASE()
  ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_TYPE, tc.CONSTRAINT_NAME, k.ORDINAL_POSITION;

  -- Regras CHECK, como validação de datas, preços e taxas.
  SELECT tc.TABLE_NAME AS tabela, tc.CONSTRAINT_NAME AS restricao,
        cc.CHECK_CLAUSE AS regra
  FROM information_schema.TABLE_CONSTRAINTS AS tc
  JOIN information_schema.CHECK_CONSTRAINTS AS cc
    ON cc.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
  AND cc.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
  WHERE tc.TABLE_SCHEMA = DATABASE()
    AND tc.CONSTRAINT_TYPE = 'CHECK'
  ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_NAME;
