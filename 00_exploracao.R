library(dplyr)

ipca_raw <- read.csv("dados/ipca_raw.csv") |>
  mutate(Data = as.Date(Data))

selic_raw <- read.csv("dados/selic_raw.csv") |>
  mutate(Data = as.Date(Data))

glimpse(ipca_raw)
ipca_raw |> distinct(DataReferencia)
ipca_raw |> distinct(baseCalculo)
ipca_raw |> distinct(Data) |> arrange(desc(Data)) |> head(5)


glimpse(selic_raw)


selic_raw |>
  filter(baseCalculo == 0) |>
  group_by(Reuniao) |>
  summarise(ultima_data = max(Data)) |>
  arrange(desc(ultima_data)) |>
  print(n = Inf)


colSums(is.na(ipca_raw))
colSums(is.na(selic_raw))


sum(duplicated(ipca_raw))
sum(duplicated(selic_raw))

ipca_raw  |> count(Data, DataReferencia, baseCalculo) |> filter(n > 1)
selic_raw |> count(Data, Reuniao, baseCalculo)        |> filter(n > 1)

range(ipca_raw$Data)
range(selic_raw$Data)


selic_raw |>
  filter(baseCalculo == 0) |>
  distinct(Data) |>
  arrange(Data) |>
  mutate(dias = as.numeric(Data - lag(Data))) |>
  count(dias)

colSums(is.na(ipca_raw))
colSums(is.na(selic_raw))

sum(duplicated(ipca_raw))
sum(duplicated(selic_raw))

ipca_raw  |> count(Data, DataReferencia, baseCalculo) |> filter(n > 1)
selic_raw |> count(Data, Reuniao, baseCalculo)        |> filter(n > 1)

range(ipca_raw$Data)
range(selic_raw$Data)

selic_raw |>
  filter(baseCalculo == 0) |>
  distinct(Data) |>
  arrange(Data) |>
  mutate(dias = as.numeric(Data - lag(Data))) |>
  count(dias)