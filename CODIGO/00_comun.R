# Definiciones compartidas por varios scripts del pipeline. Se cargan con
#   source("CODIGO/00_comun.R")
# desde la raiz del repositorio.
#
# Existe para que un mismo hecho no viva escrito en cinco archivos: los niveles de escolaridad los
# necesitan 01 (para construirlos) y 08-12 (para fijar la categoria de referencia del modelo). Si
# estuvieran repetidos, bastaria con corregir uno y olvidar otro para que los modelos cambiaran de
# referencia sin que nadie lo notara.

# Orden sustantivo de escolaridad, de menor a mayor. El primer nivel es la categoria de REFERENCIA
# de los modelos. Se usa "Sin escolaridad" y no el orden alfabetico que devuelve factor() por
# defecto -- que dejaria "Preparatoria/tecnico" como referencia, un contraste sin interpretacion.
#
# El nivel "Sin escolaridad" corresponde a h0317a == 0, que el catalogo oficial de ENSANUT no
# etiqueta pero que NO es un dato faltante: son adultos sin escolaridad (68,3 % de analfabetismo
# medido con h0318 en 2021 y 68,9 % en 2022, frente a 8,7-10,1 % entre quienes declaran Primaria;
# edad mediana 55-56 anios). Ver la nota extensa en 01_base_analitica.R.
NIVELES_ESCOLARIDAD <- c("Sin escolaridad", "Primaria o menos", "Secundaria",
                         "Preparatoria/tecnico", "Superior")

# Guardia contra el defecto que motivo todo esto: si aparece una etiqueta de escolaridad que no
# esta en NIVELES_ESCOLARIDAD, factor() la mandaria a NA EN SILENCIO y esas personas saldrian de
# los modelos sin que nadie se entere -- que es exactamente lo que pasaba con h0317a == 0. Se
# aborta en vez de perderlas calladamente. Se llama una vez, en 01, sobre la base ya construida:
# si la base esta limpia, todos los factor() de aguas abajo lo estan.
verificar_escolaridad <- function(x) {
  raras <- setdiff(unique(x[!is.na(x)]), NIVELES_ESCOLARIDAD)
  if (length(raras) > 0) {
    stop("Etiquetas de escolaridad fuera de NIVELES_ESCOLARIDAD: ", paste(raras, collapse = ", "))
  }
  invisible(TRUE)
}

# Anade el ponderador calibrado (script 02b) a la base analitica. Es el ponderador del ANALISIS
# PRINCIPAL: la medicion de presion arterial se hace en una submuestra del modulo de adultos y
# ponde_f, aplicado a esa submuestra, no la re-expande a la poblacion (suma 33-60 millones segun el
# anio en vez de ~84). El factor de correccion varia de 1,12 a 3,67 entre celdas de
# anio x estrato x sexo x grupo de edad, asi que la no-respuesta NO es uniforme y no corregirla
# sesga. Validado contra el t_ponde que ENSANUT 2023 publica: la calibracion reduce la discrepancia
# media con ese ponderador de 0,92 pp (ponde_f) a 0,48 pp. Ver 02b_calibrar_ponderador.R.
agregar_ponderador_calibrado <- function(d, res_dir = "RESULTADOS") {
  pc <- readr::read_csv(file.path(res_dir, "ponderador_calibrado.csv"),
                        col_types = readr::cols(FOLIO_I = readr::col_character(),
                                                FOLIO_INT = readr::col_character(),
                                                anio = readr::col_character(),
                                                .default = readr::col_guess()))
  n0 <- nrow(d)
  d <- dplyr::left_join(d, pc[, c("FOLIO_I", "FOLIO_INT", "anio", "ponde_cal")],
                        by = c("FOLIO_I", "FOLIO_INT", "anio"))
  if (nrow(d) != n0) stop("El join del ponderador calibrado duplico filas: ", n0, " -> ", nrow(d))
  if (any(is.na(d$ponde_cal))) {
    stop(sum(is.na(d$ponde_cal)), " filas se quedaron sin ponde_cal. ",
         "¿Se corrio 02b_calibrar_ponderador.R despues del ultimo 01_base_analitica.R?")
  }
  d
}

# --- Figuras editables para la revista -------------------------------------------------------
# La revista exige que "Maps, diagrams or graphs should be submitted in an editable format"
# (requisito habitual de las revistas), asi que las figuras se generan como .pptx vectorial
# --- rvg::dml() convierte el ggplot en formas de PowerPoint, no en una imagen pegada.
#
# Existe porque la forma directa esta rota. officer::read_pptx() crea SIEMPRE diapositivas de
# 10 x 7.5 pulgadas, y estas figuras miden hasta 14 pulgadas de ancho: colocadas con
# ph_location(width = 12.7) quedaban 3 pulgadas FUERA del area visible, de modo que al abrir el
# archivo se veia un trozo del mapa cortado. Peor aun, el ancho y el alto que se pasaban a mano
# no respetaban la relacion de aspecto del ggsave() correspondiente (Fig1 se genera 9 x 10 y se
# colocaba 7.5 x 6.3), asi que la version "editable" salia deformada respecto de la publicada.
# Aqui la diapositiva se dimensiona a la figura, no al reves.
#
# Tampoco se pone marcador de titulo: el layout "Title and Content" arrastra el titulo a 44 pt de
# la plantilla por defecto de Office, que es lo que se veia como texto gigante. El pie de figura
# va en el manuscrito, que es donde la revista lo pide.
fijar_tamano_diapositiva <- function(pptx, ancho, alto) {
  EMU <- 914400
  tmp <- file.path(tempdir(), paste0("pptx_", tools::file_path_sans_ext(basename(pptx))))
  unlink(tmp, recursive = TRUE)
  dir.create(tmp, recursive = TRUE)
  utils::unzip(pptx, exdir = tmp)
  p <- file.path(tmp, "ppt", "presentation.xml")
  x <- paste(readLines(p, warn = FALSE), collapse = "")
  if (!grepl("<p:sldSz", x)) stop("presentation.xml sin <p:sldSz>: ", pptx)
  x <- sub("<p:sldSz[^>]*/>",
           sprintf('<p:sldSz cx="%.0f" cy="%.0f"/>', ancho * EMU, alto * EMU), x)
  # writeLines anadiria un CRLF al final; el XML se escribe tal cual, en binario.
  con <- file(p, open = "wb"); writeBin(charToRaw(x), con); close(con)
  # Se pasan solo las entradas de PRIMER nivel ([Content_Types].xml, _rels, docProps, ppt) y se
  # deja que zipr recurse: con la lista recursiva completa aplana las rutas y el .pptx resultante
  # pierde ppt/presentation.xml, con lo que PowerPoint ya no lo reconoce.
  archivos <- list.files(tmp, all.files = TRUE, no.. = TRUE)
  # zip::zipr se situa en `root` antes de comprimir, asi que el destino tiene que ser una ruta
  # absoluta: con una relativa lo buscaria dentro del directorio temporal y falla.
  destino <- normalizePath(pptx, winslash = "/", mustWork = FALSE)
  unlink(destino)
  # include_directories = FALSE es imprescindible: un paquete OOXML no puede llevar entradas de
  # directorio ("ppt/", "_rels/"). Con ellas PowerPoint da el archivo por danado y ofrece
  # repararlo al abrirlo, aunque el ZIP sea valido y todas las partes esten.
  zip::zipr(destino, files = archivos, root = tmp, include_directories = FALSE)
  partes <- utils::unzip(destino, list = TRUE)$Name
  if (!"ppt/presentation.xml" %in% partes) {
    stop("El .pptx reempaquetado perdio su estructura de carpetas: ", pptx)
  }
  if (any(grepl("/$", partes))) {
    stop("El .pptx quedo con entradas de directorio; PowerPoint pedira repararlo: ", pptx)
  }
  invisible(pptx)
}

guardar_figura_pptx <- function(gg, archivo, ancho, alto) {
  ppt <- officer::read_pptx()
  ppt <- officer::add_slide(ppt, layout = "Blank", master = "Office Theme")
  ppt <- officer::ph_with(ppt, value = rvg::dml(ggobj = gg),
                          location = officer::ph_location(left = 0, top = 0,
                                                          width = ancho, height = alto))
  print(ppt, target = archivo)
  fijar_tamano_diapositiva(archivo, ancho, alto)
  # El .pptx solo sirve si es editable de verdad: sin imagenes rasterizadas pegadas dentro.
  z <- utils::unzip(archivo, list = TRUE)$Name
  if (any(grepl("^ppt/media/", z))) {
    stop("El .pptx incrusto una imagen en vez de vectores: ", archivo)
  }
  cat(sprintf("Guardado: %s (%.1f x %.1f pulgadas, vectorial)\n", archivo, ancho, alto))
  invisible(archivo)
}
