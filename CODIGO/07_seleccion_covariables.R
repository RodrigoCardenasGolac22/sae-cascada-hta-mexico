# Selecciona las covariables de area probandolas UNA POR UNA contra el modelo base.
#
# CRITERIO DE DECISION. El umbral fijo de "DeltaWAIC >= 2" que se usaba antes procede del folclore
# del AIC (Burnham & Anderson) y NO es una convencion establecida para el WAIC; atribuirselo a
# Spiegelhalter et al. era ademas incorrecto: ese articulo es del DIC. La forma correcta de decidir
# la propone la misma fuente que se cita para el WAIC (Vehtari, Gelman & Gabry 2017,
# doi 10.1007/s11222-016-9696-4): comparar la diferencia contra SU PROPIO ERROR ESTANDAR, que se
# obtiene de las contribuciones punto por punto,
#     SE(DeltaWAIC) = sqrt(n) * sd(waic_i^{con cov} - waic_i^{base}),
# porque las dos cantidades se calculan sobre las MISMAS observaciones y su diferencia es una media
# muestral. Se reportan las dos reglas: el umbral fijo preespecificado y la calibrada por el error
# estandar, de modo que se ve si coinciden.
#
# Ademas, validacion independiente con CPO leave-one-out para cualquier candidata con evidencia.
#
# Estructura: "modelo base" = BYM2 + sexo + edad + escolaridad + estrato (urbanicidad) --
# covariables de ajuste individual incluidas de forma uniforme en todos los modelos siguientes,
# como ajuste demografico uniforme, sin testeo individual por paso.
# Candidatas de area, probadas UNA POR UNA sobre el modelo base: pobreza (CONEVAL), densidad de
# establecimientos CLUES por 10 000 adultos (total y publica; decision B5 opcion 2, 2026-08-06) y
# altitud.

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
stopifnot(sum(is.na(base$muni_idx)) == 0)
base$muni_id <- paste0(base$entidad, base$municipio)

# Covariables de area por el cargador comun (00_comun.R): la especificacion tiene que ser
# IDENTICA a la de 08/09/10/11. Antes este script tenia su propia copia del bloque de carga, que
# es exactamente el patron que dejo divergir la seleccion del modelo publicado (ver A1 del plan).
base <- cargar_covariables_area(base, COV) %>%
  mutate(sexo_f = factor(sexo), estrato_f = factor(estrato),
         escolaridad_f = factor(escolaridad, levels = NIVELES_ESCOLARIDAD),
         anio_f = factor(anio))

cat("Cobertura de covariables en la base modelada (n filas):\n")
cat("  pobreza_pct NA:", sum(is.na(base$pobreza_pct)), "\n")
cat("  altitud_msnm NA:", sum(is.na(base$altitud_msnm)), "\n")

g <- inla.read.graph(file.path(GEO, "municipios.graph"))

pasos <- list(
  AWARE_ESH   = list(outcome = "diag_cronico", denom = "hta_esh"),
  AWARE_AHA   = list(outcome = "diag_cronico", denom = "hta_aha"),
  TRAT        = list(outcome = "tratado",      denom = "diag_cronico"),
  CONTROL_ESH = list(outcome = "control_esh",  denom = "tratado"),
  CONTROL_AHA = list(outcome = "control_aha",  denom = "tratado")
)
# TRAT se corre una sola vez (identico bajo ESH/AHA por construccion, verificado en el script 06):
# se etiqueta
# igual para los dos criterios al reportar, para no duplicar computo sin necesidad.

ajustar <- function(formula_rhs, datos) {
  f <- as.formula(paste("y ~", formula_rhs))
  inla(f, family = "binomial", Ntrials = 1, data = datos,
       control.compute = list(waic = TRUE, cpo = TRUE),
       control.predictor = list(compute = TRUE, link = 1))
}

bym2_term <- "f(muni_idx, model='bym2', graph=g, scale.model=TRUE, constr=TRUE, hyper=list(phi=list(prior='pc', param=c(0.5,0.5)), prec=list(prior='pc.prec', param=c(1,0.01))))"
base_rhs <- paste("1 +", bym2_term, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f")

# CLUES entra como DENSIDAD por 10 000 adultos (B5 opcion 2), no como conteo: el conteo -- aun en
# log -- iba confundido con el tamano del municipio. Los nombres de las candidatas son los mismos
# de la variable, para que resumen_covariables_waic_cpo.csv diga exactamente que se probo.
candidatas <- list(
  pobreza               = "pobreza_pct",
  clues_por_10k         = "clues_por_10k",
  clues_publico_por_10k = "clues_publico_por_10k",
  altitud               = "altitud_msnm"
)

resultados_waic <- list()
modelos_base_ajustados <- list()

for (nombre in names(pasos)) {
  p <- pasos[[nombre]]
  sub <- base %>% filter(.data[[p$denom]], !is.na(.data[[p$denom]])) %>%
    mutate(y = as.numeric(.data[[p$outcome]]))
  # escolaridad_f esta en el modelo base (base_rhs) -- si queda NA, INLA no la maneja como
  # prediccion (a diferencia de NA en el desenlace), asi que hay que filtrarla aqui tambien,
  # no solo sexo/edad/estrato: INLA no trata los NA de una covariable fija como prediccion
  n_antes_na <- nrow(sub)
  sub <- sub %>% filter(!is.na(sexo_f), !is.na(edad), !is.na(estrato_f), !is.na(escolaridad_f))
  if (nrow(sub) < n_antes_na) {
    cat(sprintf("  (%d filas excluidas por NA en sexo/edad/estrato/escolaridad, de %d)\n",
                n_antes_na - nrow(sub), n_antes_na))
  }

  cat(sprintf("\n=== %s (n=%d) ===\n", nombre, nrow(sub)))

  t0 <- Sys.time()
  m_base <- ajustar(base_rhs, sub)
  t1 <- Sys.time()
  cat(sprintf("  Modelo base (BYM2+sexo+edad+escolaridad+estrato): %.1fs, WAIC=%.1f\n",
              as.numeric(difftime(t1, t0, units = "secs")), m_base$waic$waic))
  modelos_base_ajustados[[nombre]] <- m_base

  for (cov_nombre in names(candidatas)) {
    cov_var <- candidatas[[cov_nombre]]
    sub_cov <- sub %>% filter(!is.na(.data[[cov_var]]))
    if (nrow(sub_cov) < nrow(sub)) {
      cat(sprintf("  [%s] %d filas sin %s, excluidas para esta comparacion\n",
                  cov_nombre, nrow(sub) - nrow(sub_cov), cov_var))
    }

    rhs_con_cov <- paste(base_rhs, "+", cov_var)
    t0 <- Sys.time()
    m_cov <- tryCatch(ajustar(rhs_con_cov, sub_cov), error = function(e) {
      cat("    ERROR:", conditionMessage(e), "\n"); NULL
    })
    t1 <- Sys.time()

    if (!is.null(m_cov)) {
      # re-ajustar el modelo base SOBRE EL MISMO subconjunto (sub_cov) para que la comparacion de
      # WAIC sea justa si hubo filas excluidas por covariable faltante
      m_base_mismo_n <- if (nrow(sub_cov) == nrow(sub)) m_base else ajustar(base_rhs, sub_cov)

      delta_waic <- m_cov$waic$waic - m_base_mismo_n$waic$waic
      delta_cpo <- sum(log(m_cov$cpo$cpo), na.rm = TRUE) - sum(log(m_base_mismo_n$cpo$cpo), na.rm = TRUE)
      cpo_fallos <- sum(m_cov$cpo$failure > 0, na.rm = TRUE)

      # Error estandar de la diferencia, desde las contribuciones punto por punto de cada modelo
      # sobre las MISMAS observaciones (ver la nota de cabecera).
      dif_i <- m_cov$waic$local.waic - m_base_mismo_n$waic$local.waic
      stopifnot(length(dif_i) == nrow(sub_cov))
      se_delta <- sqrt(length(dif_i)) * sd(dif_i)
      razon <- delta_waic / se_delta

      evidencia <- if (delta_waic <= -2) "REAL (mejora)" else if (delta_waic >= 2) "REAL (empeora)" else "ruido (|Delta|<2)"
      evidencia_se <- if (abs(razon) >= 2) {
        if (delta_waic < 0) "REAL (mejora)" else "REAL (empeora)"
      } else "ruido (|Delta| < 2 EE)"
      concuerdan <- identical(evidencia, evidencia_se)

      cat(sprintf("  [%s] %.1fs, DeltaWAIC=%.2f (EE %.2f = %.1f EE) -> fijo: %s | EE: %s%s | Delta log-CPO=%.2f | CPO fallos=%d\n",
                  cov_nombre, as.numeric(difftime(t1, t0, units = "secs")),
                  delta_waic, se_delta, razon, evidencia, evidencia_se,
                  if (concuerdan) "" else "   <<< DISCREPAN", delta_cpo, cpo_fallos))

      resultados_waic[[paste(nombre, cov_nombre)]] <- data.frame(
        paso = nombre, covariable = cov_nombre, n = nrow(sub_cov),
        waic_base = m_base_mismo_n$waic$waic, waic_con_cov = m_cov$waic$waic,
        delta_waic = round(delta_waic, 2), se_delta_waic = round(se_delta, 2),
        razon_delta_se = round(razon, 2),
        evidencia_waic = evidencia, evidencia_se = evidencia_se, concuerdan = concuerdan,
        delta_log_cpo = round(delta_cpo, 2), cpo_fallos = cpo_fallos
      )
    }
  }
}

resumen_df <- do.call(rbind, resultados_waic)
cat("\n\n=== RESUMEN COMPLETO: EVIDENCIA DE COVARIABLES POR PASO ===\n")
print(resumen_df, row.names = FALSE)

cat(sprintf("
Las dos reglas de decision coinciden en %d de %d comparaciones.
",
            sum(resumen_df$concuerdan), nrow(resumen_df)))
if (any(!resumen_df$concuerdan)) {
  cat("Discrepan en:
")
  print(resumen_df[!resumen_df$concuerdan,
                   c("paso", "covariable", "delta_waic", "se_delta_waic", "razon_delta_se",
                     "evidencia_waic", "evidencia_se")], row.names = FALSE)
}

write.csv(resumen_df, file.path(RES, "resumen_covariables_waic_cpo.csv"), row.names = FALSE)
saveRDS(modelos_base_ajustados, file.path(RES, "modelos_base_con_demograficas.rds"))
cat("\nGuardado: resumen_covariables_waic_cpo.csv, modelos_base_con_demograficas.rds\n")
