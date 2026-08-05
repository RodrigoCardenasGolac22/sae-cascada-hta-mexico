# Paso 9 de la secuencia: ajusta los modelos FINALES con la especificacion que sale del protocolo
# WAIC+CPO del script 07 (mejora del WAIC >= 2 unidades confirmada por CPO en la misma direccion),
# no de una eleccion a priori uniforme.
#
# Especificacion vigente. Se decide sobre la muestra completa, que incluye a los adultos sin
# escolaridad (codigo 0), unas 800 personas por modelo y las de menor escolaridad: excluirlas
# sesgaria un estudio sobre desigualdad. La evidencia con la muestra completa es:
#
#   paso          pobreza          clues_total       -> covariables de area del modelo final
#   AWARE_ESH     -8,48 REAL       -0,84 ruido          pobreza
#   AWARE_AHA     -7,26 REAL       -2,05 REAL           pobreza + clues_total   (clues es NUEVO)
#   TRAT          +1,22 ruido      -0,87 ruido          ninguna
#   CONTROL_ESH   -6,66 REAL       -4,64 REAL           pobreza + clues_total
#   CONTROL_AHA  -10,34 REAL       -3,40 REAL           pobreza + clues_total   (clues es NUEVO)
#
# Dos cambios respecto de la corrida anterior, los dos por recuperar a esa poblacion:
#  (a) la evidencia de pobreza casi se DUPLICA en los cuatro pasos donde ya estaba;
#  (b) en TRAT, pobreza pasa de "REAL pero empeora el ajuste" (+2,49) a simple ruido (+1,22): aquel
#      resultado incomodo era un artefacto de la muestra truncada, no un hallazgo.
# La altitud sigue sin ser relevante en ningun paso.
#
# Donde clues_total y clues_publico son las dos REAL (CONTROL_ESH) se toma clues_total, de mayor
# |DeltaWAIC|, para no meter dos variables CLUES casi colineales en el mismo modelo.
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

coneval <- read_csv(file.path(COV, "coneval_pobreza_municipal_2020.csv"), col_types = cols(.default = col_character()))
coneval$muni_id <- sprintf("%05d", as.numeric(coneval$clave_municipio))
coneval$pobreza_pct <- as.numeric(coneval$pobreza)

clues <- read_csv(file.path(COV, "clues_conteo_municipal.csv"), col_types = cols(muni_id = col_character()))

base <- base %>%
  left_join(coneval %>% select(muni_id, pobreza_pct), by = "muni_id") %>%
  left_join(clues %>% select(muni_id, clues_total), by = "muni_id") %>%
  mutate(sexo_f = factor(sexo), estrato_f = factor(estrato),
         escolaridad_f = factor(escolaridad, levels = NIVELES_ESCOLARIDAD),
         anio_f = factor(anio))

g <- inla.read.graph(file.path(GEO, "municipios.graph"))
bym2_term <- "f(muni_idx, model='bym2', graph=g, scale.model=TRUE, constr=TRUE, hyper=list(phi=list(prior='pc', param=c(0.5,0.5)), prec=list(prior='pc.prec', param=c(1,0.01))))"

ajustar <- function(formula_rhs, datos) {
  f <- as.formula(paste("y ~", formula_rhs))
  inla(f, family = "binomial", Ntrials = 1, data = datos,
       control.compute = list(waic = TRUE, cpo = TRUE, config = TRUE),
       control.predictor = list(compute = TRUE, link = 1))
}

# Especificacion final, resultante del protocolo WAIC+CPO del script 07:
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

modelos_finales <- list()
fitted_por_muni <- list()

for (nombre in names(especificaciones)) {
  e <- especificaciones[[nombre]]
  sub <- base %>% filter(.data[[e$denom]], !is.na(.data[[e$denom]])) %>%
    mutate(y = as.numeric(.data[[e$outcome]])) %>%
    filter(!is.na(sexo_f), !is.na(edad), !is.na(estrato_f), !is.na(escolaridad_f))
  if (grepl("pobreza_pct", e$rhs)) sub <- sub %>% filter(!is.na(pobreza_pct))
  if (grepl("clues_total", e$rhs)) sub <- sub %>% filter(!is.na(clues_total))

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
  prom_muni <- sub %>% group_by(muni_idx) %>% summarise(prev_prom = mean(fitted), .groups = "drop")
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
# script). Para AWARE_ESH/AWARE_AHA/CONTROL_ESH/CONTROL_AHA el WAIC y el Phi difieren sustancialmente
# porque esos 4 modelos SI llevan pobreza/clues_total; solo TRAT coincide por poco margen. Verificado
# cargando los .rds ya guardados: Phi mediana pasa de 0,13/0,14/0,76/0,54/0,25 (modelo sin
# covariables) a 0,087/0,050/0,790/0,720/0,566 (modelo final, el correcto). Esta seccion exporta el
# diagnostico del modelo QUE REALMENTE SE USA, para que 27_tablas_1_2_3.R deje de leer del CSV
# equivocado.
diagnosticos_finales <- data.frame()
for (nombre in names(modelos_finales)) {
  m <- modelos_finales[[nombre]]
  hp <- m$summary.hyperpar
  fila_phi <- hp[grepl("^Phi", rownames(hp)), ]
  diagnosticos_finales <- rbind(diagnosticos_finales, data.frame(
    paso = nombre,
    waic = m$waic$waic,
    phi_mediana = fila_phi[["0.5quant"]],
    phi_ic_l = fila_phi[["0.025quant"]],
    phi_ic_u = fila_phi[["0.975quant"]]
  ))
}
write.csv(diagnosticos_finales, file.path(RES, "resumen_modelos_finales.csv"), row.names = FALSE)
cat("Guardado: resumen_modelos_finales.csv (WAIC/Phi del modelo FINAL, con covariables de area)\n")
