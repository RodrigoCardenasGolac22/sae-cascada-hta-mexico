# EXTENSION A COBERTURA NACIONAL POR POST-ESTRATIFICACION CENSAL
#
# QUE HACE
# Produce la prevalencia de cada paso de la cascada en LOS 2 478 MUNICIPIOS, incluidos los ~1 900
# sin muestra directa de ENSANUT, post-estratificando las predicciones del modelo BYM2 sobre la
# composicion real de la poblacion adulta de cada municipio segun el Censo 2020.
#
# POR QUE ASI
# La alternativa simple --predecir para un unico individuo de referencia por estrato de
# urbanidad (sexo modal, edad media, escolaridad modal), identico en todos los municipios de ese
# estrato-- tiene dos defectos:
#
#  (1) SESGO. El modelo es logistico, luego no lineal: la probabilidad del individuo promedio NO es
#      la probabilidad promedio de la poblacion (desigualdad de Jensen). Se calculaba la primera y
#      se reportaba como la segunda.
#  (2) VARIACION DESCARTADA. Los municipios de Mexico difieren enormemente en la estructura de la
#      poblacion que el modelo mas usa: el % de adultos de 60+ va de 4,5 % a 50,9 % segun el
#      municipio, y el % sin escolaridad de 0,5 % a 50,5 % (Censo 2020). Congelar la demografia
#      hacia que los municipios sin muestra se diferenciaran solo por pobreza, CLUES y efecto
#      espacial, y su heterogeneidad medida (DE 1,3 pp en la reclasificacion ESH vs AHA) era un
#      artefacto del metodo, no una propiedad del pais.
#
# EL METODO: post-estratificacion con regresion multinivel (MRP), el estandar del campo.
#   Zhang X, et al. Multilevel regression and poststratification for small-area estimation of
#     population health outcomes. Am J Epidemiol. 2014;179(8):1025-33. doi:10.1093/aje/kwu018
#   Wang Y, et al. Using 3 health surveys to compare multilevel models for small area estimation
#     for chronic diseases and health behaviors. Prev Chronic Dis. 2018;15:E133.
#     doi:10.5888/pcd15.180313  -- literal: "We applied the predicted probabilities based on the
#     fitted multilevel logistic models to the [...] population counts by age, sex, and
#     race/ethnicity (2010 Census data), and we used the poststratification to obtain the
#     prevalence estimates".
#   Greenlund KJ, et al. PLACES: local data for better health. Prev Chronic Dis. 2022;19:E31.
#     doi:10.5888/pcd19.210459  -- el CDC publica asi la prevalencia de enfermedad cronica en
#     72 337 sectores censales.
#   Rao JNK, Molina I. Small Area Estimation. 2a ed. Wiley; 2015. doi:10.1002/9781118735855
#
# DIFERENCIA CON ESE PRECEDENTE, DECLARADA: el CDC dispone de la tabla censal CONJUNTA
# (edad x sexo x raza) por manzana. El Censo mexicano publica por localidad solo los MARGENES
# (sexo x edad y sexo x escolaridad). La tabla conjunta se reconstruye por ajuste iterativo
# proporcional (rastrillado) tomando como semilla la estructura conjunta observada en ENSANUT
# dentro del mismo estrato de urbanidad.
#   Deming WE, Stephan FF. Ann Math Stat. 1940;11(4):427-44. doi:10.1214/aoms/1177731829
# El estrato de urbanidad NO se rastrilla: se obtiene exacto, porque el ITER es a nivel de
# localidad y el estrato es funcion del tamano de la localidad.
#
# LIMITACION del margen de escolaridad, declarada: el censo lo publica para la poblacion de 15
# anios y mas, no de 20 y mas. Aqui se usa solo su FORMA, aplicada al total de 20+ que da el margen
# de edad (ver la funcion rastrillar). Aun asi, los de 15 a 19 anios estan todavia estudiando y se
# concentran en los niveles bajos, de modo que la distribucion educativa que se aplica al adulto
# esta ligeramente sesgada hacia abajo. El efecto es comun a todos los municipios y se cancela en
# buena parte al comparar unos con otros, que es el objeto del estudio.
#
# INCERTIDUMBRE: se toman muestras de la distribucion posterior conjunta del modelo ajustado
# (inla.posterior.sample) y se post-estratifica DENTRO de cada muestra. El intervalo resultante es
# el de la prevalencia post-estratificada, y respeta la correlacion entre celdas -- que comparten
# los mismos coeficientes. Combinar los cuantiles de las componentes por separado, como si
# fueran independientes, daria un intervalo mal calibrado.

library(dplyr)
library(readr)
library(INLA)

source("CODIGO/00_comun.R")   # NIVELES_ESCOLARIDAD, agregar_ponderador_calibrado()

# INSUMO EXTERNO: Censo de Poblacion y Vivienda 2020, Principales resultados por localidad (ITER),
# tabulado nacional. Descarga: https://www.inegi.org.mx/programas/ccpv/2020/ (seccion "Datos
# abiertos" > ITER, entidad 00 = nacional).
ITER <- Sys.getenv("ITER_CSV", unset = "DATOS_GEO_MEXICO/iter_00_cpv2020/conjunto_de_datos_iter_00CSV20.csv")
if (!file.exists(ITER)) {
  stop("No se encuentra el ITER del Censo 2020 en: ", ITER,
       "\nDescargarlo de https://www.inegi.org.mx/programas/ccpv/2020/ y ajustar la constante ITER ",
       "o definir la variable de entorno ITER_CSV.")
}
RES <- "RESULTADOS"
GEO <- "DATOS_GEO_MEXICO"
COV <- "COVARIABLES"

N_MUESTRAS <- 1000   # muestras de la posterior por modelo
set.seed(20260730)

idx_tabla <- read_csv(file.path(GEO, "muni_idx_grafo.csv"), col_types = cols(
  cve_ent = col_character(), cve_mun = col_character()))
idx_tabla$muni_id <- paste0(idx_tabla$cve_ent, idx_tabla$cve_mun)
N_MUNI <- nrow(idx_tabla)

# =============================================================================================
# 1. TABLA DE POST-ESTRATIFICACION DESDE EL CENSO
# =============================================================================================
# Bandas de edad: las quinquenales que publica el ITER, de 20 a 64, mas 65+. Se usan tal cual y no
# agregadas, para que la aproximacion dentro de banda sea lo mas pequena posible (el modelo lleva
# la edad como variable continua).
BANDAS <- c("20A24", "25A29", "30A34", "35A39", "40A44", "45A49", "50A54", "55A59", "60A64")
cols_edad <- as.vector(outer(paste0("P_", BANDAS), c("_F", "_M"), paste0))
cols_60ym <- c("P_60YMAS_F", "P_60YMAS_M")
cols_esc  <- c("P15YM_SE_F", "P15YM_SE_M", "P15PRI_INF", "P15PRI_INM", "P15PRI_COF", "P15PRI_COM",
               "P15SEC_INF", "P15SEC_INM", "P15SEC_COF", "P15SEC_COM", "P18YM_PB_F", "P18YM_PB_M")

cat("Leyendo el ITER del Censo 2020...\n")
iter <- read_csv(ITER, col_types = do.call(cols_only, c(
  list(ENTIDAD = col_character(), MUN = col_character(), LOC = col_character(),
       POBTOT = col_character()),
  setNames(rep(list(col_character()), length(c(cols_edad, cols_60ym, cols_esc))),
           c(cols_edad, cols_60ym, cols_esc)))))

# El ITER usa "*" para celdas suprimidas por confidencialidad y "N/D" para no disponible; ambos
# entran como 0, que es lo que corresponde en un conteo agregado a nivel municipal.
num0 <- function(x) { v <- suppressWarnings(as.numeric(x)); ifelse(is.na(v), 0, v) }

iter <- iter %>%
  filter(LOC != "0000", MUN != "000", ENTIDAD != "00") %>%
  mutate(across(all_of(c("POBTOT", cols_edad, cols_60ym, cols_esc)), num0),
         muni_id = paste0(ENTIDAD, MUN),
         # mismo criterio de estrato que el modulo de adultos de ENSANUT (1 rural, 2 urbano,
         # 3 metropolitano), aplicado al tamano de la localidad
         estrato = case_when(POBTOT < 2500 ~ "1", POBTOT < 100000 ~ "2", TRUE ~ "3"))

# --- margen sexo x edad x estrato (exacto) ---
marg_edad <- iter %>%
  group_by(muni_id, estrato) %>%
  summarise(across(all_of(c(cols_edad, cols_60ym)), sum), .groups = "drop")
# 65+ = (60 y mas) - (60 a 64); si el redondeo del censo lo vuelve negativo, se trunca en 0
marg_edad$P_65YMAS_F <- pmax(marg_edad$P_60YMAS_F - marg_edad$P_60A64_F, 0)
marg_edad$P_65YMAS_M <- pmax(marg_edad$P_60YMAS_M - marg_edad$P_60A64_M, 0)
BANDAS_ALL <- c(BANDAS, "65YMAS")

edad_largo <- bind_rows(lapply(BANDAS_ALL, function(b) {
  data.frame(muni_id = marg_edad$muni_id, estrato = marg_edad$estrato, banda = b,
             `1` = marg_edad[[paste0("P_", b, "_M")]],
             `2` = marg_edad[[paste0("P_", b, "_F")]], check.names = FALSE)
})) %>%
  tidyr::pivot_longer(c(`1`, `2`), names_to = "sexo", values_to = "pob") %>%
  filter(pob > 0)

# --- margen sexo x escolaridad x estrato (exacto salvo el reparto de posbasica) ---
marg_esc <- iter %>%
  group_by(muni_id, estrato) %>%
  summarise(across(all_of(cols_esc), sum), .groups = "drop") %>%
  transmute(muni_id, estrato,
            `Sin escolaridad.1` = P15YM_SE_M,        `Sin escolaridad.2` = P15YM_SE_F,
            `Primaria o menos.1` = P15PRI_INM + P15PRI_COM,
            `Primaria o menos.2` = P15PRI_INF + P15PRI_COF,
            `Secundaria.1` = P15SEC_INM + P15SEC_COM,
            `Secundaria.2` = P15SEC_INF + P15SEC_COF,
            `Posbasica.1` = P18YM_PB_M,              `Posbasica.2` = P18YM_PB_F)

esc_largo <- marg_esc %>%
  tidyr::pivot_longer(-c(muni_id, estrato), names_to = c("nivel", "sexo"), names_sep = "\\.",
                      values_to = "pob") %>%
  filter(pob > 0)

# =============================================================================================
# 2. SEMILLA Y REPARTO DE POSBASICA, DESDE LA ENCUESTA
# =============================================================================================
base <- read_csv(file.path(RES, "base_analitica_adultos_2021_2024.csv"),
                  col_types = cols(
                    entidad = col_character(), municipio = col_character(), anio = col_character(),
                    FOLIO_I = col_character(), FOLIO_INT = col_character(), estrato = col_character(),
                    diag_cronico = col_logical(), hta_esh = col_logical(), hta_aha = col_logical(),
                    tratado = col_logical(), control_esh = col_logical(), control_aha = col_logical(),
                    .default = col_guess()))
base <- agregar_ponderador_calibrado(base, RES)
base <- base %>% left_join(idx_tabla, by = c("entidad" = "cve_ent", "municipio" = "cve_mun")) %>%
  mutate(muni_id = paste0(entidad, municipio),
         sexo = as.character(sexo),
         banda = cut(edad, breaks = c(19, 24, 29, 34, 39, 44, 49, 54, 59, 64, Inf),
                     labels = BANDAS_ALL) %>% as.character(),
         escolaridad_f = factor(escolaridad, levels = NIVELES_ESCOLARIDAD),
         anio_f = factor(anio),
         sexo_f = factor(sexo), estrato_f = factor(estrato))

coneval <- read_csv(file.path(COV, "coneval_pobreza_municipal_2020.csv"), col_types = cols(.default = col_character()))
coneval$muni_id <- sprintf("%05d", as.numeric(coneval$clave_municipio))
coneval$pobreza_pct <- as.numeric(coneval$pobreza)
clues <- read_csv(file.path(COV, "clues_conteo_municipal.csv"), col_types = cols(muni_id = col_character()))

# Edad representativa de cada banda: la media ponderada observada en la encuesta dentro de la banda
# (no el punto medio del intervalo), que refleja la distribucion real de edades dentro de ella.
edad_rep <- base %>% group_by(banda) %>%
  summarise(edad = weighted.mean(edad, ponde_cal), .groups = "drop")
cat("\nEdad representativa por banda:\n"); print(as.data.frame(edad_rep), row.names = FALSE)

# El censo publica "posbasica" en un solo bloque, sin separar preparatoria/tecnico de superior.
# Se reparte con la proporcion observada en la encuesta dentro de cada estrato de urbanidad.
reparto_pb <- base %>%
  filter(escolaridad %in% c("Preparatoria/tecnico", "Superior")) %>%
  count(estrato, escolaridad, wt = ponde_cal) %>%
  group_by(estrato) %>% mutate(prop = n / sum(n)) %>% ungroup() %>%
  select(estrato, escolaridad, prop)
cat("\nReparto de 'posbasica' por estrato (proporcion observada en ENSANUT):\n")
print(as.data.frame(reparto_pb), row.names = FALSE)

esc_largo <- esc_largo %>%
  left_join(reparto_pb, by = "estrato", relationship = "many-to-many") %>%
  mutate(escolaridad = ifelse(nivel == "Posbasica", escolaridad, nivel),
         pob = ifelse(nivel == "Posbasica", pob * prop, pob)) %>%
  filter(!is.na(escolaridad)) %>%
  distinct(muni_id, estrato, sexo, escolaridad, .keep_all = TRUE) %>%
  group_by(muni_id, estrato, sexo, escolaridad) %>%
  summarise(pob = sum(pob), .groups = "drop")

# Semilla del rastrillado: estructura conjunta banda x escolaridad observada en la encuesta dentro
# de cada estrato de urbanidad y sexo. Se usa +0.5 para que ninguna celda quede en cero absoluto y
# el rastrillado pueda moverla si el censo dice que ahi hay poblacion.
semilla <- base %>%
  count(estrato, sexo, banda, escolaridad, wt = ponde_cal, name = "w") %>%
  tidyr::complete(estrato, sexo, banda = BANDAS_ALL, escolaridad = NIVELES_ESCOLARIDAD,
                  fill = list(w = 0)) %>%
  mutate(w = w + 0.5)

# =============================================================================================
# 3. RASTRILLADO (ajuste iterativo proporcional) POR MUNICIPIO x ESTRATO x SEXO
# =============================================================================================
rastrillar <- function(seed, m_fila, m_col, iter_max = 50, tol = 1e-8) {
  x <- seed
  # Los dos margenes tienen que sumar lo mismo. Se conserva el total del margen de EDAD y se
  # reescala el de escolaridad, no al reves: el de edad es exactamente la poblacion de 20+ de esa
  # celda (se construye sumando las bandas quinquenales), mientras que el de escolaridad que
  # publica el censo es de 15 anios y mas y ademas omite el "no especificado". Del margen de
  # escolaridad solo se usa, por tanto, su FORMA (la distribucion entre niveles), no su total.
  if (sum(m_fila) <= 0 || sum(m_col) <= 0) return(seed * 0)
  m_col <- m_col * (sum(m_fila) / sum(m_col))
  for (i in seq_len(iter_max)) {
    rf <- rowSums(x); rf[rf == 0] <- 1
    x <- x * (m_fila / rf)
    rc <- colSums(x); rc[rc == 0] <- 1
    x <- sweep(x, 2, m_col / rc, "*")
    if (max(abs(rowSums(x) - m_fila)) < tol) break
  }
  x
}

cat("\nConstruyendo la tabla de post-estratificacion...\n")

# Los dos margenes se pre-indexan por la llave municipio|estrato|sexo (split una sola vez) en vez
# de filtrarlos dentro del bucle: son ~15 000 bloques y filtrar tablas de cientos de miles de filas
# en cada iteracion tardaria horas.
edad_largo$k <- paste(edad_largo$muni_id, edad_largo$estrato, edad_largo$sexo, sep = "|")
esc_largo$k  <- paste(esc_largo$muni_id,  esc_largo$estrato,  esc_largo$sexo,  sep = "|")
E <- split(edad_largo[, c("banda", "pob")], edad_largo$k)
S <- split(esc_largo[, c("escolaridad", "pob")], esc_largo$k)

# Semillas: una matriz por estrato|sexo, construida una sola vez
semilla$ks <- paste(semilla$estrato, semilla$sexo, sep = "|")
SEM <- lapply(split(semilla, semilla$ks), function(d) {
  M <- matrix(0, length(BANDAS_ALL), length(NIVELES_ESCOLARIDAD),
              dimnames = list(BANDAS_ALL, NIVELES_ESCOLARIDAD))
  M[cbind(d$banda, d$escolaridad)] <- d$w
  M
})

llaves <- intersect(names(E), names(S))
cat(sprintf("   %d bloques municipio|estrato|sexo a rastrillar\n", length(llaves)))

celdas <- vector("list", length(llaves))
for (i in seq_along(llaves)) {
  kk <- llaves[i]
  partes <- strsplit(kk, "|", fixed = TRUE)[[1]]
  me <- E[[kk]]; ms <- S[[kk]]
  M <- SEM[[paste(partes[2], partes[3], sep = "|")]]
  if (is.null(M)) next
  mf <- setNames(rep(0, length(BANDAS_ALL)), BANDAS_ALL); mf[me$banda] <- me$pob
  mc <- setNames(rep(0, length(NIVELES_ESCOLARIDAD)), NIVELES_ESCOLARIDAD)
  mc[ms$escolaridad] <- ms$pob
  R <- rastrillar(M, mf, mc)
  celdas[[i]] <- data.frame(muni_id = partes[1], estrato = partes[2], sexo = partes[3],
                            banda = rep(BANDAS_ALL, times = length(NIVELES_ESCOLARIDAD)),
                            escolaridad = rep(NIVELES_ESCOLARIDAD, each = length(BANDAS_ALL)),
                            pob = as.vector(R))
  if (i %% 3000 == 0) cat(sprintf("   %d / %d\n", i, length(llaves)))
}
ps <- bind_rows(celdas) %>% filter(pob > 0.5)

ps <- ps %>%
  left_join(edad_rep, by = "banda") %>%
  left_join(idx_tabla %>% select(muni_id, muni_idx), by = "muni_id") %>%
  left_join(coneval %>% select(muni_id, pobreza_pct), by = "muni_id") %>%
  left_join(clues %>% select(muni_id, clues_total), by = "muni_id") %>%
  filter(!is.na(muni_idx)) %>%
  mutate(sexo_f = factor(sexo, levels = levels(base$sexo_f)),
         estrato_f = factor(estrato, levels = levels(base$estrato_f)),
         escolaridad_f = factor(escolaridad, levels = NIVELES_ESCOLARIDAD))

cat(sprintf("\nTabla de post-estratificacion: %d celdas en %d municipios (mediana %.0f celdas/municipio)\n",
            nrow(ps), n_distinct(ps$muni_id),
            median(table(ps$muni_id))))
cat(sprintf("Poblacion adulta 20+ representada: %.1f millones\n", sum(ps$pob) / 1e6))
write.csv(ps %>% select(muni_id, estrato, sexo, banda, escolaridad, pob),
          file.path(RES, "postestratificacion_censal.csv"), row.names = FALSE)

# =============================================================================================
# 4. POST-ESTRATIFICAR CADA MODELO SOBRE MUESTRAS DE LA POSTERIOR
# =============================================================================================
especificaciones <- list(
  AWARE_ESH   = list(denom = "hta_esh",      f = ~ sexo_f + edad + escolaridad_f + estrato_f + pobreza_pct),
  AWARE_AHA   = list(denom = "hta_aha",      f = ~ sexo_f + edad + escolaridad_f + estrato_f + pobreza_pct + clues_total),
  TRAT        = list(denom = "diag_cronico", f = ~ sexo_f + edad + escolaridad_f + estrato_f),
  CONTROL_ESH = list(denom = "tratado",      f = ~ sexo_f + edad + escolaridad_f + estrato_f + pobreza_pct + clues_total),
  CONTROL_AHA = list(denom = "tratado",      f = ~ sexo_f + edad + escolaridad_f + estrato_f + pobreza_pct + clues_total)
)

resumen_cobertura <- list()

for (nombre in names(especificaciones)) {
  e <- especificaciones[[nombre]]
  cat(sprintf("\n=== %s ===\n", nombre))
  m <- readRDS(file.path(RES, paste0("modelo_FINAL_", nombre, ".rds")))

  # celdas utilizables: las que tienen todas las covariables del modelo
  ps_m <- ps
  if ("pobreza_pct" %in% all.vars(e$f)) ps_m <- ps_m %>% filter(!is.na(pobreza_pct))
  if ("clues_total" %in% all.vars(e$f)) ps_m <- ps_m %>% filter(!is.na(clues_total))

  X <- model.matrix(e$f, data = ps_m)

  t0 <- Sys.time()
  smp <- inla.posterior.sample(N_MUESTRAS, m, verbose = FALSE)
  nm <- rownames(smp[[1]]$latent)

  # efectos fijos: INLA los nombra igual que model.matrix, con sufijo ":1"
  idx_b <- match(paste0(colnames(X), ":1"), nm)
  if (any(is.na(idx_b))) {
    stop("No se localizaron en la posterior los efectos fijos: ",
         paste(colnames(X)[is.na(idx_b)], collapse = ", "))
  }
  # BYM2: el latente trae 2n nodos; los PRIMEROS n son el efecto total, que es el que entra al
  # predictor lineal (los siguientes n son solo la componente espacial estructurada).
  idx_u_all <- grep("^muni_idx:", nm)
  stopifnot(length(idx_u_all) == 2 * N_MUNI)
  idx_u <- idx_u_all[seq_len(N_MUNI)]

  # EFECTO DE ANIO. El modelo lleva anio_f porque los indicadores de la cascada se mueven de forma
  # apreciable entre rondas (el diagnostico varia 7,4 puntos sin ponderar entre 2022 y 2024) y el
  # 58,6 % de los municipios se observa en UN SOLO anio: sin ese termino, el efecto espacial
  # absorberia una diferencia temporal y la publicaria como diferencia entre lugares.
  #
  # Las celdas censales no tienen anio -- el censo es de 2020 y describe la composicion, no el
  # momento de la medicion. La estimacion municipal que se publica corresponde al PERIODO
  # 2021-2024, que es lo que dice el titulo, asi que se promedia la probabilidad predicha sobre los
  # cuatro anios. Como anio_f entra de forma aditiva en la escala del logit, no hace falta replicar
  # las celdas: basta sumar el coeficiente del anio al predictor lineal y promediar las cuatro
  # probabilidades resultantes (el anio de referencia aporta 0).
  idx_anio <- grep("^anio_f", nm)
  if (length(idx_anio) == 0) stop("El modelo ", nombre, " no tiene anio_f: reajustar el paso 08.")
  A <- rbind(0, vapply(smp, function(s) s$latent[idx_anio], numeric(length(idx_anio))))
  n_anios <- nrow(A)
  cat(sprintf("  Efecto de anio en el modelo: %d niveles (%s)\n", n_anios,
              paste(c("referencia", sub(":1$", "", nm[idx_anio])), collapse = ", ")))

  B <- vapply(smp, function(s) s$latent[idx_b], numeric(length(idx_b)))   # p x S
  U <- vapply(smp, function(s) s$latent[idx_u], numeric(N_MUNI))          # N_MUNI x S
  rm(smp); gc(verbose = FALSE)

  # Post-estratificacion dentro de cada muestra de la posterior, por bloques de municipios para
  # no materializar una matriz celdas x muestras de golpe.
  ps_m <- ps_m %>% arrange(muni_idx)
  munis <- unique(ps_m$muni_idx)
  bloques <- split(munis, ceiling(seq_along(munis) / 150))
  prev_post <- matrix(NA_real_, length(munis), N_MUESTRAS,
                      dimnames = list(as.character(munis), NULL))

  for (bl in bloques) {
    sel <- ps_m$muni_idx %in% bl
    Xb <- X[sel, , drop = FALSE]
    d  <- ps_m[sel, ]
    eta <- Xb %*% B + U[d$muni_idx, , drop = FALSE]
    # promedio de la probabilidad sobre los anios, no del predictor lineal: el promedio hay que
    # tomarlo en la escala de la prevalencia, que es la cantidad que se reporta
    p <- 0
    for (k in seq_len(n_anios)) {
      p <- p + plogis(eta + rep(A[k, ], each = nrow(eta)))
    }
    p <- p / n_anios
    pw <- p * d$pob
    num <- rowsum(pw, d$muni_idx)
    den <- rowsum(d$pob, d$muni_idx)
    prev_post[rownames(num), ] <- num / as.vector(den)
    rm(eta, p, pw); gc(verbose = FALSE)
  }
  cat(sprintf("Post-estratificacion sobre %d muestras de la posterior: %.1f min\n",
              N_MUESTRAS, as.numeric(difftime(Sys.time(), t0, units = "mins"))))

  # n directo por municipio: denominador REAL de este paso, para el umbral de divulgacion
  sub <- base %>% filter(.data[[e$denom]], !is.na(.data[[e$denom]]))
  n_directo <- sub %>% count(muni_idx, name = "n_directo")

  nacional <- data.frame(
    muni_idx = as.integer(rownames(prev_post)),
    prev      = rowMeans(prev_post),
    prev_q025 = apply(prev_post, 1, quantile, 0.025),
    prev_q975 = apply(prev_post, 1, quantile, 0.975)) %>%
    left_join(n_directo, by = "muni_idx") %>%
    mutate(fuente = ifelse(is.na(n_directo), "sintetico_postestratificado", "muestra_directa"),
           # Control de divulgacion: en municipios CON muestra real, no se publica la celda si el
           # denominador exacto de ese paso tiene menos de 10 personas encuestadas. Los municipios
           # sin muestra no necesitan el flag: no hay ninguna persona real que proteger ahi.
           suprimir_privacidad = !is.na(n_directo) & n_directo < 10,
           ancho_ic95 = prev_q975 - prev_q025) %>%
    left_join(idx_tabla %>% select(muni_idx, cve_ent, cve_mun, nomgeo), by = "muni_idx")

  n_dir <- sum(nacional$fuente == "muestra_directa")
  n_supr <- sum(nacional$suprimir_privacidad)
  cat(sprintf("Cobertura: %d / %d municipios (%.1f%%) | con muestra directa: %d | suprimidos por privacidad: %d (%.1f%% de los directos)\n",
              nrow(nacional), N_MUNI, 100 * nrow(nacional) / N_MUNI, n_dir, n_supr,
              100 * n_supr / max(n_dir, 1)))
  cat(sprintf("Ancho IC95%%: mediana %.1f pp (directos %.1f, post-estratificados %.1f)\n",
              100 * median(nacional$ancho_ic95),
              100 * median(nacional$ancho_ic95[nacional$fuente == "muestra_directa"]),
              100 * median(nacional$ancho_ic95[nacional$fuente != "muestra_directa"])))

  write.csv(nacional, file.path(RES, paste0("NACIONAL_", nombre, ".csv")), row.names = FALSE)
  saveRDS(prev_post, file.path(RES, paste0("posterior_prev_", nombre, ".rds")))

  resumen_cobertura[[nombre]] <- data.frame(
    paso = nombre, n_muestra = n_dir, n_sintetico = nrow(nacional) - n_dir,
    n_total = nrow(nacional), pct_cobertura = round(100 * nrow(nacional) / N_MUNI, 1))
}

cobertura_df <- do.call(rbind, resumen_cobertura)
cat("\n=== RESUMEN DE COBERTURA ===\n")
print(cobertura_df, row.names = FALSE)
write.csv(cobertura_df, file.path(RES, "resumen_cobertura_nacional.csv"), row.names = FALSE)

# =============================================================================================
# 5. RECLASIFICACION ESH vs ACC/AHA
# =============================================================================================
# La diferencia se calcula DENTRO de cada muestra de la posterior, de modo que su intervalo tiene
# en cuenta que los dos modelos comparten el mismo municipio (no son independientes).
reclasificar <- function(a, b, etiqueta) {
  pa <- readRDS(file.path(RES, paste0("posterior_prev_", a, ".rds")))
  pb <- readRDS(file.path(RES, paste0("posterior_prev_", b, ".rds")))
  comunes <- intersect(rownames(pa), rownames(pb))
  d <- 100 * (pb[comunes, ] - pa[comunes, ])
  na <- read_csv(file.path(RES, paste0("NACIONAL_", a, ".csv")), col_types = cols())
  nb <- read_csv(file.path(RES, paste0("NACIONAL_", b, ".csv")), col_types = cols())
  out <- data.frame(muni_idx = as.integer(comunes),
                    diferencia_pp = rowMeans(d),
                    dif_q025 = apply(d, 1, quantile, 0.025),
                    dif_q975 = apply(d, 1, quantile, 0.975)) %>%
    left_join(na %>% select(muni_idx, prev_ESH = prev, fuente_ESH = fuente,
                            priv_ESH = suprimir_privacidad), by = "muni_idx") %>%
    left_join(nb %>% select(muni_idx, prev_AHA = prev, fuente_AHA = fuente,
                            priv_AHA = suprimir_privacidad), by = "muni_idx") %>%
    mutate(ambos_directos = fuente_ESH == "muestra_directa" & fuente_AHA == "muestra_directa",
           suprimir_privacidad = priv_ESH | priv_AHA)

  cat(sprintf("\n=== RECLASIFICACION -- %s ===\n", etiqueta))
  print(out %>% group_by(ambos_directos) %>%
          summarise(n = n(), mediana_pp = median(diferencia_pp), sd_pp = sd(diferencia_pp),
                    min_pp = min(diferencia_pp), max_pp = max(diferencia_pp), .groups = "drop"))
  cat(sprintf("  Global: n=%d mediana=%.2f DE=%.2f | suprimidos por privacidad: %d\n",
              nrow(out), median(out$diferencia_pp), sd(out$diferencia_pp),
              sum(out$suprimir_privacidad)))
  out %>% left_join(idx_tabla %>% select(muni_idx, cve_ent, cve_mun, nomgeo), by = "muni_idx")
}

write.csv(reclasificar("AWARE_ESH", "AWARE_AHA", "Diagnostico (ESH vs AHA)"),
          file.path(RES, "NACIONAL_reclasificacion_conciencia_ESH_vs_AHA.csv"), row.names = FALSE)
write.csv(reclasificar("CONTROL_ESH", "CONTROL_AHA", "Control (ESH vs AHA)"),
          file.path(RES, "NACIONAL_reclasificacion_control_ESH_vs_AHA.csv"), row.names = FALSE)

cat("\nGuardado: NACIONAL_<paso>.csv (x5), NACIONAL_reclasificacion_*.csv,\n")
cat("          postestratificacion_censal.csv, posterior_prev_<paso>.rds (x5)\n")
