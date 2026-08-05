library(sf)
library(terra)
library(geodata)

# Carpeta de cache del DEM descargado (no requiere ser persistente: se puede volver a descargar
# de geodata.ucdavis.edu si se borra; solo el CSV de salida es el artefacto que importa conservar).
SCRATCH <- "c:/Users/zabus/OneDrive/Escritorio/INVESTIGACION/ARTICULOS ORIGINALES/estudios_originales/05_ESPACIAL_BAYESIANO_SAE/ESTUDIO_SAE_CASCADA_HTA_MEXICO/DATOS_GEO_MEXICO/dem_cache"
GPKG <- "c:/Users/zabus/OneDrive/Escritorio/INVESTIGACION/ARTICULOS ORIGINALES/estudios_originales/05_ESPACIAL_BAYESIANO_SAE/ESTUDIO_SAE_CASCADA_HTA_MEXICO/DATOS_GEO_MEXICO/municipios_INEGI_oficial/inegi_extracted/QGis/MapaBaseMultiescala.gpkg"
OUT_CSV <- "c:/Users/zabus/OneDrive/Escritorio/INVESTIGACION/ARTICULOS ORIGINALES/estudios_originales/05_ESPACIAL_BAYESIANO_SAE/ESTUDIO_SAE_CASCADA_HTA_MEXICO/COVARIABLES/altitud_municipal_DEM.csv"

# 1. Descargar DEM de Mexico (SRTM-derivado, geodata, resolucion ~1km)
dem <- elevation_30s(country = "MEX", path = SCRATCH)
cat("DEM descargado. res =", res(dem), " crs =", crs(dem, describe = TRUE)$name, "\n")

# 2. Cargar shapefile de municipios INEGI (ya verificado: 2478, 0 vacias/invalidas)
m <- st_read(GPKG, layer = "municipios_4m", quiet = TRUE)
cat("Municipios cargados:", nrow(m), " | CRS original:", st_crs(m)$input, "\n")

# 3. Reproyectar a WGS84 (CRS del DEM) para poder extraer
m_wgs <- st_transform(m, crs(dem))
m_vect <- vect(m_wgs)

# 4. Extraer altitud media (y otras estadisticas) por poligono
ext_mean <- terra::extract(dem, m_vect, fun = mean, na.rm = TRUE, ID = FALSE)
ext_min  <- terra::extract(dem, m_vect, fun = min,  na.rm = TRUE, ID = FALSE)
ext_max  <- terra::extract(dem, m_vect, fun = max,  na.rm = TRUE, ID = FALSE)
ext_n    <- terra::extract(dem, m_vect, fun = function(x, ...) sum(!is.na(x)), ID = FALSE)

res_df <- data.frame(
  cve_ent = m$cve_ent,
  cve_mun = m$cve_mun,
  nomgeo = m$nomgeo,
  altitud_media_msnm = round(ext_mean[[1]], 1),
  altitud_min_msnm = round(ext_min[[1]], 1),
  altitud_max_msnm = round(ext_max[[1]], 1),
  n_pixeles_dem = ext_n[[1]]
)

# 5. Municipios sin pixeles del DEM (poligonos muy pequenos vs resolucion ~1km) -> fallback centroide
sin_pixeles <- which(is.na(res_df$altitud_media_msnm) | res_df$n_pixeles_dem == 0)
cat("Municipios sin pixel DEM intersectado (requieren fallback centroide):", length(sin_pixeles), "\n")
if (length(sin_pixeles) > 0) {
  cent <- st_centroid(m_wgs[sin_pixeles, ])
  cent_vect <- vect(cent)
  cent_alt <- terra::extract(dem, cent_vect, ID = FALSE)
  res_df$altitud_media_msnm[sin_pixeles] <- round(cent_alt[[1]], 1)
  res_df$altitud_min_msnm[sin_pixeles] <- round(cent_alt[[1]], 1)
  res_df$altitud_max_msnm[sin_pixeles] <- round(cent_alt[[1]], 1)
  res_df$n_pixeles_dem[sin_pixeles] <- 0L
}

# 6. Verificaciones
cat("\n=== VERIFICACION ===\n")
cat("Filas:", nrow(res_df), " (shapefile tenia", nrow(m), ")\n")
cat("NA en altitud_media_msnm:", sum(is.na(res_df$altitud_media_msnm)), "\n")
cat("Rango altitud media:", min(res_df$altitud_media_msnm, na.rm=TRUE), "-", max(res_df$altitud_media_msnm, na.rm=TRUE), "msnm\n")
cat("Duplicados cve_ent+cve_mun:", sum(duplicated(paste(res_df$cve_ent, res_df$cve_mun))), "\n")

# Pico mas alto conocido de Mexico: Pico de Orizaba, ~5636 msnm, en Puebla/Veracruz
top5 <- res_df[order(-res_df$altitud_media_msnm), ][1:5, c("nomgeo","cve_ent","cve_mun","altitud_media_msnm","altitud_max_msnm")]
cat("\nTop 5 municipios mas altos (media):\n")
print(top5)

write.csv(res_df, OUT_CSV, row.names = FALSE, fileEncoding = "UTF-8")
cat("\nGuardado en:", OUT_CSV, "\n")
