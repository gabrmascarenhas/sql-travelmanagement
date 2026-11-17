# Sistema de Viagens

Banco relacional em MySQL para o cenário 2 de Ambiente de Dados. O modelo registra viagens, participantes, atividades, pontos turísticos, acessibilidade e despesas em várias moedas.

## Arquivos

| Arquivo | Função |
|---|---|
| `creation.sql` | Cria o esquema `sistema_viagens`, 16 tabelas e 15 chaves estrangeiras. |
| `demonstration.sql` | Confere as contagens e mostra exemplos de viagens, agenda e conversão para BRL. Também lista a estrutura do banco. |
| `population.sql` | Insere 3409 registros fictícios, em ordem de dependência, dentro de uma transação. |

## Como executar

Com o servidor MySQL 8.0.16 ou superior ligado, abra um terminal na pasta dos arquivos. Substitua `root` pelo usuário do seu MySQL, se necessário. Execute cada comando na ordem e avance somente se o anterior terminar sem erro.

```bash
mysql -u root -p --default-character-set=utf8mb4 < creation.sql
mysql -u root -p --default-character-set=utf8mb4 < population.sql
mysql -u root -p --table < demonstration.sql
```

Para editar no Neovide, rode `neovide population.sql` na mesma pasta. A carga espera tabelas vazias. Como os IDs são fixos, uma segunda execução na mesma base encontra chaves duplicadas. Os scripts preservam os dados que já existem.

A demonstração deve mostrar **OK nas 16 tabelas** e totalizar **3.409 registros**. Uma linha com **DIVERGENTE** indica que a contagem real difere da esperada.

## Quantidades da carga

| Categoria | Tabela | Registros |
|---|---|---:|
| CRUDs de apoio | `necessidade_especial` | 9 |
| CRUDs de apoio | `recurso_acessibilidade` | 9 |
| CRUDs de apoio | `tipo_ponto_turistico` | 9 |
| CRUDs de apoio | `tipo_despesa` | 9 |
| CRUDs de apoio | `moeda` | 9 |
| Tabelas principais | `cidade` | 45 |
| Tabelas principais | `ponto_turistico` | 45 |
| Tabelas principais | `viagem` | 45 |
| Tabelas principais | `pessoa` | 45 |
| Movimentação | `participacao_viagem` | 1000 |
| Movimentação | `despesa` | 1000 |
| Movimentação | `atividade` | 1000 |
| Auxiliares | `telefone_pessoa` | 45 |
| Auxiliares | `email_pessoa` | 45 |
| Auxiliares | `pessoa_necessidade` | 22 |
| Auxiliares | `ponto_recurso_acessibilidade` | 72 |

**Total de 3409 registros.** Cada cadastro de apoio recebeu 9 linhas, cada tabela principal recebeu 45 e cada tabela de movimentação recebeu 1.000. As auxiliares receberam volumes próprios, de acordo com seus vínculos.

## Como os dados se relacionam

- `participacao_viagem` liga pessoas a viagens e permite contar os participantes.
- `atividade` guarda o início e o fim da agenda. Algumas atividades têm ponto turístico e outras representam deslocamentos.
- `despesa` liga cada gasto a uma viagem, a um tipo de despesa e a uma moeda. Para obter o valor em reais, multiplique o valor pela taxa da própria despesa.
- `ponto_turistico` referencia a cidade e o tipo de local. Os recursos disponíveis ficam em `ponto_recurso_acessibilidade`.
- Telefones, e-mails e necessidades são registrados separadamente e vinculados à pessoa.

A carga inclui viagens nacionais e internacionais, pontos com e sem recursos de acessibilidade e despesas de categorias variadas para testar os seis relatórios da atividade. As taxas de câmbio são fictícias. Telefones, endereços, comprovantes e links de serviço também são exemplos de teste.

Os totais por viagem, os custos por pessoa e a duração das atividades podem ser calculados nas consultas. Para evitar somar despesas repetidas, agregue os gastos e conte os participantes separadamente antes de juntar os resultados.
