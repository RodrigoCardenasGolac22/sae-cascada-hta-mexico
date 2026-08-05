# Paso 6 de la secuencia de ejecucion: estimaciones
# directas por municipio-paso-criterio con diseno complejo, documentando el % de municipios con
# n insuficiente por paso -- la evidencia empirica que respalda usar estimacion de area pequena
# de decidir el modelo SAE.
#
# Diseno muestral: strata = interaction(anio, estrato) -- CADA ANIO ES SU PROPIO ESTRATO dentro
# del pooled 2021-2024, siguiendo la metodologia oficial de INSP (Romero-Martinez et al. 2024,
# DOI 10.21149/16455) -- los anios no se reescalan entre si, siguiendo esa guia.
#
# Ponderador: se usa `ponde_cal` (script 02b), no `ponde_f`. La medicion de presion arterial se
# hace en una submuestra del modulo de adultos, y ponde_f aplicado a esa submuestra no la
# re-expande a la poblacion; ponde_cal la calibra por celdas de anio x estrato x sexo x grupo de
# edad contra el marco de elegibles. Ver la nota de agregar_ponderador_calibrado() en 00_comun.R.

library(dplyr)
library(readr)
library(survey)

source("CODIGO/00_comun.R")   # agregar_ponderador_calibrado()

RES <- "RESULTADOS"
options(survey.lonely.psu = "adjust")

base <- read_csv(file.path(RES, "base_analitica_adultos_2021_2024.csv"),
                  col_types = cols(
                    entidad = col_character(), municipio = col_character(),
                    estrato = col_character(), upm = col_character(),
                    anio = col_character(), muni_id = col_character(),
                    FOLIO_I = col_character(), FOLIO_INT = col_character(),
                    ponde_f = col_double(),
                    diag_cronico = col_logical(), hta_esh = col_logical(), hta_aha = col_logical(),
                    tratado = col_logical(), control_esh = col_logical(), control_aha = col_logical(),
                    .default = col_guess()
                  ))
base <- agregar_ponderador_calibrado(base, RES)

cat("N total base:", nrow(base), " | municipios:", n_distinct(base$muni_id), "\n")

# svymean sobre una variable logica produce dos columnas (FALSE/TRUE) en vez de una proporcion;
# se crean copias numericas 0/1 SOLO para las variables de desenlace (no para las de
# denominador/subset, que se mantienen logicas para el subset() de mas abajo)
for (v in c("diag_cronico", "tratado", "control_esh", "control_aha")) {
  base[[paste0(v, "_num")]] <- as.numeric(base[[v]])
}

diseno <- svydesign(ids = ~upm, strata = ~interaction(anio, estrato), weights = ~ponde_cal,
                     data = base, nest = TRUE)

# outcome, variable de denominador (subset), nombre
pasos <- list(
  conciencia_ESH  = list(outcome = "diag_cronico_num", denom = "hta_esh"),
  conciencia_AHA  = list(outcome = "diag_cronico_num", denom = "hta_aha"),
  tratamiento     = list(outcome = "tratado_num",      denom = "diag_cronico"),
  control_ESH     = list(outcome = "control_esh_num",  denom = "tratado"),
  control_AHA     = list(outcome = "control_aha_num",  denom = "tratado")
)

resultados <- list()
resumen <- list()

for (nombre in names(pasos)) {
  p <- pasos[[nombre]]
  sub_design <- subset(diseno, get(p$denom))
  sub_data <- base[base[[p$denom]] & !is.na(base[[p$denom]]), ]

  # n no ponderado por municipio (denominador real de la estimacion directa)
  n_por_muni <- sub_data %>% count(muni_id, name = "n")

  # estimacion ponderada por municipio, con manejo de errores por PSU solitaria/varianza no
  # calculable en municipios muy pequenos (no se descarta el municipio, se marca la falla)
  est <- tryCatch({
    r <- svyby(as.formula(paste0("~", p$outcome)), ~muni_id, sub_design, svymean, na.rm = TRUE,
               vartype = "ci", drop.empty.groups = TRUE)
    r
  }, error = function(e) {
    cat("  [", nombre, "] error en svyby:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(est)) {
    names(est)[names(est) == p$outcome] <- "prevalencia"
    est <- est %>% left_join(n_por_muni, by = "muni_id")
    est$cv_pct <- with(est, 100 * ((ci_u - ci_l) / 3.92) / prevalencia)  # aprox CV desde el IC95%
  } else {
    est <- n_por_muni
    est$prevalencia <- NA_real_
  }

  resultados[[nombre]] <- est

  n_insuf10 <- sum(n_por_muni$n < 10)
  n_insuf30 <- sum(n_por_muni$n < 30)
  total_muni <- nrow(n_por_muni)

  resumen[[nombre]] <- c(
    paso = nombre,
    n_total_denominador = sum(n_por_muni$n),
    n_municipios = total_muni,
    pct_muni_n_menor_10 = round(100 * n_insuf10 / total_muni, 1),
    pct_muni_n_menor_30 = round(100 * n_insuf30 / total_muni, 1)
  )

  cat(sprintf("[%s] n total=%d, municipios=%d, %% con n<10=%.1f%%, %% con n<30=%.1f%%\n",
              nombre, sum(n_por_muni$n), total_muni,
              100 * n_insuf10 / total_muni, 100 * n_insuf30 / total_muni))
}

resumen_df <- do.call(rbind, resumen) %>% as.data.frame()
cat("\n=== RESUMEN: estimacion directa por municipio-paso-criterio ===\n")
print(resumen_df, row.names = FALSE)

for (nombre in names(resultados)) {
  write.csv(resultados[[nombre]], file.path(RES, paste0("directa_", nombre, "_municipio.csv")), row.names = FALSE)
}
write.csv(resumen_df, file.path(RES, "resumen_estimaciones_directas.csv"), row.names = FALSE)
cat("\nGuardado: directa_<paso>_municipio.csv (x5), resumen_estimaciones_directas.csv\n")
