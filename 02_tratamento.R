library(dplyr)
source("R/funcoes.R")

ano_ref       <- 2026    
limiar_taxas  <- 0.05    
limiar_cambio <- 0.02   
data_corte    <- NULL    

ipca_raw   <- ler_base("dados/ipca_raw.csv")
selic_raw  <- ler_base("dados/selic_raw.csv")
pib_raw    <- ler_base("dados/pib_raw.csv")
cambio_raw <- ler_base("dados/cambio_raw.csv")

filtrar_anual <- function(dados) {
  dados |>
    filter(as.character(DataReferencia) == as.character(ano_ref),
           baseCalculo == 0)
}

reuniao_selic <- proxima_reuniao(selic_raw, data_corte)

tabela_comparativa <- bind_rows(
  comparar_semanas(filtrar_anual(ipca_raw), "IPCA", ano_ref,
                   data_corte, limiar_taxas),
  comparar_semanas(selic_raw |> filter(Reuniao == reuniao_selic, baseCalculo == 0),
                   "Selic", reuniao_selic, data_corte, limiar_taxas),
  comparar_semanas(filtrar_anual(pib_raw), "PIB Total", ano_ref,
                   data_corte, limiar_taxas),
  comparar_semanas(filtrar_anual(cambio_raw), "Câmbio", ano_ref,
                   data_corte, limiar_cambio, unidade = "R$/US$")
)

print(as.data.frame(tabela_comparativa))

dir.create("saidas", showWarnings = FALSE)
write.csv(tabela_comparativa, "saidas/comparacao_semanal.csv",
          row.names = FALSE, fileEncoding = "UTF-8")