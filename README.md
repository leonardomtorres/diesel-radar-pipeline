# Diesel Radar Pipeline

Pipeline de dados que acompanha o preço do Diesel S10 por estado, semana a semana, com base na série histórica de preços da ANP — construído para apoiar decisão de onde abastecer e quando renegociar frete.

> Em construção. Este README vai ganhar detalhes (arquitetura, como rodar, prints do dashboard) conforme o projeto avança.

## Por que esse projeto existe

Uma carreta abastece até 1.200 litros de diesel — um único abastecimento pode ultrapassar R$ 8 mil. Nesse volume, uma diferença de R$ 0,30 por litro entre estados já representa R$ 360 a mais ou a menos **num único abastecimento**, e isso se multiplica pela frota inteira ao longo do mês. Esse pipeline existe para transformar a variação semanal do preço do diesel em uma decisão concreta: onde abastecer, e quando é hora de renegociar o frete.

## Status

- [x] Estrutura do projeto
- [x] Ingestão dos dados da ANP (bronze)
- [ ] Modelagem dbt (bronze / silver / gold)
- [ ] Orquestração com Airflow
- [ ] CI/CD com GitHub Actions
- [ ] Dashboard final
