library(rbcb)
library(dplyr)

data_inicio <- "2026-01-01"

dir.create("dados", showWarnings = FALSE)

consultas <- list(
  ipca   = list(type = "annual", indic = "IPCA"),
  pib    = list(type = "annual", indic = "PIB Total"),
  cambio = list(type = "annual", indic = "C\u00e2mbio"),
  selic  = list(type = "selic")
)

coletar <- function(consulta) {
  args <- c(consulta, list(start_date = data_inicio))
  do.call(get_market_expectations, args)
}

for (nome in names(consultas)) {
  arquivo <- file.path("dados", paste0(nome, "_raw.csv"))

  dados <- tryCatch(
    coletar(consultas[[nome]]),
    error = function(e) {
      warning("Falha ao coletar '", nome, "': ", conditionMessage(e),
              call. = FALSE)
      NULL
    }
  )

  if (is.null(dados) || nrow(dados) == 0) {
    warning("'", nome, "': sem dados coletados. Arquivo anterior mantido.",
            call. = FALSE)
    next
  }

  write.csv(dados, arquivo, row.names = FALSE)
  message(nome, ": ", nrow(dados), " linhas | última divulgação: ",
          max(as.Date(dados$Data)))
}