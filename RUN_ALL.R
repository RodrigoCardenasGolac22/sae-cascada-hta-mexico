# =============================================================================
# Pipeline completo: estimacion bayesiana de area pequena de la cascada de
# atencion de la hipertension arterial en los municipios de Mexico
# (ENSANUT Continua 2021-2024)
#
# USO:  Rscript RUN_ALL.R            (desde la RAIZ del repositorio)
#       Rscript RUN_ALL.R --list    (listar posiciones y scripts)
#       Rscript RUN_ALL.R 18 27      (artefactos, conectividad y explorador)
#
# Todos los scripts usan rutas relativas a la raiz del repositorio, asi que
# este archivo debe ejecutarse desde ahi y no desde analysis/.
#
# INSUMOS EXTERNOS que hay que colocar antes de empezar (ver README):
#   1. Microdatos ENSANUT 2021-2024 en data/raw/ensanut/<anio>/
#   2. Censo de Poblacion y Vivienda 2020, tabulado ITER nacional (paso 09)
#
# TIEMPO DE COMPUTO: los pasos 06-10 ajustan modelos con INLA y son la parte
# lenta (decenas de minutos en total; el paso 10 corre validacion cruzada de
# 5 pliegues sobre 5 desenlaces). Los pasos 13-21, que producen figuras,
# tablas y documentos, corren en segundos.
# =============================================================================

pasos <- c(
  "01_base_analitica.R",          # base analitica + flujo de seleccion STROBE
  "02_covariable_clues.R",        # covariable: establecimientos de salud por municipio
  "02b_calibrar_ponderador.R",    # calibracion del ponderador y validacion contra t_ponde (2023)
  "03_verificar_covariables.R",   # control de calidad del cruce de covariables municipales
  "04_estimaciones_directas.R",   # prevalencia directa por municipio (diseno complejo)
  "05_grafo_vecindad.R",          # matriz de vecindad municipal (reina y torre)
  "06_modelos_univariados.R",     # modelos BYM2 base, sin covariables de area
  "07_seleccion_covariables.R",   # seleccion de covariables de area (WAIC + CPO)
  "08_modelos_finales.R",         # modelos finales + reclasificacion ESH vs ACC/AHA
  "08b_coeficientes.R",           # efecto del anio y coeficientes de area, desde los modelos ya ajustados
  "09_extension_nacional.R",      # extension a los municipios sin muestra directa
  "10_validacion_cruzada.R",      # validacion cruzada espacial: pliegues aleatorios y contiguos
  "06b_baseline_iid.R",           # baseline IID vs BYM2 (corre tras 08 y 10: reusa modelos y pliegues)
  "11_benchmark_nacional.R",      # comparacion con las cifras nacionales publicadas
  "12_sensibilidad_vecindad.R",   # sensibilidad a la definicion de vecindad
  "12b_diagnosticos_supuestos.R", # verificacion de supuestos de los modelos finales
  "12c_sensibilidad_ponderada.R", # principal ponderado vs sensibilidad sin ponderar (cinco pasos)
  "13_fig1_flujo_strobe.R",       # Figura 1
  "14_fig2_mapa_cascada.R",       # Figura 2
  "15_fig3_reclasificacion.R",    # Figura 3
  "16_figS1_validacion.R",        # Figura S1
  "17_figS2_incertidumbre.R",     # Figura S2
  "18_tablas.R",                  # Tablas 1, 2, 2b y S1
  "20_checklist_strobe.R",        # checklist STROBE
  "24_datos_explorador.R",        # docs/datos.json para el explorador municipal
  "05b_conectividad_grafo.R",     # Tabla S7; conserva posiciones historicas 1-25
  "25_explorador_html.py"         # embeber JSON e idiomas en docs/index.html
)

args  <- commandArgs(trailingOnly = TRUE)
if (identical(args, "--list")) {
  cat(paste(sprintf("%2d  %s", seq_along(pasos), pasos), collapse = "\n"), "\n")
  quit(status = 0L)
}
if (length(args) > 2L || any(!grepl("^[0-9]+$", args))) {
  stop("Uso: Rscript RUN_ALL.R [desde hasta] o Rscript RUN_ALL.R --list")
}
desde <- if (length(args) >= 1) as.integer(args[1]) else 1L
hasta <- if (length(args) >= 2) as.integer(args[2]) else length(pasos)
if (is.na(desde) || is.na(hasta) || desde < 1L || hasta > length(pasos) || desde > hasta) {
  stop("Rango invalido: se requiere 1 <= desde <= hasta <= ", length(pasos))
}

if (!dir.exists("analysis")) {
  stop("No se encuentra analysis/. Ejecutar RUN_ALL.R desde la raiz del repositorio.")
}
for (d in c("results/estimates", "results/tables", "results/figures", "data/processed/geography",
            "data/processed/covariates", "reproducibility")) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

if (any(grepl("[.]py$", pasos[seq.int(desde, hasta)]))) {
  python <- Sys.getenv("PYTHON", unset = "")
  if (!nzchar(python)) {
    candidates <- Sys.which(c("python3", "python"))
    candidates <- candidates[nzchar(candidates)]
    if (!length(candidates)) stop("No se encuentra Python 3. Configure PYTHON o instale Python 3.")
    python <- unname(candidates[1])
  }
}

cat(sprintf("Pipeline: pasos %d a %d de %d\n\n", desde, hasta, length(pasos)))

# Cada script se evalua en su propio entorno: son independientes entre si (leen sus insumos de
# disco y escriben sus salidas a disco), y varios reutilizan nombres de variable comunes que
# sobreescribirian el estado de este bucle si se evaluaran en el entorno global.
for (.i in seq(desde, hasta)) {
  .script <- file.path("analysis", pasos[.i])
  cat(sprintf("[%2d/%2d] %s\n", .i, length(pasos), pasos[.i]))
  .t0 <- Sys.time()
  if (grepl("[.]py$", .script)) {
    status <- system2(python, args = shQuote(.script))
    if (status != 0L) stop("Fallo al ejecutar ", .script, " (codigo ", status, ")")
  } else {
    source(.script, echo = FALSE, local = new.env(parent = globalenv()), encoding = "UTF-8")
  }
  cat(sprintf("        completado en %.1f min\n\n",
              as.numeric(difftime(Sys.time(), .t0, units = "mins"))))
}

cat("Pipeline completo.\n")

# sessionInfo solo se sobreescribe tras una corrida ENTERA: despues de un rango parcial reflejaria
# unicamente los paquetes de esos pasos, y quien intentara reproducir el estudio creeria que basta
# con esos.
if (desde == 1L && hasta == length(pasos)) {
  info_sesion <- sub("[ \t]+$", "", capture.output(sessionInfo()))
  writeLines(info_sesion, "reproducibility/sessionInfo.txt")
  cat("Entorno de esta corrida guardado en reproducibility/sessionInfo.txt\n")
} else {
  cat(sprintf("Corrida parcial (pasos %d a %d): reproducibility/sessionInfo.txt NO se actualiza.\n", desde, hasta))
}
