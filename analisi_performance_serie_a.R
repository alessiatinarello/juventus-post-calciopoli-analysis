# =============================================================================
# Determinanti della performance in Serie A
# Variabili sportive, economiche e gestionali/strutturali a confronto
#
# Unità di analisi: stagione di Serie A
# Metodo: regressione lineare (OLS) con tre specificazioni progressive
# =============================================================================

library(dplyr)
library(ggplot2)
library(tidyr)

# -----------------------------------------------------------------------------
# 1. Caricamento dei dati
# I file CSV vanno inseriti nella cartella "data/" del progetto
# -----------------------------------------------------------------------------

variabili_gestionali_strutturali <- read.csv("data/variabili_gestionali_strutturali.csv")
variabili_sportive               <- read.csv("data/variabili_sportive.csv")
variabili_economiche             <- read.csv("data/variabili_economiche.csv")

# Esplorazione della struttura dei tre data frame per verificare tipologia delle
# variabili, numero di osservazioni e coerenza dell'unità di analisi
str(variabili_economiche)
str(variabili_sportive)
str(variabili_gestionali_strutturali)

# Controllo delle variabili di tipo character
sapply(variabili_sportive, class)
sapply(variabili_economiche, class)
sapply(variabili_gestionali_strutturali, class)

# -----------------------------------------------------------------------------
# 2. Pulizia e ricodifica delle variabili sportive
# -----------------------------------------------------------------------------

# Rinomina colonne (es. età media ed età mediana) per semplificazione
names(variabili_sportive) <- gsub("\\._", "_", names(variabili_sportive))

# Rinomina della variabile dipendente per semplificazione
names(variabili_sportive)[names(variabili_sportive) == "punti_serie_a"] <- "punti"
names(variabili_sportive)

cols_sport <- c(
  "punti", "differenza_reti", "valore_di_mercato_medio",
  "valore_di_mercato_mediano", "eta_media", "eta_mediana",
  "RRCI", "numero_cambi_allenatore"
)

# Sostituzione dei segni meno non standard con il meno standard
variabili_sportive[cols_sport] <- lapply(
  variabili_sportive[cols_sport],
  function(x) gsub("[\u2013\u2014]", "-", x)
)

# Rimozione dei punti delle migliaia (non dei decimali)
variabili_sportive[cols_sport] <- lapply(
  variabili_sportive[cols_sport],
  function(x) gsub("\\.(?=\\d{3}(\\D|$))", "", x, perl = TRUE)
)

# Rimozione del simbolo percentuale (mantenendo la scala 0-100)
variabili_sportive$RRCI <- gsub("%", "", variabili_sportive$RRCI)

# Conversione delle virgole decimali in punti
variabili_sportive[cols_sport] <- lapply(
  variabili_sportive[cols_sport],
  function(x) gsub(",", ".", x)
)

# Ricodifica di valori testuali non numerici come NA
variabili_sportive[cols_sport] <- lapply(
  variabili_sportive[cols_sport],
  function(x) ifelse(x %in% c("", "n.d.", "NA", "-"), NA, x)
)

# Conversione finale in formato numerico
variabili_sportive[cols_sport] <- lapply(variabili_sportive[cols_sport], as.numeric)

str(variabili_sportive[, cols_sport])
summary(variabili_sportive[, cols_sport])

# -----------------------------------------------------------------------------
# 3. Pulizia e ricodifica delle variabili economiche
# -----------------------------------------------------------------------------

# Colonne economiche da ricodificare (esclusa 'stagione')
cols_econ <- c(
  "ricavi_totali", "ricavi_da_stadio", "ricavi_commerciali",
  "spese_per_stipendi", "ammortamenti_rosa", "plusvalenze", "risultato_netto"
)

# Sostituzione dei segni meno non standard con il meno standard
variabili_economiche[cols_econ] <- lapply(
  variabili_economiche[cols_econ],
  function(x) gsub("[\u2013\u2014]", "-", x)
)

# Rimozione dei punti delle migliaia (non dei decimali)
variabili_economiche[cols_econ] <- lapply(
  variabili_economiche[cols_econ],
  function(x) gsub("\\.(?=\\d{3}(\\D|$))", "", x, perl = TRUE)
)

# Conversione delle virgole decimali in punti
variabili_economiche[cols_econ] <- lapply(
  variabili_economiche[cols_econ],
  function(x) gsub(",", ".", x)
)

# Ricodifica di valori testuali non numerici come NA
variabili_economiche[cols_econ] <- lapply(
  variabili_economiche[cols_econ],
  function(x) ifelse(x %in% c("", "n.d.", "NA", "-"), NA, x)
)

# Conversione finale in formato numerico
variabili_economiche[cols_econ] <- lapply(variabili_economiche[cols_econ], as.numeric)

str(variabili_economiche[, c("stagione", cols_econ)])
summary(variabili_economiche[, cols_econ])

# -----------------------------------------------------------------------------
# 4. Armonizzazione della chiave 'stagione' (formato "2019/20")
# -----------------------------------------------------------------------------

unique(variabili_economiche$stagione)

variabili_economiche$stagione <- paste0(
  variabili_economiche$stagione - 1, "/",
  substr(variabili_economiche$stagione, 3, 4)
)
head(variabili_economiche$stagione)

# -----------------------------------------------------------------------------
# 5. Statistiche descrittive e controllo dei valori mancanti
# -----------------------------------------------------------------------------

summary(variabili_sportive)
summary(variabili_economiche)
summary(variabili_gestionali_strutturali)

colSums(is.na(variabili_sportive))
colSums(is.na(variabili_economiche))
colSums(is.na(variabili_gestionali_strutturali))

# -----------------------------------------------------------------------------
# 6. Merge dei tre data frame
# -----------------------------------------------------------------------------

# Controllo di coerenza delle stagioni prima del merge
setdiff(variabili_sportive$stagione, variabili_economiche$stagione)
setdiff(variabili_economiche$stagione, variabili_sportive$stagione)
setdiff(variabili_sportive$stagione, variabili_gestionali_strutturali$stagione)

# Prima si uniscono variabili sportive ed economiche: quelle sportive contengono
# la performance, che è il cuore dell'analisi
dataset_temp <- variabili_sportive %>%
  inner_join(variabili_economiche, by = "stagione")

dim(dataset_temp)

# Merge con le variabili gestionali/strutturali
dataset_finale <- dataset_temp %>%
  inner_join(variabili_gestionali_strutturali, by = "stagione")

dim(dataset_finale)
str(dataset_finale)
colSums(is.na(dataset_finale))

saveRDS(dataset_finale, "dataset_finale.rds")

summary(dataset_finale)

# -----------------------------------------------------------------------------
# 7. Modello 1 - Variabili sportive
# Si usano età mediana e valore di mercato mediano per limitare l'effetto
# degli outlier
# -----------------------------------------------------------------------------

mod_1 <- lm(
  punti ~ eta_mediana + valore_di_mercato_mediano + RRCI + numero_cambi_allenatore,
  data = dataset_finale
)
summary(mod_1)

df_mod1 <- dataset_finale %>% mutate(pred_mod1 = fitted(mod_1))

ggplot(df_mod1, aes(x = punti, y = pred_mod1)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(
    title = "Modello 1 - Variabili sportive",
    x = "Punti osservati", y = "Punti stimati"
  )

# -----------------------------------------------------------------------------
# 8. Modello 2 - Variabili sportive ed economiche
# Obiettivo: valutare l'impatto delle scelte finanziarie sulla performance,
# a parità di caratteristiche sportive. Si includono solo le variabili
# economiche principali per limitare il numero di regressori.
# -----------------------------------------------------------------------------

mod_2 <- lm(
  punti ~ eta_mediana + valore_di_mercato_mediano + RRCI + numero_cambi_allenatore +
    ricavi_totali + spese_per_stipendi + ammortamenti_rosa,
  data = dataset_finale
)
summary(mod_2)

df_mod2 <- dataset_finale %>% mutate(pred_mod2 = fitted(mod_2))

ggplot(df_mod2, aes(x = punti, y = pred_mod2)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(
    title = "Modello 2 - Variabili sportive ed economiche",
    x = "Punti osservati", y = "Punti stimati"
  )

# -----------------------------------------------------------------------------
# 9. Modello 3 - Variabili sportive, economiche e gestionali/strutturali
# -----------------------------------------------------------------------------

mod_3 <- lm(
  punti ~ eta_mediana + valore_di_mercato_mediano + RRCI + numero_cambi_allenatore +
    ricavi_totali + spese_per_stipendi + ammortamenti_rosa +
    instabilita._societaria + investimenti_infrastrutturali + eventi_straordinari,
  data = dataset_finale
)
summary(mod_3)

df_mod3 <- dataset_finale %>% mutate(pred_mod3 = fitted(mod_3))

ggplot(df_mod3, aes(x = punti, y = pred_mod3)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(
    title = "Modello 3 - Variabili sportive, economiche e gestionali",
    x = "Punti osservati", y = "Punti stimati"
  )

# -----------------------------------------------------------------------------
# 10. Confronto tra le tre specificazioni
# -----------------------------------------------------------------------------

df_confronto <- dataset_finale %>%
  mutate(
    mod1 = fitted(mod_1),
    mod2 = fitted(mod_2),
    mod3 = fitted(mod_3)
  ) %>%
  select(stagione, punti, mod1, mod2, mod3) %>%
  pivot_longer(
    cols = starts_with("mod"),
    names_to = "Modello",
    values_to = "Punti_stimati"
  )

ggplot(df_confronto, aes(x = punti, y = Punti_stimati, color = Modello)) +
  geom_point(size = 2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  scale_color_manual(
    values = c("mod1" = "blue", "mod2" = "red", "mod3" = "green"),
    labels = c(
      "mod1" = "Modello 1 - Variabili sportive",
      "mod2" = "Modello 2 - Sportive ed economiche",
      "mod3" = "Modello 3 - Sportive, economiche e gestionali"
    )
  ) +
  labs(
    title = "Confronto tra le specificazioni di regressione",
    x = "Punti osservati in Serie A",
    y = "Punti stimati dai modelli",
    color = "Specificazione"
  )

# -----------------------------------------------------------------------------
# 11. Modello standardizzato: influenza relativa delle variabili
# -----------------------------------------------------------------------------

modello3_std <- lm(
  scale(punti) ~
    scale(eta_mediana) + scale(valore_di_mercato_mediano) + scale(RRCI) +
    scale(numero_cambi_allenatore) +
    scale(ricavi_totali) + scale(spese_per_stipendi) + scale(ammortamenti_rosa) +
    scale(instabilita._societaria) + scale(investimenti_infrastrutturali),
  data = dataset_finale
)
summary(modello3_std)

coef_std <- coef(modello3_std)[-1]

df_coef <- data.frame(
  variabile    = names(coef_std),
  coefficiente = as.numeric(coef_std)
)

ggplot(df_coef, aes(x = coefficiente, y = reorder(variabile, coefficiente))) +
  geom_col() +
  geom_vline(xintercept = 0) +
  labs(
    title = "Influenza relativa delle variabili",
    x = "Coefficiente standardizzato", y = NULL
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))
