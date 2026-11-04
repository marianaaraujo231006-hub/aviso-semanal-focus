
library(dplyr)
library(gt)
library(ggplot2)

ipca_raw <- read.csv("dados/ipca_raw.csv") |>
  mutate(Data = as.Date(Data))

selic_raw <- read.csv("dados/selic_raw.csv") |>
  mutate(Data = as.Date(Data))

ultimas_divulgacoes <- function(dados) {

  datas <- dados |>
    distinct(Data) |>
    filter(!is.na(Data)) |>
    mutate(Semana = format(Data, "%G-%V")) |>
    group_by(Semana) |>
    summarise(
      Data = max(Data),
      .groups = "drop"
    ) |>
    arrange(desc(Data)) |>
    slice_head(n = 2) |>
    pull(Data)

  if (length(datas) < 2) {
    stop("Não existem duas semanas disponíveis para comparação.")
  }

  return(datas)
}

datas_ipca <- ipca_raw |>
  filter(
    DataReferencia == "2026",
    baseCalculo == 0
  ) |>
  ultimas_divulgacoes()

ipca_comparacao <- ipca_raw |>
  filter(
    DataReferencia == "2026",
    baseCalculo == 0,
    Data %in% datas_ipca
  ) |>
  select(Data, DataReferencia, Mediana, numeroRespondentes) |>
  arrange(Data) |>
  mutate(
    Semana = format(Data, "%V/%G"),

    variacao_pp = Mediana - lag(Mediana),

    variacao_respondentes =
      numeroRespondentes - lag(numeroRespondentes),

    classificacao = case_when(
      is.na(variacao_pp) ~ NA_character_,
      variacao_pp > 0.05 ~ "subiu",
      variacao_pp < -0.05 ~ "caiu",
      TRUE ~ "estável"
    )
  )

datas_selic <- selic_raw |>
  filter(
    Reuniao == "R6/2028",
    baseCalculo == 0
  ) |>
  ultimas_divulgacoes()

selic_comparacao <- selic_raw |>
  filter(
    Reuniao == "R6/2028",
    baseCalculo == 0,
    Data %in% datas_selic
  ) |>
  select(Data, Reuniao, Mediana, numeroRespondentes) |>
  arrange(Data) |>
  mutate(
    Semana = format(Data, "%V/%G"),

    variacao_pp = Mediana - lag(Mediana),

    variacao_respondentes =
      numeroRespondentes - lag(numeroRespondentes),

    classificacao = case_when(
      is.na(variacao_pp) ~ NA_character_,
      variacao_pp > 0.05 ~ "subiu",
      variacao_pp < -0.05 ~ "caiu",
      TRUE ~ "estável"
    )
  )

print(ipca_comparacao)
print(selic_comparacao)
# TABELA RESUMO DO IPCA
tabela_ipca <- ipca_comparacao |>
  summarise(
    Indicador = "IPCA",
    Referencia = as.character(first(DataReferencia)),

    Semana_anterior = first(Semana),
    Semana_atual = last(Semana),

    Data_anterior = format(first(Data), "%d/%m/%Y"),
    Data_atual = format(last(Data), "%d/%m/%Y"),

    Mediana_anterior = first(Mediana),
    Mediana_atual = last(Mediana),

    Respondentes_anterior = first(numeroRespondentes),
    Respondentes_atual = last(numeroRespondentes),

    Variacao_pp = last(variacao_pp),
    Variacao_respondentes = last(variacao_respondentes),

    Tendencia = last(classificacao)
  )


# TABELA RESUMO DA SELIC
tabela_selic <- selic_comparacao |>
  summarise(
    Indicador = "Selic",
    Referencia = first(Reuniao),

    Semana_anterior = first(Semana),
    Semana_atual = last(Semana),

    Data_anterior = format(first(Data), "%d/%m/%Y"),
    Data_atual = format(last(Data), "%d/%m/%Y"),

    Mediana_anterior = first(Mediana),
    Mediana_atual = last(Mediana),

    Respondentes_anterior = first(numeroRespondentes),
    Respondentes_atual = last(numeroRespondentes),

    Variacao_pp = last(variacao_pp),
    Variacao_respondentes = last(variacao_respondentes),

    Tendencia = last(classificacao)
  )


# CONSOLIDAÇÃO DAS TABELAS
tabela_comparativa <- bind_rows(
  tabela_ipca,
  tabela_selic
) |>
  gt() |>
  tab_header(
    title = "Boletim Focus — Comparativo semanal",
    subtitle = "Última semana disponível versus semana anterior disponível"
  ) |>
  cols_label(
    Indicador = "Indicador",
    Referencia = "Referência",
    Semana_anterior = "Semana anterior",
    Semana_atual = "Semana atual",
    Data_anterior = "Data anterior",
    Data_atual = "Data atual",
    Mediana_anterior = "Mediana anterior (%)",
    Mediana_atual = "Mediana atual (%)",
    Respondentes_anterior = "Respondentes anteriores",
    Respondentes_atual = "Respondentes atuais",
    Variacao_pp = "Variação (p.p.)",
    Variacao_respondentes = "Variação de respondentes",
    Tendencia = "Tendência"
  ) |>
  fmt_number(
    columns = c(
      Mediana_anterior,
      Mediana_atual,
      Variacao_pp
    ),
    decimals = 4
  ) |>
  fmt_number(
    columns = c(
      Respondentes_anterior,
      Respondentes_atual,
      Variacao_respondentes
    ),
    decimals = 0
  )

print(tabela_comparativa)

ipca_semanal <- ipca_raw |>
  filter(
    DataReferencia == "2026",
    baseCalculo == 0,
    Data >= Sys.Date() - 180
  ) |>
  mutate(Semana = format(Data, "%G-%V")) |>
  group_by(Semana) |>
  slice_max(
    order_by = Data,
    n = 1,
    with_ties = FALSE
  ) |>
  ungroup() |>
  arrange(Data)

grafico_ipca <- ggplot(
  data = ipca_semanal,
  mapping = aes(x = Data, y = Mediana)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Evolução semanal das expectativas do IPCA",
    subtitle = "Referência: 2026 | Última atualização de cada semana",
    x = "Data da divulgação",
    y = "Mediana da expectativa (%)",
    caption = "Fonte: Banco Central do Brasil — Boletim Focus"
  ) +
  theme_minimal()

print(grafico_ipca)

selic_semanal <- selic_raw |>
  filter(
    Reuniao == "R6/2028",
    baseCalculo == 0,
    Data >= Sys.Date() - 180
  ) |>
  mutate(Semana = format(Data, "%G-%V")) |>
  group_by(Semana) |>
  slice_max(
    order_by = Data,
    n = 1,
    with_ties = FALSE
  ) |>
  ungroup() |>
  arrange(Data)

grafico_selic <- ggplot(
  selic_semanal,
  aes(x = Data, y = Mediana)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Evolução semanal das expectativas da Selic",
    subtitle = "Referência: reunião R6/2028 | Última atualização de cada semana",
    x = "Data da divulgação",
    y = "Mediana da expectativa (%)",
    caption = "Fonte: Banco Central do Brasil — Boletim Focus"
  ) +
  theme_minimal()

print(grafico_selic)