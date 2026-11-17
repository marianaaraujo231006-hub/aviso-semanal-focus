library(rbcb)
library(dplyr)

data_inicio <- "2026-01-01"

ipca_raw <- get_market_expectations(
  type = "annual",
  indic = "IPCA",
  start_date = data_inicio
)

selic_raw <- get_market_expectations(
  type = "selic",
  start_date = data_inicio
)

dir.create("dados", showWarnings = FALSE)
write.csv(ipca_raw, "dados/ipca_raw.csv", row.names = FALSE)
write.csv(selic_raw, "dados/selic_raw.csv", row.names = FALSE)