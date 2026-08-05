# Extrae de los modelos finales YA AJUSTADOS (no reajusta nada) las dos cosas que el manuscrito
# necesita reportar y antes no reportaba:
#
#  1. EFECTO DEL ANIO. El estudio agrupa cuatro rondas y la mayoria de los municipios se observa en
#     una sola, asi que la magnitud del desplazamiento temporal es informacion que el lector
#     necesita para juzgar el mapa. Pasa de ser un supuesto declarado "no verificado" a ser un
#     resultado con su intervalo.
#
#  2. COEFICIENTE DE CADA COVARIABLE DE AREA. La pregunta "¿esta variable se asocia con el
#     desenlace?" la responde el coeficiente y su intervalo de credibilidad, NO el DeltaWAIC, que
#     responde otra: "¿mejora la prediccion fuera de muestra?". El manuscrito usaba el segundo para
#     afirmar lo primero.

library(dplyr)
library(INLA)

RES <- "RESULTADOS"
PASOS <- c("AWARE_ESH", "AWARE_AHA", "TRAT", "CONTROL_ESH", "CONTROL_AHA")
paso_legible <- c(AWARE_ESH = "Diagnóstico (ESH)", AWARE_AHA = "Diagnóstico (AHA)",
                  TRAT = "Tratamiento", CONTROL_ESH = "Control (ESH)", CONTROL_AHA = "Control (AHA)")
cov_legible <- c(pobreza_pct = "Pobreza municipal (%)",
                 clues_total = "Establecimientos de salud (n)")

anios <- list(); coefs <- list()

for (p in PASOS) {
  m <- readRDS(file.path(RES, paste0("modelo_FINAL_", p, ".rds")))
  fx <- m$summary.fixed

  # --- efecto del anio, en razon de momios respecto del anio de referencia ---
  filas_anio <- grep("^anio_f", rownames(fx), value = TRUE)
  if (length(filas_anio) == 0) {
    stop("El modelo ", p, " no incluye anio_f. Reajustar el paso 08 antes de correr este.")
  }
  for (f in filas_anio) {
    r <- fx[f, ]
    anios[[paste(p, f)]] <- data.frame(
      paso = paso_legible[[p]], anio = sub("^anio_f", "", f),
      or = exp(r[["mean"]]), or_l = exp(r[["0.025quant"]]), or_u = exp(r[["0.975quant"]]),
      excluye_1 = r[["0.025quant"]] > 0 || r[["0.975quant"]] < 0)
  }

  # --- covariables de area ---
  for (v in intersect(names(cov_legible), rownames(fx))) {
    r <- fx[v, ]
    # P(beta < 0): probabilidad posterior de que el efecto sea negativo. Se reporta la masa
    # posterior a un lado del cero en vez de un "significativo si/no".
    pneg <- INLA::inla.pmarginal(0, m$marginals.fixed[[v]])
    coefs[[paste(p, v)]] <- data.frame(
      paso = paso_legible[[p]], covariable = cov_legible[[v]],
      beta = r[["mean"]], beta_l = r[["0.025quant"]], beta_u = r[["0.975quant"]],
      p_beta_negativo = pneg,
      excluye_0 = r[["0.025quant"]] > 0 || r[["0.975quant"]] < 0)
  }
}

anio_df <- bind_rows(anios)
coef_df <- bind_rows(coefs)

cat("=== EFECTO DEL ANIO (razon de momios vs. el anio de referencia) ===\n")
print(anio_df, row.names = FALSE)
cat("\n=== COVARIABLES DE AREA: coeficiente e intervalo de credibilidad ===\n")
print(coef_df, row.names = FALSE)
cat(sprintf("\nCovariables cuyo IC 95%% excluye el 0: %d de %d\n",
            sum(coef_df$excluye_0), nrow(coef_df)))

write.csv(anio_df, file.path(RES, "efecto_anio.csv"), row.names = FALSE)
write.csv(coef_df, file.path(RES, "coeficientes_area.csv"), row.names = FALSE)
cat("\nGuardado: efecto_anio.csv, coeficientes_area.csv\n")
