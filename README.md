# Diesel Radar Pipeline

Pipeline de dados que acompanha o preço do Diesel S10 por estado, semana a semana, com base na série histórica de preços da ANP — construído para apoiar decisão de onde abastecer e quando renegociar frete.

> Em construção. Este README vai ganhar detalhes (arquitetura, como rodar, prints do dashboard) conforme o projeto avança.

## Por que esse projeto existe

Uma carreta abastece até 1.200 litros de diesel — um único abastecimento pode ultrapassar R$ 8 mil. Nesse volume, uma diferença de R$ 0,30 por litro entre estados já representa R$ 360 a mais ou a menos **num único abastecimento**, e isso se multiplica pela frota inteira ao longo do mês. Esse pipeline existe para transformar a variação semanal do preço do diesel em uma decisão concreta: onde abastecer, e quando é hora de renegociar o frete.

## Visão do projeto

O Diesel Radar é pensado em fases. A base é engenharia de dados — sem dado confiável, nada depois disso se sustenta. As fases seguintes são a evolução planejada, construídas em cima dessa base à medida que ela amadurece.

### Fase 1 — Engenharia de Dados (em andamento)

Ingestão dos dados públicos da ANP com Python, armazenamento do dado bruto e tratamento em camadas: **Bronze → Silver → Gold**, com dbt para transformação e Snowflake para armazenamento e consumo analítico. A orquestração fica com o Airflow, para que o processo inteiro rode de forma automatizada.

```
ANP → Python → Bronze → Silver → Gold → Snowflake
```

### Fase 2 — Machine Learning

Com dado histórico já tratado e confiável na Gold, o próximo passo é usar esse histórico para construir um baseline, desenvolver features e treinar modelos capazes de identificar tendências e estimar o preço futuro do diesel. Experimentos e versões de modelo registrados com MLflow.

```
Gold → Features → Baseline → Treinamento → Avaliação → Previsão
```

### Fase 3 — Da previsão à decisão

Prever um número sozinho não é o objetivo. A ideia é cruzar a previsão com informação de negócio — consumo do veículo, capacidade de abastecimento, localização, rota — e transformar isso em recomendação acionável, por exemplo:

> "Existe tendência de aumento do diesel nas próximas semanas. Antecipar o abastecimento pode representar uma economia estimada de X reais para a frota."

É nesse ponto que o Machine Learning passa a apoiar uma decisão de negócio de verdade, não só um número num gráfico.

### Fase 4 — Camada de IA (evolução futura)

Uma camada de IA generativa para facilitar o acesso a essas informações, respondendo perguntas como:

> "Onde vale mais a pena abastecer essa semana?"
> "Qual estado apresentou maior aumento no preço do diesel?"

usando os dados e previsões produzidos pelo próprio pipeline como fonte.

### A arquitetura completa, de ponta a ponta

```
ANP
 ↓
Python / Ingestão
 ↓
Snowflake + dbt
 ↓
Bronze → Silver → Gold
 ↓
Machine Learning
 ↓
Previsão
 ↓
Recomendação
 ↓
Dashboard / IA
```

No final, o Diesel Radar deixa de ser só um pipeline de dados: a engenharia de dados garante qualidade e confiabilidade, o machine learning gera capacidade preditiva, e o resultado vira informação capaz de apoiar uma decisão real de uma operação de transportes.

## Status (Fase 1)

- [x] Estrutura do projeto
- [x] Ingestão dos dados da ANP (bronze)
- [ ] Modelagem dbt (bronze / silver / gold)
- [ ] Orquestração com Airflow
- [ ] CI/CD com GitHub Actions
- [ ] Dashboard final

As fases 2, 3 e 4 são a visão de evolução do projeto — entram em construção depois que a Fase 1 estiver sólida e no ar.
