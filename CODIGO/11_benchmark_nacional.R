# Paso 10 (parte pendiente): benchmarking cuantitativo contra el informe oficial ENSANUT / contra
# Campos-Nonato et al. 2025 (Salud Publica Mex 67:633-643, DOI 10.21149/17102) -- mismo dataset
# (ENSANUT 2021-2024), mismo criterio ESH (140/90, citan ESC/ESH). Sus cifras nacionales
# publicadas: prevalencia HTA 29.1% (29.4% en otra parte del texto, inconsistencia de ellos, no
# nuestra), conciencia (diagnosticados/HTA) 62.9%, control (PAS<140/PAD<90 entre diagnosticados Y
# tratados) 60.1%. Nota: ellos restringieron la CASCADA (no la prevalencia) a 2023-2024 por su
# medida mas fina de tratamiento habitual. Aqui se compara contra nuestra
# cascada pooled 2021-2024 (a0404 puntual), declarando esa diferencia, no ocultandola.
#
# Dos numeros nacionales por paso, para verificar consistencia interna, no solo compararse con
# la literatura:
#  1) Estimacion directa con diseno complejo real (svydesign) -- la forma correcta de estimar un
#     total nacional a partir de una encuesta compleja, replica lo que hace Campos-Nonato (`svy`
#     de Stata) con nuestros propios datos.
#  2) Promedio ponderado (por ponde_cal) de los valores ajustados del modelo BYM2 final -- chequeo de
#     consistencia interna: el suavizado espacial no deberia mover mucho el promedio nacional
#     (por construccion, BYM2 con restriccion de suma-cero en el efecto espacial preserva el
#     promedio razonablemente), asi que si (1) y (2) divergen fuerte hay que investigar por que
#     antes de reportar cualquiera de los dos.

library(dplyr)
library(readr)
library(survey)
library(INLA)

source("CODIGO/00_comun.R")   # NIVELES_ESCOLARIDAD

options(survey.lonely.psu = "adjust")

RES <- "RESULTADOS"
GEO <- "DATOS_GEO_MEXICO"
COV <- "COVARIABLES"

base <- read_csv(file.path(RES, "base_analitica_adultos_2021_2024.csv"),
                  col_types = cols(
                    entidad = col_character(), municipio = col_character(), anio = col_character(),
                    FOLIO_I = col_character(), FOLIO_INT = col_character(),
                    diag_cronico = col_logical(), hta_esh = col_logical(), hta_aha = col_logical(),
                    tratado = col_logical(), control_esh = col_logical(), control_aha = col_logical(),
                    .default = col_guess()
                  ))
base <- agregar_ponderador_calibrado(base, RES)

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
         anio_f = factor(anio),
         hta_esh_num = as.numeric(hta_esh), hta_aha_num = as.numeric(hta_aha))

# --- (1) Estimacion directa nacional, diseno complejo real ---
cat("=== (1) ESTIMACION DIRECTA NACIONAL (diseno complejo, svydesign) ===\n")

diseno_total <- svydesign(ids = ~upm, strata = ~interaction(anio, estrato), weights = ~ponde_cal,
                           data = base, nest = TRUE)

prev_hta_esh <- svymean(~hta_esh_num, diseno_total, na.rm = TRUE)
prev_hta_aha <- svymean(~hta_aha_num, diseno_total, na.rm = TRUE)
cat(sprintf("Prevalencia HTA-ESH (n=%d): %.1f%% (IC95%%: %.1f-%.1f)\n", nrow(base),
            100*coef(prev_hta_esh), 100*(coef(prev_hta_esh)-1.96*SE(prev_hta_esh)),
            100*(coef(prev_hta_esh)+1.96*SE(prev_hta_esh))))
cat(sprintf("Prevalencia HTA-AHA (n=%d): %.1f%% (IC95%%: %.1f-%.1f)\n", nrow(base),
            100*coef(prev_hta_aha), 100*(coef(prev_hta_aha)-1.96*SE(prev_hta_aha)),
            100*(coef(prev_hta_aha)+1.96*SE(prev_hta_aha))))

especificaciones <- list(
  AWARE_ESH   = list(outcome = "diag_cronico", denom = "hta_esh"),
  AWARE_AHA   = list(outcome = "diag_cronico", denom = "hta_aha"),
  TRAT        = list(outcome = "tratado",      denom = "diag_cronico"),
  CONTROL_ESH = list(outcome = "control_esh",  denom = "tratado"),
  CONTROL_AHA = list(outcome = "control_aha",  denom = "tratado")
)

directa_nacional <- list()
for (nombre in names(especificaciones)) {
  e <- especificaciones[[nombre]]
  sub <- base %>% filter(.data[[e$denom]], !is.na(.data[[e$denom]])) %>%
    mutate(y_num = as.numeric(.data[[e$outcome]]))
  d <- svydesign(ids = ~upm, strata = ~interaction(anio, estrato), weights = ~ponde_cal,
                 data = sub, nest = TRUE)
  m <- svymean(~y_num, d, na.rm = TRUE)
  cat(sprintf("[%s] n=%d, directa nacional=%.1f%% (IC95%%: %.1f-%.1f)\n", nombre, nrow(sub),
              100*coef(m), 100*(coef(m)-1.96*SE(m)), 100*(coef(m)+1.96*SE(m))))
  directa_nacional[[nombre]] <- data.frame(paso = nombre, n = nrow(sub),
                                            directa_pct = round(100*unname(coef(m)), 1),
                                            directa_ic_l = round(100*unname(coef(m)-1.96*SE(m)), 1),
                                            directa_ic_u = round(100*unname(coef(m)+1.96*SE(m)), 1))
}

# --- (2) Promedio ponderado de los valores ajustados del modelo BYM2 final ---
cat("\n=== (2) PROMEDIO PONDERADO (ponde_cal) DE LOS AJUSTADOS DEL MODELO BYM2 FINAL ===\n")

modelo_nacional <- list()
for (nombre in names(especificaciones)) {
  e <- especificaciones[[nombre]]
  sub <- base %>% filter(.data[[e$denom]], !is.na(.data[[e$denom]])) %>%
    mutate(y = as.numeric(.data[[e$outcome]])) %>%
    filter(!is.na(sexo_f), !is.na(edad), !is.na(estrato_f), !is.na(escolaridad_f))
  if (nombre %in% c("AWARE_ESH", "AWARE_AHA", "CONTROL_ESH", "CONTROL_AHA")) {
    sub <- sub %>% filter(!is.na(pobreza_pct))
  }
  if (nombre %in% c("AWARE_AHA", "CONTROL_ESH", "CONTROL_AHA")) sub <- sub %>% filter(!is.na(clues_total))

  m <- readRDS(file.path(RES, paste0("modelo_FINAL_", nombre, ".rds")))
  stopifnot(nrow(sub) == nrow(m$summary.fitted.values))
  sub$fitted <- m$summary.fitted.values$mean

  prom_simple <- mean(sub$fitted)
  prom_ponderado <- weighted.mean(sub$fitted, sub$ponde_cal)
  cat(sprintf("[%s] n=%d, promedio simple ajustados=%.1f%%, promedio ponderado (ponde_cal)=%.1f%%\n",
              nombre, nrow(sub), 100*prom_simple, 100*prom_ponderado))
  modelo_nacional[[nombre]] <- data.frame(paso = nombre, n_modelo = nrow(sub),
                                           modelo_simple_pct = round(100*prom_simple, 1),
                                           modelo_ponderado_pct = round(100*prom_ponderado, 1))
}

# --- Comparacion contra Campos-Nonato et al. 2025 (cifras nacionales publicadas) ---
cat("\n=== COMPARACION CONTRA CAMPOS-NONATO ET AL. 2025 (Salud Publica Mex, mismo dataset) ===\n")
cat("Su cifra (nacional/estatal, svy Stata, cascada restringida a 2023-2024 con medida distinta\n")
cat("de tratamiento habitual): prevalencia HTA 29.1% (29.4% en otra parte del texto);\n")
cat("conciencia (diagnosticados/HTA) 62.9%; control (PAS<140/PAD<90, entre diag+tratados) 60.1%.\n\n")

resumen_directa <- do.call(rbind, directa_nacional)
resumen_modelo <- do.call(rbind, modelo_nacional)

# La prevalencia de HTA es la primera cifra del Resumen del manuscrito y hasta ahora solo se
# imprimia por consola: no quedaba en ningun archivo, asi que el manuscrito la llevaba como literal
# escrito a mano en 18_tablas.R y nadie podia verificarla sin volver a correr INLA. Entra al mismo
# CSV que los cinco pasos de la cascada, con la misma estructura.
prevalencia_hta <- data.frame(
  paso = c("PREV_HTA_ESH", "PREV_HTA_AHA"),
  n = nrow(base),
  directa_pct  = round(100 * c(coef(prev_hta_esh), coef(prev_hta_aha)), 1),
  directa_ic_l = round(100 * c(coef(prev_hta_esh) - 1.96*SE(prev_hta_esh),
                               coef(prev_hta_aha) - 1.96*SE(prev_hta_aha)), 1),
  directa_ic_u = round(100 * c(coef(prev_hta_esh) + 1.96*SE(prev_hta_esh),
                               coef(prev_hta_aha) + 1.96*SE(prev_hta_aha)), 1),
  row.names = NULL)

resumen_final <- bind_rows(prevalencia_hta,
                            resumen_directa %>% left_join(resumen_modelo, by = "paso"))
print(resumen_final, row.names = FALSE)

cat(sprintf("\nPrevalencia HTA-ESH (directa, pooled 2021-2024): %.1f%% vs Campos-Nonato 29.1-29.4%%\n",
            100*coef(prev_hta_esh)))

write.csv(resumen_final, file.path(RES, "benchmark_nacional_vs_campos_nonato.csv"), row.names = FALSE)
cat("\nGuardado: benchmark_nacional_vs_campos_nonato.csv\n")
