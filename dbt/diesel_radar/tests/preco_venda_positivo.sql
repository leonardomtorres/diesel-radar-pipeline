select *
from {{ ref('precos_combustiveis') }}
where preco_venda <= 0
