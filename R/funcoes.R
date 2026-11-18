library(dplyr)

ler_base <- function(arquivo) {
  read.csv(arquivo) |>
    mutate(Data = as.Date(Data))
}

proxima_reuniao <- function(dados, data_max = NULL, base_calculo = 0) {
  dados <- dados |> filter(baseCalculo == base_calculo)

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
                             data_max = NULL, limiar = 0.05, unidade = "%") {

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
            "): não há duas divulgações disponíveis. Sem comparação.",
            call. = FALSE)
    return(NULL)
  }

  dias_entre <- as.numeric(diff(duas_semanas$Data))
  if (dias_entre > 10) {
    warning(nome_indicador, " (", referencia,
            "): as duas últimas divulgações estão a ", dias_entre,
            " dias uma da outra (não são consecutivas). Sem comparação.",
            call. = FALSE)
    return(NULL)
  }

  duas_semanas |>
    mutate(
      Data_anterior         = lag(Data),
      Mediana_anterior      = lag(Mediana),
      Respondentes_anterior = lag(numeroRespondentes),

      Variacao = round(Mediana - Mediana_anterior, 4),
      Tendencia = case_when(
        Variacao >  limiar ~ "subiu",
        Variacao < -limiar ~ "caiu",
        TRUE               ~ "estável"
      )
    ) |>
    slice_tail(n = 1) |>
    transmute(
      Indicador  = nome_indicador,
      Referencia = as.character(referencia),
      Unidade    = unidade,
      Limiar     = limiar,
      Data_anterior,
      Data_atual = Data,
      Mediana_anterior,
      Mediana_atual = Mediana,
      Variacao,
      Respondentes_anterior,
      Respondentes_atual    = numeroRespondentes,
      Variacao_respondentes = numeroRespondentes - Respondentes_anterior,
      Tendencia
    )
}

serie_semanal <- function(dados, data_max = NULL, janela_dias = 180) {
  if (!is.null(data_max)) {
    dados <- dados |> filter(Data <= as.Date(data_max))
  }

  dados |>
    filter(Data >= max(Data) - janela_dias) |>
    mutate(Semana = format(Data, "%G-%V")) |>
    group_by(Semana) |>
    slice_max(Data, n = 1, with_ties = FALSE) |>
    ungroup() |>
    arrange(Data)
}

grafico_evolucao <- function(serie, titulo, subtitulo,
                             eixo_y = "Mediana da expectativa (%)",
                             cor_linha = "#1f4e78", cor_ponto = "#d95f02") {
  ggplot2::ggplot(serie, ggplot2::aes(x = Data, y = Mediana)) +
    ggplot2::geom_line(linewidth = 1, color = cor_linha) +
    ggplot2::geom_point(size = 2.2, color = cor_ponto) +
    ggplot2::labs(
      title    = titulo,
      subtitle = subtitulo,
      x        = "Data da divulgação",
      y        = eixo_y,
      caption  = "Fonte: Banco Central do Brasil — Relatório Focus"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank()
    )
}


ler_comparacao <- function(arquivo = "saidas/comparacao_semanal.csv") {
  read.csv(arquivo, fileEncoding = "UTF-8") |>
    mutate(
      Data_anterior = as.Date(Data_anterior),
      Data_atual    = as.Date(Data_atual),
      Referencia    = as.character(Referencia)
    )
}

arquivo_grafico <- function(indicador) {
  nomes <- c("IPCA" = "ipca", "Selic" = "selic",
             "PIB Total" = "pib", "Câmbio" = "cambio")
  paste0("saidas/grafico_", nomes[[indicador]], ".png")
}

montar_tabela_gt <- function(comparacao) {
  comparacao |>
    select(Indicador, Referencia, Unidade, Data_anterior, Data_atual,
           Mediana_anterior, Mediana_atual, Variacao, Tendencia) |>
    gt::gt() |>
    gt::tab_header(
      title    = "Aviso Semanal Focus",
      subtitle = "Última divulgação versus divulgação anterior"
    ) |>
    gt::cols_label(
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
    gt::fmt_date(columns = c(Data_anterior, Data_atual),
                 date_style = "day_m_year") |>
    gt::fmt_number(columns = c(Mediana_anterior, Mediana_atual, Variacao),
                   decimals = 4, dec_mark = ",", sep_mark = ".")
}