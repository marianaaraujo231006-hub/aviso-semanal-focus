# Aviso Semanal Focus

Projeto desenvolvido para a disciplina **REC3302 — Introdução a R**, da Faculdade de Economia, Administração e Contabilidade de Ribeirão Preto (FEA-RP/USP).

## 1. Sobre o projeto

O Aviso Semanal Focus tem como objetivo coletar, organizar e comparar as expectativas de mercado divulgadas pelo Banco Central do Brasil a fins de identificar mudanças nas projeções econômicas entre divulgações semanais consecutivas.

Nesta etapa o projeto utiliza dados de expectativas para o IPCA e a taxa Selic. O processamento é realizado em R, com a finalidade de padronizar as comparações e fornecer informações que poderão subsidiar a elaboração de um boletim econômico semanal.

## 2. Fonte dos dados

Os dados são obtidos do Sistema Expectativas de Mercado do Banco Central do Brasil, por meio do pacote `rbcb` e da função `get_market_expectations()`.

Indicadores trabalhados:

- **IPCA:** expectativas de inflação para o ano de referência de 2026.
- **Selic:** expectativas para a reunião do Copom identificada como `R6/2028`.

Para manter a comparabilidade, as análises utilizam `baseCalculo == 0`.

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
- `02_tratamento.R`: importa os arquivos coletados, identifica as duas últimas sextas-feiras disponíveis para cada indicador e compara as medianas das expectativas.
- `dados/ipca_raw.csv`: base bruta de expectativas do IPCA.
- `dados/selic_raw.csv`: base bruta de expectativas da Selic.

## 4. Metodologia de comparação

A análise considera duas divulgações semanais consecutivas para o mesmo indicador e período de referência.

A variação é calculada pela diferença entre a mediana da divulgação mais recente e a mediana da divulgação anterior:

**Variação = Mediana atual − Mediana anterior**

A classificação utiliza um limite provisório de 0,05 ponto percentual:

- **Subiu:** variação superior a +0,05 p.p.
- **Caiu:** variação inferior a −0,05 p.p.
- **Estável:** variação entre −0,05 p.p. e +0,05 p.p., inclusive.

Na primeira observação da comparação, a variação não é calculada por não existir uma observação anterior dentro do conjunto selecionado.

## 5. Resultados da execução

Na comparação entre 16 e 23 de outubro de 2026, os arquivos locais produziram os seguintes resultados:

| Indicador | Mediana anterior | Mediana atual | Variação | Classificação |
|---|---:|---:|---:|---|
| IPCA — referência 2026 | 5,2190% | 5,1891% | −0,0299 p.p. | Estável |
| Selic — R6/2028 | 10,50% | 10,25% | −0,25 p.p. | Caiu |

Os resultados são referentes à execução registrada nessa etapa e não representam necessariamente as expectativas mais recentes disponíveis.

## 6. Requisitos

Para executar os scripts, é necessário ter o R instalado e acesso à internet para consultar a fonte de dados.

O script de coleta utiliza os pacotes `rbcb` e `dplyr`. O script de tratamento utiliza `dplyr`.

Instale os pacotes necessários no R:

```r
install.packages(c("rbcb", "dplyr"))
```

## 7. Como executar

Execute os scripts a partir do diretório principal do projeto, nesta ordem:

**1. Coleta dos dados**

```r
source("01_coleta.R")
```

Esse script consulta as expectativas de mercado e grava os arquivos CSV na pasta `dados/`.

**2. Tratamento e comparação**

```r
source("02_tratamento.R")
```

Esse script importa os arquivos CSV e apresenta as tabelas de comparação do IPCA e da Selic no console.

A coleta deve ser executada antes do tratamento para garantir que os arquivos utilizados estejam disponíveis e atualizados.

## 8. Limitações da etapa atual

O projeto encontra-se em desenvolvimento. A implementação documentada contempla a coleta e a comparação das expectativas de mercado de dois indicadores.

A classificação utiliza um limite provisório de 0,05 p.p., que poderá ser revisto após a validação metodológica. A interpretação econômica dos resultados, a elaboração do boletim e outras funcionalidades previstas dependem das próximas etapas de desenvolvimento.

## 9. Referência

Banco Central do Brasil. Sistema Expectativas de Mercado — dados do Relatório Focus.

Pacote R `rbcb`: consulta de dados econômicos do Banco Central do Brasil.
