# Suplemento publico: tablas S1-S8 y figuras S1-S2, desde insumos agregados.
# Generador recuperado de la copia local y contrastado con el documento publicado:
# conserva las celdas de S2-S7 y las correcciones aceptadas en septiembre de 2026.
# S1 usa el comparador corregido; S8 requiere ejecutar antes 18c.

library(officer)
library(flextable)
library(readr)
library(dplyr)

TAB <- "results/tables"
FIG <- "results/figures"
RES <- "results/estimates"
OUT <- "manuscript/supplement"
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
ARCH <- list(suplementario = file.path(OUT, "MATERIAL_SUPLEMENTARIO.docx"))

fp_h3 <- fp_text(bold = TRUE, font.size = 11, font.family = "Arial")
fp_parrafo <- fp_par(line_spacing = 1.5, text.align = "justify")
ANCHO_UTIL <- 6.0

# fmt_es(), fmt_es_entero(), fmt_es_rango() y paso_legible viven en UN solo sitio desde el
# 2026-08-04: estaban copiados aqui y en el otro generador de entregables, y FALTABAN en
# 18_tablas.R, que por eso escribia el .xlsx del envio con punto decimal y con los codigos
# internos del pipeline a la vista. Una copia mas seria otra oportunidad de divergir.
source("analysis/00b_formato_es.R")

fp_borde <- fp_border(color = "black", width = 1)
estilo_rpmesp <- function(ft, ancho_pt = 9) {
  ft %>%
    border_remove() %>%
    hline_bottom(part = "header", border = fp_borde) %>%
    fontsize(size = ancho_pt, part = "all") %>%
    font(fontname = "Arial", part = "all") %>%
    align(align = "center", part = "all") %>%
    valign(valign = "center", part = "all") %>%
    padding(padding = 2, part = "all") %>%
    autofit() %>%
    fit_to_width(max_width = ANCHO_UTIL)
}

doc <- read_docx()
doc <- body_add_fpar(doc, fpar(ftext("Material suplementario", fp_text(bold = TRUE, font.size = 12, font.family = "Arial")),
                                fp_p = fp_par(text.align = "center", padding.bottom = 6)))
doc <- body_add_fpar(doc, fpar(ftext(
  "Estimación bayesiana de área pequeña de la cascada de atención de la hipertensión arterial en los municipios de México: análisis de la ENSANUT Continua 2021-2024",
  fp_text(italic = TRUE, font.size = 10, font.family = "Arial")), fp_p = fp_par(text.align = "center", padding.bottom = 12)))

# --- Tabla S1 ---
d <- read_csv(file.path(TAB, "TablaS1_diagnosticos_modelo.csv"), col_types = cols())
d2 <- d %>% transmute(
  Paso = paso_legible[Paso],
  # Dos columnas de n: el denominador elegible del paso y el numero efectivamente ajustado por el
  # modelo, que es menor cuando alguna covariable de area no cubre todos los municipios. Antes iba
  # una sola columna con el denominador junto al WAIC del modelo, y se leia como si el modelo se
  # hubiera ajustado sobre mas observaciones de las que uso.
  `n (denominador)` = fmt_es_entero(`n (denominador del paso)`),
  `n (modelo)` = fmt_es_entero(`n (modelo)`),
  `Municipios (muestra)` = fmt_es_entero(`Municipios (muestra)`),
  WAIC = fmt_es(WAIC, 1),
  `Phi (mediana)` = fmt_es(`Phi (mediana)`, 3),
  `RMSE BYM2` = fmt_es(`RMSE BYM2`, 4),
  `RMSE simple (no ajustado)` = fmt_es(`RMSE simple (no ajustado)`, 4),
  `Reducción RMSE (%)` = fmt_es(`Reducción RMSE (%)`, 1),
  `Cobertura nacional (%)` = fmt_es(`Cobertura nacional (%)`, 1)
)
ft <- flextable(d2) %>% estilo_rpmesp(ancho_pt = 8)
doc <- body_add_fpar(doc, fpar(ftext("Tabla S1. Diagnósticos del modelo por paso de la cascada.", fp_h3),
                                fp_p = fp_par(padding.top = 8, padding.bottom = 4)))
doc <- body_add_flextable(doc, ft)
doc <- body_add_fpar(doc, fpar(ftext(
  "Los modelos principales usan pseudo-verosimilitud con el ponderador calibrado normalizado a media 1 dentro de cada municipio. WAIC: Watanabe-Akaike Information Criterion. Phi: fracción de varianza espacial del modelo BYM2 (Besag-York-Mollié tipo 2). El comparador se estima solo en entrenamiento en cada pliegue. RMSE: raíz del error cuadrático medio, validación cruzada espacial de 5 pliegues con observados y predicciones municipales agregados mediante el ponderador calibrado. ESH: European Society of Hypertension (criterio 2023, ≥140/90 mmHg). AHA: American College of Cardiology/American Heart Association (criterio 2025, ≥130/80 mmHg).",
  fp_text(font.size = 8, italic = TRUE, font.family = "Arial")), fp_p = fp_parrafo))

# --- Tabla S2: sensibilidad al ponderador ---
# Es la tabla que sustenta la decision de usar el ponderador calibrado en el analisis principal:
# muestra el efecto de calibrar sobre las estimaciones nacionales y, para 2023, la comparacion
# contra el ponderador de tension arterial que publica la propia encuesta.
doc <- body_add_break(doc)
comp <- read_csv(file.path(RES, "comparacion_ponderadores_nacional.csv"), col_types = cols())
val  <- read_csv(file.path(RES, "validacion_calibracion_2023.csv"), col_types = cols())
paso_s2 <- c(PREV_HTA_ESH = "Prevalencia HTA (ESH)", PREV_HTA_AHA = "Prevalencia HTA (AHA)",
             AWARE_ESH = "Diagnóstico (ESH)", AWARE_AHA = "Diagnóstico (AHA)",
             TRAT = "Tratamiento", CONTROL_ESH = "Control (ESH)", CONTROL_AHA = "Control (AHA)")
s2 <- comp %>%
  transmute(Indicador = paso_s2[indicador],
            `Sin calibrar (%)` = fmt_es(ponde_f), `Calibrado (%)` = fmt_es(ponde_cal),
            `Diferencia (pp)` = fmt_es(dif_pp, 2)) %>%
  left_join(val %>% transmute(Indicador = paso_s2[indicador],
                              `2023: calibrado (%)` = fmt_es(ponde_cal),
                              `2023: ponderador de la encuesta (%)` = fmt_es(t_ponde),
                              `2023: dif. sin calibrar (pp)` = fmt_es(ponde_f - t_ponde, 2),
                              `2023: dif. calibrado (pp)` = fmt_es(dif_cal_vs_t, 2)), by = "Indicador")
media_s2 <- as.data.frame(as.list(setNames(rep("", ncol(s2)), names(s2))), check.names = FALSE)
media_s2[[1]] <- "Promedio de la diferencia absoluta"
media_s2[[7]] <- fmt_es(mean(abs(val$ponde_f - val$t_ponde)), 2)
media_s2[[8]] <- fmt_es(mean(abs(val$dif_cal_vs_t)), 2)
s2 <- bind_rows(s2, media_s2)
doc <- body_add_fpar(doc, fpar(ftext(
  "Tabla S2. Calibración del ponderador y sensibilidad de la ponderación del modelo.", fp_h3),
  fp_p = fp_par(padding.top = 8, padding.bottom = 4)))
doc <- body_add_fpar(doc, fpar(ftext("Panel A. Calibración de las estimaciones nacionales directas.", fp_text(bold = TRUE, font.size = 9, font.family = "Arial")), fp_p = fp_parrafo))
doc <- body_add_flextable(doc, flextable(s2) %>% estilo_rpmesp(ancho_pt = 7))
doc <- body_add_fpar(doc, fpar(ftext(
  "Estimaciones nacionales directas con diseño muestral complejo. 'Sin calibrar' usa el ponderador original del módulo de adultos; 'calibrado' lo ajusta por post-estratificación dentro de celdas de año, estrato de urbanidad, sexo y grupo quinquenal de edad, tomando como marco la población adulta elegible de cada ronda. Las tres últimas columnas comparan, solo para 2023 —la única ronda que lo distribuye—, el ponderador calibrado contra el ponderador propio del módulo de tensión arterial. pp: puntos porcentuales.",
  fp_text(font.size = 8, italic = TRUE, font.family = "Arial")), fp_p = fp_parrafo))

sp <- read_csv(file.path(RES, "sensibilidad_ponderada.csv"), col_types = cols())
spn <- read_csv(file.path(RES, "sensibilidad_ponderada_por_n.csv"), col_types = cols())
s2b <- sp %>% transmute(
  Desenlace = paso_legible[paso],
  `Municipios (n)` = fmt_es_entero(n_municipios),
  Correlación = fmt_es(correlacion, 2),
  `Mediana de la diferencia absoluta (pp)` = fmt_es(mediana_dif_abs_pp, 2),
  `Percentil 95 (pp)` = fmt_es(p95_dif_abs_pp, 2),
  `Máximo (pp)` = fmt_es(max_dif_abs_pp, 2))
for (estrato in c("n<=9", "n=10-29", "n>=30")) {
  z <- spn[spn$estrato_n == estrato, ]
  z <- z[match(sp$paso, z$paso), ]
  etiqueta <- c("n<=9" = "Mediana con n ≤9 (municipios)",
                 "n=10-29" = "Mediana con n 10-29 (municipios)",
                 "n>=30" = "Mediana con n ≥30 (municipios)")[[estrato]]
  s2b[[etiqueta]] <- paste0(fmt_es(z$mediana_dif_abs_pp, 2), " (", fmt_es_entero(z$n_municipios), ")")
}
s2b[["Cumple el criterio"]] <- ifelse(sp$criterio_diferencia_pequena, "sí", "no")
doc <- body_add_fpar(doc, fpar(ftext("Panel B. Modelo principal ponderado frente a sensibilidad sin ponderar.", fp_text(bold = TRUE, font.size = 9, font.family = "Arial")), fp_p = fp_par(padding.top = 6, padding.bottom = 3)))
doc <- body_add_flextable(doc, flextable(s2b) %>% estilo_rpmesp(ancho_pt = 7))

doc <- body_add_fpar(doc, fpar(ftext(
  "Ambos ajustes usan las mismas filas, fórmulas, previas y agregación municipal; solo cambia la inclusión del peso de pseudo-verosimilitud. El criterio preespecificado de diferencia pequeña exigía mediana absoluta <2 pp y r>0,95. No se cumplió en ningún desenlace y la discrepancia persistió con n≥30, por lo que el ponderado se mantuvo como principal.",
  fp_text(font.size = 8, italic = TRUE, font.family = "Arial")), fp_p = fp_parrafo))

# --- Tabla S3: efecto del anio ---
# El estudio agrupa cuatro rondas y la mayoria de los municipios se observa en una sola, asi que la
# magnitud del desplazamiento temporal es informacion que el lector necesita para juzgar el mapa.
doc <- body_add_break(doc)
ea <- read_csv(file.path(RES, "efecto_anio.csv"), col_types = cols())
s3 <- ea %>% transmute(
  Paso = paso, Año = as.character(anio),
  `RM (IC 95%)` = sprintf("%s (%s-%s)", fmt_es(or, 2), fmt_es(or_l, 2), fmt_es(or_u, 2)),
  `IC excluye 1` = ifelse(excluye_1, "sí", "no"))
doc <- body_add_fpar(doc, fpar(ftext(
  "Tabla S3. Efecto del año de la ronda en cada paso de la cascada.", fp_h3),
  fp_p = fp_par(padding.top = 8, padding.bottom = 4)))
doc <- body_add_flextable(doc, flextable(s3) %>% estilo_rpmesp(ancho_pt = 8))
doc <- body_add_fpar(doc, fpar(ftext(
  "Razón de momios (RM) de cada año frente al año de referencia (2021), del efecto fijo de año incluido en los cinco modelos. Se reporta porque el diseño de ENSANUT rota los municipios entre rondas y la mayoría se observa en un solo año: sin este término, el efecto espacial absorbería la diferencia temporal y la presentaría como diferencia entre lugares. La estimación municipal publicada corresponde al promedio del periodo 2021-2024.",
  fp_text(font.size = 10, italic = TRUE, font.family = "Arial")), fp_p = fp_parrafo))

# --- Tabla S4: seleccion de covariables y coeficientes ---
# Separa las dos preguntas que el manuscrito antes respondia con un solo numero.
doc <- body_add_break(doc)
sw <- read_csv(file.path(RES, "resumen_covariables_waic_cpo.csv"), col_types = cols())
cf <- read_csv(file.path(RES, "coeficientes_area.csv"), col_types = cols())
cov_lbl <- c(pobreza = "Pobreza municipal (%)",
             clues_por_10k = "Establecimientos de salud (por 10 000 adultos)",
             clues_publico_por_10k = "Establecimientos públicos (por 10 000 adultos)",
             altitud = "Altitud media (msnm)")
paso_lbl <- c(AWARE_ESH = "Diagnóstico (ESH)", AWARE_AHA = "Diagnóstico (AHA)",
              TRAT = "Tratamiento", CONTROL_ESH = "Control (ESH)", CONTROL_AHA = "Control (AHA)")
s4 <- sw %>% transmute(
  Paso = paso_lbl[paso], Covariable = cov_lbl[covariable],
  `ΔWAIC` = fmt_es(delta_waic, 2), `EE` = fmt_es(se_delta_waic, 2),
  `ΔWAIC / EE` = fmt_es(razon_delta_se, 2)) %>%
  left_join(cf %>% transmute(Paso = paso, Covariable = covariable,
                             # La revista pide dos decimales para los estimadores. El beta crudo
                             # necesita cuatro para no perderse, asi que se acompana de la razon de
                             # momios en la escala en que la covariable se interpreta: por cada 10
                             # puntos porcentuales de pobreza y por cada 100 establecimientos.
                             .esc = ifelse(grepl("Pobreza", covariable), 10, 1),
                             `β (IC 95%)` = sprintf("%s (%s a %s)", fmt_es(beta, 4),
                                                    fmt_es(beta_l, 4), fmt_es(beta_u, 4)),
                             `RM (IC 95%)` = sprintf("%s (%s a %s)", fmt_es(exp(beta * .esc), 2),
                                                     fmt_es(exp(beta_l * .esc), 2),
                                                     fmt_es(exp(beta_u * .esc), 2))) %>%
              select(-.esc),
            by = c("Paso", "Covariable")) %>%
  mutate(across(c(`β (IC 95%)`, `RM (IC 95%)`), ~ ifelse(is.na(.x), "no seleccionada", .x)))
doc <- body_add_fpar(doc, fpar(ftext(
  "Tabla S4. Selección de covariables de área: mejora predictiva con su incertidumbre, y coeficiente posterior de las seleccionadas.", fp_h3),
  fp_p = fp_par(padding.top = 8, padding.bottom = 4)))
doc <- body_add_flextable(doc, flextable(s4) %>% estilo_rpmesp(ancho_pt = 7))
doc <- body_add_fpar(doc, fpar(ftext(
  "ΔWAIC: cambio del WAIC al añadir la covariable al modelo base (valores negativos indican mejor ajuste predictivo); EE: su error estándar, calculado sobre las mismas observaciones. La inclusión exigió simultáneamente ΔWAIC ≤ −2, mejora del log-CPO y cero fallos CPO. Ninguna mejora alcanzó dos EE de ΔWAIC, por lo que las ganancias predictivas son modestas. β: coeficiente posterior en la escala del logit, solo para covariables seleccionadas. RM: la misma estimación como razón de momios, por cada 10 puntos porcentuales de pobreza y por una unidad de densidad de establecimientos. Las afirmaciones de asociación se apoyan en el coeficiente y su intervalo, no en el ΔWAIC.",
  fp_text(font.size = 10, italic = TRUE, font.family = "Arial")), fp_p = fp_parrafo))

# --- Tabla S5: verificacion de supuestos ---
# Existe porque el antecedente municipal de INEGI comprueba los supuestos de su modelo y este
# trabajo no lo hacia. No son los mismos supuestos: aquel es un Fay-Herriot lineal sobre tasas de
# area y este un binomial de nivel-unidad, donde ni la homocedasticidad ni la normalidad del
# residuo individual tienen sentido. Ver la nota del script 12b.
doc <- body_add_break(doc)
ds <- read_csv(file.path(RES, "diagnosticos_supuestos.csv"), col_types = cols())
vf <- read_csv(file.path(RES, "diag_multicolinealidad.csv"), col_types = cols())
vif_por_paso <- vf %>% group_by(Paso) %>%
  summarise(VIF = if (all(is.na(VIF))) "sin covariables de área"
                  else paste(sprintf("%s %.2f", sub("_pct|_total", "", Covariable), VIF), collapse = "; "),
            .groups = "drop")
# Los valores p van a TRES decimales -- "p-values should have three decimal places", literal de la
# guia general de la revista. Iban a dos (%.2f) y ademas TODA esta tabla salia con punto decimal:
# es la unica de las cinco que no pasaba por fmt_es_rango(), porque se anadio despues (commit
# cd0d866) y se construyo con sprintf() directo. 37 valores con punto en un documento en espanol
# que la revista publica SIN editar ("this file will not be edited").
# Los %.2f de VIF y de asimetria/curtosis SI son correctos: son estimadores, y la norma les pide
# dos decimales. No confundir las dos reglas.
s5 <- ds %>% left_join(vif_por_paso, by = "Paso") %>%
  transmute(Paso,
            `VIF` = fmt_es_rango(VIF),
            `Moran I (residuos)` = fmt_es_rango(sprintf("%.3f (p=%.3f)", `Moran I de los residuos`, `Moran: p`)),
            `v: asimetría / curtosis` = fmt_es_rango(sprintf("%.2f / %.2f", `v: asimetría`, `v: exceso de curtosis`)),
            `PIT aleatorizado` = paste0(fmt_es(`PIT aleatorizado: media`, 3), " (KS p", ifelse(`PIT: p (KS)` < 0.001, "<0,001", paste0("=", fmt_es(`PIT: p (KS)`, 3))), ")"),
            `Fallos CPO` = `Fallos de CPO`)
doc <- body_add_fpar(doc, fpar(ftext(
  "Tabla S5. Verificación de los supuestos de los modelos finales.", fp_h3),
  fp_p = fp_par(padding.top = 8, padding.bottom = 4)))
doc <- body_add_flextable(doc, flextable(s5) %>% estilo_rpmesp(ancho_pt = 7))
doc <- body_add_fpar(doc, fpar(ftext(
  "VIF: factor de inflación de la varianza de las covariables de área de cada modelo (>5 indicaría colinealidad). Moran I: autocorrelación espacial de los residuos municipales; no se detectó autocorrelación residual significativa. v: componente no estructurado del BYM2, descrito con asimetría y exceso de curtosis. PIT aleatorizado (Czado et al. 2009): debería ser uniforme con media 0,5 si el modelo estuviera bien calibrado; la prueba KS rechazó la uniformidad en los cinco modelos, por lo que se declara calibración predictiva imperfecta. Fallos CPO: observaciones cuya predicción dejada-fuera INLA no pudo calcular de forma fiable.",
  fp_text(font.size = 10, italic = TRUE, font.family = "Arial")), fp_p = fp_parrafo))

# --- Tabla S6: comparacion con la literatura nacional ---
# Era la "Tabla 2b" del cuerpo principal. Se movio aqui el 2026-08-04 por dos motivos: (a) la
# revista limita el Articulo Original a SEIS tablas y figuras contando ambas, y el rotulo "2b" no
# es la "secuencia en numeracion arabiga" que pide la norma 11.a -- numerada como corresponde era
# la Tabla 3, y el cuerpo pasaba a 7 items; (b) la leyenda de la Tabla 2 prometia una comparacion
# "contra Campos-Nonato et al. 2025" que esa tabla no contenia, porque vivia en esta. La
# comparacion no se pierde: sigue narrada con sus cifras en Resultados y en la Discusion, y esto
# es su respaldo tabular -- que es la definicion de material suplementario de la propia revista
# ("cuya inclusion no es necesaria en el articulo publicado").
doc <- body_add_break(doc)
s6 <- read_csv(file.path(TAB, "Tabla2b_benchmark_literatura.csv"), col_types = cols()) %>%
  mutate(across(-Indicador, fmt_es_rango))
doc <- body_add_fpar(doc, fpar(ftext(
  "Tabla S6. Comparación de las estimaciones nacionales directas con la literatura nacional publicada sobre las mismas rondas.", fp_h3),
  fp_p = fp_par(padding.top = 8, padding.bottom = 4)))
doc <- body_add_flextable(doc, flextable(s6) %>% estilo_rpmesp())
doc <- body_add_fpar(doc, fpar(ftext(
  "HTA: hipertensión arterial. pp: puntos porcentuales. Las cifras de este estudio son estimaciones directas con diseño muestral complejo, no estimaciones suavizadas del modelo. Campos-Nonato et al. 2025 (Salud Publica Mex 2025;67(6):633-643) reporta la prevalencia como 29,1% en una parte de su texto y 29,4% en otra; por eso se cita como rango. Las tres diferencias metodológicas que explican el sentido de las brechas se detallan en Resultados.",
  fp_text(font.size = 10, italic = TRUE, font.family = "Arial")), fp_p = fp_parrafo))

# --- Tabla S7: conectividad del grafo de vecindad ---
# Anadida el 2026-08-05 tras una observacion de revision: el cuerpo decia "sin islas" y
# de ahi no se deduce si los municipios insulares se excluyeron, se conectaron a mano o
# simplemente no hubo areas aisladas. La respuesta es la tercera, y esta es su evidencia.
doc <- body_add_break(doc)
s7a <- read_csv(file.path(TAB, "TablaS7_conectividad_resumen.csv"), col_types = cols()) %>%
  mutate(Valor = fmt_es_entero(Valor))
s7b <- read_csv(file.path(TAB, "TablaS7_conectividad_islas.csv"), col_types = cols()) %>%
  mutate(Vecinos = fmt_es_entero(Vecinos))
doc <- body_add_fpar(doc, fpar(ftext(
  "Tabla S7. Conectividad del grafo de vecindad municipal empleado en el término espacial BYM2.", fp_h3),
  fp_p = fp_par(padding.top = 8, padding.bottom = 4)))
doc <- body_add_flextable(doc, flextable(s7a) %>% estilo_rpmesp())
doc <- body_add_fpar(doc, fpar(ftext(
  "Municipios insulares y sus colindantes:",
  fp_text(font.size = 10, italic = TRUE, font.family = "Arial")), fp_p = fp_parrafo))
doc <- body_add_flextable(doc, flextable(s7b) %>% estilo_rpmesp())
doc <- body_add_fpar(doc, fpar(ftext(
  "El grafo se construyó con contigüidad tipo \"reina\" sobre la capa municipal 1:4 000 000 del INEGI. Se verificó una única componente conexa para los 2478 municipios, sin aristas asimétricas ni municipios sin vecinos. Los dos municipios insulares de Quintana Roo tampoco quedaron aislados: a la escala de generalización de esa capa, sus polígonos colindan con los municipios costeros contiguos, que son los mismos que se les asignaría por proximidad. El procedimiento de respaldo previsto en el código —conectar un municipio sin vecinos con aquel cuyo centroide esté más próximo— no llegó a aplicarse en ningún caso.",
  fp_text(font.size = 10, italic = TRUE, font.family = "Arial")), fp_p = fp_parrafo))

# --- Figura S1 ---
# --- Tabla S8: caracteristicas y faltantes ---
doc <- body_add_break(doc)
doc <- body_add_fpar(doc, fpar(ftext("Tabla S8. Características y faltantes por denominador clínico.", fp_h3), fp_p = fp_parrafo))
s8a <- readxl::read_xlsx(file.path(TAB, "TablaS8_descriptivos_faltantes.xlsx"), sheet = "Descriptivos")
s8b <- readxl::read_xlsx(file.path(TAB, "TablaS8_descriptivos_faltantes.xlsx"), sheet = "Faltantes")
s8nota <- readxl::read_xlsx(file.path(TAB, "TablaS8_descriptivos_faltantes.xlsx"), sheet = "Notas")
doc <- body_add_fpar(doc, fpar(ftext("Panel A. n no ponderado y porcentaje ponderado; edad: media (DE).", fp_text(bold = TRUE, font.size = 9))))
doc <- body_add_flextable(doc, flextable(s8a) %>% estilo_rpmesp(ancho_pt = 7))
doc <- body_add_fpar(doc, fpar(ftext("Panel B. Número de datos faltantes por covariable.", fp_text(bold = TRUE, font.size = 9))))
doc <- body_add_flextable(doc, flextable(s8b) %>% estilo_rpmesp(ancho_pt = 7))
doc <- body_add_fpar(doc, fpar(ftext(s8nota$Nota[[1]], fp_text(font.size = 8, font.family = "Arial")), fp_p = fp_parrafo))

doc <- body_add_break(doc)
doc <- body_add_fpar(doc, fpar(ftext("Figura S1. Validación cruzada espacial (5 pliegues).", fp_h3),
                                fp_p = fp_par(padding.top = 8, padding.bottom = 4)))
doc <- body_add_img(doc, src = file.path(FIG, "FigS1_validacion_cruzada.png"),
                     width = ANCHO_UTIL, height = ANCHO_UTIL * 9 / 12)
doc <- body_add_fpar(doc, fpar(ftext(
  "Validación cruzada espacial de 5 pliegues: observado y predicción se agregan con el ponderador calibrado dentro del municipio; BYM2 e IID usan exactamente las mismas filas, pesos y pliegues. El panel A omite municipios con n<10. El panel B muestra la reducción de RMSE agregada de todos los municipios frente al promedio ponderado del entrenamiento de cada pliegue.",
  fp_text(font.size = 9, font.family = "Arial")), fp_p = fp_parrafo))

# --- Figura S2 ---
doc <- body_add_break(doc)
doc <- body_add_fpar(doc, fpar(ftext("Figura S2. Ancho del intervalo de credibilidad al 95% (criterio ESH; celdas con n<10 suprimidas).", fp_h3),
                                fp_p = fp_par(padding.top = 8, padding.bottom = 4)))
doc <- body_add_img(doc, src = file.path(FIG, "FigS2_incertidumbre_ESH.png"),
                     width = ANCHO_UTIL, height = ANCHO_UTIL * 6.3 / 14)
doc <- body_add_fpar(doc, fpar(ftext(
  "Ancho del intervalo de credibilidad al 95% por municipio (diagnóstico, tratamiento, control), criterio ESH — mapa complementario de incertidumbre, siguiendo la práctica de The DHS Program para superficies modeladas (Burgert-Brucker et al. 2016).",
  fp_text(font.size = 9, font.family = "Arial")), fp_p = fp_parrafo))

# Mismo tamano/margenes que el manuscrito principal (Carta, 2.5cm arriba/abajo, 3.0cm izq/der --
# precedente real verificado contra un envio previo ya aceptado por la revista).
doc <- body_set_default_section(doc, prop_section(
  page_size = page_size(width = 12240/1440, height = 15840/1440, orient = "portrait"),
  page_margins = page_mar(top = 1417/1440, bottom = 1417/1440, left = 1701/1440, right = 1701/1440,
                           header = 708/1440, footer = 708/1440)
))

print(doc, target = ARCH$suplementario)
cat("Guardado:", ARCH$suplementario, "\n")
