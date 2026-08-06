# FIGURA 1: flujo de seleccion de la muestra (STROBE), periodo pooled 2021-2024, criterio ESH.
#
# La guia de reporte aplicable es STROBE, no RECORD: RECORD esta pensada para datos administrativos
# o clinicos recolectados sin fin de investigacion, y ENSANUT es una encuesta con marco muestral y
# cuestionario disenados a priori con fin estadistico. El titulo de la figura no va incrustado en
# la imagen (va en el manuscrito, junto a la leyenda), como en el resto de las figuras.
#
# Aritmetica del diagrama: el n de "PA valida" se calcula como edad_20mas - excl_sin_bp_valida
# (45,011 - 19,600 = 25,411). NO se suma aparte excl_lectura_invertida: las lecturas con
# sistolica <= diastolica se anulan ANTES de contar excl_sin_bp_valida (script 01), asi que ya
# estan contenidas en esa exclusion y sumarlas de nuevo las contaria dos veces. La cadena cierra
# exacto: 25,411 - 321 (embarazo) - 1 (sin peso de diseno) = 25,089 = n final.
#
# Cada caja de excluidos se dibuja ANTES de la caja a la que se aplica, sobre la flecha que entra.

library(dplyr)
library(readr)
library(ggplot2)
library(officer)
library(rvg)
source("CODIGO/00_comun.R")
# Formato espanol de los numeros DIBUJADOS dentro de la figura. Sin esto, ggplot2 escribe
# "45,011" y "-40.9" -- convencion inglesa -- sobre un articulo cuyo texto usa "45 011" y
# "-40,9". Ningun grep del .docx lo encuentra: el texto queda rasterizado en la imagen.
source("CODIGO/00b_formato_es.R")

RES <- "RESULTADOS"
FIG <- "FIGURAS"

flujo <- read_csv(file.path(RES, "flujo_STROBE_2021_2024.csv"), col_types = cols())
pooled <- flujo %>% summarise(across(where(is.numeric), sum))

n_entrevistados <- pooled$entrevistados
n_pa_valida     <- pooled$edad_20mas - pooled$excl_sin_bp_valida
n_sin_embarazo  <- n_pa_valida - pooled$excl_embarazo_actual
n_final         <- n_sin_embarazo - pooled$excl_sin_peso
stopifnot(n_final == pooled$n_final)  # verificacion aritmetica antes de dibujar nada

pasos <- tibble::tibble(
  paso = c(
    "Entrevistados,\nadultos ENSANUT 2021-2024",
    "PA válida por lectura\n(PAS≥80, PAD≥50 mmHg;\n28 lecturas invertidas anuladas)",
    "Sin embarazo actual",
    "Base analítica final\n(con peso de diseño)",
    "Con HTA (criterio ESH:\n≥140/90 o Dx previo)",
    "Diagnosticados",
    "Tratados\n(entre diagnosticados)"
  ),
  n = c(n_entrevistados, n_pa_valida, n_sin_embarazo, n_final,
        pooled$n_hta_esh, pooled$n_diagnosticados, pooled$n_tratados),
  # excluidos[i] = excluidos AL LLEGAR a la caja i, viniendo de la caja i-1 (NA en la caja 1)
  excluidos = c(NA, pooled$excl_sin_bp_valida, pooled$excl_embarazo_actual, pooled$excl_sin_peso,
                NA, pooled$n_hta_esh - pooled$n_diagnosticados, pooled$n_diagnosticados - pooled$n_tratados),
  motivo_excl = c(NA, "Sin PA válida (incl. lectura inválida)", "Embarazo actual",
                   "Sin peso de diseño", NA, "No diagnosticados", "No tratados")
)

n_pasos <- nrow(pasos)
pasos$y <- rev(seq_len(n_pasos))
pasos$x <- 0.35

# posicion vertical de cada caja roja: en la flecha que ENTRA a la caja i, es decir entre
# pasos$y[i-1] (arriba) y pasos$y[i] (abajo) -- punto medio = pasos$y[i] + 0.5
pasos$y_excl <- pasos$y + 0.5

fig1 <- ggplot() +
  geom_rect(data = pasos, aes(xmin = x - 0.32, xmax = x + 0.32, ymin = y - 0.35, ymax = y + 0.35),
            fill = "#e8f0fa", color = "#2166ac", linewidth = 0.6) +
  geom_text(data = pasos, aes(x = x, y = y, label = paste0(paso, "\nn = ", fmt_es_entero(n))),
            size = 3.2, lineheight = 0.9) +
  geom_segment(data = pasos[-n_pasos, ], aes(x = x, xend = x, y = y - 0.35, yend = y - 0.65),
               arrow = arrow(length = unit(0.15, "cm")), linewidth = 0.5) +
  geom_segment(data = pasos %>% filter(!is.na(excluidos)),
               aes(x = x, xend = x + 0.5, y = y_excl, yend = y_excl),
               linewidth = 0.4, color = "#b2182b") +
  geom_rect(data = pasos %>% filter(!is.na(excluidos)),
            aes(xmin = x + 0.5, xmax = x + 1.2, ymin = y_excl - 0.28, ymax = y_excl + 0.28),
            fill = "#fdecec", color = "#b2182b", linewidth = 0.5) +
  geom_text(data = pasos %>% filter(!is.na(excluidos)),
            aes(x = x + 0.85, y = y_excl, label = paste0("Excluidos: ", fmt_es_entero(excluidos), "\n", motivo_excl)),
            size = 2.6, lineheight = 0.9) +
  scale_y_continuous(limits = c(min(pasos$y) - 0.6, max(pasos$y) + 0.6)) +
  scale_x_continuous(limits = c(-0.1, 1.75)) +
  theme_void(base_size = 11)
# El pie de pagina
# ("Rama de conciencia/tratamiento... Verificado aritmeticamente...") quedaba incrustado en el PNG
# Y ademas repetido como leyenda real en el .docx (agregada por 28_manuscrito_a_docx.R) -- las dos
# decian casi lo mismo, una al lado de la otra. Retirado de la imagen (la nota de verificacion vive
# ahora solo en la leyenda del .docx); coincide con la regla ya aplicada a Fig2/Fig3/FigS2: nada de
# texto incrustado en el archivo grafico.

ggsave(file.path(FIG, "Fig1_flujo_STROBE.svg"), fig1, width = 9, height = 10, bg = "white")
ggsave(file.path(FIG, "Fig1_flujo_STROBE.png"), fig1, width = 9, height = 10, dpi = 300, bg = "white")
cat("Guardado: FIGURAS/Fig1_flujo_STROBE.svg y .png\n")

guardar_figura_pptx(fig1, file.path(FIG, "Fig1_flujo_STROBE.pptx"), ancho = 9, alto = 10)

# Exportacion para el envio a la revista mexicana (ver CODIGO/00_comun.R):
# .eps para la figura y .xlsx con los datos que la generan.
guardar_figura_eps(fig1, file.path(FIG, "Fig1_flujo_STROBE.eps"), ancho = 9, alto = 10)
guardar_datos_figura(list(flujo_STROBE = flujo), file.path(FIG, "DATOS", "Fig1_datos.xlsx"))
