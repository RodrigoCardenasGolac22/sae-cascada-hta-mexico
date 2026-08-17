# Sensibilidad del modelo PRINCIPAL ponderado frente al ajuste alternativo sin ponderar.
#
# La comprobacion inicial en AWARE_ESH y TRAT mostro que la discrepancia persistia en municipios
# con n >= 30; por la regla acordada, la pseudo-verosimilitud ponderada pasa a ser principal. Este
# paso conserva la comparacion de transparencia, la extiende a los cinco desenlaces y cuantifica
# si la diferencia depende del tamano muestral municipal.

library(dplyr)
library(readr)
library(INLA)

source("CODIGO/00_comun.R")

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
especificaciones <- especificaciones_modelo_final(RES, bym2_term)

filas <- list()
filas_n <- list()

for (nombre in names(especificaciones)) {
  e <- especificaciones[[nombre]]
  sub <- base %>% filter(.data[[e$denom]], !is.na(.data[[e$denom]])) %>%
    mutate(y = as.numeric(.data[[e$outcome]])) %>%
    filter(!is.na(sexo_f), !is.na(edad), !is.na(estrato_f), !is.na(escolaridad_f))
  for (v in e$covariables) sub <- sub %>% filter(!is.na(.data[[v]]))
  sub <- normalizar_ponderador_modelo(sub)

  # Principal ponderado: objeto que produce el paso 08.
  m_principal <- readRDS(file.path(RES, paste0("modelo_FINAL_", nombre, ".rds")))
  if (nrow(sub) != nrow(m_principal$summary.fitted.values)) {
    stop(nombre, ": el subconjunto reconstruido no coincide con el modelo final")
  }
  sub$fitted_principal <- m_principal$summary.fitted.values$mean

  # Sensibilidad sin ponderar: misma formula, filas, priors y grafo; solo se omite weights=.
  t0 <- Sys.time()
  m_sin <- inla(as.formula(paste("y ~", e$rhs)), family = "binomial", Ntrials = 1, data = sub,
                control.compute = list(waic = TRUE),
                control.predictor = list(compute = TRUE, link = 1))
  cat(sprintf("[%s] sensibilidad sin ponderar: n=%d, %.1fs\n", nombre, nrow(sub),
              as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  sub$fitted_sin <- m_sin$summary.fitted.values$mean

  # Ambos lados se agregan con el mismo objetivo poblacional para aislar el efecto del ajuste.
  por_muni <- sub %>% group_by(muni_idx) %>%
    summarise(
      prev_principal_ponderado = weighted.mean(fitted_principal, ponde_cal),
      prev_sensibilidad_sin_ponderar = weighted.mean(fitted_sin, ponde_cal),
      n = n(), .groups = "drop"
    ) %>%
    mutate(
      dif_sin_menos_principal_pp = 100 *
        (prev_sensibilidad_sin_ponderar - prev_principal_ponderado),
      quintil_principal = ntile(prev_principal_ponderado, 5),
      quintil_sin_ponderar = ntile(prev_sensibilidad_sin_ponderar, 5),
      cambia_quintil = quintil_principal != quintil_sin_ponderar,
      estrato_n = cut(n, c(-Inf, 9, 29, Inf), labels = c("n<=9", "n=10-29", "n>=30"))
    )

  dif_abs <- abs(por_muni$dif_sin_menos_principal_pp)
  correlacion <- cor(por_muni$prev_principal_ponderado,
                     por_muni$prev_sensibilidad_sin_ponderar)
  cor_n_pearson <- cor(dif_abs, por_muni$n)
  cor_n_spearman <- cor(dif_abs, por_muni$n, method = "spearman")
  mediana_dif <- median(dif_abs)
  cumple <- mediana_dif < 2 && correlacion > 0.95

  filas[[nombre]] <- data.frame(
    paso = nombre, n = nrow(sub), n_municipios = nrow(por_muni),
    modelo_principal = "ponderado", modelo_comparacion = "sin_ponderar",
    ponderacion_modelo = PONDERACION_MODELO,
    correlacion = round(correlacion, 4),
    mediana_dif_abs_pp = round(mediana_dif, 2),
    p95_dif_abs_pp = round(as.numeric(quantile(dif_abs, 0.95)), 2),
    max_dif_abs_pp = round(max(dif_abs), 2),
    n_cambian_quintil = sum(por_muni$cambia_quintil),
    pct_cambian_quintil = round(100 * mean(por_muni$cambia_quintil), 1),
    cor_absdif_n_pearson = round(cor_n_pearson, 4),
    cor_absdif_n_spearman = round(cor_n_spearman, 4),
    criterio_diferencia_pequena = cumple
  )

  filas_n[[nombre]] <- por_muni %>% group_by(estrato_n) %>%
    summarise(n_municipios = n(),
              mediana_dif_abs_pp = median(abs(dif_sin_menos_principal_pp)),
              p95_dif_abs_pp = as.numeric(quantile(abs(dif_sin_menos_principal_pp), 0.95)),
              .groups = "drop") %>%
    mutate(paso = nombre, .before = 1)

  write.csv(por_muni, file.path(RES, paste0("sensibilidad_ponderada_detalle_", nombre, ".csv")),
            row.names = FALSE)
  rm(m_sin); gc(verbose = FALSE)
}

sens_df <- bind_rows(filas)
sens_n_df <- bind_rows(filas_n)
cat("\n=== PRINCIPAL PONDERADO VS SENSIBILIDAD SIN PONDERAR ===\n")
print(sens_df, row.names = FALSE)
cat("\n=== DIFERENCIA ABSOLUTA POR TAMANO MUESTRAL MUNICIPAL ===\n")
print(as.data.frame(sens_n_df), row.names = FALSE)

write.csv(sens_df, file.path(RES, "sensibilidad_ponderada.csv"), row.names = FALSE)
write.csv(sens_n_df, file.path(RES, "sensibilidad_ponderada_por_n.csv"), row.names = FALSE)
cat("\nGuardado: sensibilidad_ponderada.csv, sensibilidad_ponderada_por_n.csv y detalle x5\n")
