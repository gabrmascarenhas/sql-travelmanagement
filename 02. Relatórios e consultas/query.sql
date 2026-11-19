-- AMBIENTE DE DADOS – 25.2 | Professora Isaura Cardoso
-- Cenário 2: Sistema de Viagens | MySQL 8.0.16+
-- Execute após creation.sql e population.sql.
-- Consultas somente de leitura: não alteram os registros.
USE sistema_viagens;

-- 1. Agenda detalhada da viagem
-- Pergunta: quais são a data, hora, duração e atividade de cada viagem?
-- Ordenação usa DATETIME original, não a data formatada em texto.
-- LEFT JOIN preserva viagens que ainda não possuem atividades cadastradas.
SELECT
    v.id_viagem,
    v.nome_ferias AS viagem,
    DATE_FORMAT(a.data_hora_inicio, '%d/%m/%Y') AS data,
    DATE_FORMAT(a.data_hora_inicio, '%H:%i') AS hora_inicio,
    DATE_FORMAT(a.data_hora_fim, '%d/%m/%Y %H:%i') AS termino,
    TIMESTAMPDIFF(MINUTE, a.data_hora_inicio, a.data_hora_fim) AS duracao_minutos,
    CONCAT(
        FLOOR(TIMESTAMPDIFF(MINUTE, a.data_hora_inicio, a.data_hora_fim) / 60),
        'h ',
        MOD(TIMESTAMPDIFF(MINUTE, a.data_hora_inicio, a.data_hora_fim), 60),
        'min'
    ) AS duracao,
    a.descricao AS atividade,
    pt.nome AS ponto_turistico
FROM viagem AS v
LEFT JOIN atividade AS a ON a.id_viagem = v.id_viagem
LEFT JOIN ponto_turistico AS pt ON pt.id_ponto = a.id_ponto
ORDER BY a.data_hora_inicio IS NULL, a.data_hora_inicio, v.id_viagem, a.id_atividade;

-- 2. Pontos turísticos sem acessibilidade
-- Pergunta: quais locais não possuem recursos de acessibilidade cadastrados?
-- O modelo não possui um campo booleano de acessibilidade. Considera-se
-- sem acessibilidade cadastrada a ausência de vínculos na tabela de recursos.
-- Isso identifica a situação do cadastro, não uma inspeção física do local.
SELECT
    c.nome AS cidade,
    c.pais,
    pt.nome AS ponto_turistico,
    tp.descricao AS tipo,
    pt.horario,
    pt.preco,
    CASE
        WHEN pt.idade_minima = 0 THEN 'Livre'
        ELSE CONCAT(pt.idade_minima, ' anos ou mais')
    END AS faixa_etaria
FROM ponto_turistico AS pt
JOIN cidade AS c ON c.id_cidade = pt.id_cidade
JOIN tipo_ponto_turistico AS tp ON tp.id_tipo_ponto = pt.id_tipo_ponto
WHERE NOT EXISTS (
    SELECT 1
    FROM ponto_recurso_acessibilidade AS pra
    WHERE pra.id_ponto = pt.id_ponto
)
ORDER BY c.nome, pt.nome, pt.id_ponto;

-- 3. Análise de gastos por tipo e custo por pessoa
-- Pergunta: quanto cada viagem gasta por categoria e por participante?
-- Os valores nominais são separados por moeda para não misturar BRL, USD etc.
-- A quantidade de pessoas é agregada antes do JOIN, evitando multiplicar gastos.
-- NULL no custo por pessoa significa que a viagem não possui participantes.
WITH participantes AS (
    SELECT id_viagem, COUNT(*) AS quantidade
    FROM participacao_viagem
    GROUP BY id_viagem
), gastos AS (
    SELECT id_viagem, id_tipo_despesa, id_moeda, SUM(valor) AS total
    FROM despesa
    GROUP BY id_viagem, id_tipo_despesa, id_moeda
)
SELECT
    v.id_viagem,
    v.nome_ferias AS viagem,
    COALESCE(td.descricao, 'Sem despesas') AS tipo_despesa,
    m.codigo AS moeda,
    COALESCE(p.quantidade, 0) AS quantidade_pessoas,
    COALESCE(g.total, 0) AS total_categoria,
    ROUND(COALESCE(g.total, 0) / NULLIF(p.quantidade, 0), 2) AS custo_por_pessoa
FROM viagem AS v
LEFT JOIN participantes AS p ON p.id_viagem = v.id_viagem
LEFT JOIN gastos AS g ON g.id_viagem = v.id_viagem
LEFT JOIN tipo_despesa AS td ON td.id_tipo_despesa = g.id_tipo_despesa
LEFT JOIN moeda AS m ON m.id_moeda = g.id_moeda
ORDER BY v.id_viagem, td.descricao, m.codigo;

-- 4. Resumo de viagens: custo total e pessoas
-- Pergunta: quais viagens são mais caras e quantas pessoas participam delas?
-- Total em BRL para permitir comparar viagens com despesas em moedas distintas.
-- Viagens sem despesas ou sem participantes continuam no relatório.
WITH participantes AS (
    SELECT id_viagem, COUNT(*) AS quantidade
    FROM participacao_viagem
    GROUP BY id_viagem
), totais AS (
    SELECT id_viagem, SUM(valor * taxa_conversao_brl) AS total_brl
    FROM despesa
    GROUP BY id_viagem
)
SELECT
    v.id_viagem,
    v.nome_ferias AS viagem,
    DATE_FORMAT(v.data_inicial, '%d/%m/%Y') AS data_inicial,
    DATE_FORMAT(v.data_final, '%d/%m/%Y') AS data_final,
    COALESCE(p.quantidade, 0) AS quantidade_pessoas,
    ROUND(COALESCE(t.total_brl, 0), 2) AS custo_total_brl
FROM viagem AS v
LEFT JOIN participantes AS p ON p.id_viagem = v.id_viagem
LEFT JOIN totais AS t ON t.id_viagem = v.id_viagem
ORDER BY COALESCE(t.total_brl, 0) DESC, v.id_viagem;

-- 5. Top 3 maiores despesas por viagem (avançado)
-- Pergunta: quais são as três despesas individuais mais caras de cada viagem?
-- Subconsulta com ROW_NUMBER particiona o ranking por viagem.
-- Comparação em BRL; id_despesa desempata e garante no máximo três linhas.
-- Viagens com menos de três despesas exibem apenas as despesas existentes.
SELECT
    ranking.id_viagem,
    ranking.viagem,
    ranking.posicao,
    ranking.id_despesa,
    ranking.tipo_despesa,
    DATE_FORMAT(ranking.data_compra, '%d/%m/%Y') AS data_compra,
    ranking.valor_original,
    ranking.moeda,
    ROUND(ranking.valor_brl, 2) AS valor_brl
FROM (
    SELECT
        v.id_viagem,
        v.nome_ferias AS viagem,
        d.id_despesa,
        td.descricao AS tipo_despesa,
        d.data_compra,
        d.valor AS valor_original,
        m.codigo AS moeda,
        d.valor * d.taxa_conversao_brl AS valor_brl,
        ROW_NUMBER() OVER (
            PARTITION BY d.id_viagem
            ORDER BY d.valor * d.taxa_conversao_brl DESC, d.id_despesa
        ) AS posicao
    FROM despesa AS d
    JOIN viagem AS v ON v.id_viagem = d.id_viagem
    JOIN tipo_despesa AS td ON td.id_tipo_despesa = d.id_tipo_despesa
    JOIN moeda AS m ON m.id_moeda = d.id_moeda
) AS ranking
WHERE ranking.posicao <= 3
ORDER BY ranking.id_viagem, ranking.posicao;

-- 6. Custo total e custo por pessoa em BRL (avançado)
-- Pergunta: qual é o custo real de cada viagem e o rateio em reais?
-- Cada despesa é convertida pela sua própria taxa ANTES da agregação.
-- Taxa representa quantos BRL correspondem a uma unidade da moeda original.
-- Para BRL, a carga utiliza taxa 1. Arredondamento só na apresentação final.
WITH despesas_convertidas AS (
    SELECT id_viagem, valor * taxa_conversao_brl AS valor_brl
    FROM despesa
), totais AS (
    SELECT id_viagem, SUM(valor_brl) AS total_brl
    FROM despesas_convertidas
    GROUP BY id_viagem
), participantes AS (
    SELECT id_viagem, COUNT(*) AS quantidade
    FROM participacao_viagem
    GROUP BY id_viagem
)
SELECT
    v.id_viagem,
    v.nome_ferias AS viagem,
    COALESCE(p.quantidade, 0) AS quantidade_pessoas,
    ROUND(COALESCE(t.total_brl, 0), 2) AS custo_total_brl,
    ROUND(COALESCE(t.total_brl, 0) / NULLIF(p.quantidade, 0), 2) AS custo_por_pessoa_brl
FROM viagem AS v
LEFT JOIN totais AS t ON t.id_viagem = v.id_viagem
LEFT JOIN participantes AS p ON p.id_viagem = v.id_viagem
ORDER BY COALESCE(t.total_brl, 0) DESC, v.id_viagem;
