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

# --- transparencia -> color solido equivalente -------------------------------
# PostScript no tiene transparencia. Cuando una figura usa alpha, cairo no puede
# hacer otra cosa que RASTERIZAR la zona afectada, y un mapa de 2478 municipios
# con alpha sale como un mapa de bits de 6 MB dentro del EPS: al ampliarlo se
# pixela y deja de ser una figura vectorial.
#
# Pero aqui el alpha se aplica a poligonos que NO se solapan, sobre fondo blanco.
# En ese caso "color al 50 %" y "color mezclado al 50 % con blanco" son EL MISMO
# pixel. Se mezcla de antemano, el alpha deja de existir, y el EPS sale vectorial
# sin que la figura cambie. Que no cambia se comprueba comparando el PNG nuevo
# con el anterior pixel a pixel, no mirandolo por encima.
mezclar_con_fondo <- function(colores, alpha, fondo = "white") {
  a <- rep_len(alpha, length(colores))
  a[is.na(a)] <- 1
  col <- grDevices::col2rgb(ifelse(is.na(colores), fondo, colores)) / 255
  fnd <- grDevices::col2rgb(fondo)[, 1] / 255
  mezcla <- col * rep(a, each = 3) + fnd * rep(1 - a, each = 3)
  out <- grDevices::rgb(t(mezcla))
  out[is.na(colores)] <- NA
  out
}

# --- exportacion para la revista mexicana -----------------------------------
# Dos normas suyas que ni el .pptx ni el .png cumplen:
#   "Las figuras exportadas de herramientas estadisticas se solicitan en formato .eps"
#   "Las figuras consistentes en graficas generadas a partir de datos deberan
#    acompanarse de dichos datos en formato editable de Excel"
# El .pptx editable sigue siendo el maestro (regla de la carpeta INVESTIGACION);
# el .eps es lo que se exporta para el envio, igual que el .tif para PLOS.

# El dispositivo es cairo_ps y NO el postscript clasico: este ultimo descarta las
# transparencias EN SILENCIO, y los mapas --que usan alpha para marcar los
# municipios sin muestra directa-- saldrian con los colores planos.
#
# DOS COSAS QUE HAY QUE SABER DE ESTE EPS, verificadas el 2026-08-05 abriendo el
# archivo, no suponiendolas:
#
#  1. NO es vectorial. PostScript no tiene transparencia real, asi que cairo
#     rasteriza a 600 ppp las zonas con alpha: el archivo son 772 flujos de imagen
#     comprimidos. Es un mapa de bits de 600 ppp dentro de un envoltorio
#     PostScript, que es exactamente lo que la revista admite para figuras tipo
#     imagen. La alternativa vectorial --exportar el SVG con LibreOffice-- se
#     probo y se descarto: aplasta el alpha y deja identicos dos de los tres
#     niveles de la leyenda "Fuente". Preferimos perder los vectores antes que
#     perder lo que la figura dice.
#
#  2. Cairo NO incrusta vista previa, y sin ella LibreOffice Draw, Word y los
#     visores en general muestran un RECTANGULO VACIO con la cabecera del archivo.
#     El EPS es correcto, pero nadie puede comprobarlo mirandolo. Por eso aqui se
#     envuelve en el formato EPSF binario (cabecera DOS de 30 bytes) con una
#     vista previa TIFF: mismo PostScript, mas una miniatura que cualquier
#     programa sabe pintar.
guardar_figura_eps <- function(gg, archivo, ancho, alto) {
  if (!isTRUE(capabilities("cairo"))) {
    stop("Este R no tiene cairo: el EPS perderia las transparencias. No se exporta a ciegas.")
  }
  ps_tmp <- tempfile(fileext = ".eps")
  ggplot2::ggsave(ps_tmp, gg, width = ancho, height = alto,
                  device = grDevices::cairo_ps, fallback_resolution = 600, bg = "white")
  if (!file.exists(ps_tmp) || file.size(ps_tmp) < 5000) {
    stop("El EPS salio vacio o demasiado pequeno para ser real: ", archivo)
  }

  # Miniatura para la vista previa: la MISMA figura, a resolucion de pantalla.
  tif_tmp <- tempfile(fileext = ".tif")
  # 150 ppp y no 72: la miniatura es lo UNICO que ven los programas de oficina,
  # porque no saben interpretar PostScript. A 72 se veia pixelada al ampliar y
  # parecia que la figura estaba mal, cuando la que esta mal es la miniatura.
  # Con compresion LZW ocupa menos que la de 72 sin comprimir.
  grDevices::tiff(tif_tmp, width = ancho, height = alto, units = "in", res = 150,
                  compression = "lzw", type = "cairo", bg = "white")
  print(gg)
  grDevices::dev.off()

  ps  <- readBin(ps_tmp,  "raw", file.size(ps_tmp))
  tif <- readBin(tif_tmp, "raw", file.size(tif_tmp))
  con <- file(archivo, "wb")
  on.exit(close(con), add = TRUE)
  # Cabecera EPSF binaria: magico, desplazamiento y longitud de cada seccion.
  writeBin(as.raw(c(0xC5, 0xD0, 0xD3, 0xC6)), con)
  for (v in c(30L, length(ps), 0L, 0L, 30L + length(ps), length(tif))) {
    writeBin(as.integer(v), con, size = 4, endian = "little")
  }
  writeBin(as.integer(-1), con, size = 2, endian = "little")   # suma de control: FFFF
  writeBin(ps, con)
  writeBin(tif, con)
  close(con)
  on.exit()

  # Se vuelve a abrir y se comprueba que las dos secciones estan donde dice la
  # cabecera. Escribir un envoltorio mal formado da un archivo que ningun visor
  # abre, y el tamano seguiria pareciendo correcto.
  d <- readBin(archivo, "raw", file.size(archivo))
  off_ps  <- readBin(d[5:8],   "integer", size = 4, endian = "little")
  len_ps  <- readBin(d[9:12],  "integer", size = 4, endian = "little")
  len_tif <- readBin(d[25:28], "integer", size = 4, endian = "little")
  cab <- rawToChar(d[(off_ps + 1):(off_ps + 22)])
  if (!startsWith(cab, "%!PS-Adobe") || len_tif < 1000 ||
      length(d) != 30 + len_ps + len_tif) {
    stop("El envoltorio EPSF salio mal formado: ", archivo)
  }
  cat(sprintf("Guardado: %s (EPS %.1f x %.1f in, %.1f MB, con vista previa TIFF de %d KB)\n",
              archivo, ancho, alto, length(d) / 1024^2, len_tif %/% 1024))
  invisible(archivo)
}

# `datos` es una lista con nombre por hoja. Se escribe con writexl y no con
# openxlsx por el mismo motivo documentado en 18_tablas.R.
guardar_datos_figura <- function(datos, archivo) {
  dir.create(dirname(archivo), showWarnings = FALSE, recursive = TRUE)
  # Excel no admite mas de 31 caracteres por hoja ni los caracteres []:*?/\
  names(datos) <- substr(gsub("[\\[\\]:*?/\\\\]", "-", names(datos)), 1, 31)
  writexl::write_xlsx(lapply(datos, as.data.frame), archivo)
  cat(sprintf("Guardado: %s (%s)\n", archivo,
              paste(sprintf("%s %d filas", names(datos),
                            vapply(datos, nrow, integer(1))), collapse = "; ")))
  invisible(archivo)
}
