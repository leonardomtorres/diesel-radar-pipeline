# Modelo de dados

## Dor de negócio

Uma carreta abastece até 1.200 litros de diesel por vez, e cada abastecimento pode passar de R$ 5-6 mil. Nesse volume, cada centavo de diferença no preço do litro representa dinheiro real: uma diferença de R$ 0,30/litro entre estados já significa R$ 360 a mais ou a menos num único abastecimento.

Este pipeline transforma a variação semanal do preço do Diesel S10 por estado em decisão de onde/quando abastecer, e em base de argumento para reajuste de frete.

## Fonte de dados

**"Levantamento de Preços de Combustíveis (últimas semanas pesquisadas)" — ANP**, pesquisa semanal (arquivo novo publicado toda semana), distribuída em **Excel (.xlsx)** para download direto — sem API REST oficial para este dataset, e o nome do arquivo muda a cada semana (tem o intervalo de datas no nome). Granularidade: 1 linha = 1 posto pesquisado numa semana. Não existe carga histórica automatizada — o pipeline acumula histórico a partir do momento em que passa a rodar; um backfill via a Série Histórica por semestre da ANP foi considerado e descartado por ora (ver decisão no histórico do projeto).

O arquivo real tem 9 linhas de título/metadado do relatório antes da tabela de dados começar. Colunas de origem (a partir da linha 10): `CNPJ, RAZÃO, FANTASIA, ENDEREÇO, NÚMERO, COMPLEMENTO, BAIRRO, CEP, MUNICÍPIO, ESTADO, BANDEIRA, PRODUTO, UNIDADE DE MEDIDA, PREÇO DE REVENDA, DATA DA COLETA` — não existe uma coluna de "valor de compra" (é um relatório só de revenda, não de distribuição).

Produto em foco: **Diesel S10** (o mais usado atualmente em frotas de carga).

## Bronze — `bronze.precos_combustiveis_raw`

Cópia crua do arquivo, sem tratar nada de negócio — só renomeada para `snake_case` e com tipos de coluna consistentes (necessário pra carga funcionar; não é limpeza de negócio, ver conversa do projeto sobre essa distinção).

| Coluna | Origem |
|---|---|
| cnpj, razao, fantasia | Arquivo original (identificação do posto) |
| endereco, numero, complemento, bairro, cep | Arquivo original |
| municipio, estado | Arquivo original |
| bandeira | Arquivo original |
| produto, unidade_de_medida | Arquivo original |
| preco_de_revenda | Arquivo original |
| data_da_coleta | Arquivo original |
| _source_file | Adicionada pelo pipeline — nome do arquivo de origem |
| _loaded_at | Adicionada pelo pipeline — timestamp da carga (UTC) |

## Silver — `silver.precos_combustiveis`

Mesma granularidade (1 linha = 1 posto + 1 produto + 1 data de coleta), mas limpa:

| Coluna | Transformação |
|---|---|
| uf | Vem de `estado`, padronizado para sigla de 2 letras |
| municipio, fantasia | Normalizados (espaços, maiúsculas) |
| produto | Normalizado para conjunto fixo (DIESEL_S10, etc) |
| data_coleta | Vem de `data_da_coleta`, tipo DATE |
| semana_referencia | Calculada: segunda-feira da semana de `data_coleta` |
| preco_venda | Vem de `preco_de_revenda`, convertido para número; linhas com preço <= 0 ou nulo são removidas |
| bandeira | Mantido |

Colunas descartadas em relação ao bronze: cnpj, razao, endereço, número, complemento, CEP (não servem à pergunta de negócio, que é regional — só o essencial pro cálculo passa pro silver).

Testes de qualidade aplicados aqui via dbt: `preco_venda` não pode ser negativo/nulo, `uf` precisa estar entre as 27 UFs válidas, `produto` precisa estar no conjunto normalizado.

## Gold — filtrado para Diesel S10

1. **`gold.precos_medios_uf_semana`** — `uf, semana_referencia, preco_medio, preco_min, preco_max, qtd_postos_pesquisados`
2. **`gold.variacao_semanal_uf`** — `uf, semana_referencia, preco_medio, preco_semana_anterior, variacao_percentual`
3. **`gold.ranking_uf_periodo`** — `semana_referencia, uf, preco_medio, posicao_ranking`
4. **`gold.economia_potencial_abastecimento`** (KPI âncora) — `semana_referencia, uf_mais_barata, preco_mais_barato, uf_mais_cara, preco_mais_caro, diferenca_por_litro, economia_estimada_1200_litros`
