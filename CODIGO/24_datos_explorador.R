# Datos para el explorador municipal (docs/index.html).
#
# El mapa impreso resuelve 3,2 km por pixel: 63 municipios ocupan menos de un pixel y 1 305 no
# llegan a 5x5. Ninguna figura estatica de 15 cm puede mostrar 2 478 poligonos. Este archivo
# alimenta la version consultable, que es donde esos municipios existen de verdad.
#
# Salida: docs/datos.json — geometria simplificada + las cinco estimaciones con su intervalo.

suppressPackageStartupMessages({library(sf); library(dplyr); library(readr); library(jsonlite)})
source("CODIGO/00b_formato_es.R")

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a

RES <- "RESULTADOS"; OUT <- "docs"
if (!dir.exists(OUT)) dir.create(OUT)

GEO <- "DATOS_GEO_MEXICO/municipios_INEGI_oficial/inegi_extracted/QGis/MapaBaseMultiescala.gpkg"
m <- st_read(GEO, layer = "municipios_4m", quiet = TRUE) %>%
  mutate(id = paste0(cve_ent, cve_mun))

# Proyeccion conica de Mexico (EPSG:6372) para que las areas y distancias no mientan, y
# simplificacion a 900 m: por debajo de la resolucion que cualquier pantalla va a mostrar, pero
# suficiente para que un municipio pequeño siga siendo un poligono y no un punto.
mp <- st_transform(m, 6372) %>% st_simplify(dTolerance = 900, preserveTopology = TRUE)

# El nombre del estado NO esta en la capa de municipios (solo cve_ent, cve_mun, nomgeo): se toma
# de la capa de estados del mismo archivo y se cruza por clave, no por nombre.
ent <- st_read(GEO, layer = "etiquetas_estados", quiet = TRUE) |> st_drop_geometry()
col_nom <- names(ent)[grepl("nom|nombre|entidad", names(ent), ignore.case = TRUE)][1]
col_cve <- names(ent)[grepl("cve", names(ent), ignore.case = TRUE)][1]
mapa_ent <- setNames(as.character(ent[[col_nom]]), sprintf("%02d", as.integer(ent[[col_cve]])))
mp$ent_nom <- unname(mapa_ent[mp$cve_ent])
stopifnot(!any(is.na(mp$ent_nom)))
cat("estados cruzados:", length(unique(mp$ent_nom)), "
")

bb <- st_bbox(mp)
cat("bbox:", round(bb), "\n")

# --- las cinco estimaciones -------------------------------------------------------------------
pasos <- c(AWARE_ESH = "diag_esh", AWARE_AHA = "diag_aha", TRAT = "trat",
           CONTROL_ESH = "ctrl_esh", CONTROL_AHA = "ctrl_aha")
est <- NULL
for (p in names(pasos)) {
  d <- read_csv(file.path(RES, paste0("NACIONAL_", p, ".csv")), col_types = cols(
                 cve_ent = col_character(), cve_mun = col_character())) %>%
    transmute(id = paste0(cve_ent, cve_mun),
              paso = pasos[[p]],
              v  = round(100 * prev, 1),
              lo = round(100 * prev_q025, 1),
              hi = round(100 * prev_q975, 1),
              n  = ifelse(is.na(n_directo), 0L, as.integer(n_directo)),
              f  = ifelse(fuente == "muestra_directa", ifelse(suprimir_privacidad, 2L, 0L), 1L))
  est <- bind_rows(est, d)
}
# f: 0 = muestra directa reportable · 1 = prediccion espacial · 2 = suprimido por n<10

# --- poblacion adulta censal por municipio ----------------------------------------------------
pob <- read_csv(file.path(RES, "postestratificacion_censal.csv"), col_types = cols(
                 muni_id = col_character())) %>%
  group_by(id = muni_id) %>% summarise(pob = round(sum(pob)), .groups = "drop")

# --- geometria a arrays compactos -------------------------------------------------------------
# Coordenadas en km redondeadas a un decimal (100 m): la mitad del tamaño de escribir dobles, y
# muy por debajo del error de la propia simplificacion.
geom_de <- function(g) {
  cs <- st_coordinates(g)
  # POLYGON trae L1,L2; MULTIPOLYGON trae L1,L2,L3. Se agrupa por TODAS las columnas de anillo
  # que existan, sea cual sea el tipo -- asumir una sola forma rompe con el archivo real.
  lcols <- grep("^L[0-9]+$", colnames(cs), value = TRUE)
  clave <- do.call(paste, c(lapply(lcols, function(k) cs[, k]), sep = "-"))
  lapply(split(seq_len(nrow(cs)), clave), function(ix) {
    round(as.vector(t(cs[ix, c("X", "Y"), drop = FALSE] / 1000)), 1)
  }) |> unname()
}
munis <- lapply(seq_len(nrow(mp)), function(i) {
  id <- mp$id[i]
  e <- est[est$id == id, ]
  vals <- setNames(lapply(unname(pasos), function(p) {
    r <- e[e$paso == p, ]
    if (!nrow(r)) NULL else list(v = r$v[1], lo = r$lo[1], hi = r$hi[1], n = r$n[1], f = r$f[1])
  }), unname(pasos))
  list(id = id, nom = mp$nomgeo[i], ent = mp$ent_nom[i],
       pob = as.integer(pob$pob[match(id, pob$id)] %||% 0),
       rings = geom_de(st_geometry(mp)[i]), est = vals[!vapply(vals, is.null, TRUE)])
})

salida <- list(
  bbox = round(as.numeric(bb) / 1000, 1),
  n_muni = nrow(mp),
  munis = munis
)
write_json(salida, file.path(OUT, "datos.json"), auto_unbox = TRUE, digits = NA)
cat("Guardado:", file.path(OUT, "datos.json"),
    sprintf("(%.2f MB, %d municipios)\n", file.size(file.path(OUT, "datos.json"))/1024^2, nrow(mp)))
