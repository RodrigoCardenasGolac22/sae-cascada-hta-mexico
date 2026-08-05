# Ajusta los modelos BYM2 base (sin covariables de area) para los
# 6 modelos univariados BYM2 (3 pasos de la cascada x 2 criterios), replicando el punto de partida
# de Perú -- 6 BYM2 univariados antes de intentar cualquier shared-component. Sin covariables
# todavia (igual que el paso 7): el proposito de esta etapa es tener los 6 modelos base
# funcionando y comparables, no elegir covariables (eso es un paso posterior, con el mismo
# protocolo WAIC+CPO del script 07).
#
# Tratamiento se ajusta DOS VECES (etiquetado ESH y AHA) aunque por construccion el desenlace es
# identico bajo ambos criterios (no depende del umbral de PA) -- para verificarlo NUMERICAMENTE,
# Se verifica numericamente (n, ajuste del modelo y prevalencia
# suavizada identicos para los modelos de tratamiento etiquetados ESH y AHA").

library(dplyr)
library(readr)
library(INLA)

RES <- "RESULTADOS"
GEO <- "DATOS_GEO_MEXICO"

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

g <- inla.read.graph(file.path(GEO, "municipios.graph"))

modelos <- list(
  AWARE_ESH   = list(outcome = "diag_cronico", denom = "hta_esh"),
  AWARE_AHA   = list(outcome = "diag_cronico", denom = "hta_aha"),
  TRAT_ESH    = list(outcome = "tratado",      denom = "diag_cronico"),
  TRAT_AHA    = list(outcome = "tratado",      denom = "diag_cronico"),
  CONTROL_ESH = list(outcome = "control_esh",  denom = "tratado"),
  CONTROL_AHA = list(outcome = "control_aha",  denom = "tratado")
)

ajustar_bym2 <- function(y, muni_idx) {
  d <- data.frame(y = as.numeric(y), muni_idx = muni_idx)
  inla(
    y ~ 1 + f(muni_idx, model = "bym2", graph = g, scale.model = TRUE, constr = TRUE,
              hyper = list(phi = list(prior = "pc", param = c(0.5, 0.5)),
                           prec = list(prior = "pc.prec", param = c(1, 0.01)))),
    family = "binomial", Ntrials = 1, data = d,
    control.compute = list(waic = TRUE, dic = TRUE, cpo = TRUE),
    control.predictor = list(compute = TRUE, link = 1)
  )
}

resumen <- list()
modelos_ajustados <- list()

for (nombre in names(modelos)) {
  p <- modelos[[nombre]]
  sub <- base[base[[p$denom]] & !is.na(base[[p$denom]]), ]

  t0 <- Sys.time()
  m <- ajustar_bym2(sub[[p$outcome]], sub$muni_idx)
  t1 <- Sys.time()
  tiempo <- round(as.numeric(difftime(t1, t0, units = "secs")), 1)

  hp <- m$summary.hyperpar
  phi_mediana <- hp["Phi for muni_idx", "0.5quant"]
  prev <- m$summary.fitted.values$mean

  resumen[[nombre]] <- data.frame(
    desenlace = nombre, n = nrow(sub), n_municipios = n_distinct(sub$muni_idx),
    tiempo_seg = tiempo, waic = m$waic$waic, dic = m$dic$dic,
    cpo_fallos = sum(m$cpo$failure > 0, na.rm = TRUE),
    phi_mediana = round(phi_mediana, 3),
    prev_min = round(min(prev), 3), prev_mediana = round(median(prev), 3), prev_max = round(max(prev), 3)
  )
  modelos_ajustados[[nombre]] <- m

  cat(sprintf("[%s] n=%d, municipios=%d, %.1fs, WAIC=%.1f, DIC=%.1f, phi=%.3f, prev=%.3f-%.3f-%.3f, CPO fallos=%d\n",
              nombre, nrow(sub), n_distinct(sub$muni_idx), tiempo, m$waic$waic, m$dic$dic, phi_mediana,
              min(prev), median(prev), max(prev), sum(m$cpo$failure > 0, na.rm = TRUE)))

  saveRDS(m, file.path(RES, paste0("modelo_bym2_", nombre, ".rds")))
}

resumen_df <- do.call(rbind, resumen)
cat("\n=== RESUMEN: 6 MODELOS BYM2 UNIVARIADOS ===\n")
print(resumen_df, row.names = FALSE)

# verificacion numerica: TRAT_ESH y TRAT_AHA deben ser identicos por construccion
cat("\n=== VERIFICACION: TRAT_ESH == TRAT_AHA (deben ser identicos por construccion) ===\n")
cat("n identico:", resumen_df$n[resumen_df$desenlace=="TRAT_ESH"] == resumen_df$n[resumen_df$desenlace=="TRAT_AHA"], "\n")
cat("WAIC identico:", isTRUE(all.equal(resumen_df$waic[resumen_df$desenlace=="TRAT_ESH"], resumen_df$waic[resumen_df$desenlace=="TRAT_AHA"])), "\n")
cat("Prevalencia mediana identica:", resumen_df$prev_mediana[resumen_df$desenlace=="TRAT_ESH"] == resumen_df$prev_mediana[resumen_df$desenlace=="TRAT_AHA"], "\n")

write.csv(resumen_df, file.path(RES, "resumen_6_modelos_bym2_univariados.csv"), row.names = FALSE)
cat("\nGuardado: resumen_6_modelos_bym2_univariados.csv + 6 .rds\n")
