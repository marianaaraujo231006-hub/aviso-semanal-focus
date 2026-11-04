# Aviso Semanal Focus

Projeto desenvolvido para a disciplina **REC3302 — Introdução a R**, da Faculdade de Economia, Administração e Contabilidade de Ribeirão Preto (FEA-RP/USP).

## 1. Sobre o projeto

O Aviso Semanal Focus tem como objetivo coletar, organizar e comparar as expectativas de mercado divulgadas pelo Banco Central do Brasil, a fim de identificar mudanças nas projeções econômicas entre divulgações semanais.

Nesta etapa, o projeto utiliza dados de expectativas para o IPCA e a taxa Selic. O processamento é realizado em R, com a finalidade de padronizar as comparações e fornecer informações que poderão subsidiar a elaboração de um boletim econômico semanal.

## 2. Fonte dos dados

Os dados são obtidos do Sistema Expectativas de Mercado do Banco Central do Brasil, por meio do pacote `rbcb` e da função `get_market_expectations()`.

**Documentação da API do Banco Central — Expectativas de Mercado:**

https://olinda.bcb.gov.br/olinda/servico/Expectativas/versao/v1/documentacao#ExpectativasMercadoAnuais

**Indicadores trabalhados:**

- **IPCA:** expectativas de inflação para o ano de referência de 2026.
- **Selic:** expectativas para a reunião do Copom identificada como `R6/2028`.

Para manter a comparabilidade entre as observações, as análises utilizam `baseCalculo == 0`.

## 3. Estrutura do projeto

```text
aviso-semanal-focus/
├── 01_coleta.R
├── 02_tratamento.R
├── README.md
└── dados/
    ├── ipca_raw.csv
    └── selic_raw.csv
```

### Descrição dos arquivos

- `01_coleta.R`: consulta as expectativas de mercado do Banco Central e salva os dados brutos de IPCA e Selic em arquivos CSV.
- `02_tratamento.R`: importa os arquivos coletados, organiza as observações por semana, compara as medianas das expectativas, calcula as variações, gera uma tabela comparativa e constrói gráficos de evolução semanal.
- `dados/ipca_raw.csv`: base bruta de expectativas do IPCA.
- `dados/selic_raw.csv`: base bruta de expectativas da Selic.

Os arquivos CSV preservam os dados coletados, enquanto o script de tratamento realiza as operações necessárias para a análise.

## 4. Metodologia de tratamento e comparação

A análise considera as duas semanas mais recentes com dados disponíveis para cada indicador.

Para identificar as observações utilizadas na comparação, o script:

1. Importa os arquivos CSV e converte a variável `Data` para o formato de data.
2. Identifica as semanas de divulgação utilizando o padrão de semana e ano (`%G-%V`).
3. Seleciona a data mais recente disponível dentro de cada semana.
4. Ordena as semanas e seleciona as duas mais recentes para realizar a comparação.

Dessa forma, a seleção não depende obrigatoriamente de uma divulgação em um dia específico da semana. É utilizada a última observação disponível em cada uma das semanas selecionadas.

### 4.1. Cálculo das variações

A variação da mediana é calculada pela diferença entre a mediana da divulgação mais recente e a mediana da divulgação anterior:

**Variação (p.p.) = Mediana atual − Mediana anterior**

O script também calcula a variação do número de respondentes:

**Variação de respondentes = Respondentes atuais − Respondentes anteriores**

### 4.2. Classificação das expectativas

A classificação utiliza um limite provisório de 0,05 ponto percentual:

- **Subiu:** variação superior a +0,05 p.p.
- **Caiu:** variação inferior a −0,05 p.p.
- **Estável:** variação entre −0,05 p.p. e +0,05 p.p., inclusive.

A classificação é aplicada à variação da mediana das expectativas.

Na primeira observação da comparação, a variação não é calculada por não existir uma observação anterior dentro do conjunto selecionado.

### 4.3. Organização dos resultados

Após os cálculos, o script organiza os resultados em uma tabela comparativa, utilizando o pacote `gt`.

A tabela apresenta:

- Indicador e período de referência;
- Semana e data da divulgação anterior;
- Semana e data da divulgação atual;
- Mediana anterior e mediana atual;
- Número de respondentes em cada divulgação;
- Variação da mediana em pontos percentuais;
- Variação do número de respondentes;
- Classificação da tendência.

## 5. Visualização da evolução semanal

Além da comparação entre as duas semanas mais recentes, o script `02_tratamento.R` gera dois gráficos de evolução das expectativas:

- **Gráfico do IPCA:** apresenta a evolução semanal das expectativas de inflação para 2026.
- **Gráfico da Selic:** apresenta a evolução semanal das expectativas para a reunião R6/2028.

Os gráficos são construídos com o pacote `ggplot2`, utilizando:

- A data da divulgação no eixo horizontal;
- A mediana da expectativa no eixo vertical;
- Linhas para representar a evolução das expectativas;
- Pontos para identificar cada observação semanal.

Para essa visualização, são considerados os últimos 180 dias disponíveis na base. Dentro de cada semana, é selecionada a observação de data mais recente.

## 6. Resultados da execução

Na comparação entre 16 e 23 de outubro de 2026, os arquivos locais produziram os seguintes resultados:

| Indicador | Mediana anterior | Mediana atual | Variação | Classificação |
|---|---:|---:|---:|---|
| IPCA — referência 2026 | 5,2190% | 5,1891% | −0,0299 p.p. | Estável |
| Selic — R6/2028 | 10,50% | 10,25% | −0,25 p.p. | Caiu |

**Variação do número de respondentes:**

- **IPCA:** aumento de 5 respondentes, de 137 para 142.
- **Selic:** aumento de 10 respondentes, de 95 para 105.

Os resultados são referentes à execução registrada nesta etapa e não representam necessariamente as expectativas mais recentes disponíveis.

## 7. Requisitos e dependências

O projeto utiliza os seguintes pacotes:

| Pacote | Finalidade |
|---|---|
| `rbcb` | Consulta às expectativas de mercado do Banco Central. |
| `dplyr` | Manipulação, organização e tratamento dos dados. |
| `gt` | Construção e formatação da tabela comparativa. |
| `ggplot2` | Construção dos gráficos de evolução semanal. |

Para instalar os pacotes necessários, execute no R:

```r
install.packages(c("rbcb", "dplyr", "gt", "ggplot2"))
```

A instalação precisa ser realizada apenas uma vez no ambiente R, salvo necessidade de reinstalação.

## 8. Como executar o projeto

Os scripts devem ser executados na ordem apresentada abaixo.

### 8.1. Coleta dos dados

No Positron, execute:

```r
source("01_coleta.R")
```

Esse script consulta as expectativas de mercado do Banco Central e grava os arquivos CSV na pasta `dados/`.

### 8.2. Tratamento e comparação

Após a coleta, execute:

```r
source("02_tratamento.R")
```

Esse script importa os arquivos CSV e realiza o tratamento das bases. Ao final da execução, são geradas:

- As tabelas de comparação semanal do IPCA e da Selic;
- A tabela comparativa formatada com `gt`;
- O gráfico de evolução semanal do IPCA;
- O gráfico de evolução semanal da Selic.

A coleta deve ser executada antes do tratamento para garantir que os arquivos utilizados estejam disponíveis e atualizados.

## 9. Implementações realizadas e próximas etapas

O projeto encontra-se em desenvolvimento. Até esta etapa, foram implementadas as seguintes funcionalidades:

- Coleta das expectativas de mercado do IPCA e da Selic por meio da API do Banco Central;
- Armazenamento das bases brutas em arquivos CSV;
- Identificação das duas semanas mais recentes com observações disponíveis;
- Seleção da última divulgação disponível em cada semana;
- Cálculo da variação das medianas e do número de respondentes;
- Classificação automática das alterações nas expectativas;
- Geração de tabela comparativa formatada;
- Construção de gráficos de evolução semanal dos indicadores.

**Observações metodológicas:** a classificação utiliza um limite provisório de 0,05 p.p., que poderá ser revisto após a validação metodológica. A utilização de `baseCalculo == 0` também integra os critérios experimentais adotados nesta etapa.

**Próximas etapas previstas:**

- Aprimoramento da metodologia de tratamento e comparação;
- Desenvolvimento da interpretação econômica dos resultados;
- Elaboração do boletim econômico semanal;
- Implementação de outras funcionalidades previstas para o projeto.

A interpretação econômica e a elaboração do boletim ainda não fazem parte das funcionalidades implementadas nesta versão.

## 10. Referências

BANCO CENTRAL DO BRASIL. **Sistema Expectativas de Mercado**. Dados do Relatório Focus. Disponível em: https://www.bcb.gov.br.

BANCO CENTRAL DO BRASIL. **API de Expectativas de Mercado**. Documentação da API Olinda. Disponível em: https://olinda.bcb.gov.br/olinda/servico/Expectativas/versao/v1/documentacao.

PACOTE `rbcb`. Consulta de dados econômicos do Banco Central do Brasil.