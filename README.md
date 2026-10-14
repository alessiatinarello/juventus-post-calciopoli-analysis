# From Rebuild to Decline: What Drove Juventus' Performance After Calciopoli (2006–2025)

An econometric analysis in R of how **sporting**, **financial** and **managerial/structural** factors relate to Juventus' league points in the 19 seasons following the 2006 Calciopoli scandal (2006/07 – 2024/25).

## Research question

Which sporting, financial and structural variables influenced Juventus' Serie A performance after Calciopoli, and to what extent did each one contribute to the results achieved in the different phases of the club's sporting cycle?

## Data

One observation per season (n = 19), built from three datasets merged on the season key (`stagione`, format `YYYY/YY`).

| Block | Variables | Sources |
|---|---|---|
| **Sporting** | Serie A points (dependent variable), goal difference, mean/median squad market value, mean/median squad age, RRCI, coaching change (dummy) | Lega Serie A, FBref, Transfermarkt |
| **Financial** | Total revenue, matchday revenue, commercial revenue, wage bill, squad amortisation, player trading gains, net result | Juventus annual financial reports |
| **Managerial / structural** (dummies) | Ownership/board instability, infrastructure investment (stadium, Continassa), extraordinary events (penalties, UEFA sanctions, Covid) | Official club communications, UEFA regulations, financial reports |

**RRCI (Roster Renewal Cost Index)**: year-on-year percentage change in squad cost, where squad cost = player amortisation + player wages.

Median values (age, market value) are used instead of means to limit the effect of outliers.

## Method

1. **Data cleaning**: harmonising number formats (thousands separators, decimal commas, non-standard minus signs, percentages), recoding missing values, aligning season formats across sources
2. **Merge**: inner joins on season, with consistency checks
3. **Three nested OLS models** (block-wise robustness strategy):
   - **Model 1**: sporting variables
   - **Model 2**: + financial variables
   - **Model 3**: + managerial/structural variables
4. **Model comparison**: observed vs. fitted points across specifications
5. **Standardised coefficients**: relative influence of each variable

## Key results

| | Model 1 | Model 2 | Model 3 |
|---|---|---|---|
| R² | 0.56 | 0.75 | 0.82 |
| Adjusted R² | 0.43 | 0.59 | 0.60 |
| F-test p-value | 0.016 | 0.012 | 0.038 |
| Significant at 5% | RRCI (+) | Median age (+) | Median age (+) |

- Each block of variables improves explanatory power, even after adjusting for the number of regressors.
- **Median squad age** is the most stable predictor: once financial variables are controlled for, more experienced squads are associated with more points.
- Financial and managerial variables are not individually significant, suggesting an **indirect or delayed** effect on performance.
- In the standardised model, the **wage bill** and **median age** show the strongest positive association with points; squad amortisation, total revenue and board instability show negative associations.
- Read descriptively, the data show a **cyclical pattern**: a weak post-relegation phase, a growth phase from 2011/12 (new stadium, rising squad value, technical and managerial stability) and a recent phase of volatility, coaching changes, penalties and board instability.

## Limitations and next steps

With 19 observations and up to 10 regressors, statistical power is limited, so the coefficients should be read as **exploratory indications** of direction and relative intensity, not causal evidence. The 2006/07 season (played in Serie B, coded as 0 Serie A points) is an influential outlier.

Natural extensions: **match-level or intra-season data**, a **panel of several clubs**, or a more parsimonious set of regressors.

## How to run

```r
install.packages(c("dplyr", "ggplot2", "tidyr"))
source("analisi_performance_serie_a.R")
```

The script expects three CSV files in a `data/` folder:
`variabili_sportive.csv`, `variabili_economiche.csv`, `variabili_gestionali_strutturali.csv`.

## Tools

R · dplyr · tidyr · ggplot2 · OLS regression

## Author

**Alessia Tinarello** — Football Data Analyst & Match Analyst
