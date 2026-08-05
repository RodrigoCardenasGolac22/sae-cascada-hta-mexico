# Paso 10 (parte pendiente): sensibilidad a la matriz de vecindad (plan Sec 6.4). Se construye una
# matriz alternativa (contigüidad "torre"/rook, comparte borde pero no basta con tocar en un
# vértice) frente a la usada en el modelo principal ("reina"/queen, script 05), y se re-ajusta el
# modelo del paso con el phi mas
# alto (Tratamiento, phi=0.761 en la corrida corregida -- el mas sensible a la definicion de
# vecindad, si algo va a cambiar por este supuesto sera ahi, no en un paso con phi bajo) para
# comparar WAIC, phi y prevalencia suavizada bajo las dos definiciones.

library(sf)
library(spdep)
library(dplyr)
library(readr)
library(INLA)

source("CODIGO/00_comun.R")   # NIVELES_ESCOLARIDAD

SHP <- "DATOS_GEO_MEXICO/municipios_INEGI_oficial/inegi_extracted/QGis/MapaBaseMultiescala.gpkg"
GEO <- "DATOS_GEO_MEXICO"
RES <- "RESULTADOS"

m <- st_read(SHP, layer = "municipios_4m", quiet = TRUE)
stopifnot(sum(st_is_empty(m)) == 0, sum(!st_is_valid(m)) == 0)

nb_queen <- poly2nb(m, queen = TRUE)
nb_rook  <- poly2nb(m, queen = FALSE)

cat("=== Comparacion de definiciones de vecindad ===\n")
cat(sprintf("Reina (queen, la usada en el modelo principal): mediana %d vecinos, %d islas\n",
            median(card(nb_queen)), sum(card(nb_queen) == 0)))
cat(sprintf("Torre (rook, alternativa de sensibilidad):      mediana %d vecinos, %d islas\n",
            median(card(nb_rook)), sum(card(nb_rook) == 0)))

idx_rook_islas <- which(card(nb_rook) == 0)
if (length(idx_rook_islas) > 0) {
  cent <- st_centroid(st_geometry(m))
  coords <- st_coordinates(cent)
  for (i in idx_rook_islas) {
    d <- spDistsN1(coords, coords[i, ], longlat = FALSE)
    d[i] <- Inf
    vecino <- which.min(d)
    nb_rook[[i]] <- as.integer(vecino)
    nb_rook[[vecino]] <- sort(unique(c(nb_rook[[vecino]], as.integer(i))))
  }
  cat(sprintf("Islas de la matriz rook (%d) conectadas a su vecino mas cercano por centroide,\n",
              length(idx_rook_islas)))
  cat("mismo criterio aplicado a la matriz reina (script 05).\n")
}

nb2INLA(file.path(GEO, "municipios_rook.graph"), nb_rook)
cat("Guardado: DATOS_GEO_MEXICO/municipios_rook.graph\n\n")

# --- Re-ajustar TRAT (el de mayor phi) con la matriz rook, comparar contra el modelo final queen ---
base <- read_csv(file.path(RES, "base_analitica_adultos_2021_2024.csv"),
                  col_types = cols(
                    entidad = col_character(), municipio = col_character(),
                    diag_cronico = col_logical(), hta_esh = col_logical(), hta_aha = col_logical(),
                    tratado = col_logical(), control_esh = col_logical(), control_aha = col_logical(),
                    .default = col_guess()
                  ))
idx_tabla <- read_csv(file.path(GEO, "muni_idx_grafo.csv"), col_types = cols(
  cve_ent = col_character(), cve_mun = col_character()))
base <- base %>% left_join(idx_tabla, by = c("entidad" = "cve_ent", "municipio" = "cve_mun")) %>%
  mutate(sexo_f = factor(sexo), estrato_f = factor(estrato),
         escolaridad_f = factor(escolaridad, levels = NIVELES_ESCOLARIDAD),
         anio_f = factor(anio))

sub <- base %>% filter(diag_cronico, !is.na(diag_cronico)) %>%
  mutate(y = as.numeric(tratado)) %>%
  filter(!is.na(sexo_f), !is.na(edad), !is.na(estrato_f), !is.na(escolaridad_f))

g_rook <- inla.read.graph(file.path(GEO, "municipios_rook.graph"))
bym2_term_rook <- "f(muni_idx, model='bym2', graph=g_rook, scale.model=TRUE, constr=TRUE, hyper=list(phi=list(prior='pc', param=c(0.5,0.5)), prec=list(prior='pc.prec', param=c(1,0.01))))"

t0 <- Sys.time()
m_rook <- inla(as.formula(paste("y ~ 1 +", bym2_term_rook, "+ sexo_f + edad + escolaridad_f + estrato_f + anio_f")),
               family = "binomial", Ntrials = 1, data = sub,
               control.compute = list(waic = TRUE, cpo = TRUE),
               control.predictor = list(compute = TRUE, link = 1))
t1 <- Sys.time()

m_queen <- readRDS(file.path(RES, "modelo_FINAL_TRAT.rds"))

cat("=== TRATAMIENTO: comparacion queen (modelo final) vs rook (sensibilidad) ===\n")
cat(sprintf("n=%d municipios usados en ambos ajustes\n", length(unique(sub$muni_idx))))
cat(sprintf("Tiempo ajuste rook: %.1fs\n", as.numeric(difftime(t1, t0, units = "secs"))))
cat(sprintf("WAIC   queen=%.1f  rook=%.1f  (diferencia=%.2f)\n",
            m_queen$waic$waic, m_rook$waic$waic, m_rook$waic$waic - m_queen$waic$waic))
phi_queen <- m_queen$summary.hyperpar["Phi for muni_idx", "0.5quant"]
phi_rook  <- m_rook$summary.hyperpar["Phi for muni_idx", "0.5quant"]
cat(sprintf("Phi    queen=%.3f  rook=%.3f  (diferencia=%.3f)\n", phi_queen, phi_rook, phi_rook - phi_queen))

sub$fitted_rook <- m_rook$summary.fitted.values$mean
prom_muni_rook <- sub %>% group_by(muni_idx) %>% summarise(prev_rook = mean(fitted_rook), .groups = "drop")

cat(sprintf("Prevalencia suavizada (rook): min=%.3f mediana=%.3f max=%.3f\n",
            min(prom_muni_rook$prev_rook), median(prom_muni_rook$prev_rook), max(prom_muni_rook$prev_rook)))

# El resultado de esta sensibilidad se cita en el manuscrito y en la nota de la Tabla S1. Hasta
# ahora solo se imprimia por consola y el valor publicado era una cadena escrita a mano en
# 18_tablas.R, que no se habria enterado si esta corrida cambiara. Se deja en disco para que la
# tabla lo lea del pipeline.
sensibilidad <- data.frame(
  paso = "TRAT",
  n_municipios = length(unique(sub$muni_idx)),
  waic_reina = m_queen$waic$waic,
  waic_torre = m_rook$waic$waic,
  delta_waic = m_rook$waic$waic - m_queen$waic$waic,
  phi_reina = phi_queen,
  phi_torre = phi_rook,
  delta_phi = phi_rook - phi_queen,
  vecinos_mediana_reina = median(card(nb_queen)),
  vecinos_mediana_torre = median(card(nb_rook)))
print(sensibilidad, row.names = FALSE)
write.csv(sensibilidad, file.path(RES, "sensibilidad_vecindad.csv"), row.names = FALSE)

saveRDS(m_rook, file.path(RES, "modelo_SENSIBILIDAD_rook_TRAT.rds"))
cat("\nGuardado: modelo_SENSIBILIDAD_rook_TRAT.rds, sensibilidad_vecindad.csv\n")
