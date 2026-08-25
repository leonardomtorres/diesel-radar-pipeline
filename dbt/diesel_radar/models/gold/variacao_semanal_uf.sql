{{ config(materialized='table', schema='GOLD') }}

with com_semana_anterior as (

    select
        semana_referencia,
        uf,
        preco_medio,
        lag(preco_medio) over (
            partition by uf
            order by semana_referencia
        ) as preco_semana_anterior
    from {{ ref('precos_medios_uf_semana') }}

)

select
    semana_referencia,
    uf,
    preco_medio,
    preco_semana_anterior,
    round(
        100.0 * (preco_medio - preco_semana_anterior) / preco_semana_anterior,
        2
    ) as variacao_percentual
from com_semana_anterior
