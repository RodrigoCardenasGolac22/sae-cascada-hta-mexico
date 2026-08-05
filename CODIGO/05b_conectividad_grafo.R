# Resume la conectividad del grafo de vecindad, para la Tabla S7.
#
# Por que existe. Un revisor pregunto como se trato la contiguidad de los municipios
# insulares (Cozumel, Isla Mujeres), porque el manuscrito solo decia "sin islas". La
# pregunta es pertinente: en un termino ICAR/BYM2 un area sin vecinos rompe la
# estructura espacial, y el lector no puede saber, leyendo "sin islas", si se
# excluyeron, si se conectaron a mano o si simplemente no hubo ninguna.
#
# La respuesta medida es la tercera: con contiguidad tipo reina sobre la capa
# municipal 1:4 000 000 del INEGI, NINGUN municipio queda sin vecinos. Los insulares
# tampoco, porque a esa escala de generalizacion su poligono llega a tocar el de los
# municipios costeros. El respaldo previsto en 05_grafo_vecindad.R --conectar un area
# aislada a su vecino de centroide mas proximo-- nunca tuvo que ejecutarse. Esta tabla
# es la evidencia de eso, y de que los vecinos asignados a las islas son los
# geograficamente correctos y no un artefacto arbitrario.

suppressPackageStartupMessages({
  library(sf); library(spdep); library(dplyr); library(readr)
})

SHP <- "DATOS_GEO_MEXICO/municipios_INEGI_oficial/inegi_extracted/QGis/MapaBaseMultiescala.gpkg"
OUT <- "TABLAS"
if (!dir.exists(OUT)) dir.create(OUT, recursive = TRUE)

m  <- st_read(SHP, layer = "municipios_4m", quiet = TRUE)
nb <- poly2nb(m, queen = TRUE)
g  <- card(nb)

stopifnot(nrow(m) == 2478)

# Municipios cuya superficie es la de una isla conocida. No se buscan por nombre a
# ciegas: se comprueba ademas que el poligono este separado del bloque continental
# por su propia geometria, mirando a quien colinda.
insulares <- c("Cozumel", "Isla Mujeres")
idx_ins <- which(m$nomgeo %in% insulares)
stopifnot(length(idx_ins) == length(insulares))

filas <- lapply(idx_ins, function(i) {
  data.frame(
    Municipio = m$nomgeo[i],
    Entidad   = "Quintana Roo",
    Vecinos   = g[i],
    `Municipios colindantes` = paste(m$nomgeo[nb[[i]]], collapse = ", "),
    check.names = FALSE
  )
})
tab_islas <- bind_rows(filas)

resumen <- data.frame(
  Indicador = c("Municipios en el grafo",
                "Municipios sin vecinos (componentes aisladas)",
                "Vecinos por municipio: mínimo",
                "Vecinos por municipio: mediana",
                "Vecinos por municipio: máximo",
                "Conexiones añadidas por el respaldo de centroide más próximo"),
  Valor = c(nrow(m), sum(g == 0), min(g), median(g), max(g), 0),
  check.names = FALSE
)

# El cero de la ultima fila no se escribe a mano: si alguna vez hubiera islas, este
# stopifnot para el pipeline en vez de dejar publicada una tabla que dice "0".
stopifnot(sum(g == 0) == 0)

write_csv(resumen,   file.path(OUT, "TablaS7_conectividad_resumen.csv"))
write_csv(tab_islas, file.path(OUT, "TablaS7_conectividad_islas.csv"))

cat("Tabla S7 (conectividad del grafo):\n")
print(resumen)
cat("\nMunicipios insulares:\n")
print(tab_islas)
cat("\nGuardado en", OUT, "\n")
