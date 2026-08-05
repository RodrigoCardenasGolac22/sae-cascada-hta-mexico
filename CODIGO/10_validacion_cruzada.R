# Paso 10: validacion cruzada espacial. NO es dejar-un-municipio-fuera exhaustivo (con ~600
# municipios y ~45s por ajuste, séria ~7.5 horas de computo por outcome) -- se usa validacion
# cruzada de 5 pliegues POR GRUPO de municipios (20% de los municipios fuera a la vez, reajustado,
# comparado contra lo observado). Compromiso computacional explicito, documentado, no una
# validacion completa dejar-uno-fuera. Comparacion: RMSE/sesgo del modelo BYM2 (prediccion fuera
# de muestra) contra una linea base simple no ajustada (promedio nacional), para cuantificar si el modelo
# realmente aporta sobre no usar ningun ajuste espacial/de covariables.
#
# Limitacion declarada: la "observada" usada aqui es la proporcion NO ponderada dentro del
# municipio (no la estimacion directa ponderada por diseno complejo del script 04): mas simple,
# documentado como tal, no presentado como equivalente a un comparativo con diseno de encuesta.

library(dplyr)
library(readr)
library(INLA)

source("CODIGO/00_comun.R")   # NIVELES_ESCOLARIDAD

RES <- "RESULTADOS"
GEO <- "DATOS_GEO_MEXICO"
COV <- "COVARIABLES"
set.seed(20260728)
N_FOLDS <- 5

base <- read_csv(file.path(RES, "base_analitica_adultos_2021_2024.csv"),
                  col_types = cols(
                    entidad = col_character(), municipio = col_character(),
                    diag_cronico = col_logical(), hta_esh = col_logical(), hta_aha = col_logical(),
                    tratado = col_logical(), control_esh = col_logical(), control_aha = col_logical(),
                    .default = col_guess()
                  ))
idx_tabla <- read_csv(file.path(GEO, "muni_idx_grafo.csv"), col_types = cols(
  cve_ent = col_character(), cve_mun = col_character()))
base <- base %>% left_join(idx_tabla, by = c("entidad" = "cve_ent", "municipio" = "cve_mun"))

coneval <- read_csv(file.path(COV, "coneval_pobreza_municipal_2020.csv"), col_types = cols(.default = col_character()))
coneval$muni_id <- sprintf("%05d", as.numeric(coneval$clave_municipio))
coneval$pobreza_pct <- as.numeric(coneval$pobreza)
clues <- read_csv(file.path(COV, "clues_conteo_municipal.csv"), col_types = cols(muni_id = col_character()))
base <- base %>%
  mutate(muni_id = paste0(entidad, municipio)) %>%
  left_join(coneval %>% select(muni_id, pobreza_pct), by = "muni_id") %>%
  left_join(clues %>% select(muni_id, clues_total), by = "muni_id") %>%
  mutate(sexo_f = factor(sexo), estrato_f = factor(estrato),
         escolaridad_f = factor(escolaridad, levels = NIVELES_ESCOLARIDAD),
         anio_f = factor(anio))

g <- inla.read.graph(file.path(GEO, "municipios.graph"))
bym2_term <- "f(muni_idx, model='bym2', graph=g, scale.model=TRUE, constr=TRUE, hyper=list(phi=list(prior='pc', param=c(0.5,0.5)), prec=list(prior='pc.prec', param=c(1,0.01))))"

especificaciones <- list(
  AWARE_ESH   = list(outcome = "diag_cronico", denom = "hta_esh",
                      rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct")),
  AWARE_AHA   = list(outcome = "diag_cronico", denom = "hta_aha",
                      rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct + clues_total")),
  TRAT        = list(outcome = "tratado",      denom = "diag_cronico",
                      rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f")),
  CONTROL_ESH = list(outcome = "control_esh",  denom = "tratado",
                      rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct + clues_total")),
  CONTROL_AHA = list(outcome = "control_aha",  denom = "tratado",
                      rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct + clues_total"))
)

resumen_cv <- list()

for (nombre in names(especificaciones)) {
  e <- especificaciones[[nombre]]
  sub <- base %>% filter(.data[[e$denom]], !is.na(.data[[e$denom]])) %>%
    mutate(y_real = as.numeric(.data[[e$outcome]])) %>%
    filter(!is.na(sexo_f), !is.na(edad), !is.na(estrato_f), !is.na(escolaridad_f))
  if (grepl("pobreza_pct", e$rhs)) sub <- sub %>% filter(!is.na(pobreza_pct))
  if (grepl("clues_total", e$rhs)) sub <- sub %>% filter(!is.na(clues_total))

  municipios_unicos <- unique(sub$muni_idx)
  fold_de_municipio <- setNames(sample(rep(1:N_FOLDS, length.out = length(municipios_unicos))), municipios_unicos)
  sub$fold <- fold_de_municipio[as.character(sub$muni_idx)]

  promedio_nacional <- mean(sub$y_real)
  preds_todas <- list()

  for (k in 1:N_FOLDS) {
    sub_k <- sub %>% mutate(y = ifelse(fold == k, NA_real_, y_real))
    t0 <- Sys.time()
    m_k <- inla(as.formula(paste("y ~", e$rhs)), family = "binomial", Ntrials = 1, data = sub_k,
                control.predictor = list(compute = TRUE, link = 1))
    t1 <- Sys.time()
    cat(sprintf("[%s] fold %d/%d: %.1fs\n", nombre, k, N_FOLDS,
                as.numeric(difftime(t1, t0, units = "secs"))))

    idx_out <- which(sub_k$fold == k)
    preds_todas[[k]] <- data.frame(
      muni_idx = sub_k$muni_idx[idx_out],
      y_real = sub_k$y_real[idx_out],
      y_pred = m_k$summary.fitted.values$mean[idx_out]
    )
  }

  preds_df <- bind_rows(preds_todas)
  por_muni <- preds_df %>% group_by(muni_idx) %>%
    summarise(obs = mean(y_real), pred_bym2 = mean(y_pred), n = n(), .groups = "drop") %>%
    mutate(pred_naive = promedio_nacional)

  rmse_bym2 <- sqrt(mean((por_muni$obs - por_muni$pred_bym2)^2))
  rmse_naive <- sqrt(mean((por_muni$obs - por_muni$pred_naive)^2))
  sesgo_bym2 <- mean(por_muni$pred_bym2 - por_muni$obs)
  sesgo_naive <- mean(por_muni$pred_naive - por_muni$obs)

  cat(sprintf("\n[%s] RESUMEN CV: n_municipios=%d | RMSE BYM2=%.4f vs naive=%.4f (%.1f%% reduccion) | sesgo BYM2=%.4f vs naive=%.4f\n\n",
              nombre, nrow(por_muni), rmse_bym2, rmse_naive, 100*(1 - rmse_bym2/rmse_naive), sesgo_bym2, sesgo_naive))

  resumen_cv[[nombre]] <- data.frame(
    paso = nombre, n_municipios = nrow(por_muni),
    rmse_bym2 = round(rmse_bym2, 4), rmse_naive = round(rmse_naive, 4),
    reduccion_rmse_pct = round(100*(1 - rmse_bym2/rmse_naive), 1),
    sesgo_bym2 = round(sesgo_bym2, 4), sesgo_naive = round(sesgo_naive, 4)
  )
  write.csv(por_muni, file.path(RES, paste0("cv_detalle_", nombre, ".csv")), row.names = FALSE)
}

resumen_df <- do.call(rbind, resumen_cv)
cat("\n=== RESUMEN VALIDACION CRUZADA (5 pliegues, todos los pasos) ===\n")
print(resumen_df, row.names = FALSE)
write.csv(resumen_df, file.path(RES, "resumen_validacion_cruzada.csv"), row.names = FALSE)
cat("\nGuardado: cv_detalle_<paso>.csv (x5), resumen_validacion_cruzada.csv\n")
