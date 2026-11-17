
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