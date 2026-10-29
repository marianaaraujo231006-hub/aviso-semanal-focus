
library(dplyr)

ipca_raw <- read.csv("dados/ipca_raw.csv") |>
  mutate(Data = as.Date(Data))

selic_raw <- read.csv("dados/selic_raw.csv") |>
  mutate(Data = as.Date(Data))

ultimas_sextas <- function(dados) {
  dados |>
    distinct(Data) |>
    filter(
      !is.na(Data),
      weekdays(Data) == "sexta-feira"
    ) |>
    arrange(desc(Data)) |>
    slice_head(n = 2) |>
    pull(Data)
}

datas_ipca <- ipca_raw |>
  filter(
    DataReferencia == "2026",
    baseCalculo == 0
  ) |>
  ultimas_sextas()

ipca_comparacao <- ipca_raw |>
  filter(
    DataReferencia == "2026",
    baseCalculo == 0,
    Data %in% datas_ipca
  ) |>
  select(Data, DataReferencia, Mediana, numeroRespondentes) |>
  arrange(Data) |>
  mutate(
    variacao_pp = Mediana - lag(Mediana),
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
  ultimas_sextas()

selic_comparacao <- selic_raw |>
  filter(
    Reuniao == "R6/2028",
    baseCalculo == 0,
    Data %in% datas_selic
  ) |>
  select(Data, Reuniao, Mediana, numeroRespondentes) |>
  arrange(Data) |>
  mutate(
    variacao_pp = Mediana - lag(Mediana),
    classificacao = case_when(
      is.na(variacao_pp) ~ NA_character_,
      variacao_pp > 0.05 ~ "subiu",
      variacao_pp < -0.05 ~ "caiu",
      TRUE ~ "estável"
    )
  )

print(ipca_comparacao)
print(selic_comparacao)
