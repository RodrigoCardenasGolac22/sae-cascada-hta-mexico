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

# =============================================================================================
# POBLACION ADULTA MUNICIPAL (Censo 2020, ITER)
# =============================================================================================
# Denominador de la densidad de establecimientos CLUES (clues_por_10k, decision B5 opcion 2 del
# plan, tomada por el autor el 2026-08-06). Es el total censal de poblacion de 20 anios y mas por
# municipio: las bandas quinquenales 20-59 mas P_60YMAS, los MISMOS margenes de edad con que
# 09_extension_nacional.R construye la tabla de post-estratificacion (alli 65+ se reconstruye como
# P_60YMAS - P_60A64; la suma total es identica). Vive aqui y no en 09 porque lo consume
# 02_covariable_clues.R, que corre antes.
#
# Los 9 municipios creados despues del Censo 2020 no existen en el ITER y quedan sin denominador
# (densidad NA); son exactamente los mismos que quedan sin tabla de post-estratificacion en 09 y
# ninguno tiene muestra de encuesta (verificado 2026-08-06).
poblacion_adulta_municipal <- function(iter_csv = Sys.getenv("ITER_CSV",
    unset = "DATOS_GEO_MEXICO/iter_00_cpv2020/conjunto_de_datos_iter_00CSV20.csv")) {
  if (!file.exists(iter_csv)) {
    stop("No se encuentra el ITER del Censo 2020 en: ", iter_csv,
         "\nDescargarlo de https://www.inegi.org.mx/programas/ccpv/2020/ (ITER, entidad 00) ",
         "o definir la variable de entorno ITER_CSV.")
  }
  bandas <- c("20A24", "25A29", "30A34", "35A39", "40A44", "45A49", "50A54", "55A59")
  cols_pob <- c(as.vector(outer(paste0("P_", bandas), c("_F", "_M"), paste0)),
                "P_60YMAS_F", "P_60YMAS_M")
  it <- readr::read_csv(iter_csv, col_types = do.call(readr::cols_only, c(
    list(ENTIDAD = readr::col_character(), MUN = readr::col_character(),
         LOC = readr::col_character()),
    setNames(rep(list(readr::col_character()), length(cols_pob)), cols_pob))))
  # "*" (suprimido por confidencialidad) y "N/D" entran como 0, el mismo criterio que el paso 09.
  num0 <- function(x) { v <- suppressWarnings(as.numeric(x)); ifelse(is.na(v), 0, v) }
  it %>%
    dplyr::filter(LOC != "0000", MUN != "000", ENTIDAD != "00") %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(cols_pob), num0),
                  muni_id = paste0(ENTIDAD, MUN)) %>%
    dplyr::group_by(muni_id) %>%
    dplyr::summarise(pob_adulta = sum(dplyr::across(dplyr::all_of(cols_pob))), .groups = "drop")
}

# =============================================================================================
# COVARIABLES MUNICIPALES DE AREA
# =============================================================================================
# Vive aqui, y no repetida en cada script, porque la especificacion tiene que ser IDENTICA en la
# seleccion (07), los modelos finales (08), la post-estratificacion (09), la validacion cruzada
# (10) y el benchmark (11). Cuando estaba repetida divergio sin que nadie lo notara: 07 probaba la
# candidata como log1p(clues_total) y 08/09/10 usaban el CONTEO CRUDO, de modo que la evidencia de
# seleccion no correspondia al modelo publicado.
#
# clues_total: el conteo llega ya completo desde 02_covariable_clues.R (marco de 2 478 municipios,
# con 0 donde no hay establecimientos en operacion). El ifelse de abajo es una red de seguridad
# para el caso de que alguien regenere el derivado con la version antigua del script, que solo
# emitia fila para los municipios con >=1 establecimiento.
#
# clues_por_10k: la covariable que ENTRA A LOS MODELOS es la densidad por 10 000 adultos
# (decision B5 opcion 2, 2026-08-06), construida en 02_covariable_clues.R con la poblacion adulta
# censal como denominador. El conteo -- incluso en escala log -- iba confundido con el tamano del
# municipio (mas establecimientos <-> municipio mas grande, y la poblacion municipal no esta en el
# modelo); la densidad desacopla ese efecto y permite llamarla "densidad" con propiedad. Es NA solo
# en los 9 municipios creados despues del Censo 2020, que no tienen denominador censal (ni tabla de
# post-estratificacion, ni muestra). Los log1p del conteo se conservan como referencia/diagnostico,
# pero ninguna formula debe usarlos.
#
# pobreza_pct: CONEVAL trae el texto "n.d" en tres municipios creados despues de 2020
# (04012 Seybaplaya, 07125 Honduras de la Sierra, 29048 La Magdalena Tlaltelulco); as.numeric()
# los deja NA en silencio. Se dejan NA a proposito y se DECLARAN en el manuscrito (decision A3
# opcion 1, tomada por el autor el 2026-08-06).
cargar_covariables_area <- function(datos, COV = "COVARIABLES") {
  coneval <- readr::read_csv(file.path(COV, "coneval_pobreza_municipal_2020.csv"),
                             col_types = readr::cols(.default = readr::col_character()))
  coneval$muni_id <- sprintf("%05d", as.numeric(coneval$clave_municipio))
  coneval$pobreza_pct <- suppressWarnings(as.numeric(coneval$pobreza))
  n_nd <- sum(is.na(coneval$pobreza_pct))
  if (n_nd > 0) {
    cat(sprintf("CONEVAL: %d municipios sin indicador de pobreza publicado -> NA (%s)\n",
                n_nd, paste(coneval$muni_id[is.na(coneval$pobreza_pct)], collapse = ", ")))
  }

  # Si el CSV no trae las columnas de densidad, el select() de abajo aborta con un error claro:
  # significa que se regenero con la version anterior de 02_covariable_clues.R.
  clues <- readr::read_csv(file.path(COV, "clues_conteo_municipal.csv"),
                           col_types = readr::cols(muni_id = readr::col_character()))

  alt <- readr::read_csv(file.path(COV, "altitud_municipal_DEM.csv"),
                         col_types = readr::cols(.default = readr::col_character()))
  alt$muni_id <- paste0(alt$cve_ent, alt$cve_mun)
  alt$altitud_msnm <- as.numeric(alt$altitud_media_msnm)

  out <- datos %>%
    dplyr::left_join(coneval %>% dplyr::select(muni_id, pobreza_pct), by = "muni_id") %>%
    dplyr::left_join(clues %>% dplyr::select(muni_id, clues_total, clues_publico, pob_adulta,
                                             clues_por_10k, clues_publico_por_10k),
                     by = "muni_id") %>%
    dplyr::left_join(alt %>% dplyr::select(muni_id, altitud_msnm), by = "muni_id") %>%
    dplyr::mutate(
      clues_total       = ifelse(is.na(clues_total), 0, clues_total),
      clues_publico     = ifelse(is.na(clues_publico), 0, clues_publico),
      log_clues_total   = log1p(clues_total),
      log_clues_publico = log1p(clues_publico)
    )

  n_sin_dens <- dplyr::n_distinct(out$muni_id[is.na(out$clues_por_10k)])
  if (n_sin_dens > 0) {
    cat(sprintf("Censo 2020: %d municipios sin poblacion censal -> densidad CLUES NA (creados despues del Censo)\n",
                n_sin_dens))
  }

  # Guardias contra la regresion que esto corrige: si la variable que entra a los modelos vuelve a
  # tener NA donde no debe, abortar en vez de perder municipios en silencio. La densidad solo puede
  # ser NA donde no hay denominador censal (pob_adulta NA).
  stopifnot(!any(is.na(out$log_clues_total)), !any(is.na(out$log_clues_publico)),
            !any(is.na(out$clues_por_10k) & !is.na(out$pob_adulta)))
  out
}

# --- Pliegues espacialmente contiguos para la validacion cruzada ------------------------------
# POR QUE. La CV asignaba los municipios a los pliegues AL AZAR (sample()), pese a que el
# manuscrito la llama "validacion cruzada espacial" y cita a Roberts et al. 2017, que es sobre
# bloques espaciales. La diferencia no es cosmetica: un municipio muestreado retenido al azar
# conserva mediana 2 vecinos muestreados dentro del ajuste, mientras que 680 de los 1 879
# municipios que el modelo predice (36,2 %) no tienen NINGUN vecino muestreado. Con pliegues
# aleatorios se mide un regimen mas facil que el que se publica.
#
# COMO. Semillas por muestreo de punto mas lejano (farthest-point) sobre el grafo COMPLETO de 2 478
# municipios --no sobre el subgrafo de los muestreados, que esta desconectado: el 12,8 % de los
# muestreados no tiene ningun vecino muestreado--, asignacion de cada municipio muestreado a su
# semilla mas cercana en numero de saltos, y un pase de reequilibrado que mueve nodos de frontera
# del pliegue mas grande al mas pequeno hasta que la diferencia de tamanos es <= tolerancia.
# Determinista: depende solo de la semilla que se le pase.
distancias_bfs <- function(origen, adj, n) {
  d <- rep(NA_integer_, n); d[origen] <- 0L
  cola <- origen; i <- 1L
  while (i <= length(cola)) {
    v <- cola[i]; i <- i + 1L
    for (w in adj[[v]]) if (is.na(d[w])) { d[w] <- d[v] + 1L; cola <- c(cola, w) }
  }
  d
}

asignar_pliegues_contiguos <- function(municipios, adj, n_nodos, n_folds = 5, semilla = 20260728,
                                       tolerancia = 0.05) {
  set.seed(semilla)
  municipios <- sort(unique(municipios))
  # 1. semillas dispersas: la primera al azar, cada siguiente la mas lejana a las ya elegidas
  semillas <- sample(municipios, 1)
  dmin <- distancias_bfs(semillas, adj, n_nodos)
  while (length(semillas) < n_folds) {
    cand <- setdiff(municipios, semillas)
    dc <- dmin[cand]; dc[is.na(dc)] <- max(dmin, na.rm = TRUE) + 1L   # inalcanzables: los mas lejanos
    nueva <- cand[which.max(dc)]
    semillas <- c(semillas, nueva)
    dn <- distancias_bfs(nueva, adj, n_nodos)
    dmin <- pmin(dmin, dn, na.rm = TRUE)
  }
  # 2. distancia de cada municipio a cada semilla y asignacion a la mas cercana
  D <- vapply(semillas, function(s) distancias_bfs(s, adj, n_nodos)[municipios], integer(length(municipios)))
  D[is.na(D)] <- .Machine$integer.max
  fold <- apply(D, 1, which.min)
  # 3. reequilibrado: del pliegue mayor al menor, moviendo el nodo con menor penalizacion de
  #    distancia (es decir, el que esta mas en la frontera entre los dos)
  objetivo <- length(municipios) / n_folds
  # El tope de iteraciones tiene que escalar con el desbalance inicial, no con n_folds: cada
# iteracion mueve UN nodo, y el desbalance de partida puede ser de mas de 100 municipios.
  for (iter in seq_len(4L * length(municipios))) {
    tam <- tabulate(fold, n_folds)
    if ((max(tam) - min(tam)) <= max(1, ceiling(tolerancia * objetivo))) break
    grande <- which.max(tam); pequeno <- which.min(tam)
    cand <- which(fold == grande)
    coste <- D[cand, pequeno] - D[cand, grande]
    fold[cand[which.min(coste)]] <- pequeno
  }
  setNames(fold, as.character(municipios))
}
