library(dplyr)
library(glue)
source("R/funcoes.R")

comparacao <- ler_comparacao()

if (!"Limiar" %in% names(comparacao)) {
  stop("A tabela em saidas/ é de uma versão antiga. Rode o 02_tratamento.R de novo.")
}

arquivos_graficos <- vapply(comparacao$Indicador, arquivo_grafico, character(1))
if (!all(file.exists(arquivos_graficos))) {
  stop("Gráficos não encontrados em saidas/. Rode o 03_visualizacao.R antes.")
}

fmt_br <- function(x, casas = 2, sinal = FALSE) {
  prefixo <- ifelse(sinal & x > 0, "+", "")
  paste0(
    prefixo,
    format(round(x, casas), nsmall = casas, decimal.mark = ",",
           big.mark = ".", trim = TRUE)
  )
}

fmt_data <- function(x) format(x, "%d/%m/%Y")

gerar_frase_indicador <- function(linha) {
  casas  <- ifelse(linha$Indicador == "Selic", 2, 4)
  eh_taxa <- linha$Unidade == "%"

  ref <- ifelse(linha$Indicador == "Selic",
                paste("reunião", linha$Referencia),
                paste("ref.", linha$Referencia))

  valor <- function(x) {
    if (eh_taxa) paste0(fmt_br(x, casas), "%") else paste("R$", fmt_br(x, casas))
  }
  unidade_variacao <- if (eh_taxa) "p.p." else "R$"

  tendencia <- switch(linha$Tendencia,
    "subiu" = "apresentou alta",
    "caiu"  = "apresentou queda",
    "manteve-se estável"
  )

  respondentes <- if (linha$Variacao_respondentes == 0) {
    glue("permaneceu em {linha$Respondentes_atual}")
  } else {
    glue("passou de {linha$Respondentes_anterior} para {linha$Respondentes_atual}")
  }

  as.character(glue(
    "{linha$Indicador} ({ref}): entre {fmt_data(linha$Data_anterior)} e ",
    "{fmt_data(linha$Data_atual)}, a mediana das expectativas {tendencia}, ",
    "passando de {valor(linha$Mediana_anterior)} para {valor(linha$Mediana_atual)} ",
    "({fmt_br(linha$Variacao, casas, sinal = TRUE)} {unidade_variacao}). ",
    "O número de respondentes {respondentes}."
  ))
}

gerar_textos_boletim <- function(df) {
  frases <- vapply(seq_len(nrow(df)),
                   function(i) gerar_frase_indicador(df[i, ]),
                   character(1))
  names(frases) <- df$Indicador

  resumo <- glue_collapse(glue("{df$Indicador} ({df$Tendencia})"),
                          sep = ", ", last = " e ")

  datas_atuais    <- unique(df$Data_atual)
  datas_anteriores <- unique(df$Data_anterior)

  periodo <- if (length(datas_atuais) == 1 && length(datas_anteriores) == 1) {
    glue("entre as divulgações de {fmt_data(datas_anteriores)} e {fmt_data(datas_atuais)}")
  } else {
    "entre a última divulgação disponível de cada indicador e a anterior"
  }

  abertura <- glue(
    "Na comparação {periodo}, o Relatório Focus registrou o seguinte ",
    "comportamento nas medianas das expectativas de mercado: {resumo}."
  )

  list(abertura = as.character(abertura), frases = frases)
}

textos_focus <- gerar_textos_boletim(comparacao)

if (!isTRUE(getOption("knitr.in.progress"))) {
  cat("\n", textos_focus$abertura, "\n\n", sep = "")
  for (frase in textos_focus$frases) cat("-", frase, "\n")
}