# Modelo de dados

## Dor de negócio

Uma carreta abastece até 1.200 litros de diesel por vez, e cada abastecimento pode passar de R$ 5-6 mil. Nesse volume, cada centavo de diferença no preço do litro representa dinheiro real: uma diferença de R$ 0,30/litro entre estados já significa R$ 360 a mais ou a menos num único abastecimento.

Este pipeline transforma a variação semanal do preço do Diesel S10 por estado em decisão de onde/quando abastecer, e em base de argumento para reajuste de frete.

## Fonte de dados

**Série Histórica de Preços de Combustíveis e de GLP — ANP**, pesquisa semanal (dado novo às sextas-feiras), distribuída em CSV para download direto (sem API REST oficial para este dataset). Granularidade original: 1 linha = 1 posto pesquisado numa semana.

Colunas do CSV de origem: `Região, Estado, Município, Revenda, CNPJ da Revenda, Endereço, Bairro, CEP, Produto, Data da Coleta, Valor de Venda, Valor de Compra, Unidade de Medida, Bandeira`.

Produto em foco: **Diesel S10** (o mais usado atualmente em frotas de carga).

## Bronze — `bronze.precos_combustiveis_raw`

Cópia crua do CSV, sem tratar nada, renomeada para `snake_case`.

| Coluna | Origem |
|---|---|
| regiao, estado, municipio | CSV original |
| revenda, cnpj_revenda | CSV original |
| endereco, bairro, cep | CSV original |
| produto | CSV original |
| data_coleta | CSV original |
| valor_venda, valor_compra, unidade_medida | CSV original |
| bandeira | CSV original |
| _source_file | Adicionada pelo pipeline — nome do arquivo de origem |
| _loaded_at | Adicionada pelo pipeline — timestamp da carga |

## Silver — `silver.precos_combustiveis`

Mesma granularidade (1 linha = 1 posto + 1 produto + 1 data de coleta), mas limpa:

| Coluna | Transformação |
|---|---|
| uf | Padronizado para sigla de 2 letras |
| municipio, revenda | Normalizados (espaços, maiúsculas) |
| produto | Normalizado para conjunto fixo (DIESEL_S10, etc) |
| data_coleta | Tipo DATE |
| semana_referencia | Calculada: segunda-feira da semana da data_coleta |
| valor_venda | Convertido para número; linhas com preço <= 0 ou nulo são removidas |
| bandeira | Mantido |

Colunas descartadas em relação ao bronze: endereço, CEP, complemento (não servem à pergunta de negócio, que é regional).

Testes de qualidade aplicados aqui via dbt: `valor_venda` não pode ser negativo/nulo, `uf` precisa estar entre as 27 UFs válidas, `produto` precisa estar no conjunto normalizado.

## Gold — filtrado para Diesel S10

1. **`gold.precos_medios_uf_semana`** — `uf, semana_referencia, preco_medio, preco_min, preco_max, qtd_postos_pesquisados`
2. **`gold.variacao_semanal_uf`** — `uf, semana_referencia, preco_medio, preco_semana_anterior, variacao_percentual`
3. **`gold.ranking_uf_periodo`** — `semana_referencia, uf, preco_medio, posicao_ranking`
4. **`gold.economia_potencial_abastecimento`** (KPI âncora) — `semana_referencia, uf_mais_barata, preco_mais_barato, uf_mais_cara, preco_mais_caro, diferenca_por_litro, economia_estimada_1200_litros`
