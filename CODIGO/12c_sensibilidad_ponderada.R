# Sensibilidad al supuesto de ignorabilidad del diseno muestral (item B4 del plan, decision D-4a
# del autor, 2026-08-06).
#
# POR QUE. Los modelos se ajustan SIN ponderadores, con el argumento (declarado en Metodos) de que
# estrato, anio y municipio estan en el modelo y el diseno seria ignorable condicionado a ellos.
# El argumento es razonable pero incompleto: la Tabla S2 prueba el efecto de la calibracion solo
# en las estimaciones DIRECTAS, y la seleccion de vivienda/UPM dentro del municipio queda sin
# tocar. En un paper de SAE sobre encuesta compleja es la objecion numero uno.
#
# QUE HACE. Reajusta DOS pasos con verosimilitud ponderada y compara las prevalencias municipales
# resultantes contra las del modelo sin ponderar (el modelo final de 08, sin reajustarlo):
#   - TRAT: el paso de mayor Phi (~0,8), donde el efecto municipal pesa mas;
#   - AWARE_ESH: el desenlace principal del estudio.
# El ponderador es el calibrado del script 02b, REESCALADO A MEDIA 1 DENTRO DE CADA MUNICIPIO:
# los pesos absolutos inflarian la precision aparente (el n efectivo no es la suma de pesos); lo
# que se quiere trasladar al ajuste es la composicion relativa dentro del municipio, no el tamano
# poblacional.
#
# CRITERIO DE LECTURA (preespecificado en el plan): si la mediana de |diferencia| es < 2 pp y la
# correlacion > 0,95, la frase de Metodos sobre ignorabilidad queda respaldada empiricamente. Si
# no, hay que reportar el modelo ponderado como principal o, al menos, discutirlo.
#
# ORDEN DE EJECUCION: despues de 08 (lee modelo_FINAL_<paso>.rds) y de 02b (ponderador calibrado).

library(dplyr)
library(readr)
library(INLA)

source("CODIGO/00_comun.R")   # NIVELES_ESCOLARIDAD, cargar_covariables_area(), agregar_ponderador_calibrado()

RES <- "RESULTADOS"
GEO <- "DATOS_GEO_MEXICO"
COV <- "COVARIABLES"

base <- read_csv(file.path(RES, "base_analitica_adultos_2021_2024.csv"),
                  col_types = cols(
                    entidad = col_character(), municipio = col_character(), anio = col_character(),
                    FOLIO_I = col_character(), FOLIO_INT = col_character(),
                    diag_cronico = col_logical(), hta_esh = col_logical(), hta_aha = col_logical(),
                    tratado = col_logical(), control_esh = col_logical(), control_aha = col_logical(),
                    .default = col_guess()
                  ))
base <- agregar_ponderador_calibrado(base, RES)
idx_tabla <- read_csv(file.path(GEO, "muni_idx_grafo.csv"), col_types = cols(
  cve_ent = col_character(), cve_mun = col_character()))
base <- base %>% left_join(idx_tabla, by = c("entidad" = "cve_ent", "municipio" = "cve_mun"))
base$muni_id <- paste0(base$entidad, base$municipio)
base <- cargar_covariables_area(base, COV) %>%
  mutate(sexo_f = factor(sexo), estrato_f = factor(estrato),
         escolaridad_f = factor(escolaridad, levels = NIVELES_ESCOLARIDAD),
         anio_f = factor(anio))

g <- inla.read.graph(file.path(GEO, "municipios.graph"))
bym2_term <- "f(muni_idx, model='bym2', graph=g, scale.model=TRUE, constr=TRUE, hyper=list(phi=list(prior='pc', param=c(0.5,0.5)), prec=list(prior='pc.prec', param=c(1,0.01))))"

# Parte fija IDENTICA a 08_modelos_finales.R para los dos pasos elegidos.
especificaciones <- list(
  AWARE_ESH = list(outcome = "diag_cronico", denom = "hta_esh",
                   rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct")),
  TRAT      = list(outcome = "tratado", denom = "diag_cronico",
                   rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f"))
)

filas <- list()

for (nombre in names(especificaciones)) {
  e <- especificaciones[[nombre]]
  sub <- base %>% filter(.data[[e$denom]], !is.na(.data[[e$denom]])) %>%
    mutate(y = as.numeric(.data[[e$outcome]])) %>%
    filter(!is.na(sexo_f), !is.na(edad), !is.na(estrato_f), !is.na(escolaridad_f))
  if (grepl("pobreza_pct", e$rhs)) sub <- sub %>% filter(!is.na(pobreza_pct))
  if (grepl("clues_por_10k", e$rhs)) sub <- sub %>% filter(!is.na(clues_por_10k))

  # --- lado NO ponderado: el modelo final de 08, sin reajustar ---
  m_sin <- readRDS(file.path(RES, paste0("modelo_FINAL_", nombre, ".rds")))
  if (nrow(sub) != nrow(m_sin$summary.fitted.values)) {
    stop(nombre, ": el subconjunto reconstruido (", nrow(sub), ") no coincide con el modelo final (",
         nrow(m_sin$summary.fitted.values), "). ¿Se corrio 08 con otra base o especificacion?")
  }
  sub$fitted_sin <- m_sin$summary.fitted.values$mean

  # --- lado ponderado: verosimilitud ponderada con ponde_cal reescalado a media 1 por municipio ---
  sub <- sub %>% group_by(muni_idx) %>% mutate(w = ponde_cal / mean(ponde_cal)) %>% ungroup()
  t0 <- Sys.time()
  m_con <- inla(as.formula(paste("y ~", e$rhs)), family = "binomial", Ntrials = 1, data = sub,
                weights = sub$w,
                control.compute = list(waic = TRUE, config = TRUE),
                control.predictor = list(compute = TRUE, link = 1))
  cat(sprintf("[%s] modelo ponderado: n=%d, %.1fs\n", nombre, nrow(sub),
              as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  sub$fitted_con <- m_con$summary.fitted.values$mean

  # --- prevalencia municipal bajo cada modelo (promedio de los individuos modelados, como en 08) ---
  por_muni <- sub %>% group_by(muni_idx) %>%
    summarise(prev_sin = mean(fitted_sin), prev_con = mean(fitted_con), n = n(), .groups = "drop") %>%
    mutate(dif_pp = 100 * (prev_con - prev_sin),
           quintil_sin = ntile(prev_sin, 5),
           quintil_con = ntile(prev_con, 5),
           cambia_quintil = quintil_sin != quintil_con)

  correlacion <- cor(por_muni$prev_sin, por_muni$prev_con)
  mediana_dif <- median(abs(por_muni$dif_pp))
  p95_dif <- quantile(abs(por_muni$dif_pp), 0.95)
  max_dif <- max(abs(por_muni$dif_pp))
  n_cambian <- sum(por_muni$cambia_quintil)

  cumple <- mediana_dif < 2 && correlacion > 0.95
  cat(sprintf("[%s] correlacion=%.4f | mediana |dif|=%.2f pp | p95=%.2f | max=%.2f | cambian de quintil: %d de %d (%.1f%%) -> %s\n\n",
              nombre, correlacion, mediana_dif, p95_dif, max_dif, n_cambian, nrow(por_muni),
              100 * n_cambian / nrow(por_muni),
              if (cumple) "IGNORABILIDAD RESPALDADA (mediana < 2 pp y r > 0,95)"
              else "REVISAR: discutir o reportar el ponderado como principal"))

  filas[[nombre]] <- data.frame(
    paso = nombre, n = nrow(sub), n_municipios = nrow(por_muni),
    correlacion = round(correlacion, 4),
    mediana_dif_abs_pp = round(mediana_dif, 2),
    p95_dif_abs_pp = round(as.numeric(p95_dif), 2),
    max_dif_abs_pp = round(max_dif, 2),
    n_cambian_quintil = n_cambian,
    pct_cambian_quintil = round(100 * n_cambian / nrow(por_muni), 1),
    criterio_cumplido = cumple
  )
  write.csv(por_muni %>% select(muni_idx, n, prev_sin, prev_con, dif_pp,
                                quintil_sin, quintil_con, cambia_quintil),
            file.path(RES, paste0("sensibilidad_ponderada_detalle_", nombre, ".csv")),
            row.names = FALSE)
}

sens_df <- bind_rows(filas)
cat("\n=== SENSIBILIDAD A LA PONDERACION (modelo final sin ponderar vs verosimilitud ponderada) ===\n")
print(sens_df, row.names = FALSE)

write.csv(sens_df, file.path(RES, "sensibilidad_ponderada.csv"), row.names = FALSE)
cat("\nGuardado: sensibilidad_ponderada.csv, sensibilidad_ponderada_detalle_<paso>.csv (x2)\n")
