library(dplyr)
library(gt)
library(ggplot2)

comparacao <- read.csv("saidas/comparacao_semanal.csv") |>
  mutate(
    Data_anterior = as.Date(Data_anterior),
    Data_atual    = as.Date(Data_atual),
    Referencia    = as.character(Referencia)
  )

ref_ipca  <- comparacao$Referencia[comparacao$Indicador == "IPCA"]
ref_selic <- comparacao$Referencia[comparacao$Indicador == "Selic"]


tabela_gt <- comparacao |>
  select(Indicador, Referencia, Data_anterior, Data_atual,
         Mediana_anterior, Mediana_atual, Variacao_pp, Tendencia) |>
  gt() |>
  tab_header(
    title = "Aviso Semanal Focus",
    subtitle = "Última divulgação versus divulgação anterior"
  ) |>
  cols_label(
    Indicador        = "Indicador",
    Referencia       = "Referência",
    Data_anterior    = "Data anterior",
    Data_atual       = "Data atual",
    Mediana_anterior = "Mediana anterior (%)",
    Mediana_atual    = "Mediana atual (%)",
    Variacao_pp      = "Variação (p.p.)",
    Tendencia        = "Tendência"
  ) |>
  fmt_date(columns = c(Data_anterior, Data_atual), date_style = "day_m_year") |>
  fmt_number(columns = c(Mediana_anterior, Mediana_atual, Variacao_pp),
             decimals = 4, dec_mark = ",", sep_mark = ".")

print(tabela_gt)

ipca_raw <- read.csv("dados/ipca_raw.csv") |>
  mutate(Data = as.Date(Data))

selic_raw <- read.csv("dados/selic_raw.csv") |>
  mutate(Data = as.Date(Data))

grafico_evolucao <- function(dados, titulo, subtitulo, janela_dias = 180) {
  semanal <- dados |>
    filter(Data >= max(Data) - janela_dias) |>
    mutate(Semana = format(Data, "%G-%V")) |>
    group_by(Semana) |>
    slice_max(Data, n = 1, with_ties = FALSE) |>
    ungroup()

  ggplot(semanal, aes(x = Data, y = Mediana)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    labs(
      title    = titulo,
      subtitle = subtitulo,
      x = "Data da divulgação",
      y = "Mediana da expectativa (%)",
      caption = "Fonte: Banco Central do Brasil — Relatório Focus"
    ) +
    theme_minimal()
}

grafico_ipca <- ipca_raw |>
  filter(as.character(DataReferencia) == ref_ipca, baseCalculo == 0) |>
  grafico_evolucao(
    "Evolução semanal das expectativas do IPCA",
    paste("Referência:", ref_ipca, "| Última divulgação de cada semana")
  )

grafico_selic <- selic_raw |>
  filter(Reuniao == ref_selic, baseCalculo == 0) |>
  grafico_evolucao(
    "Evolução semanal das expectativas da Selic",
    paste("Reunião:", ref_selic, "| Última divulgação de cada semana")
  )

print(grafico_ipca)
print(grafico_selic)

dir.create("saidas", showWarnings = FALSE)
gtsave(tabela_gt, "saidas/tabela_comparativa.html")
ggsave("saidas/grafico_ipca.png",  grafico_ipca,  width = 8, height = 4.5, dpi = 150)
ggsave("saidas/grafico_selic.png", grafico_selic, width = 8, height = 4.5, dpi = 150)