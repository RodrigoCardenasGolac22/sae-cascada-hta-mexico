# Construye el conteo municipal de establecimientos de salud CLUES (total y publico), analogo
# Conteo total y publico de establecimientos de salud por municipio.

library(dplyr)
library(readxl)

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

covariable_clues <- n_total %>%
  full_join(n_publico, by = "muni_id") %>%
  mutate(clues_publico = ifelse(is.na(clues_publico), 0, clues_publico))

write.csv(covariable_clues, file.path(COV, "clues_conteo_municipal.csv"), row.names = FALSE)
cat("\nMunicipios con >=1 establecimiento de salud:", nrow(covariable_clues), "\n")
cat("Guardado: COVARIABLES/clues_conteo_municipal.csv\n")
