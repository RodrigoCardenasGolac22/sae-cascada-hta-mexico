# Checklist STROBE (estudio transversal) en .xlsx editable, para que el autor pueda ajustarlo
# Sec 5: toda tabla entregable en formato editable). Los 22 items y su texto de recomendacion son
# COPIA VERBATIM del checklist oficial descargado directo de equator-network.org (STROBE_checklist
# v4_cross-sectional.pdf, von Elm et al. 2007) -- NO parafraseados de memoria, traducidos con
# cuidado de no alterar el alcance de cada item. La columna "Ubicacion en el manuscrito" es el
# valor real de este documento: cruza cada item contra la seccion/subseccion real donde SI se
# cumple en MANUSCRITO_BORRADOR.md (verificado leyendo el manuscrito, no asumido).

library(writexl)

TAB <- "TABLAS"
if (!dir.exists(TAB)) dir.create(TAB)

strobe <- data.frame(
  Sección = c(
    "Título y resumen", "Título y resumen",
    "Introducción", "Introducción",
    "Métodos", "Métodos", "Métodos", "Métodos", "Métodos", "Métodos", "Métodos",
    "Métodos", "Métodos", "Métodos", "Métodos", "Métodos", "Métodos",
    "Resultados", "Resultados", "Resultados", "Resultados", "Resultados", "Resultados",
    "Resultados", "Resultados", "Resultados",
    "Discusión", "Discusión", "Discusión", "Discusión",
    "Otra información"
  ),
  Ítem = c(
    "1a", "1b",
    "2", "3",
    "4", "5", "6a", "7", "8*", "9", "10",
    "11", "12a", "12b", "12c", "12d", "12e",
    "13a", "13b", "13c", "14a", "14b", "15*",
    "16a", "16b", "17",
    "18", "19", "20", "21",
    "22"
  ),
  Recomendación = c(
    "Indique el diseño del estudio con un término de uso común en el título o el resumen.",
    "Proporcione en el resumen un resumen informativo y equilibrado de lo que se hizo y se encontró.",
    "Explique los antecedentes científicos y la justificación de la investigación.",
    "Indique los objetivos específicos, incluida cualquier hipótesis preespecificada.",
    "Presente los elementos clave del diseño del estudio al inicio del artículo.",
    "Describa el entorno, las ubicaciones y las fechas relevantes, incluidos los períodos de reclutamiento, exposición y recolección de datos.",
    "Indique los criterios de elegibilidad y las fuentes y métodos de selección de los participantes.",
    "Defina claramente todos los desenlaces, exposiciones, predictores, posibles factores de confusión y modificadores de efecto. Indique los criterios diagnósticos, si corresponde.",
    "Para cada variable de interés, indique las fuentes de datos y los detalles de los métodos de medición.",
    "Describa los esfuerzos realizados para abordar posibles fuentes de sesgo.",
    "Explique cómo se determinó el tamaño del estudio.",
    "Explique cómo se manejaron las variables cuantitativas en los análisis; si corresponde, describa qué agrupaciones se eligieron y por qué.",
    "Describa todos los métodos estadísticos, incluidos los usados para controlar la confusión.",
    "Describa cualquier método usado para examinar subgrupos e interacciones.",
    "Explique cómo se abordaron los datos faltantes.",
    "Si corresponde, describa los métodos analíticos que tienen en cuenta la estrategia de muestreo.",
    "Describa cualquier análisis de sensibilidad.",
    "Reporte el número de individuos en cada etapa del estudio (elegibles, examinados, incluidos, analizados); considere un diagrama de flujo.",
    "Indique las razones de la no participación en cada etapa.",
    "Considere el uso de un diagrama de flujo.",
    "Dé las características de los participantes del estudio (demográficas, clínicas, sociales) e información sobre exposiciones y posibles factores de confusión.",
    "Indique el número de participantes con datos faltantes para cada variable de interés.",
    "Reporte el número de eventos del desenlace o medidas resumen.",
    "Dé estimaciones no ajustadas y, si corresponde, ajustadas por factores de confusión, con su precisión (ej. intervalo de confianza/credibilidad del 95%).",
    "Reporte los límites de categoría cuando las variables continuas fueron categorizadas.",
    "Reporte otros análisis realizados (subgrupos, interacciones, análisis de sensibilidad).",
    "Resuma los resultados clave en relación con los objetivos del estudio.",
    "Discuta las limitaciones del estudio, considerando fuentes de sesgo o imprecisión potenciales.",
    "Dé una interpretación general cautelosa de los resultados considerando objetivos, limitaciones, multiplicidad de análisis y evidencia de estudios similares.",
    "Discuta la generalizabilidad (validez externa) de los resultados del estudio.",
    "Indique la fuente de financiamiento y el papel de los financiadores en el presente estudio."
  ),
  `Ubicación en el manuscrito` = c(
    "Resumen/Abstract: \"Estudio ecológico transversal, análisis secundario\"",
    "Resumen (español) y Abstract (inglés), estructurados en Objetivos/Materiales y métodos/Resultados/Conclusiones",
    "Introducción, párrafos 1-3 (vacío de conocimiento, antecedente INEGI, cascada nacional-estatal ya documentada)",
    "Introducción, párrafo final",
    "Materiales y métodos > Diseño y fuente de datos",
    "Materiales y métodos > Diseño y fuente de datos (ENSANUT Continua 2021-2024, México)",
    "Materiales y métodos > Diseño muestral complejo; Figura 1 (flujo STROBE)",
    "Materiales y métodos > Definición operacional de la cascada; Covariables",
    "Materiales y métodos > Diseño y fuente de datos (metodología ENSANUT, referencia 12)",
    "Discusión > Limitaciones (submuestra con presión arterial medida, 43,5% de los entrevistados); Materiales y métodos > Diseño muestral complejo (calibración del ponderador y validación contra el ponderador de tensión arterial de 2023)",
    "Materiales y métodos > Diseño y fuente de datos; Resultados > Muestra (n=25 089)",
    "Materiales y métodos > Covariables; Modelo estadístico",
    "Materiales y métodos > Modelo estadístico (BYM2 vía INLA)",
    "No aplica — no se examinaron subgrupos por interacción en el modelo principal (declarado como alcance del estudio)",
    "Resultados > Muestra (ninguna covariable demográfica tuvo dato faltante en la base analítica); Materiales y métodos > Covariables (definición del nivel 'sin escolaridad')",
    "Materiales y métodos > Diseño muestral complejo",
    "Materiales y métodos > Reclasificación y validación (sensibilidad a matriz de vecindad); Figura S1 (validación cruzada)",
    "Figura 1 (diagrama de flujo STROBE completo)",
    "Figura 1 (cada exclusión con su n)",
    "Figura 1",
    "Resultados > Muestra; Tabla 1",
    "Resultados > Muestra (0 registros con covariable demográfica faltante); Figura 1 (flujo con el n de cada exclusión)",
    "Resultados > Prevalencia nacional y comparación con literatura",
    "Resultados > Modelos municipales; Figura 2; Tabla 2 (IC95%/credibilidad)",
    "Materiales y métodos > Definición operacional de la cascada (umbrales ESH/ACC-AHA)",
    "Resultados > Reclasificación ESH vs. ACC/AHA; Validación cruzada; Figura 3; Figura S1",
    "Discusión, primer párrafo",
    "Discusión > Limitaciones",
    "Discusión (interpretación general, cierre de cada hallazgo)",
    # Se referencia por CONTENIDO, no por ordinal. Decia "octavo punto" y dejo de ser cierto en
    # cuanto el commit cd0d866 inserto un "Quinto" (asimetria del componente no estructurado) y
    # corrio toda la numeracion: la generalizabilidad paso a ser el noveno, y el checklist
    # -- que es lo que el editor usa para comprobar el reporte -- siguio apuntando al octavo,
    # que habla de la busqueda bibliografica. Un ordinal se rompe cada vez que la lista crece.
    "Discusión > Limitaciones, punto sobre la especificidad del contexto mexicano y su aplicabilidad a otros sistemas de salud",
    "Primera página (Financiamiento: \"no se recibió financiamiento específico\")"
  ),
  stringsAsFactors = FALSE
)

# writexl, no openxlsx: openxlsx 4.2.8.1 declara en los rels de la hoja un xl/drawings/drawing1.xml
# que no escribe, y Excel pide "reparar" al abrir el archivo. El checklist es un documento
# OBLIGATORIO del envio, asi que no puede llegar corrupto al editor.
strobe_xlsx <- rbind(strobe,
                     setNames(data.frame("Fuente: STROBE Statement checklist v4, cross-sectional studies (von Elm et al. 2007), descargado de equator-network.org. *Dar información por separado para grupos expuestos y no expuestos, si aplica.", "", "", ""), names(strobe)))
writexl::write_xlsx(list(STROBE = strobe_xlsx), file.path(TAB, "STROBE_checklist.xlsx"))

write.csv(strobe, file.path(TAB, "STROBE_checklist.csv"), row.names = FALSE)

cat("Guardado: TABLAS/STROBE_checklist.xlsx (editable) + .csv\n")
cat("Items totales:", nrow(strobe), "(22 items STROBE, algunos con sub-items a-e)\n")
