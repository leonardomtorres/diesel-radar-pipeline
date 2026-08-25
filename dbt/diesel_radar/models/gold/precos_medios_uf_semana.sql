{{ config(materialized='table', schema='GOLD') }}

select
    semana_referencia,
    uf,
    avg(preco_venda) as preco_medio,
    min(preco_venda) as preco_min,
    max(preco_venda) as preco_max,
    count(*) as qtd_postos_pesquisados
from {{ ref('precos_combustiveis') }}
where produto = 'DIESEL_S10'
group by semana_referencia, uf
