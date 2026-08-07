# Construye la covariable municipal de establecimientos de salud CLUES: el conteo (total y
# publico) y la DENSIDAD por 10 000 adultos, que es la que entra a los modelos (decision B5
# opcion 2, 2026-08-06).

library(dplyr)
library(readr)
library(readxl)

source("CODIGO/00_comun.R")   # poblacion_adulta_municipal()

COV <- "COVARIABLES"
clues <- read_excel(file.path(COV, "clues_establecimientos_salud.xlsx"))

cat("=== Valores unicos de ESTATUS DE OPERACION ===\n")
print(table(clues[["ESTATUS DE OPERACION"]], useNA = "ifany"))

cat("\n=== Valores unicos de NOMBRE DE LA INSTITUCION ===\n")
print(table(clues[["NOMBRE DE LA INSTITUCION"]], useNA = "ifany"))

# Instituciones que NO son establecimientos de salud propiamente dichos: al revisar los valores
# unicos se ve que CLUES mezcla oficinas de fiscalia/poder judicial/ciencias
# forenses/seguridad/transporte con clinicas y hospitales. Si se cuentan como "establecimientos
# de salud" contaminarian la covariable de densidad de servicios de salud (ni el total ni el
# publico deberian incluirlas).
no_salud <- c(
  "FISCALIA GENERAL DE JUSTICIA", "FISCALIA GENERAL DEL ESTADO",
  "INSTITUTO DE CIENCIAS FORENSES ESTATAL", "PODER JUDICIAL DEL ESTADO",
  "PROCURADURIA GENERAL DE LA REPUBLICA", "SECRETARIA DE COMUNICACIONES Y TRANSPORTES",
  "SECRETARÍA DE SEGURIDAD Y PROTECCIÓN CIUDADANA"
)

# Instituciones publicas de salud (gobierno) -- Cruz Roja Mexicana se deja fuera de "publico"
# (es una institucion civil/no gubernamental, no parte del sistema publico de salud formal),
# pero SI se cuenta en el total de establecimientos de salud (si presta servicios medicos).
# Centros de Integracion Juvenil (atencion en adicciones) tambien se cuenta en el total pero no
# en "publico" estricto por la misma logica de clasificacion institucional, no de financiamiento.
publico_salud <- c(
  "SECRETARIA DE SALUD", "INSTITUTO MEXICANO DEL SEGURO SOCIAL",
  "INSTITUTO MEXICANO DEL SEGURO SOCIAL REGIMEN BIENESTAR", "SERVICIOS DE SALUD IMSS BIENESTAR",
  "INSTITUTO DE SEGURIDAD Y SERVICIOS SOCIALES DE LOS TRABAJADORES DEL ESTADO",
  "PETROLEOS MEXICANOS", "SECRETARIA DE LA DEFENSA NACIONAL", "SECRETARIA DE MARINA",
  "SERVICIOS MEDICOS ESTATALES", "SERVICIOS MEDICOS MUNICIPALES", "SERVICIOS MEDICOS UNIVERSITARIOS",
  "SISTEMA NACIONAL PARA EL DESARROLLO INTEGRAL DE LA FAMILIA"
)

clues_salud <- clues %>%
  filter(`ESTATUS DE OPERACION` == "EN OPERACION",
         !(`NOMBRE DE LA INSTITUCION` %in% no_salud))

clues_salud$cve_ent <- sprintf("%02d", as.numeric(clues_salud[["CLAVE DE LA ENTIDAD"]]))
clues_salud$cve_mun <- sprintf("%03d", as.numeric(clues_salud[["CLAVE DEL MUNICIPIO"]]))
clues_salud$muni_id <- paste0(clues_salud$cve_ent, clues_salud$cve_mun)
clues_salud$es_publico <- clues_salud[["NOMBRE DE LA INSTITUCION"]] %in% publico_salud

cat("\n=== Establecimientos EN OPERACION, excluyendo no-salud ===\n")
cat("Total:", nrow(clues_salud), " (de", nrow(clues), "originales)\n")
cat("Publicos:", sum(clues_salud$es_publico), " | No publicos (privados+Cruz Roja+CIJ):",
    sum(!clues_salud$es_publico), "\n")

n_total <- clues_salud %>% count(muni_id, name = "clues_total")
n_publico <- clues_salud %>% filter(es_publico) %>% count(muni_id, name = "clues_publico")

# MARCO COMPLETO DE MUNICIPIOS. count() solo emite fila para los municipios que tienen al menos un
# establecimiento, de modo que "cero establecimientos" salia como AUSENCIA DE FILA y aguas abajo un
# left_join lo convertia en NA. Consecuencia medida: 18 municipios se caian de los tres modelos que
# llevan la covariable (cobertura nacional 2 448 en vez de 2 466) y 3 de ellos, que si tienen
# muestra de encuesta, perdian a sus encuestados en el ajuste. Ademas el coeficiente de CLUES se
# estimaba sin un solo municipio con cero establecimientos, que es justo el extremo de interes.
#
# Verificado contra el crudo (2026-08-06): de esos 18, quince no aparecen en CLUES en absoluto y
# tres aparecen SOLO con unidades FUERA DE OPERACION -- 19003 Los Aldamas (3 de la Secretaria de
# Salud), 20408 (1) y 20476 (1). Bajo la definicion de este estudio (establecimientos en operacion)
# el valor correcto para los 18 es CERO, no dato faltante. Los tres que tuvieron servicios y los
# perdieron son el cero mas informativo del conjunto.
#
# Notese la asimetria que habia: clues_publico si se rellenaba con 0, y clues_total no podia,
# porque no habia marco completo contra el que hacer el join. Este es ese marco.
marco <- read_csv(file.path("DATOS_GEO_MEXICO", "muni_idx_grafo.csv"),
                  col_types = cols(cve_ent = col_character(), cve_mun = col_character())) %>%
  transmute(muni_id = paste0(cve_ent, cve_mun))

covariable_clues <- marco %>%
  left_join(n_total, by = "muni_id") %>%
  left_join(n_publico, by = "muni_id") %>%
  mutate(across(c(clues_total, clues_publico), ~ ifelse(is.na(.x), 0, .x)))

stopifnot(nrow(covariable_clues) == nrow(marco),
          !any(is.na(covariable_clues$clues_total)),
          !any(is.na(covariable_clues$clues_publico)))

# --- Densidad por 10 000 adultos (decision B5 opcion 2, tomada por el autor el 2026-08-06) -----
# El conteo, aun en escala log, sigue confundido con el tamano del municipio: mas establecimientos
# <-> municipio mas grande, y la poblacion municipal no esta en el modelo. La covariable que entra
# a los modelos es la densidad clues_por_10k = 1e4 * establecimientos / poblacion adulta censal
# (20+, ITER 2020, misma definicion de bandas que el paso 09). Desacopla el efecto del tamano
# (correlacion con log1p del conteo en los municipios muestreados: -0,19, medida 2026-08-06) y
# permite llamarla "densidad" con propiedad, que es lo que el manuscrito ya decia.
pob_adulta_muni <- poblacion_adulta_municipal()
covariable_clues <- covariable_clues %>%
  left_join(pob_adulta_muni, by = "muni_id") %>%
  mutate(clues_por_10k         = 1e4 * clues_total / pob_adulta,
         clues_publico_por_10k = 1e4 * clues_publico / pob_adulta)

# Los UNICOS municipios sin densidad deben ser los que no existen en el ITER (creados despues del
# Censo 2020): sin denominador censal no hay densidad, igual que no hay tabla de
# post-estratificacion en 09. Ninguno tiene muestra de encuesta (verificado 2026-08-06). Si algun
# municipio del ITER trajera poblacion adulta cero, la densidad saldria Inf: se aborta.
sin_censo <- covariable_clues$muni_id[is.na(covariable_clues$pob_adulta)]
stopifnot(identical(is.na(covariable_clues$clues_por_10k), is.na(covariable_clues$pob_adulta)),
          !any(is.infinite(covariable_clues$clues_por_10k)))
cat("\nMunicipios sin poblacion censal (creados despues del Censo 2020) -> densidad NA:",
    length(sin_censo), "\n  ", paste(sin_censo, collapse = ", "), "\n")
cat(sprintf("Densidad clues_por_10k: mediana %.1f | p95 %.1f | max %.1f por 10 000 adultos\n",
            median(covariable_clues$clues_por_10k, na.rm = TRUE),
            quantile(covariable_clues$clues_por_10k, 0.95, na.rm = TRUE),
            max(covariable_clues$clues_por_10k, na.rm = TRUE)))

write.csv(covariable_clues, file.path(COV, "clues_conteo_municipal.csv"), row.names = FALSE)
cat("\nMunicipios en el marco:", nrow(covariable_clues),
    "| con >=1 establecimiento en operacion:", sum(covariable_clues$clues_total > 0),
    "| con cero:", sum(covariable_clues$clues_total == 0), "\n")
write.csv(covariable_clues %>% filter(clues_total == 0) %>% select(muni_id),
          file.path("RESULTADOS", "municipios_clues_cero.csv"), row.names = FALSE)
cat("Guardado: COVARIABLES/clues_conteo_municipal.csv, RESULTADOS/municipios_clues_cero.csv\n")
