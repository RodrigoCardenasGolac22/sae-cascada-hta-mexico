# CALIBRACION DEL PONDERADOR DE LA SUBMUESTRA CON PRESION ARTERIAL VALIDA
#
# EL PROBLEMA
# La medicion de presion arterial se hace en una SUBMUESTRA del modulo de adultos: de los 45 011
# adultos entrevistados en 2021-2024 solo 25 089 tienen lectura valida (43,5 % de perdida). El
# pipeline usaba `ponde_f` del modulo de adultos sobre esa submuestra, lo que equivale a asumir que
# la submuestra es un subconjunto aleatorio simple de los adultos. La suma de `ponde_f` sobre la
# base analitica lo desmiente: 45,1 millones en 2023 frente a los 86,0 millones de adultos que
# representa el modulo completo ese anio.
#
# LA EVIDENCIA DE QUE EL INSP TAMBIEN LO CONSIDERA UN PROBLEMA
# La ronda 2023 -- y solo esa -- distribuye en el modulo de antropometria una variable `t_ponde`,
# etiquetada en el catalogo oficial como "Ponderador THA - an30=1". No es el mismo numero que
# `ponde_f` (razon mediana 1,725; rango 0,82-6,29) y su suma, 85 966 460, coincide EXACTAMENTE con
# la de `ponde_f` del modulo de adultos ese anio. Es decir: `t_ponde` re-expande la submuestra con
# medicion de presion arterial a toda la poblacion adulta. Es exactamente la correccion que hace
# falta, pero no existe en 2021, 2022 ni 2024.
#
# LA SOLUCION
# Calibrar el ponderador de la base analitica por celdas de post-estratificacion, de forma uniforme
# en los cuatro anios: dentro de cada celda anio x estrato x sexo x grupo de edad, se escala
# `ponde_f` por (poblacion elegible de la celda) / (poblacion representada por los respondentes de
# la celda). Es un ajuste por no-respuesta estandar, y es aplicable a los cuatro anios porque solo
# necesita el marco de elegibles, que el script 01 ya guarda.
#
# LA VALIDACION QUE LO HACE DEFENDIBLE
# En 2023 existen las dos cosas: el ponderador calibrado aqui y el `t_ponde` del INSP. Si el
# calibrado reproduce a `t_ponde`, entonces aplicarlo a los otros tres anios no es una invencion
# nuestra: es reconstruir con un metodo documentado lo que el propio INSP hizo cuando lo publico.
# Si NO lo reproduce, `t_ponde` codifica algo mas que un ajuste por no-respuesta y hay que decirlo
# en vez de suponerlo. Este script produce la evidencia para decidir; no decide por su cuenta.
#
# La validacion no consiste en que el numero "se parezca". Se reportan la
# correlacion, la distribucion de la razon, y -- lo que de verdad importa -- si las prevalencias
# nacionales estimadas con uno y con otro difieren en algo relevante.

library(dplyr)
library(readr)
library(survey)

options(survey.lonely.psu = "adjust")
RES <- "RESULTADOS"

base <- read_csv(file.path(RES, "base_analitica_adultos_2021_2024.csv"),
                  col_types = cols(
                    entidad = col_character(), municipio = col_character(),
                    estrato = col_character(), upm = col_character(), anio = col_character(),
                    FOLIO_I = col_character(), FOLIO_INT = col_character(),
                    diag_cronico = col_logical(), hta_esh = col_logical(), hta_aha = col_logical(),
                    tratado = col_logical(), control_esh = col_logical(), control_aha = col_logical(),
                    .default = col_guess()))

margenes <- read_csv(file.path(RES, "margenes_poblacion_elegible.csv"),
                      col_types = cols(anio = col_character(), estrato = col_character(),
                                       grupo_edad = col_character(), .default = col_guess()))

# mismas celdas que el script 01
base <- base %>%
  mutate(grupo_edad = as.character(cut(edad, breaks = c(19, 39, 59, 79, Inf),
                                       labels = c("20-39", "40-59", "60-79", "80+"))))

# --- factor de calibracion por celda -------------------------------------------------------
respondentes <- base %>%
  group_by(anio, estrato, sexo, grupo_edad) %>%
  summarise(pob_respondente = sum(ponde_f), n_respondente = n(), .groups = "drop")

celdas <- margenes %>%
  left_join(respondentes, by = c("anio", "estrato", "sexo", "grupo_edad")) %>%
  mutate(factor_cal = pob_elegible / pob_respondente)

cat("=== CELDAS DE CALIBRACION (anio x estrato x sexo x grupo de edad) ===\n")
cat(sprintf("Celdas del marco: %d | con respondentes: %d | SIN respondentes: %d\n",
            nrow(celdas), sum(!is.na(celdas$n_respondente)), sum(is.na(celdas$n_respondente))))

# Celdas finas sin respondentes o con muy pocos: se colapsan a una celda mas gruesa antes de
# calibrar. Un factor estimado sobre 1-2 personas es ruido, no informacion.
MIN_N <- 10
gruesa <- margenes %>%
  group_by(anio, estrato, grupo_edad) %>%
  summarise(pob_elegible_g = sum(pob_elegible), .groups = "drop") %>%
  left_join(base %>% group_by(anio, estrato, grupo_edad) %>%
              summarise(pob_resp_g = sum(ponde_f), n_g = n(), .groups = "drop"),
            by = c("anio", "estrato", "grupo_edad")) %>%
  mutate(factor_g = pob_elegible_g / pob_resp_g)

por_anio <- margenes %>% group_by(anio) %>% summarise(pe = sum(pob_elegible), .groups = "drop") %>%
  left_join(base %>% group_by(anio) %>% summarise(pr = sum(ponde_f), .groups = "drop"), by = "anio") %>%
  mutate(factor_a = pe / pr)

celdas <- celdas %>%
  left_join(gruesa %>% select(anio, estrato, grupo_edad, n_g, factor_g),
            by = c("anio", "estrato", "grupo_edad")) %>%
  left_join(por_anio %>% select(anio, factor_a), by = "anio") %>%
  mutate(
    nivel_usado = case_when(
      !is.na(n_respondente) & n_respondente >= MIN_N ~ "fina (anio x estrato x sexo x edad)",
      !is.na(n_g) & n_g >= MIN_N                     ~ "gruesa (anio x estrato x edad)",
      TRUE                                            ~ "anio"),
    factor_cal = case_when(
      nivel_usado == "fina (anio x estrato x sexo x edad)"  ~ factor_cal,
      nivel_usado == "gruesa (anio x estrato x edad)"       ~ factor_g,
      TRUE                                                   ~ factor_a))

cat("\nNivel de colapso usado por celda:\n")
print(celdas %>% count(nivel_usado), row.names = FALSE)
cat(sprintf("\nFactor de calibracion: min=%.3f p25=%.3f mediana=%.3f p75=%.3f max=%.3f\n",
            min(celdas$factor_cal, na.rm = TRUE), quantile(celdas$factor_cal, .25, na.rm = TRUE),
            median(celdas$factor_cal, na.rm = TRUE), quantile(celdas$factor_cal, .75, na.rm = TRUE),
            max(celdas$factor_cal, na.rm = TRUE)))

base <- base %>%
  left_join(celdas %>% select(anio, estrato, sexo, grupo_edad, factor_cal, nivel_usado),
            by = c("anio", "estrato", "sexo", "grupo_edad")) %>%
  mutate(ponde_cal = ponde_f * factor_cal)

stopifnot(!any(is.na(base$ponde_cal)), all(base$ponde_cal > 0))

cat("\n=== SUMA DE PONDERADORES POR ANIO (millones) ===\n")
print(base %>% group_by(anio) %>%
        summarise(n = n(), ponde_f = sum(ponde_f) / 1e6, ponde_cal = sum(ponde_cal) / 1e6,
                  .groups = "drop") %>%
        left_join(por_anio %>% transmute(anio, elegible = pe / 1e6), by = "anio"), row.names = FALSE)

# --- VALIDACION CONTRA t_ponde (solo 2023) -------------------------------------------------
b23 <- base %>% filter(anio == "2023", !is.na(t_ponde))
cat(sprintf("\n=== VALIDACION EN 2023 (n=%d con t_ponde) ===\n", nrow(b23)))
if (nrow(b23) > 0) {
  r <- b23$ponde_cal / b23$t_ponde
  cat(sprintf("Suma t_ponde=%.0f | Suma ponde_cal=%.0f | Suma ponde_f=%.0f\n",
              sum(b23$t_ponde), sum(b23$ponde_cal), sum(b23$ponde_f)))
  cat(sprintf("Correlacion ponde_cal vs t_ponde: Pearson=%.4f  Spearman=%.4f\n",
              cor(b23$ponde_cal, b23$t_ponde), cor(b23$ponde_cal, b23$t_ponde, method = "spearman")))
  cat(sprintf("Razon ponde_cal/t_ponde: min=%.3f p25=%.3f mediana=%.3f p75=%.3f max=%.3f\n",
              min(r), quantile(r, .25), median(r), quantile(r, .75), max(r)))
  cat(sprintf("Correlacion ponde_f vs t_ponde (referencia, sin calibrar): %.4f\n",
              cor(b23$ponde_f, b23$t_ponde)))
}

# Lo que de verdad decide: ¿cambian las prevalencias nacionales?
pasos <- list(AWARE_ESH   = list(o = "diag_cronico", d = "hta_esh"),
              AWARE_AHA   = list(o = "diag_cronico", d = "hta_aha"),
              TRAT        = list(o = "tratado",      d = "diag_cronico"),
              CONTROL_ESH = list(o = "control_esh",  d = "tratado"),
              CONTROL_AHA = list(o = "control_aha",  d = "tratado"))

estimar <- function(datos, peso) {
  d <- svydesign(ids = ~upm, strata = ~interaction(anio, estrato), weights = as.formula(paste0("~", peso)),
                 data = datos, nest = TRUE)
  out <- list()
  m <- svymean(~as.numeric(hta_esh), d, na.rm = TRUE)
  out[["PREV_HTA_ESH"]] <- 100 * as.numeric(coef(m))
  for (nm in names(pasos)) {
    p <- pasos[[nm]]
    sd_ <- subset(d, datos[[p$d]] & !is.na(datos[[p$d]]))
    mm <- svymean(as.formula(paste0("~as.numeric(", p$o, ")")), sd_, na.rm = TRUE)
    out[[nm]] <- 100 * as.numeric(coef(mm))
  }
  unlist(out)
}

cat("\n=== PREVALENCIAS NACIONALES: ponde_f vs ponde_cal (pooled 2021-2024) ===\n")
e_f   <- estimar(base, "ponde_f")
e_cal <- estimar(base, "ponde_cal")
comp <- data.frame(indicador = names(e_f), ponde_f = round(e_f, 2), ponde_cal = round(e_cal, 2),
                   dif_pp = round(e_cal - e_f, 2))
print(comp, row.names = FALSE)

cat("\n=== SOLO 2023: ponde_f vs ponde_cal vs t_ponde ===\n")
b23b <- base %>% filter(anio == "2023")
if (sum(!is.na(b23b$t_ponde)) == nrow(b23b) && nrow(b23b) > 0) {
  e23 <- data.frame(indicador = names(e_f),
                    ponde_f   = round(estimar(b23b, "ponde_f"), 2),
                    ponde_cal = round(estimar(b23b, "ponde_cal"), 2),
                    t_ponde   = round(estimar(b23b, "t_ponde"), 2))
  e23$dif_cal_vs_t <- round(e23$ponde_cal - e23$t_ponde, 2)
  print(e23, row.names = FALSE)
  write.csv(e23, file.path(RES, "validacion_calibracion_2023.csv"), row.names = FALSE)
} else {
  cat("  (2023 tiene filas sin t_ponde; se omite la comparacion directa)\n")
}

write.csv(base %>% select(FOLIO_I, FOLIO_INT, anio, ponde_f, t_ponde, factor_cal, nivel_usado, ponde_cal),
          file.path(RES, "ponderador_calibrado.csv"), row.names = FALSE)
write.csv(comp, file.path(RES, "comparacion_ponderadores_nacional.csv"), row.names = FALSE)
cat("\nGuardado: ponderador_calibrado.csv, comparacion_ponderadores_nacional.csv, validacion_calibracion_2023.csv\n")
