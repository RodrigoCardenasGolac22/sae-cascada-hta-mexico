# Formato de presentacion de cifras y etiquetas en castellano: coma decimal,
# separador de millar, rangos y nombres legibles de los pasos de la cascada.
# Se carga con  source("CODIGO/00b_formato_es.R")  desde la raiz del repositorio.
#
# Definirlas UNA sola vez evita que dos generadores escriban el mismo dato con
# formatos distintos: coma o punto decimal, etiqueta legible o codigo interno.
#
# Va en un archivo propio y no en 00_comun.R porque aquel lo cargan 14 scripts de ANALISIS, y
# esto es presentacion. Y no lleva nada de officer/flextable a proposito: son funciones de
# cadena puras, sin dependencias, para que 18_tablas.R (que solo usa writexl) pueda cargarlo.
#
# Regla: si un generador de entregables formatea un numero, lo hace desde aqui. Nunca su copia.

# Numero -> coma decimal. NA -> celda vacia, no la palabra "NA".
fmt_es <- function(x, dec = 1) {
  ifelse(is.na(x), "", sub("\\.", ",", formatC(x, format = "f", digits = dec)))
}

# Separador de miles: espacio de NO SEPARACION (U+00A0), NO coma ni espacio normal. Las instrucciones de la revista dicen que usa el Sistema
# Internacional de Unidades, y el SI agrupa de tres en tres con espacio precisamente porque la
# coma ya es el separador decimal en espanol. Con coma, "2,478 municipios" se lee como dos
# municipios y pico.
fmt_es_entero <- function(x) {
  ifelse(is.na(x), "", format(round(x), big.mark = " ", trim = TRUE))
}

# Punto -> coma DENTRO de una cadena ya compuesta ("63.6-67.9" -> "63,6-67,9"). Necesaria porque
# los rangos y los porcentajes se arman con sprintf()/paste0() antes de llegar al formateador, y
# entonces ya no son numericos: fmt_es() no los toca. Este era exactamente el agujero del .xlsx.
fmt_es_rango <- function(s) gsub("(\\d)\\.(\\d)", "\\1,\\2", s)

# Etiquetas de los pasos de la cascada para cualquier entregable. Las claves son los codigos
# internos del pipeline, que NO deben aparecer nunca en un archivo que vea el editor: la revista
# pide que las tablas se interpreten "without referring to the text", y "CONTROL_AHA" no se
# interpreta sin el codigo fuente.
paso_legible <- c(AWARE_ESH = "Diagnóstico (ESH)", AWARE_AHA = "Diagnóstico (AHA)",
                  TRAT = "Tratamiento", CONTROL_ESH = "Control (ESH)",
                  CONTROL_AHA = "Control (AHA)",
                  PREV_HTA_ESH = "Prevalencia de HTA (ESH)",
                  PREV_HTA_AHA = "Prevalencia de HTA (AHA)")
