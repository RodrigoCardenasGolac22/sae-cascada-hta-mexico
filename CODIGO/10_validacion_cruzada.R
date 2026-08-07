# Paso 10: validacion cruzada espacial. NO es dejar-un-municipio-fuera exhaustivo (con ~600
# municipios y ~45s por ajuste, seria ~7.5 horas de computo por outcome) -- se usa validacion
# cruzada de 5 pliegues POR GRUPO de municipios (20% de los municipios fuera a la vez, reajustado,
# comparado contra lo observado). Compromiso computacional explicito, documentado, no una
# validacion completa dejar-uno-fuera. Comparacion: RMSE/sesgo del modelo BYM2 (prediccion fuera
# de muestra) contra una linea base simple no ajustada (promedio nacional), para cuantificar si el
# modelo realmente aporta sobre no usar ningun ajuste espacial/de covariables.
#
# DOS ESQUEMAS DE PLIEGUES, REPORTADOS COMO COTAS (item B2 del plan, recomendacion revisada
# 2026-08-06). Medido sobre el grafo: un municipio retenido con pliegues ALEATORIOS conserva
# mediana 2 vecinos muestreados dentro del ajuste (18,5% se queda con 0); con pliegues CONTIGUOS
# (bloques espaciales, Roberts et al. 2017) el 72,5% se queda con 0; y el regimen REAL que el
# paper publica -- los 1 879 municipios sin muestra -- tiene el 36,1% sin ningun vecino
# muestreado. Ninguno de los dos esquemas reproduce ese regimen: el aleatorio es la cota superior
# de rendimiento (vecindario intacto) y el contiguo la inferior (vecindario arrasado). Se corren
# LOS DOS y el regimen real queda acotado entre ambos.
#
# METRICA PRINCIPAL: el RMSE ESTRATIFICADO por numero de vecinos muestreados que conserva el
# municipio retenido (0 / 1-2 / 3+), que es la unica que responde directamente "¿como estima el
# modelo donde no hay nada alrededor?" -- el estrato 0 es el que corresponde al 36,1% real.
#
# COMPARADOR RUIDOSO, DECLARADO Y CUANTIFICADO (item B3): lo "observado" es la proporcion NO
# ponderada del municipio, con mediana n = 8 encuestados; con n = 8 y p ~ 0,66 el error estandar
# de la propia "verdad" es ~0,17, asi que la mayor parte del RMSE absoluto es varianza de muestreo
# del comparador, no error del modelo. Se reporta (a) el RMSE irreducible esperado
# sqrt(mean(obs*(1-obs)/n)) -- la parte del error que es puro ruido del comparador -- y (b) el
# RMSE restringido a municipios con n >= 30, donde la comparacion tiene sentido. Lo interpretable
# es la diferencia relativa entre modelos, no el RMSE absoluto.

library(dplyr)
library(readr)
library(INLA)

source("CODIGO/00_comun.R")   # NIVELES_ESCOLARIDAD, cargar_covariables_area(), asignar_pliegues_contiguos()

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

# Covariables de area por el cargador comun (00_comun.R): misma especificacion que 07/08/09/11.
base <- base %>% mutate(muni_id = paste0(entidad, municipio))
base <- cargar_covariables_area(base, COV) %>%
  mutate(sexo_f = factor(sexo), estrato_f = factor(estrato),
         escolaridad_f = factor(escolaridad, levels = NIVELES_ESCOLARIDAD),
         anio_f = factor(anio))

g <- inla.read.graph(file.path(GEO, "municipios.graph"))
# Lista de adyacencia del grafo completo: la usan los pliegues contiguos y el conteo de vecinos
# muestreados retenidos.
adj <- lapply(seq_len(g$n), function(i) as.integer(g$nbs[[i]]))

bym2_term <- "f(muni_idx, model='bym2', graph=g, scale.model=TRUE, constr=TRUE, hyper=list(phi=list(prior='pc', param=c(0.5,0.5)), prec=list(prior='pc.prec', param=c(1,0.01))))"

especificaciones <- list(
  AWARE_ESH   = list(outcome = "diag_cronico", denom = "hta_esh",
                      rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct")),
  AWARE_AHA   = list(outcome = "diag_cronico", denom = "hta_aha",
                      rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct")),
  TRAT        = list(outcome = "tratado",      denom = "diag_cronico",
                      rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f")),
  CONTROL_ESH = list(outcome = "control_esh",  denom = "tratado",
                      rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct")),
  CONTROL_AHA = list(outcome = "control_aha",  denom = "tratado",
                      rhs = paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f + pobreza_pct"))
)

resumen_cv <- list()
estratificado <- list()

for (nombre in names(especificaciones)) {
  e <- especificaciones[[nombre]]
  sub <- base %>% filter(.data[[e$denom]], !is.na(.data[[e$denom]])) %>%
    mutate(y_real = as.numeric(.data[[e$outcome]])) %>%
    filter(!is.na(sexo_f), !is.na(edad), !is.na(estrato_f), !is.na(escolaridad_f))
  if (grepl("pobreza_pct", e$rhs)) sub <- sub %>% filter(!is.na(pobreza_pct))
  if (grepl("clues_por_10k", e$rhs)) sub <- sub %>% filter(!is.na(clues_por_10k))

  municipios_unicos <- sort(unique(sub$muni_idx))

  # Los dos esquemas de pliegues sobre el MISMO universo de municipios. El contiguo es
  # determinista (semilla propia dentro de asignar_pliegues_contiguos); el aleatorio depende de la
  # semilla global fijada arriba.
  fold_ale <- setNames(sample(rep(1:N_FOLDS, length.out = length(municipios_unicos))),
                       municipios_unicos)
  fold_con <- asignar_pliegues_contiguos(municipios_unicos, adj, g$n, N_FOLDS)

  # Asignacion auditable (checklist del plan: "cv_pliegues_<paso>.csv existe").
  write.csv(data.frame(muni_idx = municipios_unicos,
                       fold_aleatorio = as.integer(fold_ale[as.character(municipios_unicos)]),
                       fold_contiguo  = as.integer(fold_con[as.character(municipios_unicos)])),
            file.path(RES, paste0("cv_pliegues_", nombre, ".csv")), row.names = FALSE)

  # Vecinos MUESTREADOS de cada municipio (dentro del universo de este paso).
  vecinos_m <- lapply(municipios_unicos, function(m) intersect(adj[[m]], municipios_unicos))
  names(vecinos_m) <- as.character(municipios_unicos)

  promedio_nacional <- mean(sub$y_real)

  for (esquema in c("aleatorio", "contiguo")) {
    fold_de_municipio <- if (esquema == "aleatorio") fold_ale else fold_con
    sub$fold <- fold_de_municipio[as.character(sub$muni_idx)]
    stopifnot(!any(is.na(sub$fold)))

    preds_todas <- list()
    for (k in 1:N_FOLDS) {
      sub_k <- sub %>% mutate(y = ifelse(fold == k, NA_real_, y_real))
      t0 <- Sys.time()
      m_k <- inla(as.formula(paste("y ~", e$rhs)), family = "binomial", Ntrials = 1, data = sub_k,
                  control.predictor = list(compute = TRUE, link = 1))
      t1 <- Sys.time()
      cat(sprintf("[%s | %s] fold %d/%d: %.1fs\n", nombre, esquema, k, N_FOLDS,
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

    # Cuantos vecinos muestreados CONSERVA dentro del ajuste cada municipio retenido: la variable
    # que separa el regimen facil (vecindario intacto) del que corresponde a los municipios sin
    # muestra que el paper publica.
    por_muni$vecinos_retenidos <- vapply(as.character(por_muni$muni_idx), function(mm) {
      k <- fold_de_municipio[[mm]]
      vs <- vecinos_m[[mm]]
      if (length(vs) == 0) return(0L)
      sum(fold_de_municipio[as.character(vs)] != k)
    }, integer(1))
    por_muni$estrato_vecinos <- cut(por_muni$vecinos_retenidos, breaks = c(-Inf, 0, 2, Inf),
                                    labels = c("0", "1-2", "3+"))
    # Varianza de muestreo del propio comparador (B3): obs*(1-obs)/n por municipio.
    por_muni$var_comparador <- por_muni$obs * (1 - por_muni$obs) / por_muni$n

    rmse_bym2  <- sqrt(mean((por_muni$obs - por_muni$pred_bym2)^2))
    rmse_naive <- sqrt(mean((por_muni$obs - por_muni$pred_naive)^2))
    sesgo_bym2  <- mean(por_muni$pred_bym2 - por_muni$obs)
    sesgo_naive <- mean(por_muni$pred_naive - por_muni$obs)
    rmse_irreducible <- sqrt(mean(por_muni$var_comparador))

    n30 <- por_muni %>% filter(n >= 30)
    rmse_n30       <- sqrt(mean((n30$obs - n30$pred_bym2)^2))
    rmse_naive_n30 <- sqrt(mean((n30$obs - n30$pred_naive)^2))

    pct_sin_vecinos <- 100 * mean(por_muni$vecinos_retenidos == 0)
    cat(sprintf("\n[%s | %s] RESUMEN CV: n_municipios=%d | RMSE BYM2=%.4f vs naive=%.4f (%.1f%% reduccion) | sesgo BYM2=%.4f | irreducible=%.4f | n>=30 (%d munis): BYM2=%.4f vs naive=%.4f | retenidos sin vecinos: %.1f%%\n\n",
                nombre, esquema, nrow(por_muni), rmse_bym2, rmse_naive,
                100 * (1 - rmse_bym2 / rmse_naive), sesgo_bym2, rmse_irreducible,
                nrow(n30), rmse_n30, rmse_naive_n30, pct_sin_vecinos))

    resumen_cv[[paste(nombre, esquema)]] <- data.frame(
      paso = nombre, esquema = esquema, n_municipios = nrow(por_muni),
      rmse_bym2 = round(rmse_bym2, 4), rmse_naive = round(rmse_naive, 4),
      reduccion_rmse_pct = round(100 * (1 - rmse_bym2 / rmse_naive), 1),
      sesgo_bym2 = round(sesgo_bym2, 4), sesgo_naive = round(sesgo_naive, 4),
      rmse_irreducible = round(rmse_irreducible, 4),
      n_municipios_n30 = nrow(n30),
      rmse_n30 = round(rmse_n30, 4), rmse_naive_n30 = round(rmse_naive_n30, 4),
      pct_retenidos_sin_vecinos = round(pct_sin_vecinos, 1)
    )

    # RMSE por estrato de vecinos retenidos: la metrica principal de B2.
    estratificado[[paste(nombre, esquema)]] <- por_muni %>%
      group_by(estrato_vecinos) %>%
      summarise(n_municipios = n(),
                rmse_bym2 = round(sqrt(mean((obs - pred_bym2)^2)), 4),
                rmse_naive = round(sqrt(mean((obs - pred_naive)^2)), 4),
                rmse_irreducible = round(sqrt(mean(var_comparador)), 4),
                .groups = "drop") %>%
      mutate(paso = nombre, esquema = esquema, .before = 1)

    # El detalle del esquema aleatorio conserva el nombre historico (16_figS1 lo consume tal
    # cual); el contiguo lleva sufijo.
    sufijo <- if (esquema == "contiguo") "_contiguo" else ""
    write.csv(por_muni %>% select(muni_idx, obs, pred_bym2, pred_naive, n,
                                  vecinos_retenidos, estrato_vecinos),
              file.path(RES, paste0("cv_detalle_", nombre, sufijo, ".csv")), row.names = FALSE)
  }
}

resumen_long <- bind_rows(resumen_cv)
estrat_df <- bind_rows(estratificado)

# resumen_validacion_cruzada.csv mantiene UNA FILA POR PASO con los nombres de columna historicos
# (que 16_figS1 y 18_tablas leen) referidos al esquema ALEATORIO -- la cota superior, comparable
# con v1.1 -- y anade las columnas _contiguo (cota inferior) y las metricas de B3.
ale <- resumen_long %>% filter(esquema == "aleatorio") %>% select(-esquema)
con <- resumen_long %>% filter(esquema == "contiguo") %>%
  select(paso, rmse_bym2, rmse_naive, reduccion_rmse_pct, sesgo_bym2, rmse_n30,
         pct_retenidos_sin_vecinos) %>%
  rename_with(~ paste0(.x, "_contiguo"), -paso)
resumen_df <- ale %>% left_join(con, by = "paso")

cat("\n=== RESUMEN VALIDACION CRUZADA (5 pliegues x 2 esquemas, todos los pasos) ===\n")
cat("El esquema aleatorio es la COTA SUPERIOR de rendimiento (vecindario intacto) y el contiguo\n")
cat("la COTA INFERIOR (vecindario arrasado); el regimen real de los municipios sin muestra queda\n")
cat("acotado entre ambos. La metrica que responde 'como estima donde no hay nada alrededor' es el\n")
cat("RMSE del estrato 0 de cv_rmse_estratificado.csv.\n\n")
print(resumen_long, row.names = FALSE)
cat("\n--- RMSE estratificado por vecinos muestreados retenidos ---\n")
print(as.data.frame(estrat_df), row.names = FALSE)

write.csv(resumen_df, file.path(RES, "resumen_validacion_cruzada.csv"), row.names = FALSE)
write.csv(estrat_df %>% select(paso, esquema, estrato_vecinos, n_municipios,
                               rmse_bym2, rmse_naive, rmse_irreducible),
          file.path(RES, "cv_rmse_estratificado.csv"), row.names = FALSE)
cat("\nGuardado: cv_detalle_<paso>.csv y cv_detalle_<paso>_contiguo.csv (x5 cada uno),\n")
cat("          cv_pliegues_<paso>.csv (x5), cv_rmse_estratificado.csv, resumen_validacion_cruzada.csv\n")
