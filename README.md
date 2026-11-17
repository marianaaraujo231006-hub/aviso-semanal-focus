## 1. Sobre o projeto

O Aviso Semanal Focus coleta as expectativas de mercado divulgadas pelo Banco Central do Brasil (Relatório Focus) e compara a divulgação mais recente com a da semana anterior, para responder à pergunta: **o que mudou nas expectativas desta semana?**

O projeto tem caráter aplicado e didático. Ele não estima modelos nem faz previsões próprias: apenas organiza e compara as expectativas já divulgadas pelo Banco Central.

Nesta etapa, o projeto trabalha com **IPCA** e **Selic**. PIB e câmbio estão previstos para etapas futuras.

## 2. Fonte dos dados

Os dados vêm do Sistema Expectativas de Mercado do Banco Central do Brasil, pelo pacote `rbcb` e pela função `get_market_expectations()`.

Indicadores e períodos de referência:

- **IPCA:** expectativa para o ano de 2026 (parâmetro `ano_ipca`).
- **Selic:** expectativa para a **próxima reunião do Copom**, escolhida automaticamente pelo código. É a reunião mais próxima no calendário entre as que ainda têm expectativas atualizadas. Quando uma reunião acontece, o código passa a usar a seguinte, sem alteração manual.

Todas as análises usam `baseCalculo == 0`, para manter a comparabilidade.

## 3. Estrutura do projeto

```
aviso-semanal-focus/
├── 00_exploracao.R
├── 01_coleta.R
├── 02_tratamento.R
├── 03_visualizacao.R
├── README.md
├── dados/
│   ├── ipca_raw.csv
│   └── selic_raw.csv
└── saidas/
    ├── comparacao_semanal.csv
    ├── tabela_comparativa.html
    ├── grafico_ipca.png
    └── grafico_selic.png
```

- `00_exploracao.R`: exploração da estrutura dos dados e verificações de qualidade (valores faltantes, repetições, intervalos entre datas, reuniões do Copom ainda ativas). Não é necessário para gerar o aviso.
- `01_coleta.R`: consulta o Banco Central e grava os dados brutos em `dados/`.
- `02_tratamento.R`: lê os dados brutos, compara as duas últimas semanas de cada indicador e grava a tabela final em `saidas/comparacao_semanal.csv`.
- `03_visualizacao.R`: lê a tabela de comparação e gera a tabela formatada e os gráficos de evolução semanal.
- `dados/`: bases brutas, sem alterações em relação ao que o Banco Central devolveu.
- `saidas/`: resultados do tratamento e da visualização, que alimentam o documento em Quarto.

## 4. Metodologia de comparação

1. Para cada indicador, o código seleciona a **última divulgação de cada semana** (semana ISO) e fica com as **duas semanas mais recentes**.
2. As duas divulgações precisam ser **consecutivas**. Se houver menos de duas semanas disponíveis, ou se as datas estiverem a mais de 10 dias uma da outra, o código emite um aviso e **não faz a comparação**.
3. A variação é a diferença entre as medianas, calculada com `lag()`:

   **Variação (p.p.) = Mediana atual − Mediana anterior**

4. A classificação usa um limiar provisório de **0,05 ponto percentual** (parâmetro `limiar_pp`):
   - **subiu:** variação maior que +0,05 p.p.
   - **caiu:** variação menor que −0,05 p.p.
   - **estável:** variação entre −0,05 e +0,05 p.p., inclusive.

A variação é arredondada em 4 casas decimais antes da classificação, para evitar erros de arredondamento do computador.

## 5. Resultado da execução

Comparação entre as divulgações de 6 e 13 de novembro de 2026:

| Indicador | Referência | Mediana anterior | Mediana atual | Variação | Tendência |
|---|---|---:|---:|---:|---|
| IPCA | 2026 | 5,2195% | 5,1082% | −0,1113 p.p. | caiu |
| Selic | R8/2026 | 13,75% | 13,75% | 0,0000 p.p. | estável |

Estes números correspondem à execução registrada acima e podem não refletir as expectativas mais recentes. Para atualizar, execute os scripts novamente (seção 7).

## 6. Validação

A lógica foi testada com semanas passadas, usando `data_corte <- "2026-10-23"`. Na comparação entre 16 e 23 de outubro de 2026, o IPCA 2026 passou de 5,2190% para 5,1891% (variação de −0,0299 p.p., classificada como estável), valores iguais aos da primeira versão do projeto. Nessa data, a reunião da Selic escolhida foi a `R7/2026`.

A conferência dos números com o site do Banco Central será feita na etapa de validação do projeto.

## 7. Requisitos e como executar

É necessário ter o R instalado. A coleta precisa de acesso à internet. Os pacotes usados em cada etapa:

| Etapa | Pacotes |
|---|---|
| `01_coleta.R` | `rbcb`, `dplyr` |
| `02_tratamento.R` | `dplyr` |
| `03_visualizacao.R` | `dplyr`, `gt`, `ggplot2` |

Instale os pacotes uma vez, no Console do R:

```r
install.packages(c("rbcb", "dplyr", "gt", "ggplot2"))
```

Execute os scripts a partir da pasta do projeto, nesta ordem:

```r
source("01_coleta.R")         # coleta e salva os dados em dados/
source("02_tratamento.R")     # compara as semanas e salva em saidas/
source("03_visualizacao.R")   # gera a tabela formatada e os gráficos
```

Quem só quiser gerar o aviso com os dados que já estão no repositório pode pular o `01_coleta.R` e não precisa do pacote `rbcb`.

Para testar a lógica com uma data passada, edite o parâmetro `data_corte` no início do `02_tratamento.R` (por exemplo, `"2026-10-23"`). Com `NULL`, o script usa a última data disponível.

## 8. Observações sobre os dados

- A base do IPCA tem uma coluna `IndicadorDetalhe` que vem vazia da fonte. Ela não é usada.
- As bases contêm uma linha por dia útil. Nas verificações realizadas (`00_exploracao.R`), não há linhas repetidas nem semanas sem divulgação.

## 9. Limitações da etapa atual

O projeto está em desenvolvimento. A etapa atual cobre a coleta, a comparação e a visualização de IPCA e Selic. O limiar de 0,05 p.p. é provisório e pode ser revisto após a validação metodológica. A geração do texto automático e do documento em Quarto, a inclusão de PIB e câmbio e a validação com as publicações oficiais dependem das próximas etapas.

## 10. Referências

Banco Central do Brasil. Sistema Expectativas de Mercado — dados do Relatório Focus.

Pacote R `rbcb`: consulta de dados econômicos do Banco Central do Brasil.
=======
# Aviso Semanal Focus

Projeto desenvolvido para a disciplina **REC3302 — Introdução a R**, da Faculdade de Economia, Administração e Contabilidade de Ribeirão Preto (FEA-RP/USP).

## 1. Sobre o projeto

O Aviso Semanal Focus tem como objetivo coletar, organizar, comparar e automatizar a comunicação das expectativas de mercado divulgadas pelo Banco Central do Brasil, a fim de identificar mudanças nas projeções econômicas entre divulgações semanais e gerar um boletim econômico reprodutível.

O projeto processa dados de expectativas para o **IPCA** e a **taxa Selic**, além de permitir a ampliação automática para o **PIB Total** e a **taxa de Câmbio**. Todo o fluxo é realizado em R e consolidado em um documento Quarto (`boletim_focus.qmd`) com textos analíticos gerados dinamicamente via `glue()`, tabela comparativa e gráficos de evolução semanal.

## 2. Fonte dos dados

Os dados são obtidos do Sistema Expectativas de Mercado do Banco Central do Brasil, por meio do pacote `rbcb` e da função `get_market_expectations()`.

**Documentação da API do Banco Central — Expectativas de Mercado:**

https://olinda.bcb.gov.br/olinda/servico/Expectativas/versao/v1/documentacao#ExpectativasMercadoAnuais

**Indicadores trabalhados:**

- **IPCA:** expectativas de inflação para o ano de referência de 2026 (`%`).
- **Selic:** expectativas para a reunião do Copom identificada como `R6/2028` (`%`).
- **PIB Total (ampliação):** expectativas de crescimento do PIB para o ano de referência de 2026 (`%`).
- **Câmbio (ampliação):** expectativas para a taxa de câmbio ao final do ano de referência de 2026 (`R$/US$`).

Para manter a comparabilidade entre as observações, as análises utilizam por padrão `baseCalculo == 0` (podendo ser ajustado nos parâmetros do script de automatização).

## 3. Estrutura do projeto

```text
aviso-semanal-focus/
├── 01_coleta.R
├── 02_tratamento.R
├── 03_automatização.R
├── boletim_focus.qmd
├── README.md
└── dados/
    ├── ipca_raw.csv
    ├── selic_raw.csv
    ├── pib_raw.csv       
    └── cambio_raw.csv    
```

### Descrição dos arquivos

- `01_coleta.R`: consulta as expectativas de mercado do Banco Central e salva os dados brutos de IPCA e Selic em arquivos CSV.
- `02_tratamento.R`: importa os arquivos coletados, organiza as observações por semana, compara as medianas das expectativas, calcula as variações, gera uma tabela comparativa e constrói gráficos de evolução semanal.
- `03_automatização.R`: centraliza parâmetros de ajuste rápido (feedback da sala), amplia a coleta e o tratamento para PIB Total e Câmbio, gera textos e frases analíticas automáticas com `glue()`, consolida a tabela comparativa e os gráficos, e monta o documento Quarto (`boletim_focus.qmd`).
- `boletim_focus.qmd`: documento Quarto que integra as frases automáticas, a tabela comparativa (`gt`), os gráficos em abas interativas (`ggplot2`) e o quadro de parâmetros metodológicos.
- `dados/ipca_raw.csv`: base bruta de expectativas do IPCA.
- `dados/selic_raw.csv`: base bruta de expectativas da Selic.
- `dados/pib_raw.csv` e `dados/cambio_raw.csv`: bases brutas de PIB Total e Câmbio coletadas complementarmente pelo script de automatização.

## 4. Metodologia de tratamento, comparação e automatização

A análise considera as duas semanas mais recentes com dados disponíveis para cada indicador.

Para identificar as observações utilizadas na comparação, os scripts:

1. Importam os arquivos CSV e convertem a variável `Data` para o formato de data.
2. Identificam as semanas de divulgação utilizando o padrão de semana e ano (`%G-%V`).
3. Selecionam a data mais recente disponível dentro de cada semana.
4. Ordenam as semanas e selecionam as duas mais recentes para realizar a comparação.

Dessa forma, a seleção não depende obrigatoriamente de uma divulgação em um dia específico da semana. É utilizada a última observação disponível em cada uma das semanas selecionadas.

### 4.1. Cálculo das variações

A variação da mediana é calculada pela diferença entre a mediana da divulgação mais recente e a mediana da divulgação anterior:

**Variação = Mediana atual − Mediana anterior**

- Para IPCA, Selic e PIB Total, a variação é expressa em **pontos percentuais (p.p.)**.
- Para a taxa de Câmbio, a variação é expressa em **R$/US$**.

O script também calcula a variação do número de respondentes:

**Variação de respondentes = Respondentes atuais − Respondentes anteriores**

### 4.2. Classificação das expectativas

Por padrão, a classificação utiliza os seguintes limites de estabilidade (configuráveis em `03_automatização.R`):

- **Indicadores em taxa (IPCA, Selic e PIB Total) — limite de 0,05 p.p.:**
  - **Subiu:** variação superior a +0,05 p.p.
  - **Caiu:** variação inferior a −0,05 p.p.
  - **Estável:** variação entre −0,05 p.p. e +0,05 p.p., inclusive.
- **Taxa de Câmbio — limite de R$ 0,02:**
  - **Subiu:** variação superior a +R$ 0,02.
  - **Caiu:** variação inferior a −R$ 0,02.
  - **Estável:** variação entre −R$ 0,02 e +R$ 0,02, inclusive.

### 4.3. Geração de frases automáticas com `glue()`

No script `03_automatização.R`, as funções `gerar_frase_indicador()` e `gerar_textos_boletim()` utilizam o pacote `glue` (`glue()` e `glue_collapse()`) para transformar os resultados numéricos da tabela de resumo em frases analíticas padronizadas em português (com formatação decimal brasileira).

Para cada indicador, o texto gerado informa automaticamente:

- Indicador e período/reunião de referência;
- Datas e semanas das divulgações comparadas;
- Comportamento da expectativa (`apresentou alta`, `apresentou queda` ou `manteve-se estável`);
- Mediana anterior, mediana atual e variação no período;
- Evolução do número de instituições respondentes.

### 4.4. Organização da tabela comparativa

Os resultados consolidados são apresentados em uma tabela formatada com o pacote `gt`, contendo:

- Indicador e período de referência;
- Semana e data da divulgação anterior e atual;
- Mediana anterior e mediana atual;
- Número de respondentes em cada divulgação;
- Variação da mediana e variação do número de respondentes;
- Classificação da tendência.

### 4.5. Parâmetros ajustáveis (Feedback da Sala)

Na seção inicial de `03_automatização.R`, foram isolados parâmetros globais para permitir ajustes rápidos a partir das discussões e sugestões em sala de aula:

- `ANO_REF_ANUAL`: ano de referência para IPCA, PIB Total e Câmbio (padrão `"2026"`);
- `REUNIAO_REF_SELIC`: reunião do Copom para a Selic (padrão `"R6/2028"`);
- `BASE_CALCULO`: base de cálculo do Focus (`0` para 30 dias; `1` para 5 dias);
- `LIMITE_ESTABILIDADE_PP` e `LIMITE_ESTABILIDADE_BRL`: limites para classificação de tendência;
- `JANELA_DIAS_GRAFICO`: horizonte histórico exibido nos gráficos semanais (padrão `180` dias);
- `INCLUIR_PIB_CAMBIO`: chave lógica (`TRUE`/`FALSE`) para incluir ou ocultar PIB Total e Câmbio;
- `COR_LINHA_GRAFICO` e `COR_PONTO_GRAFICO`: personalização visual dos gráficos.

## 5. Visualização da evolução semanal

Os scripts `02_tratamento.R` e `03_automatização.R` constroem gráficos de evolução semanal com o pacote `ggplot2`:

- **Gráfico do IPCA:** evolução semanal das expectativas de inflação para 2026.
- **Gráfico da Selic:** evolução semanal das expectativas para a reunião R6/2028.
- **Gráfico do PIB Total:** evolução semanal das expectativas de crescimento do PIB para 2026.
- **Gráfico do Câmbio:** evolução semanal das expectativas para a taxa de câmbio (R$/US$) em 2026.

Nos gráficos são considerados os últimos 180 dias disponíveis na base, selecionando-se a observação de data mais recente dentro de cada semana.

## 6. Resultados da execução

Na comparação entre 16 e 23 de outubro de 2026, os arquivos locais de IPCA e Selic produziram os seguintes resultados:

| Indicador | Mediana anterior | Mediana atual | Variação | Classificação |
|---|---:|---:|---:|---|
| IPCA — referência 2026 | 5,2190% | 5,1891% | −0,0299 p.p. | Estável |
| Selic — R6/2028 | 10,50% | 10,25% | −0,25 p.p. | Caiu |

**Variação do número de respondentes:**

- **IPCA:** aumento de 5 respondentes, de 137 para 142.
- **Selic:** aumento de 10 respondentes, de 95 para 105.

*(Ao executar `03_automatização.R` com conexão à internet, a tabela e as frases passam a incorporar também os resultados atualizados de **PIB Total** e **Câmbio**).*

## 7. Requisitos e dependências

O projeto utiliza os seguintes pacotes:

| Pacote | Finalidade |
|---|---|
| `rbcb` | Consulta às expectativas de mercado do Banco Central. |
| `dplyr` | Manipulação, organização e tratamento dos dados. |
| `gt` | Construção e formatação da tabela comparativa. |
| `ggplot2` | Construção dos gráficos de evolução semanal. |
| `glue` | Geração de textos e frases analíticas automáticas. |
| `quarto` | *(Opcional)* Renderização programática do boletim em HTML via R. |

Para instalar os pacotes necessários, execute no R:

```r
install.packages(c("rbcb", "dplyr", "gt", "ggplot2", "glue", "quarto"))
```

## 8. Como executar o projeto

Os scripts devem ser executados na ordem apresentada abaixo.

### 8.1. Coleta dos dados

No Positron / RStudio, execute:

```r
source("01_coleta.R")
```

Esse script consulta as expectativas de mercado do Banco Central e grava os arquivos CSV iniciais (`ipca_raw.csv` e `selic_raw.csv`) na pasta `dados/`.

### 8.2. Tratamento e comparação inicial

Após a coleta, execute:

```r
source("02_tratamento.R")
```

### 8.3. Automatização, frases com `glue()` e documento Quarto

Em seguida, execute:

```r
source("03_automatização.R")
```

Esse script:

1. Coleta automaticamente os dados de **PIB Total** e **Câmbio** (caso ainda não estejam salvos em `dados/`);
2. Calcula as variações e tendências para todos os indicadores ativos;
3. Imprime no console a síntese e as frases automáticas geradas com `glue()`;
4. Gera a tabela comparativa consolidada (`gt`) e os gráficos semanais (`ggplot2`);
5. Monta e atualiza o arquivo `boletim_focus.qmd`.

Para gerar o relatório final em HTML, abra o arquivo `boletim_focus.qmd` no Positron ou RStudio e clique em **Render** (ou execute `quarto::quarto_render("boletim_focus.qmd")` no console).

## 9. Implementações realizadas

Até esta etapa, foram implementadas as seguintes funcionalidades:

- Coleta das expectativas de mercado de IPCA, Selic, PIB Total e Câmbio por meio da API do Banco Central;
- Armazenamento das bases brutas em arquivos CSV na pasta `dados/`;
- Identificação das duas semanas mais recentes com observações disponíveis e seleção da última divulgação de cada semana;
- Cálculo da variação das medianas e do número de respondentes;
- Classificação automática das alterações nas expectativas com limites parametrizáveis;
- Geração automática de frases analíticas e resumo executivo utilizando `glue()`;
- Geração de tabela comparativa formatada (`gt`) e gráficos de evolução semanal (`ggplot2`);
- Montagem de documento Quarto (`boletim_focus.qmd`) com abas para visualização do boletim completo;
- Estruturação de bloco de parâmetros no início do script para incorporação imediata de ajustes e feedbacks da sala.

## 10. Referências

BANCO CENTRAL DO BRASIL. **Sistema Expectativas de Mercado**. Dados do Relatório Focus. Disponível em: https://www.bcb.gov.br.

BANCO CENTRAL DO BRASIL. **API de Expectativas de Mercado**. Documentação da API Olinda. Disponível em: https://olinda.bcb.gov.br/olinda/servico/Expectativas/versao/v1/documentacao.

PACOTE `rbcb`. Consulta de dados econômicos do Banco Central do Brasil.
>>>>>>> ca13494ed632a7baba2a11bb94cfc5d363476b25
