# Tabla S8: descriptivos de los denominadores elegibles, antes de excluir
# covariables faltantes. Solo se publican agregados; nunca filas individuales.
library(dplyr)
library(readr)
source("analysis/00_comun.R")
source("analysis/00b_formato_es.R")
RES <- "results/estimates"
TAB <- "results/tables"
base <- read_csv(file.path(RES, "base_analitica_adultos_2021_2024.csv"),
                 col_types = cols(FOLIO_I = col_character(), FOLIO_INT = col_character(),
                                  entidad = col_character(), municipio = col_character(),
                                  .default = col_guess()))
base <- agregar_ponderador_calibrado(base, RES)
base$muni_id <- paste0(base$entidad, base$municipio)
base <- cargar_covariables_area(base)
verificar_escolaridad(base$escolaridad)
stopifnot(nrow(base) == 25088, !anyNA(base$ponde_cal), all(base$ponde_cal > 0))
grupos <- list(Total = rep(TRUE, nrow(base)), HTA_ESH = base$hta_esh,
               HTA_AHA = base$hta_aha, Diagnosticados = base$diag_cronico,
               Tratados = base$tratado)
categorias <- list(sexo = c("1" = "Hombres", "2" = "Mujeres"),
                   estrato = c("1" = "Rural", "2" = "Urbano", "3" = "Metropolitano"),
                   escolaridad = setNames(NIVELES_ESCOLARIDAD, NIVELES_ESCOLARIDAD),
                   anio = setNames(as.character(2021:2024), as.character(2021:2024)))
filas <- faltantes <- list()
variables <- c("edad", "sexo", "escolaridad", "estrato", "anio", "pobreza_pct")
for (g in names(grupos)) {
  d <- base[which(grupos[[g]] %in% TRUE), ]
  w <- d$ponde_cal
  agregar <- function(variable, categoria, n, valor, de = NA_real_) {
    data.frame(grupo = g, n_denominador = nrow(d), variable = variable,
               categoria = categoria, n = n, valor_ponderado = valor, de_ponderada = de)
  }
  x <- d$edad; ok <- !is.na(x)
  media <- weighted.mean(x[ok], w[ok])
  # Dispersion descriptiva ponderada de la distribucion, no EE ni IC de encuesta.
  de <- sqrt(weighted.mean((x[ok] - media)^2, w[ok]))
  filas[[length(filas) + 1L]] <- agregar("edad", "Media (DE), anios", sum(ok), media, de)
  for (v in names(categorias)) {
    ok <- !is.na(d[[v]])
    stopifnot(all(as.character(d[[v]][ok]) %in% names(categorias[[v]])))
    for (k in names(categorias[[v]])) {
      en <- ok & as.character(d[[v]]) == k
      filas[[length(filas) + 1L]] <- agregar(v, categorias[[v]][[k]], sum(en),
                                            100 * sum(w[en]) / sum(w[ok]))
    }
  }
  for (v in variables) {
    faltantes[[length(faltantes) + 1L]] <- data.frame(
      grupo = g, n_denominador = nrow(d), variable = v,
      n_faltantes = sum(is.na(d[[v]])), n_disponibles = sum(!is.na(d[[v]])))
  }
}
descriptivos <- bind_rows(filas)
faltantes <- bind_rows(faltantes)
stopifnot(all(faltantes$n_disponibles + faltantes$n_faltantes == faltantes$n_denominador))
for (g in names(grupos)) for (v in names(categorias)) {
  z <- filter(descriptivos, grupo == g, variable == v)
  stopifnot(abs(sum(z$valor_ponderado) - 100) < 1e-8,
            sum(z$n) == faltantes$n_disponibles[faltantes$grupo == g & faltantes$variable == v])
}
# Presentacion ancha para el suplemento; CSV largo para auditoria y reutilizacion.
plantilla <- descriptivos %>% filter(grupo == "Total") %>% select(variable, categoria)
etiquetas <- c(edad = "Edad", sexo = "Sexo", escolaridad = "Escolaridad",
               estrato = "Urbanidad", anio = "Año", pobreza_pct = "Pobreza municipal")
etiquetas_grupo <- c(Total = "Total", HTA_ESH = "HTA (ESH)", HTA_AHA = "HTA (AHA)",
                     Diagnosticados = "Diagnosticados", Tratados = "Tratados")
plantilla$categoria[plantilla$variable == "edad"] <- "media (DE), años"
plantilla$categoria[plantilla$categoria == "Preparatoria/tecnico"] <- "Preparatoria/técnico"
a <- data.frame(Característica = paste(etiquetas[plantilla$variable], plantilla$categoria, sep = ": "))
b <- data.frame(Variable = unname(etiquetas[variables]))
for (g in names(grupos)) {
  z <- filter(descriptivos, grupo == g)
  col <- ifelse(z$variable == "edad",
                paste0(fmt_es(z$valor_ponderado, 1), " (", fmt_es(z$de_ponderada, 1), ")"),
                paste0(fmt_es_entero(z$n), " (", fmt_es(z$valor_ponderado, 1), "%)"))
  etiqueta <- paste0(etiquetas_grupo[[g]], " (n=", unique(z$n_denominador), ")")
  a[[etiqueta]] <- col
  b[[etiqueta]] <- filter(faltantes, grupo == g)$n_faltantes
}
nota <- paste(
  "Poblaciones elegibles antes de excluir covariables faltantes; las columnas se superponen.",
  "Diagnóstico y tratamiento son autorreportados. n es el conteo no ponderado; porcentajes,",
  "medias y DE usan el ponderador calibrado. DE describe dispersión, no error estándar ni intervalo de confianza.",
  "Los porcentajes usan personas con dato disponible para esa variable y grupo.",
  "El panel B cuenta faltantes por covariable; cero significa ausencia de faltantes en esta base seleccionada,",
  "no ausencia de no respuesta en la encuesta original. Las exclusiones previas se reportan en Figura 1.",
  "Pobreza solo interviene en los modelos de control: de 4388 tratados se excluyen seis, quedan 4382.",
  "Rural, urbano y metropolitano corresponden a los estratos 1, 2 y 3 de ENSANUT."
)
write.csv(descriptivos, file.path(TAB, "TablaS8_descriptivos.csv"), row.names = FALSE)
write.csv(faltantes, file.path(TAB, "TablaS8_faltantes.csv"), row.names = FALSE)
writexl::write_xlsx(list(Descriptivos = a, Faltantes = b, Notas = data.frame(Nota = nota)),
                    file.path(TAB, "TablaS8_descriptivos_faltantes.xlsx"))
cat("Tabla S8 generada; conteos, porcentajes y faltantes verificados.\n")
