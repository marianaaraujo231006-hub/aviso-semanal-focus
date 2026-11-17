library(dplyr)

ano_ipca    <- 2026     
limiar_pp   <- 0.05     
data_corte  <- NULL
                        


ipca_raw <- read.csv("dados/ipca_raw.csv") |>
  mutate(Data = as.Date(Data))

selic_raw <- read.csv("dados/selic_raw.csv") |>
  mutate(Data = as.Date(Data))


proxima_reuniao <- function(dados, data_max = NULL) {
  dados <- dados |> filter(baseCalculo == 0)

  if (!is.null(data_max)) {
    dados <- dados |> filter(Data <= as.Date(data_max))
  }

  dados |>
    group_by(Reuniao) |>
    summarise(ultima_data = max(Data), .groups = "drop") |>
    filter(ultima_data == max(ultima_data)) |>   
    mutate(
      ano    = as.integer(sub(".*/", "", Reuniao)),
      numero = as.integer(sub("R(\\d+)/.*", "\\1", Reuniao))
    ) |>
    arrange(ano, numero) |>
    slice_head(n = 1) |>                           
    pull(Reuniao)
}

comparar_semanas <- function(dados, nome_indicador, referencia,
                             data_max = NULL, limiar = 0.05) {

  dados <- dados |> select(Data, Mediana, numeroRespondentes)

  if (!is.null(data_max)) {
    dados <- dados |> filter(Data <= as.Date(data_max))
  }

  duas_semanas <- dados |>
    mutate(Semana = format(Data, "%G-%V")) |>
    group_by(Semana) |>
    slice_max(Data, n = 1, with_ties = FALSE) |>
    ungroup() |>
    arrange(desc(Data)) |>
    slice_head(n = 2) |>
    arrange(Data)


  if (nrow(duas_semanas) < 2) {
    warning(nome_indicador, " (", referencia,
            "): não há duas divulgações disponíveis. Sem comparação.")
    return(NULL)
  }

  dias_entre <- as.numeric(diff(duas_semanas$Data))
  if (dias_entre > 10) {
    warning(nome_indicador, " (", referencia,
            "): as duas últimas divulgações estão a ", dias_entre,
            " dias uma da outra (não são consecutivas). Sem comparação.")
    return(NULL)
  }

  duas_semanas |>
    mutate(
      Data_anterior         = lag(Data),
      Mediana_anterior      = lag(Mediana),
      Respondentes_anterior = lag(numeroRespondentes),
      Variacao_pp           = round(Mediana - Mediana_anterior, 4),
      Tendencia = case_when(
        Variacao_pp >  limiar ~ "subiu",
        Variacao_pp < -limiar ~ "caiu",
        TRUE                  ~ "estável"
      )
    ) |>
    slice_tail(n = 1) |>
    transmute(
      Indicador = nome_indicador,
      Referencia = referencia,
      Data_anterior,
      Data_atual = Data,
      Mediana_anterior,
      Mediana_atual = Mediana,
      Variacao_pp,
      Respondentes_anterior,
      Respondentes_atual = numeroRespondentes,
      Tendencia
    )
}

dados_ipca <- ipca_raw |>
  filter(as.character(DataReferencia) == as.character(ano_ipca),
         baseCalculo == 0)

tabela_ipca <- comparar_semanas(dados_ipca, "IPCA", as.character(ano_ipca),
                                data_corte, limiar_pp)

reuniao_selic <- proxima_reuniao(selic_raw, data_corte)

dados_selic <- selic_raw |>
  filter(Reuniao == reuniao_selic, baseCalculo == 0)

tabela_selic <- comparar_semanas(dados_selic, "Selic", reuniao_selic,
                                 data_corte, limiar_pp)

tabela_comparativa <- bind_rows(tabela_ipca, tabela_selic)
print(as.data.frame(tabela_comparativa))

dir.create("saidas", showWarnings = FALSE)
write.csv(tabela_comparativa, "saidas/comparacao_semanal.csv",
          row.names = FALSE)