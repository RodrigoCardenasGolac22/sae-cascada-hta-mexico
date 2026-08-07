# Baseline NO ESPACIAL contra el que se valida el componente espacial (item B1 del plan,
# decision D-4a del autor, 2026-08-06).
#
# POR QUE. El titulo y el aporte del estudio son "bayesiano espacial", y la validacion solo
# contrastaba contra el promedio nacional. Falta el baseline que decide: el MISMO modelo con un
# efecto aleatorio IID por municipio en lugar del termino BYM2. Con Phi = 0,06-0,11 en el
# desenlace principal (diagnostico), un revisor puede sostener que un multinivel simple habria
# dado lo mismo; este script responde esa objecion con evidencia predictiva, no solo con Phi.
#
# COMO SE LEE EL RESULTADO (los dos escenarios previstos en el plan):
#  - Si el BYM2 gana en tratamiento y control y empata en diagnostico -> ES EL HALLAZGO, no un
#    problema: el agrupamiento espacial se concentra en tratamiento y control, no en el
#    diagnostico, ahora con WAIC y RMSE fuera de muestra ademas de Phi.
#  - Si empata en todo -> hay que decirlo y bajar el tono del aporte espacial en Titulo/Discusion
#    (decision pendiente #3 del plan, solo se activa en este escenario).
#
# ORDEN DE EJECUCION: corre DESPUES de 08 (lee modelo_FINAL_<paso>.rds para el lado BYM2, sin
# reajustarlo) y DESPUES de 10 (reutiliza los pliegues ALEATORIOS guardados en
# cv_pliegues_<paso>.csv, de modo que rmse_cv_iid y rmse_cv_bym2 se calculan sobre exactamente los
# mismos pliegues). Se llama 06b porque conceptualmente es el baseline de los modelos (06-08),
# pero RUN_ALL.R lo encadena tras el paso 10.
#
# La parte fija DEBE ser identica a la de 08_modelos_finales.R. Si el protocolo de 07 cambia la
# especificacion final, hay que actualizar 08 y este script a la vez.

library(dplyr)
library(readr)
library(INLA)

source("CODIGO/00_comun.R")   # NIVELES_ESCOLARIDAD, cargar_covariables_area()

RES <- "RESULTADOS"
GEO <- "DATOS_GEO_MEXICO"
COV <- "COVARIABLES"
N_FOLDS <- 5

for (f in c(file.path(RES, "modelo_FINAL_AWARE_ESH.rds"),
            file.path(RES, "cv_pliegues_AWARE_ESH.csv"),
            file.path(RES, "resumen_validacion_cruzada.csv"))) {
  if (!file.exists(f)) stop("Falta ", f, ": este script corre DESPUES de 08 y de 10.")
}

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
base$muni_id <- paste0(base$entidad, base$municipio)
base <- cargar_covariables_area(base, COV) %>%
  mutate(sexo_f = factor(sexo), estrato_f = factor(estrato),
         escolaridad_f = factor(escolaridad, levels = NIVELES_ESCOLARIDAD),
         anio_f = factor(anio))

# Mismo prior pc.prec que el BYM2 de 08; solo cambia la estructura (iid vs bym2).
iid_term <- "f(muni_idx, model='iid', hyper=list(prec=list(prior='pc.prec', param=c(1,0.01))))"

# Parte fija IDENTICA a 08_modelos_finales.R (ver la nota de cabecera).
especificaciones <- list(
  AWARE_ESH   = list(outcome = "diag_cronico", denom = "hta_esh",
                      fija = "sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct"),
  AWARE_AHA   = list(outcome = "diag_cronico", denom = "hta_aha",
                      fija = "sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct"),
  TRAT        = list(outcome = "tratado",      denom = "diag_cronico",
                      fija = "sexo_f + edad + escolaridad_f + estrato_f + anio_f"),
  CONTROL_ESH = list(outcome = "control_esh",  denom = "tratado",
                      fija = "sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct"),
  CONTROL_AHA = list(outcome = "control_aha",  denom = "tratado",
                      fija = "sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct")
)

rmse_cv_bym2_tab <- read_csv(file.path(RES, "resumen_validacion_cruzada.csv"), col_types = cols())

filas <- list()

for (nombre in names(especificaciones)) {
  e <- especificaciones[[nombre]]
  sub <- base %>% filter(.data[[e$denom]], !is.na(.data[[e$denom]])) %>%
    mutate(y_real = as.numeric(.data[[e$outcome]])) %>%
    filter(!is.na(sexo_f), !is.na(edad), !is.na(estrato_f), !is.na(escolaridad_f))
  if (grepl("pobreza_pct", e$fija)) sub <- sub %>% filter(!is.na(pobreza_pct))
  if (grepl("clues_por_10k", e$fija)) sub <- sub %>% filter(!is.na(clues_por_10k))

  # --- lado BYM2: el modelo final YA AJUSTADO en 08, sobre las mismas observaciones ---
  m_bym2 <- readRDS(file.path(RES, paste0("modelo_FINAL_", nombre, ".rds")))
  if (nrow(sub) != nrow(m_bym2$summary.fitted.values)) {
    stop(nombre, ": el subconjunto reconstruido (", nrow(sub), ") no coincide con el modelo final (",
         nrow(m_bym2$summary.fitted.values), "). ¿Se corrio 08 con otra base o especificacion?")
  }
  hp <- m_bym2$summary.hyperpar
  phi_mediana <- hp[grepl("^Phi", rownames(hp)), "0.5quant"]

  # --- lado IID: mismo desenlace, misma parte fija, efecto municipal sin estructura espacial ---
  rhs_iid <- paste("1 +", iid_term, "+", e$fija)
  sub$y <- sub$y_real
  t0 <- Sys.time()
  m_iid <- inla(as.formula(paste("y ~", rhs_iid)), family = "binomial", Ntrials = 1, data = sub,
                control.compute = list(waic = TRUE),
                control.predictor = list(compute = TRUE, link = 1))
  cat(sprintf("[%s] IID completo: n=%d, %.1fs, WAIC=%.1f (BYM2: %.1f)\n", nombre, nrow(sub),
              as.numeric(difftime(Sys.time(), t0, units = "secs")), m_iid$waic$waic,
              m_bym2$waic$waic))

  # DeltaWAIC con su error estandar por contribuciones punto a punto, la misma formula que 07
  # (Vehtari, Gelman & Gabry 2017): ambos modelos estan ajustados sobre las MISMAS observaciones.
  # Convencion de signo identica a 07: delta = candidato (BYM2) - baseline (IID); negativo = el
  # espacial mejora.
  dif_i <- m_bym2$waic$local.waic - m_iid$waic$local.waic
  stopifnot(length(dif_i) == nrow(sub))
  delta_waic <- m_bym2$waic$waic - m_iid$waic$waic
  se_delta <- sqrt(length(dif_i)) * sd(dif_i)

  # --- RMSE fuera de muestra del IID sobre LOS MISMOS pliegues aleatorios que uso 10 ---
  pliegues <- read_csv(file.path(RES, paste0("cv_pliegues_", nombre, ".csv")), col_types = cols())
  fold_de_municipio <- setNames(pliegues$fold_aleatorio, pliegues$muni_idx)
  sub$fold <- fold_de_municipio[as.character(sub$muni_idx)]
  stopifnot(!any(is.na(sub$fold)))

  preds_todas <- list()
  for (k in 1:N_FOLDS) {
    sub_k <- sub %>% mutate(y = ifelse(fold == k, NA_real_, y_real))
    t0 <- Sys.time()
    m_k <- inla(as.formula(paste("y ~", rhs_iid)), family = "binomial", Ntrials = 1, data = sub_k,
                control.predictor = list(compute = TRUE, link = 1))
    cat(sprintf("[%s] CV IID fold %d/%d: %.1fs\n", nombre, k, N_FOLDS,
                as.numeric(difftime(Sys.time(), t0, units = "secs"))))
    idx_out <- which(sub_k$fold == k)
    preds_todas[[k]] <- data.frame(muni_idx = sub_k$muni_idx[idx_out],
                                   y_real = sub_k$y_real[idx_out],
                                   y_pred = m_k$summary.fitted.values$mean[idx_out])
  }
  por_muni <- bind_rows(preds_todas) %>% group_by(muni_idx) %>%
    summarise(obs = mean(y_real), pred_iid = mean(y_pred), .groups = "drop")
  rmse_cv_iid <- sqrt(mean((por_muni$obs - por_muni$pred_iid)^2))
  rmse_cv_bym2 <- rmse_cv_bym2_tab$rmse_bym2[rmse_cv_bym2_tab$paso == nombre]

  evidencia <- if (delta_waic <= -2) "BYM2 mejora (|Delta|>=2)" else if (delta_waic >= 2) "BYM2 empeora (|Delta|>=2)" else "empate (|Delta|<2)"
  evidencia_se <- if (abs(delta_waic / se_delta) >= 2) {
    if (delta_waic < 0) "BYM2 mejora (>=2 EE)" else "BYM2 empeora (>=2 EE)"
  } else "empate (<2 EE)"

  cat(sprintf("[%s] DeltaWAIC(BYM2-IID)=%.2f (EE %.2f) -> %s | %s | RMSE CV: IID=%.4f vs BYM2=%.4f | Phi=%.3f\n\n",
              nombre, delta_waic, se_delta, evidencia, evidencia_se, rmse_cv_iid, rmse_cv_bym2,
              phi_mediana))

  filas[[nombre]] <- data.frame(
    paso = nombre, n = nrow(sub),
    waic_iid = round(m_iid$waic$waic, 1), waic_bym2 = round(m_bym2$waic$waic, 1),
    delta_waic = round(delta_waic, 2), se_delta_waic = round(se_delta, 2),
    razon_delta_se = round(delta_waic / se_delta, 2),
    evidencia_waic = evidencia, evidencia_se = evidencia_se,
    rmse_cv_iid = round(rmse_cv_iid, 4), rmse_cv_bym2 = round(rmse_cv_bym2, 4),
    phi_mediana = round(phi_mediana, 3)
  )
}

comparacion <- bind_rows(filas)
cat("\n=== BYM2 vs BASELINE IID (misma parte fija, mismas observaciones, mismos pliegues) ===\n")
print(comparacion, row.names = FALSE)

write.csv(comparacion, file.path(RES, "comparacion_bym2_vs_iid.csv"), row.names = FALSE)
cat("\nGuardado: comparacion_bym2_vs_iid.csv\n")
