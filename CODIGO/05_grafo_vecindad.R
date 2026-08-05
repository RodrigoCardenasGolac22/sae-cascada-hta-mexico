# Construye la matriz/grafo de vecindad municipal para el modelo BYM2, a partir del shapefile
# INEGI oficial ya verificado (2,478 municipios, 0 geometrias vacias/
# invalidas, capa "municipios_4m"). Paso previo al modelo de prueba de concepto (paso 7 del plan).

library(sf)
library(spdep)

SHP <- "DATOS_GEO_MEXICO/municipios_INEGI_oficial/inegi_extracted/QGis/MapaBaseMultiescala.gpkg"
OUT <- "DATOS_GEO_MEXICO"

m <- st_read(SHP, layer = "municipios_4m", quiet = TRUE)
cat("Municipios:", nrow(m), "\n")
cat("Geometrias vacias:", sum(st_is_empty(m)), "\n")

# poly2nb necesita geometrias validas y no vacias -- ya verificado que son 0, pero
# se revalida aqui explicitamente antes de construir el grafo (no confiar en la verificacion
# de otra sesion sin volver a comprobarla)
stopifnot(sum(st_is_empty(m)) == 0, sum(!st_is_valid(m)) == 0)

nb <- poly2nb(m, queen = TRUE)
n_sin_vecinos <- sum(card(nb) == 0)
cat("Municipios SIN vecinos (islas):", n_sin_vecinos, "\n")

if (n_sin_vecinos > 0) {
  idx_sin_vecinos <- which(card(nb) == 0)
  cat("Municipios afectados (nomgeo, cve_ent, cve_mun):\n")
  print(data.frame(m)[idx_sin_vecinos, c("nomgeo","cve_ent","cve_mun")])

  # fix estandar: conectar cada isla a su vecino mas cercano por centroide (mismo enfoque
  # (un area sin vecinos rompe el termino espacial BYM2, asi que se conecta al centroide mas cercano)
  cent <- st_centroid(st_geometry(m))
  coords <- st_coordinates(cent)
  for (i in idx_sin_vecinos) {
    d <- spDistsN1(coords, coords[i, ], longlat = FALSE)
    d[i] <- Inf
    vecino_mas_cercano <- which.min(d)
    nb[[i]] <- as.integer(vecino_mas_cercano)
    nb[[vecino_mas_cercano]] <- sort(unique(c(nb[[vecino_mas_cercano]], as.integer(i))))
    cat("  Conectado municipio", i, "(", m$nomgeo[i], ") a su vecino mas cercano:", vecino_mas_cercano,
        "(", m$nomgeo[vecino_mas_cercano], ")\n")
  }
  cat("Municipios SIN vecinos tras el fix:", sum(card(nb) == 0), "\n")
}

# indice para el modelo INLA, en el MISMO orden que las filas del shapefile
muni_idx_tabla <- data.frame(
  muni_idx = seq_len(nrow(m)),
  cve_ent = m$cve_ent,
  cve_mun = m$cve_mun,
  nomgeo = m$nomgeo
)
write.csv(muni_idx_tabla, file.path(OUT, "muni_idx_grafo.csv"), row.names = FALSE)

nb2INLA(file.path(OUT, "municipios.graph"), nb)
cat("\nGuardado: DATOS_GEO_MEXICO/municipios.graph, DATOS_GEO_MEXICO/muni_idx_grafo.csv\n")

# resumen de conectividad
cat("\nResumen de numero de vecinos por municipio:\n")
print(summary(card(nb)))
