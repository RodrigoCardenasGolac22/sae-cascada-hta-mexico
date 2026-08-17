# Paso 9 de la secuencia: ajusta los modelos FINALES con la especificacion que sale del protocolo
# WAIC+CPO del script 07 (DeltaWAIC <= -2, mejora concordante del log-CPO y cero fallos CPO),
# no de una eleccion a priori uniforme.
#
# Especificacion vigente. Se decide sobre la muestra completa, que incluye a los adultos sin
# escolaridad (codigo 0), unas 800 personas por modelo y las de menor escolaridad: excluirlas
# sesgaria un estudio sobre desigualdad.
#
# DE DONDE SALE. La evidencia por paso y candidata vive en RESULTADOS/resumen_covariables_waic_cpo.csv,
# que produce el script 07. NO se copia aqui a proposito: la version anterior de esta cabecera listaba
# los DeltaWAIC de una corrida anterior (-8,48 / -7,26 / -6,66 / -10,34 ...) que ya no coincidian con
# el CSV vigente, y esta cabecera es la justificacion escrita de los modelos que se publican. Misma
# politica que el script 01: "un numero fijado en un comentario caduca en cuanto cambia la base".
# Para leer la decision: ordenar ese CSV por paso y mirar delta_waic junto a razon_delta_se.
#
# La especificacion no se escribe a mano: se deriva de la columna `seleccionada` que deja el paso
# 07 tras aplicar el protocolo preespecificado al ajuste ponderado.
# Calcula la reclasificacion espacial ESH -> ACC/AHA para conciencia y control (tratamiento se
# excluye del mapa de reclasificacion: identico por construccion bajo ambos criterios, ya
# verificado en el script 06).

library(dplyr)
library(readr)
library(INLA)

source("CODIGO/00_comun.R")   # NIVELES_ESCOLARIDAD

RES <- "RESULTADOS"
GEO <- "DATOS_GEO_MEXICO"
COV <- "COVARIABLES"

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
base <- agregar_ponderador_calibrado(base, RES)

# Covariables de area por el cargador comun de 00_comun.R: la especificacion tiene que ser identica
# a la que se probo en 07 (clues_por_10k, densidad por 10 000 adultos) y a la de 09/10/11.
base <- cargar_covariables_area(base, COV) %>%
  mutate(sexo_f = factor(sexo), estrato_f = factor(estrato),
         escolaridad_f = factor(escolaridad, levels = NIVELES_ESCOLARIDAD),
         anio_f = factor(anio))

g <- inla.read.graph(file.path(GEO, "municipios.graph"))
bym2_term <- "f(muni_idx, model='bym2', graph=g, scale.model=TRUE, constr=TRUE, hyper=list(phi=list(prior='pc', param=c(0.5,0.5)), prec=list(prior='pc.prec', param=c(1,0.01))))"

ajustar <- function(formula_rhs, datos) {
  f <- as.formula(paste("y ~", formula_rhs))
  inla(f, family = "binomial", Ntrials = 1, data = datos, weights = datos$peso_modelo,
       control.compute = list(waic = TRUE, cpo = TRUE, config = TRUE),
       control.predictor = list(compute = TRUE, link = 1))
}

# Especificacion final, resultante del protocolo WAIC+CPO ponderado del script 07.
especificaciones <- especificaciones_modelo_final(RES, bym2_term)
especificacion_df <- bind_rows(lapply(especificaciones, function(e) data.frame(
  paso = e$paso, outcome = e$outcome, denom = e$denom,
  covariables_area = if (length(e$covariables)) paste(e$covariables, collapse = ";") else "ninguna",
  formula_fija = e$fija, ponderacion_modelo = PONDERACION_MODELO
)))
write.csv(especificacion_df, file.path(RES, "especificacion_modelos_finales.csv"), row.names = FALSE)

modelos_finales <- list()
fitted_por_muni <- list()

for (nombre in names(especificaciones)) {
  e <- especificaciones[[nombre]]
  sub <- base %>% filter(.data[[e$denom]], !is.na(.data[[e$denom]])) %>%
    mutate(y = as.numeric(.data[[e$outcome]])) %>%
    filter(!is.na(sexo_f), !is.na(edad), !is.na(estrato_f), !is.na(escolaridad_f))
  for (v in e$covariables) sub <- sub %>% filter(!is.na(.data[[v]]))
  sub <- normalizar_ponderador_modelo(sub)

  t0 <- Sys.time()
  m <- ajustar(e$rhs, sub)
  t1 <- Sys.time()
  cat(sprintf("[%s] n=%d, %.1fs, WAIC=%.1f\n", nombre, nrow(sub),
              as.numeric(difftime(t1, t0, units = "secs")), m$waic$waic))

  modelos_finales[[nombre]] <- m
  saveRDS(m, file.path(RES, paste0("modelo_FINAL_", nombre, ".rds")))

  # prevalencia suavizada PROMEDIO por municipio (promediando sobre los individuos modelados en
  # cada municipio, ya que el modelo es de nivel-unidad con covariables individuales -- no un
  # unico valor por municipio como en un modelo puramente de area)
  sub$fitted <- m$summary.fitted.values$mean
  prom_muni <- sub %>% group_by(muni_idx) %>%
    summarise(prev_prom = weighted.mean(fitted, ponde_cal), .groups = "drop")
  fitted_por_muni[[nombre]] <- prom_muni
}

# --- Reclasificacion ESH vs AHA ---
cat("\n=== RECLASIFICACION: Conciencia (ESH vs AHA) ===\n")
reclas_conciencia <- fitted_por_muni$AWARE_ESH %>%
  rename(prev_ESH = prev_prom) %>%
  inner_join(fitted_por_muni$AWARE_AHA %>% rename(prev_AHA = prev_prom), by = "muni_idx") %>%
  mutate(diferencia_pp = 100 * (prev_AHA - prev_ESH))

cat("Municipios comparables (presentes en ambos modelos):", nrow(reclas_conciencia), "\n")
cat("Diferencia (pp), resumen: min=", round(min(reclas_conciencia$diferencia_pp), 1),
    " mediana=", round(median(reclas_conciencia$diferencia_pp), 1),
    " max=", round(max(reclas_conciencia$diferencia_pp), 1), "\n")
cat("SD de la diferencia entre municipios:", round(sd(reclas_conciencia$diferencia_pp), 2), "pp\n")

cat("\n=== RECLASIFICACION: Control (ESH vs AHA) ===\n")
reclas_control <- fitted_por_muni$CONTROL_ESH %>%
  rename(prev_ESH = prev_prom) %>%
  inner_join(fitted_por_muni$CONTROL_AHA %>% rename(prev_AHA = prev_prom), by = "muni_idx") %>%
  mutate(diferencia_pp = 100 * (prev_AHA - prev_ESH))

cat("Municipios comparables:", nrow(reclas_control), "\n")
cat("Diferencia (pp), resumen: min=", round(min(reclas_control$diferencia_pp), 1),
    " mediana=", round(median(reclas_control$diferencia_pp), 1),
    " max=", round(max(reclas_control$diferencia_pp), 1), "\n")
cat("SD de la diferencia entre municipios:", round(sd(reclas_control$diferencia_pp), 2), "pp\n")

# unir con nombres de municipio para inspeccion
reclas_conciencia <- reclas_conciencia %>% left_join(idx_tabla, by = "muni_idx")
reclas_control <- reclas_control %>% left_join(idx_tabla, by = "muni_idx")

write.csv(reclas_conciencia, file.path(RES, "reclasificacion_conciencia_ESH_vs_AHA.csv"), row.names = FALSE)
write.csv(reclas_control, file.path(RES, "reclasificacion_control_ESH_vs_AHA.csv"), row.names = FALSE)
cat("\nGuardado: modelo_FINAL_<paso>.rds (x5), reclasificacion_conciencia_ESH_vs_AHA.csv, reclasificacion_control_ESH_vs_AHA.csv\n")

# --- Diagnosticos del modelo FINAL (WAIC, Phi) ---
# ANTES: Tabla S1 (27_tablas_1_2_3.R) tomaba WAIC/Phi de resumen_6_modelos_bym2_univariados.csv,
# el modelo SIN covariables de area (script 06), no el que genera el mapa (este
# script). Esta seccion exporta el diagnostico del modelo QUE REALMENTE SE USA para impedir que
# las tablas lean el resumen del modelo base por error.
diagnosticos_finales <- data.frame()
for (nombre in names(modelos_finales)) {
  m <- modelos_finales[[nombre]]
  hp <- m$summary.hyperpar
  fila_phi <- hp[grepl("^Phi", rownames(hp)), ]
  diagnosticos_finales <- rbind(diagnosticos_finales, data.frame(
    paso = nombre,
    ponderacion_modelo = PONDERACION_MODELO,
    waic = m$waic$waic,
    phi_mediana = fila_phi[["0.5quant"]],
    phi_ic_l = fila_phi[["0.025quant"]],
    phi_ic_u = fila_phi[["0.975quant"]]
  ))
}
write.csv(diagnosticos_finales, file.path(RES, "resumen_modelos_finales.csv"), row.names = FALSE)
cat("Guardado: resumen_modelos_finales.csv (WAIC/Phi del modelo FINAL, con covariables de area)\n")
