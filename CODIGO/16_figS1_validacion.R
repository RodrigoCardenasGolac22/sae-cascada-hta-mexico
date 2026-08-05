# Figura S1 (plan, seccion 9; renombrada de "Fig 4" a "Figura S1" al pasar a material
# suplementario -- ver MANUSCRITO_BORRADOR.md "Tablas y figuras"): reduccion de incertidumbre SAE
# vs. directa + validacion cruzada, por paso. Panel A: observado vs predicho (BYM2, 5 pliegues)
# para los 5 pasos, con linea de referencia 1:1 -- calibracion visual. Panel B: reduccion de RMSE
# del modelo BYM2 sobre el promedio nacional simple (no ajustado), por paso -- resumen cuantitativo
# ya reportado en resumen_validacion_cruzada.csv.
#
# Convenciones de redaccion de la figura: (1) "simple
# no ajustado" en los 3 textos de esta figura -- termino de jerga de Machine Learning ("naive
# baseline") que en espanol coloquial suena a "credulo/tonto", registro no adecuado para una
# publicacion medica (el manuscrito usa la
# traduccion literal, no un termino epidemiologico estandar). (2) titulo "Fig 4. Validacion
# cruzada..." incrustado en la imagen, retirado -- inconsistente con Fig2/Fig3/FigS2, que ya
# seguian la regla real (titulos van en el manuscrito, no en el archivo grafico). (3) archivos
# renombrados de Fig4_* a FigS1_* -- coincidian con el nombre viejo de antes de mover esta figura a
# material suplementario, aunque el manuscrito ya decia "Figura S1" en todo su texto (mismo patron
# consistente con la numeracion del material suplementario). (4) formato de porcentaje:
# antes pegaba el numero crudo (dio "2%" en vez de "2,0%" para control-ESH, unico bien
# inconsistente con las demas barras) -- ahora fuerza 1 decimal siempre con sprintf.

library(dplyr)
library(readr)
library(ggplot2)
library(officer)
library(rvg)
library(patchwork)
source("CODIGO/00_comun.R")
# Formato espanol de los numeros DIBUJADOS dentro de la figura. Sin esto, ggplot2 escribe
# "45,011" y "-40.9" -- convencion inglesa -- sobre un articulo cuyo texto usa "45 011" y
# "-40,9". Ningun grep del .docx lo encuentra: el texto queda rasterizado en la imagen.
source("CODIGO/00b_formato_es.R")

RES <- "RESULTADOS"
FIG <- "FIGURAS"

pasos_nombres <- c(AWARE_ESH = "Diagnóstico (ESH)", AWARE_AHA = "Diagnóstico (AHA)",
                    TRAT = "Tratamiento", CONTROL_ESH = "Control (ESH)", CONTROL_AHA = "Control (AHA)")

detalle <- bind_rows(lapply(names(pasos_nombres), function(p) {
  read_csv(file.path(RES, paste0("cv_detalle_", p, ".csv")), col_types = cols()) %>%
    mutate(paso = pasos_nombres[p])
})) %>% mutate(paso = factor(paso, levels = pasos_nombres))

resumen <- read_csv(file.path(RES, "resumen_validacion_cruzada.csv"), col_types = cols()) %>%
  mutate(paso_label = factor(pasos_nombres[paso], levels = pasos_nombres))

panel_a <- ggplot(detalle, aes(x = obs, y = pred_bym2)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(aes(size = n), alpha = 0.35, color = "#2166ac") +
  scale_size_continuous(name = "n municipio\n(pliegue de prueba)", range = c(0.5, 3)) +
  facet_wrap(~paso, nrow = 1) +
  scale_x_continuous(labels = function(x) fmt_es_rango(format(x, nsmall = 2, trim = TRUE))) +
  scale_y_continuous(labels = function(x) fmt_es_rango(format(x, nsmall = 2, trim = TRUE))) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(x = "Prevalencia observada (fuera de muestra, 5 pliegues)", y = "Prevalencia predicha (BYM2)",
       title = "A) Calibración: observado vs. predicho, validación cruzada espacial de 5 pliegues") +
  theme_bw(base_size = 10) +
  theme(plot.title = element_text(face = "bold", size = 11), legend.position = "right",
        strip.background = element_rect(fill = "#e8f0fa"))

panel_b <- ggplot(resumen, aes(x = paso_label, y = reduccion_rmse_pct)) +
  geom_col(fill = "#2166ac", width = 0.6) +
  geom_text(aes(label = fmt_es_rango(sprintf("%.1f%%", reduccion_rmse_pct))), vjust = -0.4, size = 3.3) +
  labs(x = NULL, y = "Reducción de RMSE\nBYM2 vs. promedio nacional simple (%)",
       title = "B) Ganancia del modelo espacial sobre una línea base simple no ajustada, por paso") +
  ylim(0, max(resumen$reduccion_rmse_pct) * 1.25) +
  theme_bw(base_size = 10) +
  theme(plot.title = element_text(face = "bold", size = 11),
        axis.text.x = element_text(angle = 20, hjust = 1))

figS1 <- panel_a / panel_b +
  plot_layout(heights = c(1.1, 1)) +
  plot_annotation(
    caption = "Compromiso computacional declarado: 5 pliegues por grupo de municipios, no dejar-un-municipio-fuera exhaustivo (~7,5 h estimadas).\n\"Observado\" = proporción NO ponderada dentro del municipio (más simple que la estimación directa con diseño complejo del script 05).",
    theme = theme(plot.caption = element_text(hjust = 0.5, size = 7.5))
  )

ggsave(file.path(FIG, "FigS1_validacion_cruzada.svg"), figS1, width = 12, height = 9, bg = "white")
ggsave(file.path(FIG, "FigS1_validacion_cruzada.png"), figS1, width = 12, height = 9, dpi = 300, bg = "white")
cat("Guardado: FIGURAS/FigS1_validacion_cruzada.svg y .png\n")

guardar_figura_pptx(figS1, file.path(FIG, "FigS1_validacion_cruzada.pptx"), ancho = 12, alto = 9)
