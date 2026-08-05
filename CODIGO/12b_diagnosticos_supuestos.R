# =============================================================================
# Verificacion de los supuestos de los modelos finales.
#
# Por que existe: la nota metodologica de INEGI (referencia 4), el antecedente
# municipal de este trabajo, dedica una seccion a comprobar los supuestos de su
# modelo -- normalidad, homocedasticidad y multicolinealidad -- y aqui no se
# comprobaba ninguno.
#
# Los supuestos NO son los mismos, y copiarlos habria sido un error. INEGI ajusta
# un Fay-Herriot lineal sobre tasas agregadas por area: alli la normalidad y la
# homocedasticidad de los residuos son supuestos centrales. Este modelo es
# binomial jerarquico de nivel-unidad con enlace logit, donde la varianza queda
# determinada por la media (la homocedasticidad no aplica) y el residuo
# individual no puede ser normal porque el desenlace es 0/1.
#
# ADVERTENCIA sobre tres diagnosticos que parecen obvios y NO lo son. La primera
# version de este script los calculo asi y daba numeros que invitaban a concluir
# que el modelo fallaba, cuando lo que fallaba era el diagnostico:
#
#   * Moran I sobre el EFECTO BYM2: da 0,30-0,99 con p<0,001 en los cinco pasos,
#     pero es que el efecto espacial DEBE estar autocorrelacionado, es su
#     proposito. De hecho sigue a Phi punto por punto (Phi 0,105 -> I 0,46;
#     Phi 0,81 -> I 0,99): mide lo mismo que Phi, no lo que sobra. Lo que hay
#     que mirar es el Moran de los RESIDUOS.
#   * PIT sin aleatorizar: con desenlace binario sigue a la prevalencia
#     (65,8 % -> 0,797; 81,0 % -> 0,886), no a la calidad de la calibracion.
#     Se usa el PIT aleatorizado de Czado et al. (2009).
#   * Shapiro sobre el efecto TOTAL del BYM2 (u+v): ese efecto es una mezcla de
#     un componente ICAR y uno gaussiano, y no tiene por que ser normal. El
#     supuesto gaussiano recae sobre el componente NO estructurado v.
#
# Se corre despues de 08_modelos_finales.R y de 09_extension_nacional.R, leyendo
# lo ya calculado: no reajusta ningun modelo.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(INLA); library(spdep)
})

RES <- "RESULTADOS"; GEO <- "DATOS_GEO_MEXICO"; COV <- "COVARIABLES"

pasos <- c("AWARE_ESH", "AWARE_AHA", "TRAT", "CONTROL_ESH", "CONTROL_AHA")
etiqueta <- c(AWARE_ESH = "Diagnóstico (ESH)", AWARE_AHA = "Diagnóstico (AHA)",
              TRAT = "Tratamiento", CONTROL_ESH = "Control (ESH)", CONTROL_AHA = "Control (AHA)")
directa <- c(AWARE_ESH = "directa_conciencia_ESH_municipio.csv",
             AWARE_AHA = "directa_conciencia_AHA_municipio.csv",
             TRAT      = "directa_tratamiento_municipio.csv",
             CONTROL_ESH = "directa_control_ESH_municipio.csv",
             CONTROL_AHA = "directa_control_AHA_municipio.csv")
# covariables de area que el protocolo selecciono en cada modelo (script 07)
covs_modelo <- list(AWARE_ESH = "pobreza_pct",
                    AWARE_AHA = c("pobreza_pct", "clues_total"),
                    TRAT = character(0),
                    CONTROL_ESH = c("pobreza_pct", "clues_total"),
                    CONTROL_AHA = c("pobreza_pct", "clues_total"))

# --- 1. Multicolinealidad ----------------------------------------------------
# Se calcula sobre las combinaciones QUE CADA MODELO USA. Calcularlo sobre las
# cuatro candidatas a la vez inflaria el VIF de clues_total hasta 4,65 por su
# correlacion de 0,88 con clues_publico -- una variable que ningun modelo final
# incluye, porque cuando las dos superaban el umbral se tomo solo una.
coneval <- read_csv(file.path(COV, "coneval_pobreza_municipal_2020.csv"),
                    col_types = cols(.default = col_character()))
coneval$muni_id <- sprintf("%05d", as.numeric(coneval$clave_municipio))
coneval$pobreza_pct <- as.numeric(coneval$pobreza)
clues <- read_csv(file.path(COV, "clues_conteo_municipal.csv"),
                  col_types = cols(muni_id = col_character()))
cov_muni <- coneval %>% select(muni_id, pobreza_pct) %>%
  left_join(clues %>% select(muni_id, clues_total), by = "muni_id")

vif_de <- function(vs, d) {
  if (length(vs) < 2) return(setNames(rep(1, length(vs)), vs))   # con 1 covariable no hay colinealidad
  sapply(vs, function(v) {
    r2 <- summary(lm(as.formula(paste(v, "~", paste(setdiff(vs, v), collapse = "+"))), d))$r.squared
    1 / (1 - r2)
  })
}
vif_filas <- lapply(names(covs_modelo), function(p) {
  vs <- covs_modelo[[p]]
  if (length(vs) == 0) return(tibble(Paso = etiqueta[[p]], Covariable = "(sin covariables de área)", VIF = NA_real_))
  tibble(Paso = etiqueta[[p]], Covariable = vs, VIF = round(as.numeric(vif_de(vs, cov_muni)), 2))
})
vif_tab <- bind_rows(vif_filas)
write_csv(vif_tab, file.path(RES, "diag_multicolinealidad.csv"))
cat("1. MULTICOLINEALIDAD (VIF sobre la especificacion real de cada modelo)\n")
print(as.data.frame(vif_tab), row.names = FALSE)
cat(sprintf("   correlacion pobreza-clues_total: %.3f\n\n",
            cor(cov_muni$pobreza_pct, cov_muni$clues_total, use = "pairwise.complete.obs")))

# --- vecindad: el MISMO grafo que usan los modelos ---------------------------
g_inla <- inla.read.graph(file.path(GEO, "municipios.graph"))
nb <- lapply(seq_len(g_inla$n), function(i) {
  v <- g_inla$nbs[[i]]; if (length(v) == 0L) 0L else as.integer(v)
})
class(nb) <- "nb"; attr(nb, "region.id") <- as.character(seq_len(g_inla$n))

filas <- list()
for (p in pasos) {
  f <- file.path(RES, paste0("modelo_FINAL_", p, ".rds"))
  if (!file.exists(f)) { cat("falta", f, "\n"); next }
  m <- readRDS(f)
  n_area <- g_inla$n

  # --- 2. Normalidad del componente NO estructurado -------------------------
  # summary.random del bym2 apila 2N filas: 1..N es el efecto total (u+v) y
  # N+1..2N es el componente espacial estructurado u. El supuesto gaussiano iid
  # recae sobre v = (u+v) - u, que es el que se extrae aqui.
  tot <- m$summary.random$muni_idx$mean[seq_len(n_area)]
  u   <- m$summary.random$muni_idx$mean[n_area + seq_len(n_area)]
  v   <- tot - u
  v   <- v[is.finite(v)]
  sw  <- tryCatch(shapiro.test(v[seq_len(min(length(v), 5000))]), error = function(e) NULL)
  # Shapiro-Wilk con n = 2478 rechaza ante desviaciones minimas, y ademas se aplica
  # sobre MEDIAS POSTERIORES, que el encogimiento bayesiano concentra alrededor de
  # cero: incluso con el modelo bien especificado saldrian leptocurticas. La forma
  # se describe mejor con asimetria y curtosis, que dicen CUANTO se desvia y en que
  # sentido, en vez de un p-valor que solo dice que n es grande.
  z <- (v - mean(v)) / sd(v)
  asim <- mean(z^3)
  curt <- mean(z^4) - 3          # exceso de curtosis; 0 = normal

  # --- 3. Autocorrelacion espacial de los RESIDUOS --------------------------
  # residuo de area = prevalencia directa observada - prevalencia del modelo,
  # solo donde hay muestra directa. Si el termino espacial hizo su trabajo, lo
  # que queda no debe seguir agrupado geograficamente.
  dir_p <- read_csv(file.path(RES, directa[[p]]), col_types = cols(muni_id = col_character()))
  nac   <- read_csv(file.path(RES, paste0("NACIONAL_", p, ".csv")),
                    col_types = cols(cve_ent = col_character(), cve_mun = col_character()))
  # los dos archivos escriben la clave municipal en formatos distintos:
  # "01_001" en las estimaciones directas y "01"+"001" en las nacionales.
  dir_p$muni_id <- gsub("_", "", dir_p$muni_id, fixed = TRUE)
  nac$muni_id   <- paste0(nac$cve_ent, nac$cve_mun)
  comunes <- length(intersect(dir_p$muni_id, nac$muni_id))
  if (comunes == 0) stop("Las claves municipales no cruzan en ", p, ": revisar el formato de muni_id")
  res <- nac %>% select(muni_idx, muni_id, prev) %>%
    inner_join(dir_p %>% select(muni_id, prevalencia), by = "muni_id") %>%
    filter(is.finite(prevalencia), is.finite(prev)) %>%
    mutate(residuo = prevalencia - prev)
  # El subgrafo se construye a mano y no con subset.nb: hay que quedarse solo con
  # los municipios que tienen residuo y RENUMERAR sus vecinos a la nueva posicion,
  # descartando los vecinos que quedan fuera de la seleccion.
  idx  <- sort(unique(res$muni_idx[res$muni_idx >= 1 & res$muni_idx <= n_area]))
  pos  <- match(seq_len(n_area), idx)              # posicion nueva de cada area, NA si sale
  nb_sub <- lapply(idx, function(i) {
    v <- nb[[i]]
    v <- v[v != 0L]
    w <- pos[v]; w <- w[!is.na(w)]
    if (length(w) == 0L) 0L else as.integer(sort(w))
  })
  class(nb_sub) <- "nb"; attr(nb_sub, "region.id") <- as.character(seq_along(idx))
  lw_sub <- nb2listw(nb_sub, style = "W", zero.policy = TRUE)
  r_ord  <- res$residuo[match(idx, res$muni_idx)]
  mi <- tryCatch(moran.test(r_ord, lw_sub, zero.policy = TRUE, na.action = na.omit),
                 error = function(e) NULL)

  # --- 4. Calibracion predictiva: PIT ALEATORIZADO --------------------------
  # Czado, Gneiting & Held (2009): con desenlace discreto el PIT solo es
  # uniforme si se aleatoriza dentro del salto de la distribucion predictiva.
  # INLA da pit = P(Y <= y) y cpo = P(Y = y), asi que u = pit - runif*cpo.
  set.seed(20260804)
  ok <- is.finite(m$cpo$pit) & is.finite(m$cpo$cpo)
  pit_r <- m$cpo$pit[ok] - runif(sum(ok)) * m$cpo$cpo[ok]
  ks <- suppressWarnings(ks.test(pit_r, "punif"))

  fallos <- sum(m$cpo$failure > 0, na.rm = TRUE)

  filas[[p]] <- tibble(
    Paso = etiqueta[[p]],
    `Municipios con residuo` = length(r_ord),
    `Moran I de los residuos` = if (is.null(mi)) NA_real_ else round(unname(mi$estimate[1]), 4),
    `Moran: p` = if (is.null(mi)) NA_real_ else round(mi$p.value, 3),
    `v: asimetría` = round(asim, 2),
    `v: exceso de curtosis` = round(curt, 2),
    `PIT aleatorizado: media` = round(mean(pit_r), 3),
    `PIT: p (KS)` = round(ks$p.value, 3),
    `Fallos de CPO` = fallos
  )
  cat(sprintf("%-13s residuos n=%3d | Moran I=%+.4f (p=%.3f) | v asim=%+.2f curt=%+.2f (Shapiro p=%.3f) | PIT=%.3f (KS p=%.3f) | CPO=%d\n",
              p, length(r_ord),
              if (is.null(mi)) NA else unname(mi$estimate[1]),
              if (is.null(mi)) NA else mi$p.value,
              asim, curt, if (is.null(sw)) NA else sw$p.value,
              mean(pit_r), ks$p.value, fallos))
  rm(m); gc(verbose = FALSE)
}

diag <- bind_rows(filas)
write_csv(diag, file.path(RES, "diagnosticos_supuestos.csv"))
cat("\nGuardado: RESULTADOS/diagnosticos_supuestos.csv y diag_multicolinealidad.csv\n")
