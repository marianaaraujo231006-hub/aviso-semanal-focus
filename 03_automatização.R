library(dplyr)
library(gt)
library(ggplot2)
library(glue)

# ==============================================================================
# 1. PARÂMETROS DE CONFIGURAÇÃO (AJUSTÁVEIS)
# ==============================================================================

ANO_REF_ANUAL           <- "2026"     # Ano de referência para IPCA, PIB Total e Câmbio
REUNIAO_REF_SELIC       <- "R6/2028"  # Reunião do Copom de referência para a Selic
BASE_CALCULO            <- 0          # 0 = expectativas dos últimos 30 dias | 1 = últimos 5 dias
LIMITE_ESTABILIDADE_PP  <- 0.05       # Limite (p.p.) para classificar "subiu"/"caiu"/"estável"
LIMITE_ESTABILIDADE_BRL <- 0.02       # Limite (R$) para classificar o Câmbio
JANELA_DIAS_GRAFICO     <- 180        # Janela histórica (em dias) para os gráficos semanais
INCLUIR_PIB_CAMBIO      <- TRUE       # Ampliar análise para PIB Total e Câmbio
COR_LINHA_GRAFICO       <- "#1f4e78"  # Cor principal das séries nos gráficos
COR_PONTO_GRAFICO       <- "#d95f02"  # Cor de destaque dos pontos semanais

# ==============================================================================
# 2. COLETA COMPLEMENTAR (PIB TOTAL E CÂMBIO) E CARREGAMENTO DAS BASES
# ==============================================================================
dir.create("dados", showWarnings = FALSE)

# Carrega bases obrigatórias já existentes (IPCA e Selic)
ipca_raw <- read.csv("dados/ipca_raw.csv") |>
  mutate(Data = as.Date(Data))

selic_raw <- read.csv("dados/selic_raw.csv") |>
  mutate(Data = as.Date(Data))

# Função auxiliar para carregar ou baixar indicadores adicionais via rbcb
carregar_ou_coletar_anual <- function(indicador, arquivo_csv, data_inicio = "2026-01-01") {
  if (!file.exists(arquivo_csv)) {
    if (requireNamespace("rbcb", quietly = TRUE)) {
      message(glue("Coletando '{indicador}' na API do Banco Central (rbcb)..."))
      tryCatch({
        dados_api <- rbcb::get_market_expectations(
          type = "annual",
          indic = indicador,
          start_date = data_inicio
        )
        write.csv(dados_api, arquivo_csv, row.names = FALSE)
      }, error = function(e) {
        warning(glue("Não foi possível baixar '{indicador}' via API: {e$message}"))
      })
    } else {
      warning(glue("Arquivo '{arquivo_csv}' não encontrado e pacote 'rbcb' não instalado."))
    }
  }

  if (file.exists(arquivo_csv)) {
    read.csv(arquivo_csv) |>
      mutate(Data = as.Date(Data))
  } else {
    NULL
  }
}

pib_raw    <- NULL
cambio_raw <- NULL

if (INCLUIR_PIB_CAMBIO) {
  pib_raw    <- carregar_ou_coletar_anual("PIB Total", "dados/pib_raw.csv")
  cambio_raw <- carregar_ou_coletar_anual("Câmbio", "dados/cambio_raw.csv")
}


# ==============================================================================
# 3. FUNÇÕES PADRONIZADAS DE TRATAMENTO E COMPARAÇÃO SEMANAL
# ==============================================================================

# Seleciona a última divulgação disponível em cada uma das 2 semanas mais recentes
ultimas_divulgacoes <- function(dados) {
  datas <- dados |>
    distinct(Data) |>
    filter(!is.na(Data)) |>
    mutate(Semana = format(Data, "%G-%V")) |>
    group_by(Semana) |>
    summarise(Data = max(Data), .groups = "drop") |>
    arrange(desc(Data)) |>
    slice_head(n = 2) |>
    pull(Data)

  if (length(datas) < 2) {
    stop("Não existem duas semanas disponíveis para comparação.")
  }

  return(datas)
}

# Processa a comparação entre as duas semanas mais recentes para qualquer indicador
comparar_duas_semanas <- function(dados_filtrados,
                                  nome_indicador,
                                  referencia,
                                  unidade = "%",
                                  limite_estabilidade = LIMITE_ESTABILIDADE_PP) {
  datas_comp <- ultimas_divulgacoes(dados_filtrados)

  comparacao <- dados_filtrados |>
    filter(Data %in% datas_comp) |>
    select(Data, Mediana, numeroRespondentes) |>
    arrange(Data) |>
    mutate(
      Indicador = nome_indicador,
      Referencia = as.character(referencia),
      Unidade = unidade,
      Semana = format(Data, "%V/%G"),
      variacao_mediana = Mediana - lag(Mediana),
      variacao_respondentes = numeroRespondentes - lag(numeroRespondentes),
      classificacao = case_when(
        is.na(variacao_mediana) ~ NA_character_,
        variacao_mediana > limite_estabilidade ~ "subiu",
        variacao_mediana < -limite_estabilidade ~ "caiu",
        TRUE ~ "estável"
      )
    )

  resumo <- comparacao |>
    summarise(
      Indicador = first(Indicador),
      Referencia = first(Referencia),
      Unidade = first(Unidade),
      Semana_anterior = first(Semana),
      Semana_atual = last(Semana),
      Data_anterior = format(first(Data), "%d/%m/%Y"),
      Data_atual = format(last(Data), "%d/%m/%Y"),
      Mediana_anterior = first(Mediana),
      Mediana_atual = last(Mediana),
      Respondentes_anterior = first(numeroRespondentes),
      Respondentes_atual = last(numeroRespondentes),
      Variacao_pp = last(variacao_mediana),
      Variacao_respondentes = last(variacao_respondentes),
      Tendencia = last(classificacao)
    )

  list(comparacao = comparacao, resumo = resumo)
}

# Processa IPCA e Selic
res_ipca <- ipca_raw |>
  filter(DataReferencia == ANO_REF_ANUAL, baseCalculo == BASE_CALCULO) |>
  comparar_duas_semanas(
    nome_indicador = "IPCA",
    referencia = ANO_REF_ANUAL,
    unidade = "%",
    limite_estabilidade = LIMITE_ESTABILIDADE_PP
  )

res_selic <- selic_raw |>
  filter(Reuniao == REUNIAO_REF_SELIC, baseCalculo == BASE_CALCULO) |>
  comparar_duas_semanas(
    nome_indicador = "Selic",
    referencia = REUNIAO_REF_SELIC,
    unidade = "%",
    limite_estabilidade = LIMITE_ESTABILIDADE_PP
  )

lista_resumos <- list(res_ipca$resumo, res_selic$resumo)

# Processa PIB Total e Câmbio se disponíveis
res_pib <- NULL
if (!is.null(pib_raw) && nrow(pib_raw) > 0) {
  res_pib <- pib_raw |>
    filter(DataReferencia == ANO_REF_ANUAL, baseCalculo == BASE_CALCULO) |>
    comparar_duas_semanas(
      nome_indicador = "PIB Total",
      referencia = ANO_REF_ANUAL,
      unidade = "%",
      limite_estabilidade = LIMITE_ESTABILIDADE_PP
    )
  lista_resumos <- append(lista_resumos, list(res_pib$resumo))
}

res_cambio <- NULL
if (!is.null(cambio_raw) && nrow(cambio_raw) > 0) {
  res_cambio <- cambio_raw |>
    filter(DataReferencia == ANO_REF_ANUAL, baseCalculo == BASE_CALCULO) |>
    comparar_duas_semanas(
      nome_indicador = "Câmbio",
      referencia = ANO_REF_ANUAL,
      unidade = "R$/US$",
      limite_estabilidade = LIMITE_ESTABILIDADE_BRL
    )
  lista_resumos <- append(lista_resumos, list(res_cambio$resumo))
}

tabela_resumo_geral <- bind_rows(lista_resumos)


# ==============================================================================
# 4. GERAÇÃO DE FRASES AUTOMÁTICAS COM glue()
# ==============================================================================

# Formata número no padrão brasileiro (vírgula decimal)
fmt_br <- function(x, casas = 2, sinal = FALSE) {
  prefixo <- ifelse(sinal & x > 0, "+", "")
  paste0(
    prefixo,
    format(round(x, casas), nsmall = casas, decimal.mark = ",", big.mark = ".", trim = TRUE)
  )
}

# Gera frase automática detalhada para uma linha da tabela de resumo
gerar_frase_indicador <- function(linha_resumo, casas_decimais = 2) {
  ind        <- linha_resumo$Indicador
  ref        <- linha_resumo$Referencia
  unid       <- linha_resumo$Unidade
  sem_ant    <- linha_resumo$Semana_anterior
  sem_atu    <- linha_resumo$Semana_atual
  dt_ant     <- linha_resumo$Data_anterior
  dt_atu     <- linha_resumo$Data_atual
  med_ant    <- fmt_br(linha_resumo$Mediana_anterior, casas = casas_decimais)
  med_atu    <- fmt_br(linha_resumo$Mediana_atual, casas = casas_decimais)
  var_val    <- fmt_br(linha_resumo$Variacao_pp, casas = casas_decimais, sinal = TRUE)
  resp_ant   <- linha_resumo$Respondentes_anterior
  resp_atu   <- linha_resumo$Respondentes_atual
  var_resp   <- linha_resumo$Variacao_respondentes
  tendencia  <- linha_resumo$Tendencia

  unid_var <- ifelse(unid == "%", "p.p.", "R$/US$")

  texto_tendencia <- case_when(
    tendencia == "subiu"   ~ "apresentou alta",
    tendencia == "caiu"    ~ "apresentou queda",
    TRUE                   ~ "manteve-se estável"
  )

  texto_respondentes <- case_when(
    var_resp > 0 ~ glue("aumentou em {var_resp} instituições (de {resp_ant} para {resp_atu})"),
    var_resp < 0 ~ glue("reduziu em {abs(var_resp)} instituições (de {resp_ant} para {resp_atu})"),
    TRUE         ~ glue("permaneceu inalterado em {resp_atu} instituições")
  )

  rotulo_valor_ant <- ifelse(unid == "%", glue("{med_ant}%"), glue("R$ {med_ant}"))
  rotulo_valor_atu <- ifelse(unid == "%", glue("{med_atu}%"), glue("R$ {med_atu}"))

  glue(
    "• {ind} (ref. {ref}): entre {dt_ant} (semana {sem_ant}) e {dt_atu} (semana {sem_atu}), ",
    "a mediana das expectativas {texto_tendencia}, passando de {rotulo_valor_ant} para ",
    "{rotulo_valor_atu} ({var_val} {unid_var}). O número de respondentes {texto_respondentes}."
  )
}

# Gera todas as frases individuais e um parágrafo de síntese do boletim
gerar_textos_boletim <- function(df_resumo) {
  frases_individuais <- vapply(
    seq_len(nrow(df_resumo)),
    function(i) {
      linha <- df_resumo[i, ]
      casas <- ifelse(linha$Indicador == "IPCA", 4, 2)
      as.character(gerar_frase_indicador(linha, casas_decimais = casas))
    },
    character(1)
  )
  names(frases_individuais) <- df_resumo$Indicador

  resumo_tendencias <- glue_collapse(
    glue("{df_resumo$Indicador} ({df_resumo$Tendencia})"),
    sep = ", ",
    last = " e "
  )

  frase_abertura <- glue(
    "Na comparação entre as divulgações de {first(df_resumo$Data_anterior)} e ",
    "{first(df_resumo$Data_atual)}, o Boletim Focus registrou o seguinte comportamento ",
    "nas medianas das expectativas de mercado: {resumo_tendencias}."
  )

  list(
    abertura = frase_abertura,
    frases = frases_individuais
  )
}

# Executa geração das frases com glue()
textos_focus <- gerar_textos_boletim(tabela_resumo_geral)

if (!isTRUE(getOption("knitr.in.progress"))) {
  cat("\n================ SÍNTESE AUTOMÁTICA (glue) ================\n")
  cat(textos_focus$abertura, "\n\n")
  for (frase in textos_focus$frases) {
    cat(frase, "\n")
  }
  cat("===========================================================\n\n")
}


# ==============================================================================
# 5. TABELA COMPARATIVA FORMATADA (gt) E GRÁFICOS SEMANAIS (ggplot2)
# ==============================================================================

construir_tabela_gt <- function(df_resumo) {
  df_resumo |>
    select(-Unidade) |>
    gt() |>
    tab_header(
      title = "Boletim Focus — Comparativo Semanal de Expectativas",
      subtitle = glue(
        "Última semana disponível versus semana anterior | Limite de estabilidade: ±{fmt_br(LIMITE_ESTABILIDADE_PP, 2)} p.p."
      )
    ) |>
    cols_label(
      Indicador = "Indicador",
      Referencia = "Referência",
      Semana_anterior = "Semana anterior",
      Semana_atual = "Semana atual",
      Data_anterior = "Data anterior",
      Data_atual = "Data atual",
      Mediana_anterior = "Mediana anterior",
      Mediana_atual = "Mediana atual",
      Respondentes_anterior = "Resp. anteriores",
      Respondentes_atual = "Resp. atuais",
      Variacao_pp = "Variação",
      Variacao_respondentes = "Var. respondentes",
      Tendencia = "Tendência"
    ) |>
    fmt_number(
      columns = c(Mediana_anterior, Mediana_atual, Variacao_pp),
      decimals = 4,
      dec_mark = ",",
      sep_mark = "."
    ) |>
    fmt_number(
      columns = c(Respondentes_anterior, Respondentes_atual, Variacao_respondentes),
      decimals = 0,
      sep_mark = "."
    ) |>
    tab_source_note(
      source_note = "Fonte: Banco Central do Brasil — Sistema Expectativas de Mercado (Boletim Focus)."
    )
}

tabela_comparativa <- construir_tabela_gt(tabela_resumo_geral)
if (!isTRUE(getOption("knitr.in.progress"))) {
  print(tabela_comparativa)
}

# Função padronizada para série semanal (últimos N dias com referência na data máxima da base)
preparar_serie_semanal <- function(dados_filtrados, janela_dias = JANELA_DIAS_GRAFICO) {
  data_ref_max <- max(dados_filtrados$Data, na.rm = TRUE)

  dados_filtrados |>
    filter(Data >= data_ref_max - janela_dias) |>
    mutate(Semana = format(Data, "%G-%V")) |>
    group_by(Semana) |>
    slice_max(order_by = Data, n = 1, with_ties = FALSE) |>
    ungroup() |>
    arrange(Data)
}

gerar_grafico_evolucao <- function(serie_semanal, titulo, subtitulo, eixo_y = "Mediana da expectativa (%)") {
  ggplot(serie_semanal, aes(x = Data, y = Mediana)) +
    geom_line(linewidth = 1, color = COR_LINHA_GRAFICO) +
    geom_point(size = 2.2, color = COR_PONTO_GRAFICO) +
    labs(
      title = titulo,
      subtitle = subtitulo,
      x = "Data da divulgação",
      y = eixo_y,
      caption = "Fonte: Banco Central do Brasil — Boletim Focus"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )
}

ipca_semanal <- ipca_raw |>
  filter(DataReferencia == ANO_REF_ANUAL, baseCalculo == BASE_CALCULO) |>
  preparar_serie_semanal()

grafico_ipca <- gerar_grafico_evolucao(
  ipca_semanal,
  titulo = "Evolução semanal das expectativas do IPCA",
  subtitulo = glue("Referência: {ANO_REF_ANUAL} | Última atualização de cada semana (últimos {JANELA_DIAS_GRAFICO} dias)")
)

selic_semanal <- selic_raw |>
  filter(Reuniao == REUNIAO_REF_SELIC, baseCalculo == BASE_CALCULO) |>
  preparar_serie_semanal()

grafico_selic <- gerar_grafico_evolucao(
  selic_semanal,
  titulo = "Evolução semanal das expectativas da Selic",
  subtitulo = glue("Referência: reunião {REUNIAO_REF_SELIC} | Última atualização de cada semana (últimos {JANELA_DIAS_GRAFICO} dias)")
)

if (!isTRUE(getOption("knitr.in.progress"))) {
  print(grafico_ipca)
  print(grafico_selic)
}

grafico_pib <- NULL
if (!is.null(pib_raw) && nrow(pib_raw) > 0) {
  pib_semanal <- pib_raw |>
    filter(DataReferencia == ANO_REF_ANUAL, baseCalculo == BASE_CALCULO) |>
    preparar_serie_semanal()

  grafico_pib <- gerar_grafico_evolucao(
    pib_semanal,
    titulo = "Evolução semanal das expectativas do PIB Total",
    subtitulo = glue("Referência: {ANO_REF_ANUAL} | Última atualização de cada semana (últimos {JANELA_DIAS_GRAFICO} dias)")
  )
  if (!isTRUE(getOption("knitr.in.progress"))) {
    print(grafico_pib)
  }
}

grafico_cambio <- NULL
if (!is.null(cambio_raw) && nrow(cambio_raw) > 0) {
  cambio_semanal <- cambio_raw |>
    filter(DataReferencia == ANO_REF_ANUAL, baseCalculo == BASE_CALCULO) |>
    preparar_serie_semanal()

  grafico_cambio <- gerar_grafico_evolucao(
    cambio_semanal,
    titulo = "Evolução semanal das expectativas da Taxa de Câmbio",
    subtitulo = glue("Referência: {ANO_REF_ANUAL} | Última atualização de cada semana (últimos {JANELA_DIAS_GRAFICO} dias)"),
    eixo_y = "Mediana da expectativa (R$/US$)"
  )
  if (!isTRUE(getOption("knitr.in.progress"))) {
    print(grafico_cambio)
  }
}


# ==============================================================================
# 6. MONTAGEM E RENDERIZAÇÃO DO DOCUMENTO QUARTO (boletim_focus.qmd)
# ==============================================================================

gerar_documento_quarto <- function(caminho_qmd = "boletim_focus.qmd") {
  conteudo_qmd <- c(
    "---",
    'title: "Aviso Semanal Focus — Boletim Automatizado"',
    'subtitle: "REC3302 — Introdução a R (FEA-RP/USP)"',
    "format:",
    "  html:",
    "    theme: cosmo",
    "    toc: true",
    "    toc-title: \"Sumário\"",
    "    code-fold: true",
    "    embed-resources: true",
    "lang: pt-BR",
    "execute:",
    "  echo: false",
    "  warning: false",
    "  message: false",
    "---",
    "",
    "```{r setup}",
    "source('03_automatização.R')",
    "```",
    "",
    "## 1. Destaques da Semana",
    "",
    "`r textos_focus$abertura`",
    "",
    "```{r frases_automaticas, results='asis'}",
    "for (f in textos_focus$frases) {",
    "  cat(gsub('^• ', '- ', f), '\\n')",
    "}",
    "```",
    "",
    "## 2. Tabela Comparativa",
    "",
    "```{r tabela_comparativa}",
    "tabela_comparativa",
    "```",
    "",
    "## 3. Evolução Semanal das Expectativas",
    "",
    "::: {.panel-tabset}",
    "",
    "### IPCA",
    "",
    "```{r grafico_ipca, fig.width=8, fig.height=4.5}",
    "grafico_ipca",
    "```",
    "",
    "### Selic",
    "",
    "```{r grafico_selic, fig.width=8, fig.height=4.5}",
    "grafico_selic",
    "```",
    "",
    "```{r graficos_extras, results='asis', fig.width=8, fig.height=4.5}",
    "if (!is.null(grafico_pib)) {",
    "  cat('### PIB Total\\n\\n')",
    "  print(grafico_pib)",
    "  cat('\\n\\n')",
    "}",
    "if (!is.null(grafico_cambio)) {",
    "  cat('### Câmbio\\n\\n')",
    "  print(grafico_cambio)",
    "  cat('\\n\\n')",
    "}",
    "```",
    "",
    ":::",
    "",
    "## 4. Parâmetros e Ajustes Metodológicos",
    "",
    "```{r tabela_parametros}",
    "data.frame(",
    "  Parametro = c(",
    "    'Ano de referência (indicadores anuais)',",
    "    'Reunião de referência da Selic',",
    "    'Base de cálculo (0 = 30 dias, 1 = 5 dias)',",
    "    'Limite de estabilidade — taxas (p.p.)',",
    "    'Limite de estabilidade — câmbio (R$)',",
    "    'Janela histórica dos gráficos (dias)'",
    "  ),",
    "  Valor_Atual = c(",
    "    as.character(ANO_REF_ANUAL),",
    "    as.character(REUNIAO_REF_SELIC),",
    "    as.character(BASE_CALCULO),",
    "    fmt_br(LIMITE_ESTABILIDADE_PP, 2),",
    "    fmt_br(LIMITE_ESTABILIDADE_BRL, 2),",
    "    as.character(JANELA_DIAS_GRAFICO)",
    "  )",
    ") |>",
    "  gt() |>",
    "  cols_label(Parametro = 'Parâmetro configurável', Valor_Atual = 'Valor utilizado')",
    "```"
  )

  writeLines(conteudo_qmd, con = caminho_qmd, useBytes = TRUE)
  message(glue("Documento Quarto salvo em '{caminho_qmd}'."))
}

# Gera o arquivo boletim_focus.qmd quando executado fora da renderização do Quarto
if (!isTRUE(getOption("knitr.in.progress"))) {
  gerar_documento_quarto("boletim_focus.qmd")
}
