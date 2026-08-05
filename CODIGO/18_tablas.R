# Tablas 1-3 del plan (seccion 9). Se emiten en .xlsx editable ademas de .csv: toda figura o
# .csv. Tabla 1: caracteristicas de la muestra por anio y paso. Tabla 2: prevalencia nacional por
# paso y criterio vs benchmark oficial (Campos-Nonato et al. 2025). Tabla 3: diagnosticos del
# modelo (WAIC, Phi, validacion cruzada, sensibilidad a vecindad) por paso.

library(dplyr)
library(readr)
library(writexl)

# Formato de presentacion (coma decimal, separador de miles, etiquetas legibles de los pasos),
# compartido con los demas generadores para que un mismo dato no salga con dos formatos.
source("CODIGO/00b_formato_es.R")

RES <- "RESULTADOS"
TAB <- "TABLAS"
if (!dir.exists(TAB)) dir.create(TAB)

# ================= TABLA 1: caracteristicas de la muestra por anio =================
flujo <- read_csv(file.path(RES, "flujo_STROBE_2021_2024.csv"), col_types = cols())
base  <- read_csv(file.path(RES, "base_analitica_adultos_2021_2024.csv"),
                   col_types = cols(entidad = col_character(), municipio = col_character(), .default = col_guess()))

muni_por_anio <- base %>% group_by(anio) %>%
  summarise(n_municipios = n_distinct(paste0(entidad, municipio)), .groups = "drop")

tabla1 <- flujo %>%
  left_join(muni_por_anio, by = "anio") %>%
  transmute(
    Año = anio,
    `n Entrevistados` = entrevistados,
    `n Base analítica final` = n_final,
    `n Municipios distintos` = n_municipios,
    `n HTA-ESH` = n_hta_esh,
    `n HTA-AHA` = n_hta_aha,
    `n Diagnosticados` = n_diagnosticados,
    `n Tratados` = n_tratados,
    `% enlace integrantes (escolaridad)` = integrantes_match_pct
  )

tabla1_total <- tabla1 %>% summarise(
  Año = "Total pooled 2021-2024",
  `n Entrevistados` = sum(`n Entrevistados`),
  `n Base analítica final` = sum(`n Base analítica final`),
  `n Municipios distintos` = n_distinct(paste0(base$entidad, base$municipio)),
  `n HTA-ESH` = sum(`n HTA-ESH`),
  `n HTA-AHA` = sum(`n HTA-AHA`),
  `n Diagnosticados` = sum(`n Diagnosticados`),
  `n Tratados` = sum(`n Tratados`),
  `% enlace integrantes (escolaridad)` = NA
)
tabla1_final <- bind_rows(tabla1 %>% mutate(Año = as.character(Año)), tabla1_total)

# nota de rotacion municipal, no ocultar (regla del plan, tabla 1)
# Los pies de tabla expanden todas las siglas: el PDF oficial
# La regla editorial habitual exige "contain only the necessary information to be interpreted without
# referring to the text... Place the meaning of all acronyms, signs and calls in the table
# footnotes", y ninguna de las 4 tablas la tenia (HTA, ESH, AHA, IC95%, BYM2, WAIC, Phi, RMSE
# aparecian sin definir en los encabezados).
# La suma de municipios por anio (1003) no equivale a los municipios unicos del periodo pooled
# (599), porque la muestra de municipios rota entre rondas anuales. El pie lo dice explicitamente
# para que la tabla se interprete sin recurrir al texto.
suma_muni_anio <- sum(muni_por_anio$n_municipios)
muni_pooled    <- n_distinct(paste0(base$entidad, base$municipio))
nota_rotacion <- sprintf("Nota: los municipios NO son los mismos cada año (diseño rotativo de ENSANUT) — la suma de 'n Municipios distintos' por año (%d) NO equivale a los %d municipios únicos del periodo pooled. HTA: hipertensión arterial. ESH: European Society of Hypertension (criterio 2023, ≥140/90 mmHg). AHA: American College of Cardiology/American Heart Association (criterio 2025, ≥130/80 mmHg).",
                          suma_muni_anio, muni_pooled)

# ================= TABLA 2: prevalencia nacional vs benchmark =================
tabla2_base <- read_csv(file.path(RES, "benchmark_nacional_vs_campos_nonato.csv"), col_types = cols())

# El CSV trae ademas de los 5 pasos de la cascada las dos filas de prevalencia de HTA
# (PREV_HTA_ESH / PREV_HTA_AHA), que alimentan la Tabla 2b pero no la Tabla 2.
PASOS_CASCADA <- c("AWARE_ESH", "AWARE_AHA", "TRAT", "CONTROL_ESH", "CONTROL_AHA")
tabla2 <- tabla2_base %>%
  filter(paso %in% PASOS_CASCADA) %>%
  transmute(
    Paso = paso, n = n,
    `Directa nacional (%)` = directa_pct,
    # Se fuerza el numero de decimales: paste0() sin formatear deja
    # "40.6-44" cuando el limite superior era un entero exacto (44.0 se imprime "44" en R) --
    # viola la regla editorial "Percentages should have one decimal place". sprintf("%.1f", ...)
    # fuerza el decimal en AMBOS limites antes de pegar.
    `IC95% directa` = paste0(sprintf("%.1f", directa_ic_l), "–", sprintf("%.1f", directa_ic_u)),
    `Modelo BYM2 nacional (%, ponderado)` = modelo_ponderado_pct
  )
# Tabla 2b. La columna "Este estudio" se DERIVA del CSV del pipeline, no se escribe a mano: antes
# eran literales y la prevalencia de HTA (28,5 %) no salia de ningun archivo, con lo que nadie podia
# verificarla sin volver a correr INLA.
# Las cifras de Campos-Nonato SI son literales, porque vienen de un articulo publicado y no de este
# pipeline: Salud Publica Mex 2025;67(6):633-643, doi 10.21149/17102. La prevalencia aparece como
# 29,1 % en una parte de su texto y 29,4 % en otra (inconsistencia de esa fuente, no nuestra), por
# eso se cita como rango.
CN_PREV <- "29,1-29,4%"; CN_PREV_LO <- 29.1; CN_PREV_HI <- 29.4
CN_DIAG <- 62.9
CN_CTRL <- 60.1

fila_bm <- function(p) tabla2_base[tabla2_base$paso == p, ]
fmt_est <- function(p) with(fila_bm(p), sprintf("%.1f%% (%.1f-%.1f)", directa_pct, directa_ic_l, directa_ic_u))
val_est <- function(p) fila_bm(p)$directa_pct

tabla2_benchmark <- tibble::tibble(
  Indicador = c("Prevalencia HTA", "Diagnóstico previo (entre HTA)", "Control (entre diagnosticados y tratados)"),
  `Este estudio (directa)` = c(fmt_est("PREV_HTA_ESH"), fmt_est("AWARE_ESH"), fmt_est("CONTROL_ESH")),
  `Campos-Nonato et al. 2025` = c(CN_PREV, sprintf("%.1f%%", CN_DIAG), sprintf("%.1f%%", CN_CTRL)),
  `Diferencia (pp)` = c(
    sprintf("%+.1f a %+.1f", val_est("PREV_HTA_ESH") - CN_PREV_LO, val_est("PREV_HTA_ESH") - CN_PREV_HI),
    sprintf("%+.1f", val_est("AWARE_ESH") - CN_DIAG),
    sprintf("%+.1f", val_est("CONTROL_ESH") - CN_CTRL))
)
nota_tabla2 <- "IC95%: intervalo de confianza al 95%. BYM2: modelo espacial bayesiano Besag-York-Mollié tipo 2. HTA: hipertensión arterial. pp: puntos porcentuales."

# ================= TABLA 3: diagnosticos del modelo =================
# Municipios/WAIC/Phi salen del modelo FINAL (script 08), no de
# resumen_6_modelos_bym2_univariados.csv, que corresponde al modelo sin covariables de area y no al
# modelo que realmente genera el mapa (Figura 2) y las cifras de Resultados. Para 4 de los 5 pasos
# (todos menos TRAT, que no lleva covariable de area) el WAIC y el Phi diferian sustancialmente.
# Fuente correcta: resumen_modelos_finales.csv (extraido de modelo_FINAL_*.rds, el objeto que de
# verdad se usa para predecir). "Municipios (muestra)" se toma de resumen_cobertura_nacional.csv
# (n_muestra), ya verificado que coincide exacto con resumen_validacion_cruzada.csv -- mismo
# universo de municipios que el modelo final.
modelos_finales_diag <- read_csv(file.path(RES, "resumen_modelos_finales.csv"), col_types = cols())
cv <- read_csv(file.path(RES, "resumen_validacion_cruzada.csv"), col_types = cols())
cobertura_nac <- read_csv(file.path(RES, "resumen_cobertura_nacional.csv"), col_types = cols())

# n de individuos por paso: reusar de tabla2_base (benchmark_nacional_vs_campos_nonato.csv), ya
# verificado identico a Tabla 2 / cuerpo del manuscrito -- no re-declararlo, para que un cambio
# futuro no diverja entre Tabla 2 y Tabla S1.
# DOS columnas de n, no una. El WAIC y el Phi de esta tabla salen del modelo, cuyo n es menor que
# el denominador del paso (algunas covariables de area no cubren todos los municipios). Antes se
# mostraba solo el denominador junto al WAIC del modelo, y un lector concluia que el modelo se
# ajusto sobre mas observaciones de las que uso.
tabla3 <- modelos_finales_diag %>%
  left_join(tabla2_base %>% transmute(paso = paso, n_ind = n, n_mod = n_modelo), by = "paso") %>%
  transmute(Paso = paso, `n (denominador del paso)` = n_ind, `n (modelo)` = n_mod,
            WAIC = round(waic, 1), `Phi (mediana)` = round(phi_mediana, 3)) %>%
  left_join(cobertura_nac %>% transmute(Paso = paso, `Municipios (muestra)` = n_muestra), by = "Paso") %>%
  left_join(cv %>% transmute(Paso = paso, `RMSE BYM2` = rmse_bym2, `RMSE simple (no ajustado)` = rmse_naive,
                              `Reducción RMSE (%)` = reduccion_rmse_pct), by = "Paso") %>%
  left_join(cobertura_nac %>% transmute(Paso = paso, `Cobertura nacional (%)` = pct_cobertura), by = "Paso") %>%
  select(Paso, `n (denominador del paso)`, `n (modelo)`, `Municipios (muestra)`, WAIC,
         `Phi (mediana)`, `RMSE BYM2`, `RMSE simple (no ajustado)`, `Reducción RMSE (%)`,
         `Cobertura nacional (%)`)

# La sensibilidad a la vecindad se LEE del pipeline (script 12), no se escribe a mano: asi la
# tabla no puede quedarse con un numero de una corrida anterior.
sens <- read_csv(file.path(RES, "sensibilidad_vecindad.csv"), col_types = cols())
nota_sensibilidad <- sprintf("Nota: el paso de tratamiento es idéntico bajo criterio ESH y ACC/AHA por construcción (verificado numéricamente) -- una sola fila, no dos. 'n (denominador del paso)' es el número de personas elegibles para ese paso de la cascada; 'n (modelo)' es el número efectivamente ajustado, menor cuando alguna covariable de área no cubre todos los municipios. WAIC y Phi corresponden al modelo FINAL (con covariables de área seleccionadas por WAIC+CPO), no al modelo univariado de exploración. Sensibilidad a matriz de vecindad (reina vs. torre), probada en Tratamiento (mayor Phi): WAIC %.1f vs %.1f (Δ=%.2f), Phi %.3f vs %.3f (Δ=%.3f). WAIC: Widely Applicable Information Criterion (criterio de selección de modelos, valores menores indican mejor ajuste). Phi: fracción de la varianza espacial explicada por la estructura geográfica (modelo BYM2), de 0 a 1. RMSE: raíz del error cuadrático medio (validación cruzada espacial de 5 pliegues). BYM2: modelo espacial bayesiano Besag-York-Mollié tipo 2.",
                              sens$waic_reina, sens$waic_torre, sens$delta_waic,
                              sens$phi_reina, sens$phi_torre, sens$delta_phi)

# ================= Guardar todo =================
# El .xlsx se escribe con writexl y NO con openxlsx. Motivo verificado: openxlsx 4.2.8.1 deja en
# xl/worksheets/_rels/ una referencia a xl/drawings/drawing1.xml que no incluye en el archivo, de
# modo que Excel pide "reparar" al abrirlo y openpyxl falla con KeyError. Se reprodujo con el caso
# minimo (createWorkbook + addWorksheet + writeData), asi que es del paquete, no de este script.
#
# Ventaja adicional: al escribir los valores ya formateados como texto, la hoja de calculo muestra
# los numeros con coma decimal y espacio de millar, igual que el manuscrito, en vez de con el punto
# decimal que impondria una celda numerica.
fmt_celda <- function(x, dec = 1) {
  # OJO con la rama de CADENA. Las columnas de intervalo ("63.6-67.9") se arman antes con
  # sprintf()/paste0(), asi que llegan aqui como character: sin tratarlas, una conversion
  # numerica no las toca y en la misma hoja acaban conviviendo "65,8" y "63.6-67.9".
  if (!is.numeric(x)) return(ifelse(is.na(x), "", fmt_es_rango(as.character(x))))
  ifelse(is.na(x), "",
         sub(".", ",", fixed = TRUE,
             formatC(x, format = "f", digits = dec, big.mark = " ")))
}
# Los decimales se deciden POR COLUMNA, no uno solo para toda la tabla: un conteo con tres
# decimales ("7 756,000") es un error visible. Se toma el numero de decimales del propio valor,
# con un maximo, y los enteros se dejan sin parte decimal.
decimales_de <- function(x, maximo = 3) {
  if (!is.numeric(x)) return(0)
  v <- x[!is.na(x)]
  if (length(v) == 0 || all(abs(v - round(v)) < 1e-9)) return(0)
  d <- max(vapply(v, function(z) {
    s <- format(z, scientific = FALSE, trim = TRUE)
    pos <- regexpr(".", s, fixed = TRUE)
    if (pos < 0L) 0L else nchar(s) - pos
  }, integer(1)))
  min(d, maximo)
}
a_texto <- function(d, maximo = 3) {
  d[] <- lapply(d, function(col) fmt_celda(col, dec = decimales_de(col, maximo)))
  d
}
# La nota al pie va como fila final: una hoja de writexl es un unico data frame, y ponerla debajo
# de la tabla es donde el lector la espera.
con_nota <- function(d, nota) {
  fila <- as.data.frame(matrix("", 1, ncol(d)), stringsAsFactors = FALSE)
  names(fila) <- names(d)
  fila[[1]] <- nota
  rbind(d, fila)
}

# Etiquetas legibles SOLO en los entregables. Los .csv conservan los codigos internos
# (AWARE_ESH, TRAT...) porque son la interfaz con los scripts 19 y 21, que ya relabelan al
# construir sus .docx. El .xlsx, en cambio, lo abre el editor de la revista: "CONTROL_AHA" no se
# interpreta "without referring to the text", que es lo que la norma 11.a exige de una tabla.
legible <- function(d) { d$Paso <- unname(paso_legible[d$Paso]); d }

# El .xlsx del envio contiene EXACTAMENTE las tablas del cuerpo principal. Antes traia ademas la
# hoja TablaS1, que es material SUPLEMENTARIO y viaja en su propio archivo (script 21): la revista
# separa los dos materiales, y mezclarlos enturbia el conteo de tablas y figuras del cuerpo, que
# ya esta en el limite. Por eso la comparacion con la literatura es una tabla suplementaria.
writexl::write_xlsx(list(
  # Cabeceras IDENTICAS a las del .docx (script 19). La revista pide la misma tabla dos veces
  # --incrustada y como archivo aparte-- y el editor las va a ver juntas: dos redacciones de la
  # misma columna es exactamente lo que la copia separada no debe introducir.
  Tabla1 = con_nota(a_texto(tabla1_final %>%
                              select(-`% enlace integrantes (escolaridad)`) %>%
                              rename(`n entrevistados`   = `n Entrevistados`,
                                     `n base analítica`  = `n Base analítica final`,
                                     `n municipios`      = `n Municipios distintos`,
                                     `n diagnosticados`  = `n Diagnosticados`,
                                     `n tratados`        = `n Tratados`)),
                    nota_rotacion),
  Tabla2 = con_nota(a_texto(legible(tabla2) %>%
                              rename(`Modelo BYM2 (%, ponderado)` =
                                       `Modelo BYM2 nacional (%, ponderado)`)),
                    nota_tabla2)
), file.path(TAB, "Tablas_cuerpo.xlsx"))

# Hoja de trabajo interna con los diagnosticos del modelo. NO se envia: su contenido publicado es
# la Tabla S1 del suplementario (script 21). Existe para revisarla en Excel sin abrir R.
writexl::write_xlsx(list(
  TablaS1 = con_nota(a_texto(legible(tabla3), maximo = 4), nota_sensibilidad)
), file.path(TAB, "Tablas_suplementarias_trabajo.xlsx"))

# Los .csv conservan los valores numericos sin formatear: son la version legible por maquina y la
# que leen los scripts 19 y 21.
write.csv(tabla1_final, file.path(TAB, "Tabla1_caracteristicas_muestra.csv"), row.names = FALSE)
write.csv(tabla2, file.path(TAB, "Tabla2_prevalencia_nacional.csv"), row.names = FALSE)
write.csv(tabla2_benchmark, file.path(TAB, "Tabla2b_benchmark_literatura.csv"), row.names = FALSE)
write.csv(tabla3, file.path(TAB, "TablaS1_diagnosticos_modelo.csv"), row.names = FALSE)

cat("=== TABLA 1 ===\n"); print(tabla1_final)
cat("\n=== TABLA 2 ===\n"); print(tabla2); print(tabla2_benchmark)
cat("\n=== TABLA 3 ===\n"); print(tabla3)
cat("\nGuardado: TABLAS/Tablas_1_2_3.xlsx (editable) + .csv individuales\n")
