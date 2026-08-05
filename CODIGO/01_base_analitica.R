# Construye la base analitica adulta 2021-2024 para el SAE de cascada de HTA Mexico,
# con el flujo STROBE completo y las exclusiones oficiales verificadas contra el
# cuestionario y el informe oficial de ENSANUT de los 4 anios (2021-2024).
#
# Exclusiones aplicadas (todas verificadas contra fuente, no supuestas):
#  - Edad >=20 (poblacion del cuestionario de adultos, ya es asi por diseno -- filtro de
#    seguridad).
#  - PA valida por lectura: PAS >= 80 y PAD >= 50 mmHg, criterio oficial de ENSANUT (Informe de
#    resultados nacionales 2023, INSP). El informe declara solo el limite inferior; no se aplica un
#    limite superior porque ENSANUT no declara ninguno, y el rango de NCD-RisC (70-270/50-150) no
#    esta verificado para este instrumento.
#  - Sistolica <= diastolica: regla generica de calidad de dato (fisiologicamente imposible),
#    no una exclusion declarada especificamente por ENSANUT -- aplicada como sentido comun,
#    documentada como tal.
#  - Embarazo ACTUAL (a0808==1): excluida de TODA la muestra analitica (no solo de la
#    definicion de diagnostico previo). El cuestionario de adultos de ENSANUT no tiene una
#    pregunta de "posparto < 2 meses", asi que esa exclusion adicional no se aplica
#    aqui por falta de la variable, no por omision.
#  - a0401 codigo 2 ("SI, durante el embarazo"): tratado como diagnostico NO valido para
#    HTA cronica (decidido tras verificar el filtro impreso en el cuestionario real).
#
# Escolaridad (h0317a) viene del modulo "02-Informacion sobre los residentes" (integrantes), NO
# del modulo "01-Informacion sobre el hogar": son dos archivos distintos bajo el mismo
# cuestionario. Se enlaza por FOLIO_I + FOLIO_INT contra el modulo de adultos, y se colapsa en
# cuatro niveles (primaria o menos / secundaria / preparatoria-tecnico / superior).
#
# Urbanicidad/ruralidad no requiere ese enlace: ya viene en adultos/antropometria como `estrato`
# (1 = Rural, 2 = Urbano, 3 = Metropolitano, segun el catalogo oficial de variables).
#
# ENSANUT no distribuye una variable dedicada de afiliacion o aseguramiento en salud; se documenta
# como no disponible en vez de sustituirla por un proxy no equivalente.

library(dplyr)
library(readr)
library(haven)

source("CODIGO/00_comun.R")   # NIVELES_ESCOLARIDAD y factorizar_covariables()

DIR <- "DATOS_ENSANUT/microdatos_por_anio"
OUT <- "RESULTADOS"
YEARS <- 2021:2024

files <- list(
  `2021` = list(adul = "2021/ensadul2021_entrega_w_15_12_2021.csv", antro = "2021/ensaantro21_entrega_w_17_12_2021.csv", integ = "2021/integrantes_ensanut2021_w_12_01_2022.csv", fmt = "csv"),
  `2022` = list(adul = "2022/ensadul2022_entrega_w.csv",              antro = "2022/ensaantro2022_entrega_w.csv",           integ = "2022/integrantes_ensanut2022_w.csv",            fmt = "csv"),
  `2023` = list(adul = "2023/adultos_ensanut2023_w_n.csv",             antro = "2023/Antropometria_HTA_4mar24.csv",          integ = "2023/integrantes_ensanut2023_w_n.csv",         fmt = "csv"),
  `2024` = list(adul = "2024/adultos_ensanut2024_w.dta",               antro = "2024/antropometria_ensanut2024_w.csv",       integ = "2024/integrantes_ensanut2024_w_ICB.dta",       fmt = "dta_adul")
)

# h0317a colapsada a 5 niveles.
#
# El catalogo oficial del modulo de integrantes etiqueta SOLO los valores 1-12 ("Preescolar" ..
# "Doctorado"). El valor 0 aparece de forma sistematica en los microdatos (2 555 casos en 2021,
# 1 961 en 2022, 984 en 2023) y NO esta etiquetado, pero no es un dato faltante: es poblacion SIN
# ESCOLARIDAD. Verificado contra h0318 ("¿sabe leer y escribir un recado?") y contra la edad:
#
#   h0317a   n(2021)   analfabetismo(h0318=No)   edad mediana   % con 20+
#   0          2 555          68,3 %                 55            65,8 %
#   1          1 803          84,5 %                  5             2,5 %   (preescolares)
#   2         12 395           8,7 %                 39            61,0 %
#   ""         1 584             --                   1             0,0 %   (menores, no adultos)
#
# El vacio real ("") son menores de edad y no entran a la muestra analitica de 20+; el 0 son
# adultos, dos tercios de ellos analfabetos, y por eso el 0 NO se trata como dato faltante: los
# scripts 08-12 filtran !is.na(escolaridad_f), de modo que mandarlo a NA sacaria a esos adultos
# de LOS CINCO MODELOS: ~800 personas en diagnostico-ESH y ~490 en control, los mas viejos
# (35,7 % de los de 80+ frente a 0,8 % de los de 20-39). En un estudio sobre desigualdad en el
# acceso a la atencion, eso descartaba justamente al grupo mas desfavorecido.
#
# "Sin escolaridad" va como nivel PROPIO y no fundido en "Primaria o menos" porque son grupos
# empiricamente distintos: 68,3 % de analfabetismo frente a 8,7 %.
colapsar_escolaridad <- function(x) {
  case_when(
    x == 0 ~ "Sin escolaridad",
    x %in% c(1, 2) ~ "Primaria o menos",
    x == 3 ~ "Secundaria",
    x %in% c(4, 5, 6, 7, 8) ~ "Preparatoria/tecnico",
    x %in% c(9, 10, 11, 12) ~ "Superior",
    TRUE ~ NA_character_
  )
}

# NIVELES_ESCOLARIDAD (el orden de los niveles y la categoria de referencia de los modelos) vive en
# CODIGO/00_comun.R, que ya se cargo arriba: lo necesitan tambien los scripts 08-12 y no debe estar
# escrito en dos sitios.

read_semicolon <- function(path) {
  read_delim(path, delim = ";", locale = locale(encoding = "UTF-8"),
             col_types = cols(.default = col_character()), na = c("", "NA"))
}

for (y in as.character(YEARS)) {
  zips <- list.files(file.path(DIR, y), pattern = "\\.zip$", full.names = TRUE)
  for (z in zips) unzip(z, exdir = file.path(DIR, y), overwrite = FALSE)
}

# En los CSV de 2021-2023, ponde_f (y en general las variables numericas con decimales) usa COMA
# como separador decimal (ej. "792,951734411252"). as.numeric() sobre esos valores devuelve NA en
# silencio, sin error ni warning, asi que la coma se convierte a punto antes de castear. Es no-op
# para las variables de codigos enteros (edad, a0401, a0404, a0808).
num <- function(x) suppressWarnings(as.numeric(gsub(",", ".", trimws(x), fixed = TRUE)))

# lectura valida por el criterio oficial ENSANUT: PAS>=80 y PAD>=50; si no cumple, NA
lectura_valida <- function(s, d) {
  ok <- !is.na(s) & !is.na(d) & s >= 80 & d >= 50
  list(s = ifelse(ok, s, NA_real_), d = ifelse(ok, d, NA_real_))
}

all_years <- list()
flow <- list()
margenes <- list()   # totales ponderados de la poblacion elegible, por celda de calibracion

for (y in as.character(YEARS)) {
  f <- files[[y]]

  if (f$fmt == "dta_adul") {
    adul_raw <- read_dta(file.path(DIR, f$adul))
    adul <- adul_raw %>%
      transmute(
        FOLIO_I = as.character(FOLIO_I), FOLIO_INT = as.character(FOLIO_INT),
        # entidad/municipio en el .dta de 2024 YA vienen como texto con cero a la izquierda
        # ("01","001"), igual que en los CSV de los demas anios -- NO pasar por as.numeric()
        # (eso rompia el cero a la izquierda: "01"->1->"1", desalineando el ID de municipio
        # entre 2024 y 2021-2023 sin lanzar ningun error).
        entidad = as.character(entidad),
        municipio = as.character(municipio),
        edad = as.numeric(edad),
        sexo = as.numeric(sexo),  # 1=Hombre, 2=Mujer (verificado contra diccionario oficial)
        a0401 = as.numeric(a0401), a0404 = as.numeric(a0404),
        a0808 = as.numeric(a0808),
        ponde_f = as.numeric(ponde_f), estrato = as.character(as.numeric(estrato)),
        upm = as.character(upm)  # upm es alfanumerico (ej. "010010001091A"), nunca numerico
      )
  } else {
    adul_txt <- read_semicolon(file.path(DIR, f$adul))
    names(adul_txt) <- tolower(names(adul_txt))
    adul <- adul_txt %>%
      transmute(FOLIO_I = folio_i, FOLIO_INT = folio_int,
                entidad = entidad, municipio = municipio,
                edad = num(edad), sexo = num(sexo),
                a0401 = num(a0401), a0404 = num(a0404),
                a0808 = num(a0808),
                ponde_f = num(ponde_f), estrato = estrato, upm = upm)
  }

  antro_txt <- read_semicolon(file.path(DIR, f$antro))
  names(antro_txt) <- tolower(names(antro_txt))
  antro <- antro_txt %>%
    transmute(FOLIO_I = folio_i, FOLIO_INT = folio_int,
              s2_raw = num(an27_02s), d2_raw = num(an27_02d),
              s3_raw = num(an27_03s), d3_raw = num(an27_03d))

  # t_ponde: ponderador propio del modulo de tension arterial, etiquetado en el catalogo oficial
  # como "Ponderador THA - an30=1". SOLO lo distribuye la ronda 2023; en 2021, 2022 y 2024 no
  # existe y queda NA. No es el mismo numero que ponde_f del modulo de adultos (razon mediana
  # 1,725; rango 0,82-6,29), y su suma en 2023 (85 966 460) coincide exactamente con la de ponde_f
  # del modulo de adultos ese anio, es decir, re-expande la submuestra con medicion de presion
  # arterial a toda la poblacion adulta. Se arrastra para calibrar y validar los ponderadores de
  # la base analitica (script 02b).
  antro$t_ponde <- if ("t_ponde" %in% names(antro_txt)) num(antro_txt$t_ponde) else NA_real_
  # ponde_f del modulo de ANTROPOMETRIA: no coincide con el de adultos en ningun registro
  # (0 de 8 263 en 2021, 0 de 3 151 en 2023). Se arrastra con nombre propio para no confundirlo.
  antro$ponde_f_antro <- if ("ponde_f" %in% names(antro_txt)) num(antro_txt$ponde_f) else NA_real_

  if (f$fmt == "dta_adul") {
    integ_raw <- read_dta(file.path(DIR, f$integ))
    integ <- integ_raw %>%
      transmute(FOLIO_I = as.character(FOLIO_I), FOLIO_INT = as.character(FOLIO_INT),
                escolaridad = colapsar_escolaridad(as.numeric(h0317a)))
  } else {
    integ_txt <- read_semicolon(file.path(DIR, f$integ))
    names(integ_txt) <- tolower(names(integ_txt))
    integ <- integ_txt %>%
      transmute(FOLIO_I = folio_i, FOLIO_INT = folio_int,
                escolaridad = colapsar_escolaridad(num(h0317a)))
  }

  n_entrevistados <- nrow(adul)
  n_integ_match <- sum(paste(adul$FOLIO_I, adul$FOLIO_INT) %in% paste(integ$FOLIO_I, integ$FOLIO_INT))

  merged <- adul %>%
    left_join(antro, by = c("FOLIO_I", "FOLIO_INT")) %>%
    left_join(integ, by = c("FOLIO_I", "FOLIO_INT"))
  n_edad_ok <- sum(merged$edad >= 20, na.rm = TRUE)
  merged <- merged %>% filter(edad >= 20)

  # aplicar validez de lectura oficial ENSANUT (PAS>=80, PAD>=50) por lectura
  l2 <- lectura_valida(merged$s2_raw, merged$d2_raw)
  l3 <- lectura_valida(merged$s3_raw, merged$d3_raw)
  merged$sbp <- rowMeans(cbind(l2$s, l3$s), na.rm = TRUE)
  merged$dbp <- rowMeans(cbind(l2$d, l3$d), na.rm = TRUE)
  merged$sbp <- ifelse(is.nan(merged$sbp), NA_real_, merged$sbp)
  merged$dbp <- ifelse(is.nan(merged$dbp), NA_real_, merged$dbp)

  n_bp_valida_bruta <- sum(!is.na(merged$sbp) & !is.na(merged$dbp))

  # sistolica <= diastolica: fisiologicamente invalido, se anula la lectura (no la persona)
  invertida <- !is.na(merged$sbp) & !is.na(merged$dbp) & merged$sbp <= merged$dbp
  merged$sbp[invertida] <- NA_real_
  merged$dbp[invertida] <- NA_real_
  n_excl_invertida <- sum(invertida)

  # POBLACION ELEGIBLE (denominador de la calibracion del script 02b): adultos de 20+, no
  # embarazadas y con ponderador de diseno, ANTES de exigir presion arterial valida. La medicion de
  # PA se hace en una submuestra del modulo de adultos, asi que este es el marco respecto al cual
  # la muestra analitica es una submuestra de respondentes -- no al reves. Se guardan los totales
  # ponderados por celda de calibracion para poder re-expandir despues.
  elegibles <- merged %>%
    filter(is.na(a0808) | a0808 != 1, !is.na(ponde_f))
  margenes[[y]] <- elegibles %>%
    mutate(anio = y, grupo_edad = cut(edad, breaks = c(19, 39, 59, 79, Inf),
                                      labels = c("20-39", "40-59", "60-79", "80+"))) %>%
    group_by(anio, estrato, sexo, grupo_edad) %>%
    summarise(pob_elegible = sum(ponde_f), n_elegible = n(), .groups = "drop")

  # PA valida como prerrequisito de entrada a TODA la muestra analitica, no solo del desenlace de
  # control -- mismo criterio de inclusion que el analisis nacional publicado con estos datos
  # (Campos-Nonato et al., Salud Publica Mex 2025;67:633-643). Sin este filtro entrarian personas
  # con diagnostico autorreportado pero sin PA medida ese dia, y `control_esh`/`control_aha`
  # evaluarian FALSE (no controlado) en vez de NA (desconocido) para ellas, sesgando el control
  # hacia abajo.
  n_antes_bp <- nrow(merged)
  merged <- merged %>% filter(!is.na(sbp), !is.na(dbp))
  n_excl_sin_bp_valida <- n_antes_bp - nrow(merged)

  # embarazo actual: excluida de TODA la muestra analitica, no solo de conciencia
  n_antes_embarazo <- nrow(merged)
  merged <- merged %>% filter(is.na(a0808) | a0808 != 1)
  n_excl_embarazo <- n_antes_embarazo - nrow(merged)

  # peso de diseno faltante: svydesign exige peso no faltante en todos los casos; se documenta como
  # exclusion explicita, no se oculta ni se imputa. El numero exacto lo reporta la columna
  # excl_sin_peso de flujo_STROBE_2021_2024.csv. No se escribe aqui a proposito: un numero
  # fijado en un comentario caduca en cuanto cambia la base.
  n_antes_peso <- nrow(merged)
  merged <- merged %>% filter(!is.na(ponde_f))
  n_excl_sin_peso <- n_antes_peso - nrow(merged)

  merged <- merged %>%
    mutate(
      anio = y,
      diag_cronico = a0401 %in% 1,  # excluye codigo 2 "SI, durante el embarazo" y 3 "NO"
      hta_esh = sbp >= 140 | dbp >= 90 | diag_cronico,  # sbp/dbp sin NA por el filtro de PA valida
      hta_aha = sbp >= 130 | dbp >= 80 | diag_cronico,
      # tratado se ANIDA en diag_cronico: la cascada es diagnostico -> tratamiento (entre
      # diagnosticados) -> control (entre tratados), y el denominador de control debe ser un
      # subconjunto del de tratamiento. Sin el anidamiento entraban 17 personas con a0401 == 2
      # ("Si, durante el embarazo"), el codigo que diag_cronico excluye por no ser diagnostico de
      # HTA cronica: quedaban fuera del paso de diagnostico pero dentro del denominador de control.
      # Impacto medido antes de anidar: 0,00 pp en control-ESH y -0,03 pp en control-AHA.
      tratado = a0404 %in% 1 & diag_cronico,
      control_esh = ifelse(tratado, sbp < 140 & dbp < 90, NA),  # NA si no aplica (no tratado), no FALSE
      control_aha = ifelse(tratado, sbp < 130 & dbp < 80, NA),
      muni_id = paste(entidad, municipio, sep = "_")
    )

  flow[[y]] <- c(
    anio = y,
    entrevistados = n_entrevistados,
    edad_20mas = n_edad_ok,
    bp_valida_bruta = n_bp_valida_bruta,
    excl_lectura_invertida = n_excl_invertida,
    excl_sin_bp_valida = n_excl_sin_bp_valida,
    excl_embarazo_actual = n_excl_embarazo,
    excl_sin_peso = n_excl_sin_peso,
    n_final = nrow(merged),
    n_hta_esh = sum(merged$hta_esh, na.rm = TRUE),
    n_hta_aha = sum(merged$hta_aha, na.rm = TRUE),
    n_diagnosticados = sum(merged$diag_cronico, na.rm = TRUE),
    n_tratados = sum(merged$tratado, na.rm = TRUE),
    integrantes_match_pct = round(100 * n_integ_match / n_entrevistados, 1),
    escolaridad_no_na_pct = round(100 * mean(!is.na(merged$escolaridad)), 1)
  )

  all_years[[y]] <- merged
  cat(sprintf("Año %s: %d entrevistados -> %d (20+) -> %d final tras exclusiones. HTA-ESH=%d, HTA-AHA=%d. Enlace integrantes=%.1f%%, escolaridad no-NA=%.1f%%\n",
              y, n_entrevistados, n_edad_ok, nrow(merged),
              sum(merged$hta_esh, na.rm = TRUE), sum(merged$hta_aha, na.rm = TRUE),
              100 * n_integ_match / n_entrevistados, 100 * mean(!is.na(merged$escolaridad))))
}

base_analitica <- bind_rows(all_years)
flow_df <- do.call(rbind, flow) %>% as.data.frame()

cat("\n=== FLUJO STROBE, 2021-2024 ===\n")
print(flow_df, row.names = FALSE)

cat("\n=== TOTAL BASE ANALÍTICA POOLED ===\n")
cat("N final (2021-2024):", nrow(base_analitica), "\n")
cat("N con HTA-ESH:", sum(base_analitica$hta_esh, na.rm = TRUE), "\n")
cat("N con HTA-AHA:", sum(base_analitica$hta_aha, na.rm = TRUE), "\n")
cat("N diagnosticados (conciencia):", sum(base_analitica$diag_cronico, na.rm = TRUE), "\n")
cat("N tratados:", sum(base_analitica$tratado, na.rm = TRUE), "\n")
cat("N municipios distintos en la base final:", n_distinct(base_analitica$muni_id), "\n")
cat("\nDistribución de escolaridad (colapsada, 4 niveles):\n")
print(table(base_analitica$escolaridad, useNA = "ifany"))

verificar_escolaridad(base_analitica$escolaridad)
cat(sprintf("\nEscolaridad sin dato tras la recodificacion: %d de %d (%.2f%%)\n",
            sum(is.na(base_analitica$escolaridad)), nrow(base_analitica),
            100 * mean(is.na(base_analitica$escolaridad))))

margenes_df <- bind_rows(margenes)
cat("\n=== POBLACION ELEGIBLE (20+, no gestante, con peso) por anio ===\n")
print(margenes_df %>% group_by(anio) %>%
        summarise(celdas = n(), n_elegible = sum(n_elegible),
                  pob_elegible = sum(pob_elegible), .groups = "drop"), row.names = FALSE)

write.csv(base_analitica, file.path(OUT, "base_analitica_adultos_2021_2024.csv"), row.names = FALSE)
write.csv(flow_df, file.path(OUT, "flujo_STROBE_2021_2024.csv"), row.names = FALSE)
write.csv(margenes_df, file.path(OUT, "margenes_poblacion_elegible.csv"), row.names = FALSE)
cat("\nGuardado: base_analitica_adultos_2021_2024.csv, flujo_STROBE_2021_2024.csv, margenes_poblacion_elegible.csv\n")
