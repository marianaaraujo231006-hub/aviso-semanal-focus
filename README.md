# Aviso Semanal Focus: Documentação da base (Etapa 2)

## Fonte
Sistema Expectativas de Mercado do Banco Central do Brasil, consultado
pelo pacote `rbcb` (função `get_market_expectations()`).

## Colunas principais
- `Data`: data do cálculo da estatística (divulgação semanal do Focus)
- `Mediana`: mediana das expectativas das instituições credenciadas
- `numeroRespondentes`: número de instituições que forneceram expectativas
- `baseCalculo`: base de cálculo das estatísticas (ver abaixo)

## Particularidades por indicador
- **IPCA (type = "annual")**: a chave de comparação é `DataReferencia`
  (ano para o qual a expectativa é esperada). `IndicadorDetalhe` é NA.
- **Selic (type = "selic")**: não há `DataReferencia`; a chave é `Reuniao`
  (reunião do Copom para a qual a estatística é esperada, ex.: "R6/2026").

## baseCalculo
Segundo a documentação da API (Olinda):
- 0: expectativas mais recentes de cada instituição a partir do 30º dia
  anterior à data de cálculo.
- 1: expectativas mais recentes de cada instituição a partir do 4º dia
  útil anterior à data de cálculo.

**Decisão do grupo:** usar `baseCalculo == 0` em todas as comparações,
para não misturar critérios.

## Regra de comparação
Comparar apenas duas divulgações consecutivas do mesmo indicador e do
mesmo período de referência (ano no IPCA; reunião na Selic).