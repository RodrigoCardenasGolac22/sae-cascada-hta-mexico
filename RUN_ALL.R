# =============================================================================
# Pipeline completo: estimacion bayesiana de area pequena de la cascada de
# atencion de la hipertension arterial en los municipios de Mexico
# (ENSANUT Continua 2021-2024)
#
# USO:  Rscript RUN_ALL.R            (desde la RAIZ del repositorio)
#       Rscript RUN_ALL.R 13 21      (solo los pasos 13 a 21)
#
# Todos los scripts usan rutas relativas a la raiz del repositorio, asi que
# este archivo debe ejecutarse desde ahi y no desde CODIGO/.
#
# INSUMOS EXTERNOS que hay que colocar antes de empezar (ver README):
#   1. Microdatos ENSANUT 2021-2024 en DATOS_ENSANUT/microdatos_por_anio/<anio>/
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
  "10_validacion_cruzada.R",      # validacion cruzada espacial de 5 pliegues
  "11_benchmark_nacional.R",      # comparacion con las cifras nacionales publicadas
  "12_sensibilidad_vecindad.R",   # sensibilidad a la definicion de vecindad
  "12b_diagnosticos_supuestos.R", # verificacion de supuestos de los modelos finales
  "13_fig1_flujo_strobe.R",       # Figura 1
  "14_fig2_mapa_cascada.R",       # Figura 2
  "15_fig3_reclasificacion.R",    # Figura 3
  "16_figS1_validacion.R",        # Figura S1
  "17_figS2_incertidumbre.R",     # Figura S2
  "18_tablas.R",                  # Tablas 1, 2, 2b y S1
  "19_manuscrito_docx.R",         # manuscrito .docx
  "20_checklist_strobe.R",        # checklist STROBE
  "21_material_suplementario.R",  # material suplementario .docx
  "22_paquete_envio.R",           # arma 0_ENVIO/ y verifica que se propago
  "24_datos_explorador.R"         # docs/datos.json para el explorador municipal
)

args  <- commandArgs(trailingOnly = TRUE)
desde <- if (length(args) >= 1) as.integer(args[1]) else 1L
hasta <- if (length(args) >= 2) as.integer(args[2]) else length(pasos)

if (!dir.exists("CODIGO")) {
  stop("No se encuentra CODIGO/. Ejecutar RUN_ALL.R desde la raiz del repositorio.")
}
for (d in c("RESULTADOS", "TABLAS", "FIGURAS")) if (!dir.exists(d)) dir.create(d)

cat(sprintf("Pipeline: pasos %d a %d de %d\n\n", desde, hasta, length(pasos)))

# Cada script se evalua en su propio entorno: son independientes entre si (leen sus insumos de
# disco y escriben sus salidas a disco), y varios reutilizan nombres de variable comunes que
# sobreescribirian el estado de este bucle si se evaluaran en el entorno global.
for (.i in seq(desde, hasta)) {
  .script <- file.path("CODIGO", pasos[.i])
  cat(sprintf("[%2d/%2d] %s\n", .i, length(pasos), pasos[.i]))
  .t0 <- Sys.time()
  source(.script, echo = FALSE, local = new.env(parent = globalenv()))
  cat(sprintf("        completado en %.1f min\n\n",
              as.numeric(difftime(Sys.time(), .t0, units = "mins"))))
}

cat("Pipeline completo.\n")

# sessionInfo solo se sobreescribe tras una corrida ENTERA: despues de un rango parcial reflejaria
# unicamente los paquetes de esos pasos, y quien intentara reproducir el estudio creeria que basta
# con esos.
if (desde == 1L && hasta == length(pasos)) {
  writeLines(capture.output(sessionInfo()), "sessionInfo.txt")
  cat("Entorno de esta corrida guardado en sessionInfo.txt\n")
} else {
  cat(sprintf("Corrida parcial (pasos %d a %d): sessionInfo.txt NO se actualiza.\n", desde, hasta))
}
