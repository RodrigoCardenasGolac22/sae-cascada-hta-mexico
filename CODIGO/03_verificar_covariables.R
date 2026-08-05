# Re-verifica el cruce de las covariables municipales (CONEVAL pobreza, CLUES salud, DEM altitud)
# contra los municipios REALES que aparecen en la base analitica final (616 municipios, 2021-2024
# pooled) -- no contra el listado teorico de 2,478 municipios de Mexico. Paso 5 de la secuencia de
# ejecucion del analisis.

library(dplyr)
library(readr)
library(readxl)

RES <- "RESULTADOS"
COV <- "COVARIABLES"

base <- read_csv(file.path(RES, "base_analitica_adultos_2021_2024.csv"), col_types = cols(.default = col_character()))
municipios_base <- base %>% distinct(entidad, municipio, muni_id)
cat("Municipios distintos en la base analitica:", nrow(municipios_base), "\n")

# --- 1. CONEVAL pobreza ---
coneval <- read_csv(file.path(COV, "coneval_pobreza_municipal_2020.csv"), col_types = cols(.default = col_character()))
cat("\n=== CONEVAL: formato de clave (primeras filas) ===\n")
print(head(coneval[, c("clave_entidad","clave_municipio")], 5))

# clave_municipio de CONEVAL es el CODIGO INEGI COMPLETO de 5 digitos (entidad+municipio),
# guardado como numero -> perdio el cero a la izquierda de la entidad al leerlo
# (ej. "01001" -> 1001), por lo que hay que reconstruirla con sprintf("%05d", ...) antes de cruzar
# que combinaba mal clave_entidad+clave_municipio por separado.
coneval_key5 <- sprintf("%05d", as.numeric(coneval$clave_municipio))
cat("Verificacion de reconstruccion: primeros 5 codigos ->", paste(head(coneval_key5,5), collapse=", "), "\n")
cat("Coincide entidad implicita con clave_entidad declarada?",
    all(as.numeric(substr(coneval_key5,1,2)) == as.numeric(coneval$clave_entidad)), "\n")

base_key5 <- paste0(municipios_base$entidad, municipios_base$municipio)
match_coneval <- base_key5 %in% coneval_key5
cat("Municipios de la base que cruzan con CONEVAL:", sum(match_coneval), "/", length(base_key5),
    sprintf(" (%.1f%%)\n", 100 * mean(match_coneval)))
if (any(!match_coneval)) {
  cat("Municipios SIN cruce CONEVAL:\n")
  print(municipios_base[!match_coneval, ])
}

# --- 2. CLUES salud ---
clues <- read_excel(file.path(COV, "clues_establecimientos_salud.xlsx"))
cat("\n=== CLUES: formato de clave (primeras filas) ===\n")
print(head(clues[, c("CLAVE DE LA ENTIDAD","CLAVE DEL MUNICIPIO")], 5))
cat("Total establecimientos:", nrow(clues), "\n")

clues_ent <- sprintf("%02d", as.numeric(clues[["CLAVE DE LA ENTIDAD"]]))
clues_mun <- sprintf("%03d", as.numeric(clues[["CLAVE DEL MUNICIPIO"]]))
clues_key <- paste0(clues_ent, clues_mun)
cat("Verificacion de reconstruccion: primeros 5 codigos ->", paste(head(clues_key,5), collapse=", "), "\n")

match_clues <- base_key5 %in% clues_key
cat("Municipios de la base que cruzan con CLUES:", sum(match_clues), "/", length(base_key5),
    sprintf(" (%.1f%%)\n", 100 * mean(match_clues)))
if (any(!match_clues)) {
  cat("Municipios SIN cruce CLUES:\n")
  print(municipios_base[!match_clues, ])
}

# conteo de establecimientos por municipio, para verificar que la variable derivada tiene sentido
estab_por_muni <- table(clues_key)
cat("Establecimientos por municipio (resumen): mediana=", median(estab_por_muni),
    " min=", min(estab_por_muni), " max=", max(estab_por_muni), "\n")

# --- 3. Altitud DEM ---
alt <- read_csv(file.path(COV, "altitud_municipal_DEM.csv"), col_types = cols(.default = col_character()))
cat("\n=== Altitud DEM: formato de clave (primeras filas) ===\n")
print(head(alt[, c("cve_ent","cve_mun")], 5))
alt_key <- paste0(alt$cve_ent, alt$cve_mun)
match_alt <- base_key5 %in% alt_key
cat("Municipios de la base que cruzan con altitud DEM:", sum(match_alt), "/", length(base_key5),
    sprintf(" (%.1f%%)\n", 100 * mean(match_alt)))
if (any(!match_alt)) {
  cat("Municipios SIN cruce altitud:\n")
  print(municipios_base[!match_alt, ])
}

cat("\n=== RESUMEN FINAL ===\n")
cat(sprintf("CONEVAL: %d/%d (%.1f%%) | CLUES: %d/%d (%.1f%%) | Altitud DEM: %d/%d (%.1f%%)\n",
            sum(match_coneval), length(base_key5), 100*mean(match_coneval),
            sum(match_clues), length(base_key5), 100*mean(match_clues),
            sum(match_alt), length(base_key5), 100*mean(match_alt)))
