library(dplyr)
library(gt)
library(ggplot2)
source("R/funcoes.R")

comparacao <- read.csv("saidas/comparacao_semanal.csv",
                       fileEncoding = "UTF-8") |>
  mutate(
    Data_anterior = as.Date(Data_anterior),
    Data_atual    = as.Date(Data_atual),
    Referencia    = as.character(Referencia)
  )

tabela_gt <- comparacao |>
  select(Indicador, Referencia, Unidade, Data_anterior, Data_atual,
         Mediana_anterior, Mediana_atual, Variacao, Tendencia) |>
  gt() |>
  tab_header(
    title    = "Aviso Semanal Focus",
    subtitle = "Última divulgação versus divulgação anterior"
  ) |>
  cols_label(
    Indicador        = "Indicador",
    Referencia       = "Referência",
    Unidade          = "Unidade",
    Data_anterior    = "Data anterior",
    Data_atual       = "Data atual",
    Mediana_anterior = "Mediana anterior",
    Mediana_atual    = "Mediana atual",
    Variacao         = "Variação",
    Tendencia        = "Tendência"
  ) |>
  fmt_date(columns = c(Data_anterior, Data_atual), date_style = "day_m_year") |>
  fmt_number(columns = c(Mediana_anterior, Mediana_atual, Variacao),
             decimals = 4, dec_mark = ",", sep_mark = ".")

print(tabela_gt)

bases_brutas <- list(
  "IPCA"      = ler_base("dados/ipca_raw.csv"),
  "Selic"     = ler_base("dados/selic_raw.csv"),
  "PIB Total" = ler_base("dados/pib_raw.csv"),
  "Câmbio"    = ler_base("dados/cambio_raw.csv")
)

nomes_arquivo <- c("IPCA" = "ipca", "Selic" = "selic",
                   "PIB Total" = "pib", "Câmbio" = "cambio")

filtrar_base <- function(indicador, referencia) {
  base <- bases_brutas[[indicador]]
  if (indicador == "Selic") {
    base |> filter(Reuniao == referencia, baseCalculo == 0)
  } else {
    base |> filter(as.character(DataReferencia) == referencia, baseCalculo == 0)
  }
}

dir.create("saidas", showWarnings = FALSE)

for (i in seq_len(nrow(comparacao))) {
  linha <- comparacao[i, ]

  serie <- filtrar_base(linha$Indicador, linha$Referencia) |>
    serie_semanal(data_max = linha$Data_atual)

  rotulo_ref <- ifelse(linha$Indicador == "Selic", "Reunião:", "Referência:")

  grafico <- grafico_evolucao(
    serie,
    titulo    = paste("Evolução semanal das expectativas —", linha$Indicador),
    subtitulo = paste(rotulo_ref, linha$Referencia,
                      "| Última divulgação de cada semana"),
    eixo_y    = paste0("Mediana da expectativa (", linha$Unidade, ")")
  )

  print(grafico)
  ggsave(paste0("saidas/grafico_", nomes_arquivo[[linha$Indicador]], ".png"),
         grafico, width = 8, height = 4.5, dpi = 150)
}

gtsave(tabela_gt, "saidas/tabela_comparativa.html")