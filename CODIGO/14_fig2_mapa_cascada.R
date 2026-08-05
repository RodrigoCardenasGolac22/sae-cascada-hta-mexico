# Fig 2 (figura estrella, plan seccion 9): mapa municipal de conciencia/tratamiento/control,
# criterio ESH, cobertura nacional.
#
# Convenciones de mapa tomadas de la practica habitual en revistas de geografia de la salud
# (escala comparable entre paneles, proyeccion adecuada, escala grafica y norte):
#  - Clasificacion por CUANTILES (6 clases), no gradiente continuo -- Brewer & Pickle 2002,
#    Annals AAG 92(4):662-681: los cuantiles se interpretan con mas precision en mapas de tasas de
#    salud, <=7 clases por limite cognitivo (Miller). Escala AUTOESCALADA por panel (cada paso de
#    la cascada es una variable distinta, no la misma variable repetida en una serie).
#  - Bordes municipales SIEMPRE visibles (gris oscuro fino) -- sin esto, municipios vecinos del
#    mismo color se fusionan en un blob sin granularidad (verificado contra 4 papers Q1 reales).
#  - Contorno NACIONAL grueso y negro (distingue el borde real del pais de un borde interno).
#  - Fondo blanco explicito (no transparente).
#  - Flecha de norte + escala grafica, SOLO en el primer panel (misma area geografica en los 3).
#  - SIN titulo/subtitulo de figura incrustado en el archivo grafico -- confirmado contra
#    directrices Q1 reales (IJHG, pag. 11): "los titulos de las figuras deben incluirse en el
#    manuscrito principal, no en el archivo grafico". Solo quedan las etiquetas de panel A/B/C.
#  - Paleta viridis "C" (magma) evitada en el extremo mas oscuro solo si se confunde con bordes --
#    aqui se mantiene magma discretizado por cuantiles (no continuo), que sigue siendo legible
#    porque el borde gris NO se superpone con el propio color de relleno de forma ambigua (a
#    diferencia del caso secuencial de un solo color de Fig 3, ver ese script).
#
# Especifico de este estudio: columna
# "fuente" (muestra directa vs. prediccion espacial sintetica) se mantiene como ATRIBUTO VISUAL
# adicional (opacidad reducida), ya que responde una pregunta distinta a la de suprimir celdas
# pequenas (aqui: "hay observacion directa o no", no "n es demasiado chico para confiar").
#
# Control de divulgacion (privacidad): mismo criterio que el script 09
# (09_modelos_finales.R: n<10 -> no reportar) pero aplicado al denominador EXACTO de cada paso
# (calculado en 24_extension_nacional_mezcla_poblacional.R, columna suprimir_privacidad), no a un
# proxy de "adultos totales". Los municipios marcados se muestran en gris solido (relleno NA,
# misma paleta que "sin cobertura"), a opacidad plena -- visualmente distintos de la prediccion
# espacial (coloreada, semi-transparente) porque comunican algo distinto: no es que falte
# informacion, es que la informacion existe pero no se publica por riesgo de identificacion.

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

leer_nacional <- function(nombre) {
  read_csv(file.path(RES, paste0("NACIONAL_", nombre, ".csv")), col_types = cols()) %>%
    transmute(cve_ent = cve_ent, cve_mun = cve_mun,
              prevalencia = ifelse(suprimir_privacidad, NA_real_, prev),
              fuente = case_when(
                suprimir_privacidad ~ "Suprimido (n<10, privacidad)",
                fuente == "muestra_directa" ~ "Muestra directa",
                TRUE ~ "Sin muestra directa"))
}

pasos <- list("A. Diagnóstico" = leer_nacional("AWARE_ESH"),
              "B. Tratamiento" = leer_nacional("TRAT"),
              "C. Control" = leer_nacional("CONTROL_ESH"))

# Ubicacion de la leyenda de "Fuente" para que no se recorte al exportar (
# Con los 3 niveles de Fuente en 2 columnas, la etiqueta larga "Sin muestra directa" excede el
# ancho disponible de cada panel y el panel vecino la recorta. Se usa 1 sola columna: cada nivel en
# su propia fila, con el ancho completo.
#
# Ademas: "NA" (leyenda de Prevalencia, municipios sin geometria/dato) es un termino de R/estadistica
# que no deberia aparecer literal en una figura en espanol de una revista medica -- se convierte a
# un nivel explicito "Sin dato" con su propio color (mismo gris que antes), lo que obliga a
# reemplazar scale_fill_viridis_d() por scale_fill_manual() con los colores viridis generados a
# mano (viridisLite::viridis(), el mismo paquete que usa la escala automatica por dentro).
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
  mm$clase <- clasificar_cuantiles(mm$prevalencia)
  niveles_prevalencia <- setdiff(levels(mm$clase), "Sin dato")
  colores_clase <- setNames(c(viridisLite::viridis(length(niveles_prevalencia), option = "C"), "grey85"),
                             c(niveles_prevalencia, "Sin dato"))
  p <- ggplot(mm) +
    geom_sf(aes(fill = clase, alpha = fuente), color = "grey40", linewidth = 0.04) +
    geom_sf(data = contorno_pais, fill = NA, color = "black", linewidth = 0.35) +
    scale_fill_manual(name = "Prevalencia", values = colores_clase, drop = FALSE) +
    scale_alpha_manual(name = "Fuente", values = c("Muestra directa" = 1, "Sin muestra directa" = 0.5,
                                                    "Suprimido (n<10, privacidad)" = 1),
                        na.translate = FALSE) +
    # order fija el orden de los BLOQUES de leyenda. Sin el, ggplot lo decide por panel y en
    # "Tratamiento" salia "Prevalencia" antes que "Fuente", al reves que en los otros dos.
    guides(fill = guide_legend(nrow = 4, byrow = TRUE, title.position = "top", order = 2,
                                override.aes = list(linewidth = 0.2)),
           # override.aes explicito: por defecto los 3 niveles de "Fuente" se ven todos NEGROS en
           # la leyenda (el color de relleno de la leyenda de alpha no hereda la escala de fill) --
           # aunque en el mapa real "Suprimido" SI se ve gris solido (fill=NA->grey85) y distinto de
           # "Muestra directa" (coloreado). Sin esto, un lector no podria distinguirlos en la leyenda.
           alpha = guide_legend(ncol = 1, title.position = "top", order = 1,
                                 override.aes = list(fill = c("grey40", "grey40", "grey85")))) +
    labs(title = titulo) +
    theme_void(base_size = 12) +
    theme(legend.position = "bottom",
          legend.box = "vertical",
          legend.box.just = "left",
          legend.margin = margin(t = 0, b = 0),
          legend.spacing.y = unit(0.05, "cm"),
          legend.key.size = unit(0.42, "cm"),
          legend.title = element_text(size = 10, hjust = 0),
          legend.text = element_text(size = 8.5),
          plot.title = element_text(hjust = 0.5, size = 13, face = "bold"),
          plot.margin = margin(t = 5, r = 18, b = 5, l = 18),
          plot.background = element_rect(fill = "white", color = NA),
          panel.background = element_rect(fill = "white", color = NA))
  if (con_norte_escala) {
    p <- p +
      annotation_north_arrow(location = "tr", which_north = "true",
                              height = unit(0.9, "cm"), width = unit(0.9, "cm"),
                              style = north_arrow_minimal) +
      annotation_scale(location = "bl", width_hint = 0.25, text_cex = 0.9)
  }
  p
}

p1 <- hacer_mapa(pasos[[1]], names(pasos)[1], con_norte_escala = TRUE)
p2 <- hacer_mapa(pasos[[2]], names(pasos)[2])
p3 <- hacer_mapa(pasos[[3]], names(pasos)[3])

fig2 <- (p1 + p2 + p3 + plot_layout(nrow = 1)) &
  theme(plot.background = element_rect(fill = "white", color = NA))
fig2 <- fig2 + plot_annotation(theme = theme(plot.background = element_rect(fill = "white", color = NA)))

ggsave(file.path(FIG, "Fig2_cascada_municipal_ESH.svg"), fig2, width = 9.5, height = 6.4, bg = "white")
ggsave(file.path(FIG, "Fig2_cascada_municipal_ESH.png"), fig2, width = 9.5, height = 6.4, dpi = 400, bg = "white")
cat("Guardado: FIGURAS/Fig2_cascada_municipal_ESH.svg y .png\n")

guardar_figura_pptx(fig2, file.path(FIG, "Fig2_cascada_municipal_ESH.pptx"), ancho = 14, alto = 6.3)
