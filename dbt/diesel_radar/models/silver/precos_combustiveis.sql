{{ config(materialized='table') }}

with fonte as (

    select
        "estado" as uf,
        "municipio" as municipio,
        "fantasia" as fantasia,
        "produto" as produto_origem,
        "data_da_coleta" as data_coleta,
        "preco_de_revenda" as preco_venda,
        "bandeira" as bandeira
    from {{ source('bronze', 'precos_combustiveis_raw') }}

),

normalizado as (

    select
        case upper(trim(uf))
            when 'ACRE' then 'AC'
            when 'ALAGOAS' then 'AL'
            when 'AMAPA' then 'AP'
            when 'AMAZONAS' then 'AM'
            when 'BAHIA' then 'BA'
            when 'CEARA' then 'CE'
            when 'DISTRITO FEDERAL' then 'DF'
            when 'ESPIRITO SANTO' then 'ES'
            when 'GOIAS' then 'GO'
            when 'MARANHAO' then 'MA'
            when 'MATO GROSSO' then 'MT'
            when 'MATO GROSSO DO SUL' then 'MS'
            when 'MINAS GERAIS' then 'MG'
            when 'PARA' then 'PA'
            when 'PARAIBA' then 'PB'
            when 'PARANA' then 'PR'
            when 'PERNAMBUCO' then 'PE'
            when 'PIAUI' then 'PI'
            when 'RIO DE JANEIRO' then 'RJ'
            when 'RIO GRANDE DO NORTE' then 'RN'
            when 'RIO GRANDE DO SUL' then 'RS'
            when 'RONDONIA' then 'RO'
            when 'RORAIMA' then 'RR'
            when 'SANTA CATARINA' then 'SC'
            when 'SAO PAULO' then 'SP'
            when 'SERGIPE' then 'SE'
            when 'TOCANTINS' then 'TO'
            else upper(trim(uf))
        end as uf,
        upper(trim(municipio)) as municipio,
        upper(trim(fantasia)) as fantasia,
        case
            when upper(trim(produto_origem)) in ('DIESEL S10', 'DIESEL S-10') then 'DIESEL_S10'
            when upper(trim(produto_origem)) in ('DIESEL S500', 'DIESEL S-500', 'DIESEL') then 'DIESEL_S500'
            when upper(trim(produto_origem)) like 'GASOLINA%' then 'GASOLINA'
            when upper(trim(produto_origem)) = 'ETANOL' then 'ETANOL'
            when upper(trim(produto_origem)) = 'GLP' then 'GLP'
            when upper(trim(produto_origem)) = 'GNV' then 'GNV'
            else upper(trim(produto_origem))
        end as produto,
        cast(data_coleta as date) as data_coleta,
        preco_venda,
        upper(trim(bandeira)) as bandeira
    from fonte
    where preco_venda > 0

)

select
    *,
    dateadd(day, 1 - dayofweekiso(data_coleta), data_coleta) as semana_referencia
from normalizado
