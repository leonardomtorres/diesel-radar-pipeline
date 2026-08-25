{{ config(materialized='table', schema='GOLD') }}

with mais_barata as (

    select
        semana_referencia,
        uf as uf_mais_barata,
        preco_medio as preco_mais_barato
    from {{ ref('ranking_uf_periodo') }}
    where posicao_ranking = 1

),

mais_cara as (

    select
        semana_referencia,
        uf as uf_mais_cara,
        preco_medio as preco_mais_caro
    from {{ ref('ranking_uf_periodo') }}
    qualify row_number() over (
        partition by semana_referencia
        order by preco_medio desc
    ) = 1

)

select
    b.semana_referencia,
    b.uf_mais_barata,
    b.preco_mais_barato,
    c.uf_mais_cara,
    c.preco_mais_caro,
    round(c.preco_mais_caro - b.preco_mais_barato, 4) as diferenca_por_litro,
    round((c.preco_mais_caro - b.preco_mais_barato) * 1200, 2) as economia_estimada_1200_litros
from mais_barata b
join mais_cara c on b.semana_referencia = c.semana_referencia
