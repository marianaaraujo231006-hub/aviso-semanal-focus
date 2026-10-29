library(rbcb)
library(dplyr)


ipca_raw <- get_market_expectations(
  type = "annual",
  indic = "IPCA",
  start_date = "2026-01-01"
)

glimpse(ipca_raw)
ipca_raw |> distinct(DataReferencia)
ipca_raw |> distinct(baseCalculo)
ipca_raw |> distinct(Data) |> arrange(desc(Data)) |> head(5)


ipca_raw |>
  filter(DataReferencia == "2026", baseCalculo == 0) |>
  select(Data, DataReferencia, Mediana, baseCalculo) |>
  arrange(desc(Data)) |>
  head(10)

selic_raw <- get_market_expectations(
  type = "selic",
  start_date = "2026-01-01"
)
glimpse(selic_raw)
selic_raw |> distinct(Reuniao)

dir.create("dados", showWarnings = FALSE)
write.csv(ipca_raw, "dados/ipca_raw.csv", row.names = FALSE)
write.csv(selic_raw, "dados/selic_raw.csv", row.names = FALSE)

selic_raw |>
  filter(Reuniao == "R6/2026", baseCalculo == 0) |>
  select(Data, Reuniao, Mediana) |>
  arrange(desc(Data)) |>
  head(5)

?get_market_expectations

ipca_raw |>
  filter(
    DataReferencia == "2026",
    baseCalculo == 0
  ) |>
  distinct(Data) |>
  arrange(desc(Data)) |>
  head(20)