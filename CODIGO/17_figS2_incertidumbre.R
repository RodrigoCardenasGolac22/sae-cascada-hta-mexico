# Figura suplementaria (companera de Fig 2): mapa del ANCHO del intervalo de credibilidad al 95%
# por municipio -- practica real de DHS Program para el mismo problema (mapas modelados en zonas
# sin encuesta directa). Guia oficial: Burgert-Brucker C.R.,
# Dontamsetti T., Marshall A.M.J., Gething P.W. "Guidance for Use of The DHS Program Modeled Map
# Surfaces." DHS Spatial Analysis Reports No. 14. Rockville: ICF International; 2016. Cita textual
# (seccion 3.3, verificada contra el PDF real bajado de dhsprogram.com/pubs/pdf/SAR14/SAR14.pdf):
# "the width of the 95% CI... More uncertainty in a location indicates that the model poorly
# estimates the indicator value in that location, while less uncertainty indicates that the model
# is better able to estimate the indicator value in that location."
#
# A diferencia de Fig 2/3 (donde se SUPRIME el valor si n<10 por riesgo de privacidad), este mapa
# de incertidumbre NO se suprime: el ancho del IC95% no revela el valor puntual de ninguna persona
# real, solo que tan seguro esta el modelo -- no hay riesgo de identificacion que proteger aqui.

library(sf)
library(dplyr)
library(readr)
library(ggplot2)
library(officer)
library(rvg)
library(patchwork)
library(ggspatial)
source("CODIGO/00_comun.R")

GEO_SHP <- "DATOS_GEO_MEXICO/municipios_INEGI_oficial/inegi_extracted/QGis/MapaBaseMultiescala.gpkg"
RES <- "RESULTADOS"
FIG <- "FIGURAS"

m <- st_read(GEO_SHP, layer = "municipios_4m", quiet = TRUE)
m <- st_make_valid(m)
m <- m[!st_is_empty(m), ]
contorno_pais <- st_union(m)

leer_incertidumbre <- function(nombre) {
  read_csv(file.path(RES, paste0("NACIONAL_", nombre, ".csv")), col_types = cols()) %>%
    transmute(cve_ent = cve_ent, cve_mun = cve_mun, ancho_ic95,
              fuente = ifelse(fuente == "muestra_directa", "Muestra directa", "Sin muestra directa"))
}

pasos <- list("A. Diagnóstico" = leer_incertidumbre("AWARE_ESH"),
              "B. Tratamiento" = leer_incertidumbre("TRAT"),
              "C. Control" = leer_incertidumbre("CONTROL_ESH"))

# Etiqueta explicita "Sin dato" en vez de "NA", igual que en las Figuras 2 y 3.
# Aqui ademas se encontro un problema propio: na.value="grey85" es pra'cticamente el MISMO color
# que la 2a clase de la paleta secuencial "Greys" (RColorBrewer::brewer.pal(6,"Greys")[2] =
# "#D9D9D9" = grey85 exacto) -- "Sin dato" se habria confundido visualmente con una clase real de
# datos. Se usa un color claramente fuera de la familia de grises (crema palido) para que se lea
# como "no es parte de la escala", no como un valor mas de la gradiente.
clasificar_cuantiles <- function(x, n_clases = 6) {
  breaks <- unique(quantile(x, probs = seq(0, 1, length.out = n_clases + 1), na.rm = TRUE))
  clase <- cut(x, breaks = breaks, include.lowest = TRUE,
               labels = paste0(scales::percent(head(breaks, -1), accuracy = 1), "-",
                                scales::percent(breaks[-1], accuracy = 1)))
  clase <- factor(clase, levels = c(levels(clase), "Sin dato"))
  clase[is.na(clase)] <- "Sin dato"
  clase
}

hacer_mapa <- function(d, titulo, con_norte_escala = FALSE) {
  mm <- m %>% left_join(d, by = c("cve_ent", "cve_mun"))
  mm$clase <- clasificar_cuantiles(mm$ancho_ic95)
  niveles_ic <- setdiff(levels(mm$clase), "Sin dato")
  colores_clase <- setNames(c(RColorBrewer::brewer.pal(length(niveles_ic), "Greys"), "#FDF0D5"),
                             c(niveles_ic, "Sin dato"))
  p <- ggplot(mm) +
    geom_sf(aes(fill = clase, alpha = fuente), color = "grey40", linewidth = 0.04) +
    geom_sf(data = contorno_pais, fill = NA, color = "black", linewidth = 0.35) +
    # secuencial de un solo color (Greys): mas oscuro = IC mas ancho = menos confianza. No se usa
    # una paleta divergente porque "ancho de IC" no tiene signo, solo magnitud (misma logica que
    # Fig 3 con la diferencia de reclasificacion, documentada ahi).
    scale_fill_manual(name = "Ancho IC95%\n(pp)", values = colores_clase, drop = FALSE) +
    scale_alpha_manual(name = "Fuente", values = c("Muestra directa" = 1, "Sin muestra directa" = 0.5),
                        na.translate = FALSE) +
    guides(fill = guide_legend(nrow = 4, byrow = TRUE, title.position = "top",
                                override.aes = list(linewidth = 0.2)),
           alpha = guide_legend(ncol = 1, title.position = "top",
                                 override.aes = list(fill = "grey40"))) +
    labs(title = titulo) +
    theme_void(base_size = 10) +
    theme(legend.position = "bottom",
          legend.key.size = unit(0.4, "cm"),
          legend.title = element_text(size = 9, hjust = 0.5),
          legend.text = element_text(size = 7),
          plot.title = element_text(hjust = 0.5, size = 11, face = "bold"),
          plot.margin = margin(t = 5, r = 18, b = 5, l = 18),
          plot.background = element_rect(fill = "white", color = NA),
          panel.background = element_rect(fill = "white", color = NA))
  if (con_norte_escala) {
    p <- p +
      annotation_north_arrow(location = "tr", which_north = "true",
                              height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                              style = north_arrow_minimal) +
      annotation_scale(location = "bl", width_hint = 0.25, text_cex = 0.7)
  }
  p
}

p1 <- hacer_mapa(pasos[[1]], names(pasos)[1], con_norte_escala = TRUE)
p2 <- hacer_mapa(pasos[[2]], names(pasos)[2])
p3 <- hacer_mapa(pasos[[3]], names(pasos)[3])

figS <- (p1 + p2 + p3 + plot_layout(nrow = 1)) &
  theme(plot.background = element_rect(fill = "white", color = NA))
figS <- figS + plot_annotation(theme = theme(plot.background = element_rect(fill = "white", color = NA)))

ggsave(file.path(FIG, "FigS2_incertidumbre_ESH.svg"), figS, width = 14, height = 6.3, bg = "white")
ggsave(file.path(FIG, "FigS2_incertidumbre_ESH.png"), figS, width = 14, height = 6.3, dpi = 300, bg = "white")
cat("Guardado: FIGURAS/FigS2_incertidumbre_ESH.svg y .png\n")

guardar_figura_pptx(figS, file.path(FIG, "FigS2_incertidumbre_ESH.pptx"), ancho = 14, alto = 6.3)
