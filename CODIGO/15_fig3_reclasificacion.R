# Fig 3 (plan seccion 9): mapa de reclasificacion espacial ESH -> ACC/AHA, conciencia y control,
# cobertura nacional.
#
# Mismas convenciones que Fig 2 (ver ese script para el razonamiento completo). Diferencia clave
# frente a Fig 2: TODOS los valores de reclasificacion son negativos (verificado: rango -47.0 a
# -1.4 en conciencia, -31.3 a -13.4 en control, ninguno cruza 0) -- exactamente la misma situacion
# de esta figura: una escala DIVERGENTE roja-azul desperdiciaria la
# mitad del rango de color (el lado azul nunca se usaria). Se usa una escala SECUENCIAL de un solo
# color (RColorBrewer "Reds", invertida para que mas oscuro = mayor caida), NO magma/viridis "A"
# (su extremo oscuro es casi negro, se confunde con el color de borde -- misma razon documentada
# de los valores).

library(sf)
library(dplyr)
library(readr)
library(ggplot2)
library(officer)
library(rvg)
library(patchwork)
library(ggspatial)
source("CODIGO/00_comun.R")
# Formato espanol de los numeros DIBUJADOS dentro de la figura. Sin esto, ggplot2 escribe
# "45,011" y "-40.9" -- convencion inglesa -- sobre un articulo cuyo texto usa "45 011" y
# "-40,9". Ningun grep del .docx lo encuentra: el texto queda rasterizado en la imagen.
source("CODIGO/00b_formato_es.R")

GEO_SHP <- "DATOS_GEO_MEXICO/municipios_INEGI_oficial/inegi_extracted/QGis/MapaBaseMultiescala.gpkg"
RES <- "RESULTADOS"
FIG <- "FIGURAS"

m <- st_read(GEO_SHP, layer = "municipios_4m", quiet = TRUE)
m <- st_make_valid(m)
m <- m[!st_is_empty(m), ]
contorno_pais <- st_union(m)

leer_reclas <- function(nombre) {
  # El CSV de reclasificacion ya trae cve_ent/cve_mun/nomgeo (los une el script 09); volver a
  # unirlos contra muni_idx_grafo.csv duplicaba las columnas y rompia el transmute.
  read_csv(file.path(RES, paste0("NACIONAL_reclasificacion_", nombre, "_ESH_vs_AHA.csv")),
           col_types = cols(cve_ent = col_character(), cve_mun = col_character())) %>%
    transmute(cve_ent, cve_mun,
              diferencia_pp = ifelse(suprimir_privacidad, NA_real_, diferencia_pp),
              fuente = case_when(
                suprimir_privacidad ~ "Suprimido (n<10, privacidad)",
                ambos_directos ~ "Muestra directa",
                TRUE ~ "Sin muestra directa"))
}

datos <- list("A. Diagnóstico" = leer_reclas("conciencia"), "B. Control" = leer_reclas("control"))

# Mismas convenciones que la Figura 2 (ubicacion de la leyenda de Fuente y etiqueta explicita en
# espanol) -- mismo fix: "Sin dato" como nivel explicito con scale_fill_manual (colores Brewer
# generados a mano), y guia de alpha en 1 columna en vez de 2.
clasificar_cuantiles_delta <- function(x, n_clases = 6) {
  breaks <- unique(quantile(x, probs = seq(0, 1, length.out = n_clases + 1), na.rm = TRUE))
  clase <- cut(x, breaks = breaks, include.lowest = TRUE,
               labels = fmt_es_rango(paste0(round(head(breaks, -1), 1), " a ", round(breaks[-1], 1))))
  clase <- factor(clase, levels = c(levels(clase), "Sin dato"))
  clase[is.na(clase)] <- "Sin dato"
  clase
}

hacer_mapa <- function(d, titulo, con_norte_escala = FALSE) {
  mm <- m %>% left_join(d, by = c("cve_ent", "cve_mun"))
  mm$clase <- clasificar_cuantiles_delta(mm$diferencia_pp)
  niveles_delta <- setdiff(levels(mm$clase), "Sin dato")
  colores_clase <- setNames(c(rev(RColorBrewer::brewer.pal(length(niveles_delta), "Reds")), "grey85"),
                             c(niveles_delta, "Sin dato"))
  # Sin transparencia: cada clase se desdobla en su color y ese mismo color ya
  # mezclado al 50 % con el fondo (ver mezclar_con_fondo en 00_comun.R). PostScript
  # no admite alpha y cairo rasterizaria el mapa entero; asi el EPS sale vectorial
  # y la figura no cambia. El borde NO se mezcla: el alpha de geom_sf solo afecta
  # al relleno, y atenuarlo tambien empeoraba la comparacion contra el original.
  ATENUADO <- "~atenuado"
  mm$relleno <- factor(
    ifelse(!is.na(mm$fuente) & mm$fuente == "Sin muestra directa",
           paste0(as.character(mm$clase), ATENUADO), as.character(mm$clase)),
    levels = c(names(colores_clase), paste0(names(colores_clase), ATENUADO)))
  valores_relleno <- c(colores_clase,
                       setNames(mezclar_con_fondo(colores_clase, 0.5),
                                paste0(names(colores_clase), ATENUADO)))
  p <- ggplot(mm) +
    geom_sf(aes(fill = relleno, alpha = fuente), color = "grey40", linewidth = 0.04) +
    geom_sf(data = contorno_pais, fill = NA, color = "black", linewidth = 0.35) +
    scale_fill_manual(name = "Diferencia (pp)", values = valores_relleno,
                      breaks = names(colores_clase), labels = names(colores_clase),
                      drop = FALSE) +
    scale_alpha_manual(name = "Fuente", values = c("Muestra directa" = 1, "Sin muestra directa" = 1,
                                                    "Suprimido (n<10, privacidad)" = 1),
                        na.value = 1, na.translate = FALSE) +
    guides(fill = guide_legend(nrow = 4, byrow = TRUE, title.position = "top",
                                override.aes = list(linewidth = 0.2)),
           alpha = guide_legend(ncol = 1, title.position = "top",
                                 # el gris del medio va YA MEZCLADO: antes su tono claro
                                 # se lo daba el alpha, y sin el los dos primeros cuadros
                                 # de la leyenda quedaban identicos
                                 override.aes = list(fill = c("grey40",
                                                              mezclar_con_fondo("grey40", 0.5),
                                                              "grey85")))) +
    labs(title = titulo) +
    theme_void(base_size = 10) +
    theme(legend.position = "bottom",
          legend.key.size = unit(0.4, "cm"),
          legend.title = element_text(size = 9, hjust = 0.5),
          legend.text = element_text(size = 7),
          plot.title = element_text(hjust = 0.5, size = 11, face = "bold"),
          plot.margin = margin(t = 5, r = 14, b = 5, l = 14),
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

p1 <- hacer_mapa(datos[[1]], names(datos)[1], con_norte_escala = TRUE)
p2 <- hacer_mapa(datos[[2]], names(datos)[2])

fig3 <- (p1 + p2 + plot_layout(nrow = 1)) &
  theme(plot.background = element_rect(fill = "white", color = NA))
fig3 <- fig3 + plot_annotation(theme = theme(plot.background = element_rect(fill = "white", color = NA)))

ggsave(file.path(FIG, "Fig3_reclasificacion_ESH_vs_AHA.svg"), fig3, width = 10, height = 6.3, bg = "white")
ggsave(file.path(FIG, "Fig3_reclasificacion_ESH_vs_AHA.png"), fig3, width = 10, height = 6.3, dpi = 300, bg = "white")
cat("Guardado: FIGURAS/Fig3_reclasificacion_ESH_vs_AHA.svg y .png\n")

guardar_figura_pptx(fig3, file.path(FIG, "Fig3_reclasificacion_ESH_vs_AHA.pptx"), ancho = 10, alto = 6.3)

# Exportacion para el envio a la revista mexicana (ver CODIGO/00_comun.R):
# .eps para la figura y .xlsx con los datos que la generan.
guardar_figura_eps(fig3, file.path(FIG, "Fig3_reclasificacion_ESH_vs_AHA.eps"), ancho = 10, alto = 6.3)
guardar_datos_figura(datos, file.path(FIG, "DATOS", "Fig3_datos.xlsx"))
