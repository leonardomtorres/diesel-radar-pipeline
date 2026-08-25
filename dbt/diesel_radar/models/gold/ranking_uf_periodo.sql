{{ config(materialized='table', schema='GOLD') }}

select
    semana_referencia,
    uf,
    preco_medio,
    rank() over (
        partition by semana_referencia
        order by preco_medio asc
    ) as posicao_ranking
from {{ ref('precos_medios_uf_semana') }}
order by semana_referencia, posicao_ranking
