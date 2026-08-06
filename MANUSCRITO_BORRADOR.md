<!--SOLO:EXTENSA-->
<!--
Fuente del manuscrito. El .docx se genera desde este archivo con CODIGO/19_manuscrito_docx.R;
no editar el .docx a mano.

Requisitos de formato aplicados (los de la revista de destino; ver la configuracion del envio):
  - Resumen <= 250 palabras; contenido <= 4000 palabras; <= 35 referencias.
  - Máximo 6 tablas y figuras COMBINADAS en el cuerpo principal; el material suplementario
    se envía como archivo aparte y no cuenta contra ese límite.
  - Estructura: Primera página, Título, Resumen, Palabras clave, Mensajes clave (3 párrafos,
    100 palabras, lenguaje no especializado), Introducción, Materiales y métodos, Resultados,
    Discusión, Expresiones de gratitud, Referencias.
  - Arial 10, interlineado 1.5. Coma decimal en el texto en español; punto decimal en el
    texto en inglés.
  - Palabras clave de los tesauros DeCS (español) y MeSH (inglés). Las seis parejas se
    verificaron una por una contra ambos tesauros y comparten identificador, es decir, cada
    término en español y su equivalente en inglés designan el mismo descriptor:
    hipertensión / hypertension (D006973), atención a la salud / delivery of health care
    (D003695), análisis de área pequeña / small-area analysis (D017062), teorema de Bayes /
    Bayes theorem (D001499), análisis espacial / spatial analysis (D062206), México / Mexico
    (D008800).
  - Referencias en Vancouver, numeradas por orden de aparición, con DOI.
-->
<!--/SOLO-->

<!--SOLO:BREVE-->
<!--
Fuente del manuscrito. El .docx se genera desde este archivo con CODIGO/19_manuscrito_docx.R;
no editar el .docx a mano.

Requisitos de formato aplicados (los de la revista de destino; ver la configuracion del envio):
  - Resumen <= 200 palabras; contenido <= 4000 palabras INCLUIDAS las referencias.
  - Máximo 5 tablas y figuras COMBINADAS. La revista no aloja material suplementario: los
    anexos viven en el repositorio publico y el texto remite a el.
  - Las tablas del cuerpo se rotulan "Cuadro" con numeral romano (lo aplica CODIGO/18b para
    las menciones y CODIGO/19 para las leyendas).
  - Citas numericas en superindice SIN parentesis. Titulo corto <= 5 palabras.
  - Estructura: Primera página, Título, Resumen, Palabras clave, Introducción, Materiales y
    métodos, Resultados, Discusión, Expresiones de gratitud, Referencias.
  - Arial 10, interlineado 1.5. Coma decimal en el texto en español; punto decimal en el
    texto en inglés.
  - Palabras clave de los tesauros DeCS (español) y MeSH (inglés); las seis parejas comparten
    identificador (hipertensión/hypertension D006973, atención a la salud/delivery of health
    care D003695, análisis de área pequeña/small-area analysis D017062, teorema de Bayes/Bayes
    theorem D001499, análisis espacial/spatial analysis D062206, México/Mexico D008800).
  - Referencias en Vancouver, numeradas por orden de aparición, con DOI.
-->
<!--/SOLO-->

# Estimación bayesiana de área pequeña de la cascada de atención de la hipertensión arterial en los municipios de México

## Primera página

**Título (inglés):** Bayesian small area estimation of the hypertension care cascade in Mexican
municipalities

<!--SOLO:EXTENSA-->
**Título corto (inglés):** Bayesian mapping of the hypertension care cascade
<!--/SOLO-->

<!--SOLO:BREVE-->
**Título corto (inglés):** Bayesian mapping of hypertension care
<!--/SOLO-->

**Autores:**

Vicente J. Vílchez-Díaz^1,a^ https://orcid.org/0009-0007-3755-8226

Oriana García-Ruiz^2,b^ https://orcid.org/0000-0002-7233-9703

Samar S. Sifuentes-Vidigal^2,b^ https://orcid.org/0009-0006-8564-8317

Miguel A. Velarde-Mera^2,b^ https://orcid.org/0009-0009-6073-9767

Rodrigo J. Cárdenas-Golac^2,c^ https://orcid.org/0009-0005-4444-1523

^1^ Universidad Nacional de Ingeniería (UNI), Lima, Perú. ^2^ Universidad Nacional de la Amazonía
Peruana (UNAP), Iquitos, Perú. ^a^ Bachiller en ciencia de la computación. ^b^ Estudiante de
medicina. ^c^ Médico cirujano.

**Contribuciones de autoría (taxonomía CRediT):** Todos los autores declaran que cumplen los
criterios de autoría recomendados por el ICMJE. Roles según CRediT. VVD: conceptualización,
metodología, software, análisis formal, curación de datos, validación, visualización, redacción –
borrador original, redacción – revisión y edición. OGR: investigación, redacción – borrador
original, redacción – revisión y edición. SSV: investigación, redacción – borrador original. MVM:
investigación, redacción – borrador original. RCG: supervisión, administración del proyecto,
recursos, redacción – revisión y edición.

**Financiamiento:** Los autores declaran no haber recibido financiamiento específico para este
estudio.

**Conflictos de interés:** Los autores declaran no tener conflictos de interés.

**Correspondencia:** Rodrigo J. Cárdenas-Golac, Universidad Nacional de la Amazonía Peruana,
Av. Las Flores 205, Iquitos, Maynas, Loreto, Perú. Teléfono: +51 981 947 739. Correo electrónico:
rodrigo.cardenas@unapiquitos.edu.pe

---

## Resumen

<!--SOLO:EXTENSA-->
**Objetivos.** Estimar la prevalencia municipal de la cascada de atención de la hipertensión
(diagnóstico, tratamiento, control) con un modelo bayesiano de área pequeña post-estratificado
sobre la composición censal, y cuantificar cómo el criterio diagnóstico (ESH 2023 vs. ACC/AHA
2025) reclasifica esas estimaciones.
<!--/SOLO-->

<!--SOLO:BREVE-->
**Objetivos.** Estimar la prevalencia municipal de la cascada de atención de la hipertensión
(diagnóstico, tratamiento, control) en México con un modelo bayesiano de área pequeña
post-estratificado sobre la composición censal.
<!--/SOLO-->

**Materiales y métodos.** Estudio ecológico transversal, análisis secundario de la ENSANUT
Continua 2021-2024 (25 089 adultos ≥20 años, 599 municipios con muestra directa). Se ajustaron modelos BYM2 de
nivel-unidad vía INLA, con covariables de área seleccionadas por un protocolo preespecificado de
WAIC, post-estratificados sobre la composición adulta de cada municipio por sexo, edad y
escolaridad (Censo 2020). Se validó con validación cruzada espacial y comparación contra cifras
publicadas.

<!--SOLO:EXTENSA-->
**Resultados.** La prevalencia directa de hipertensión fue 27,4%; diagnóstico 65,8%, tratamiento
81,0% y control 63,8% (criterio ESH). El modelo cubrió 98,8-99,6% de los 2478 municipios. La
fracción de varianza espacial (Phi) fue 0,06-0,11 en diagnóstico, 0,81 en tratamiento y 0,50-0,67
en control. El coeficiente de pobreza municipal excluyó el cero en los 4 pasos donde el protocolo
la seleccionó. El criterio ACC/AHA redujo la prevalencia suavizada una mediana de 23,0 pp en
diagnóstico y 25,1 pp en control, con variación entre municipios modesta y equivalente con y sin
muestra directa (DE 2,2 y 2,6 pp). La validación cruzada redujo el error 3,0-9,2%.
<!--/SOLO-->

<!--SOLO:BREVE-->
**Resultados.** La prevalencia directa de hipertensión fue 27,4%; diagnóstico 65,8%, tratamiento
81,0% y control 63,8% (criterio ESH). El modelo cubrió 98,8-99,6% de los 2478 municipios. La
fracción de varianza espacial (Phi) fue 0,06-0,11 en diagnóstico, 0,81 en tratamiento y
0,50-0,67 en control. El coeficiente de pobreza municipal excluyó el cero en los 4 pasos donde
el protocolo la seleccionó. La validación cruzada redujo el error 3,0-9,2%.
<!--/SOLO-->

<!--SOLO:EXTENSA-->
**Conclusiones.** Existe una cascada de atención de la hipertensión con brechas municipales en
México, cuantificables con estimación de área pequeña post-estratificada. El criterio diagnóstico
la desplaza de forma amplia y bastante uniforme, no desigual según el lugar.
<!--/SOLO-->

<!--SOLO:BREVE-->
**Conclusiones.** Existe una cascada de atención de la hipertensión con brechas municipales en
México, cuantificables con estimación de área pequeña post-estratificada. El agrupamiento
geográfico se concentra en el tratamiento y el control, no en el diagnóstico.
<!--/SOLO-->

**Palabras clave:** hipertensión; atención a la salud; análisis de área pequeña; teorema de Bayes;
análisis espacial; México.

## Abstract

<!--SOLO:EXTENSA-->
**Objectives.** To estimate municipal-level prevalence of the hypertension care cascade
(awareness, treatment, control) using a Bayesian small area model poststratified on census
composition, and to quantify how the diagnostic threshold (ESH 2023 vs. ACC/AHA 2025) reclassifies
these estimates by location.
<!--/SOLO-->

<!--SOLO:BREVE-->
**Objectives.** To estimate municipal-level prevalence of the hypertension care cascade
(awareness, treatment, control) in Mexico using a Bayesian small area model poststratified on
census composition.
<!--/SOLO-->

**Materials and methods.** Cross-sectional ecological study, secondary analysis of the ENSANUT
Continua 2021-2024 (25,089 adults ≥20 years, 599 municipalities with direct survey data).
Unit-level hierarchical Bayesian BYM2 models were fit via INLA, with area-level covariates
selected via a prespecified WAIC protocol, and poststratified on each municipality's adult population
composition by sex, age and education (2020 Census). Validation included spatial cross-validation
and comparison against published national estimates.

<!--SOLO:EXTENSA-->
**Results.** National direct hypertension prevalence was 27.4%; awareness 65.8%, treatment 81.0%,
and control 63.8% (ESH criterion). The model covered 98.8-99.6% of the country's 2478
municipalities. The structured spatial variance fraction (Phi) was 0.06-0.11 for awareness, 0.81
for treatment and 0.50-0.67 for control. The municipal poverty coefficient excluded zero in the 4
steps where the protocol selected it. The ACC/AHA criterion reduced smoothed prevalence by a median
of 23.0 percentage points (pp) for awareness and 25.1 pp for control versus ESH, with modest
between-municipality variation, equivalent in municipalities with and without direct survey data
(SD 2.2 and 2.6 pp). Cross-validation showed error reductions of 3.0-9.2% versus a naive average.
<!--/SOLO-->

<!--SOLO:BREVE-->
**Results.** National direct hypertension prevalence was 27.4%; awareness 65.8%, treatment 81.0%,
and control 63.8% (ESH criterion). The model covered 98.8-99.6% of the country's 2478
municipalities. The structured spatial variance fraction (Phi) was 0.06-0.11 for awareness, 0.81
for treatment and 0.50-0.67 for control. The municipal poverty coefficient excluded zero in the 4
steps where the protocol selected it. Cross-validation showed error reductions of 3.0-9.2% versus
a naive average.
<!--/SOLO-->

<!--SOLO:EXTENSA-->
**Conclusions.** A hypertension care cascade with municipal gaps exists in Mexico, quantifiable
with poststratified Bayesian small area estimation. The diagnostic threshold shifts the cascade
substantially and fairly uniformly, rather than unequally across locations.
<!--/SOLO-->

<!--SOLO:BREVE-->
**Conclusions.** A hypertension care cascade with municipal gaps exists in Mexico, quantifiable
with poststratified Bayesian small area estimation. Geographical clustering concentrates in
treatment and control rather than awareness.
<!--/SOLO-->

**Keywords:** hypertension; delivery of health care; small-area analysis; Bayes theorem; spatial
analysis; Mexico.

<!--SOLO:EXTENSA-->
## Mensajes clave

**Motivación.** Se conoce la prevalencia nacional de hipertensión en México, pero no había un mapa
municipal de su cascada de atención ni comparación entre los dos criterios diagnósticos vigentes.

**Hallazgos principales.** Se estimó la cascada en casi todos los municipios del país. El
diagnóstico varía poco entre lugares; el tratamiento y el control se agrupan geográficamente de
forma marcada. El criterio más estricto desplaza la cascada de forma amplia y pareja.

**Implicancia de salud pública.** La planeación local debería concentrarse en tratamiento y
control, donde la geografía pesa, y prever que cambiar de criterio desplaza las cifras casi en
bloque.

---
<!--/SOLO-->

## Introducción

<!--SOLO:EXTENSA-->
La hipertensión arterial (HTA) es un factor de riesgo modificable de enfermedad cardiovascular, y
su control efectivo requiere completar una secuencia de pasos —la llamada "cascada de atención"—
desde el diagnóstico (o "conciencia" en el marco internacional
original) hasta el tratamiento y el
control de la presión arterial (1). En México, la Encuesta Nacional de Salud y Nutrición (ENSANUT)
Continua ha documentado esta cascada a nivel nacional y estatal: con datos de 2020-2023, 43,0% de
los adultos con HTA no habían sido diagnosticados y solo 36,3% de los diagnosticados y tratados
tenían la presión arterial controlada (2); con datos de 2021-2024, 37,1% seguían sin diagnóstico y
60,1% de los tratados alcanzaban el control (3).
<!--/SOLO-->

<!--SOLO:BREVE-->
La hipertensión arterial (HTA) es un factor de riesgo modificable de enfermedad cardiovascular, y
su control efectivo requiere completar una secuencia de pasos —la llamada "cascada de atención"—
desde el diagnóstico (o "conciencia" en el marco internacional original) hasta el tratamiento y el
control de la presión arterial (1). En México, la Encuesta Nacional de Salud y Nutrición (ENSANUT)
Continua ha documentado esta cascada a nivel nacional y estatal: con datos de 2021-2024, 37,1% de
los adultos con HTA seguían sin diagnóstico y 60,1% de los tratados alcanzaban el control (3).
<!--/SOLO-->

<!--SOLO:EXTENSA-->
Sin embargo, ninguno de estos análisis resuelve la cascada a nivel municipal, la unidad de
gobierno local desde la que se planifican la mayoría de las intervenciones de salud pública en
México. El Instituto Nacional de Estadística y Geografía (INEGI) sí publicó en 2020
estimaciones municipales de un indicador relacionado con la ENSANUT 2018, por el método Spatial
Empirical Best Linear Unbiased Predictor (4) — antecedente directo, pero que difiere en tres
aspectos: estima un solo indicador, no la cascada condicional; usa un marco frecuentista
(Fay-Herriot espacial), no una distribución posterior; y usa un solo año. Tampoco existe, hasta
donde pudimos verificar, un estudio mexicano que compare la cascada municipal bajo los dos
criterios vigentes —European Society of Hypertension (ESH) 2023, ≥140/90 mmHg (5), y el más
estricto del American College of Cardiology/American Heart Association (ACC/AHA) 2025, ≥130/80
mmHg (6)—, pese a que ese cambio de umbral reclasifica de forma no trivial quién cuenta como
hipertenso, diagnosticado y controlado.
<!--/SOLO-->

<!--SOLO:BREVE-->
Sin embargo, ninguno de estos análisis resuelve la cascada a nivel municipal, la unidad de
gobierno local desde la que se planifican la mayoría de las intervenciones de salud pública en
México. El Instituto Nacional de Estadística y Geografía (INEGI) sí publicó en 2020 estimaciones
municipales de un indicador relacionado con la ENSANUT 2018, por el método Spatial Empirical Best
Linear Unbiased Predictor (4): antecedente directo, pero estima un solo indicador y no la cascada
condicional, en marco frecuentista y limitado a un año. La hipertensión se define aquí bajo los
dos criterios vigentes: European Society of Hypertension (ESH) 2023, ≥140/90 mmHg (5), y el más
estricto del American College of Cardiology/American Heart Association (ACC/AHA) 2025, ≥130/80
mmHg (6).
<!--/SOLO-->

Una búsqueda en PubMed, SciELO y LILACS no halló ningún registro que combine hipertensión,
estimación de área pequeña bayesiana y nivel municipal en México; los más cercanos fueron el
antecedente de INEGI (4) y un estudio de deprivación municipal.

<!--SOLO:EXTENSA-->
Los modelos bayesianos de área pequeña con estructura espacial explícita (Besag-York-Mollié 2,
BYM2) permiten estimar indicadores de salud donde la muestra de encuesta es insuficiente,
aprovechando la correlación entre áreas vecinas y produciendo intervalos de credibilidad explícitos
(7,8). Ahora bien, un modelo ajustado sobre individuos no da por sí solo la prevalencia de un área: hay que
promediar sus predicciones sobre la composición real de esa población, porque con enlace no lineal
la probabilidad del individuo promedio no equivale a la promedio de la población (9). El procedimiento estándar —post-estratificación con regresión multinivel— predice la
probabilidad en cada celda demográfica y la pondera por la población censal de esa celda (10); es
el método con que agencias nacionales publican prevalencias de enfermedad crónica en decenas de
miles de áreas pequeñas (11). El diseño replica el de un estudio análogo del mismo grupo
sobre la cascada de HTA en distritos de Perú, en preparación y aún no publicado, sin su
componente temporal por municipio.
<!--/SOLO-->

<!--SOLO:BREVE-->
Los modelos bayesianos de área pequeña con estructura espacial explícita (Besag-York-Mollié 2,
BYM2) permiten estimar indicadores de salud donde la muestra de encuesta es insuficiente,
aprovechando la correlación entre áreas vecinas y produciendo intervalos de credibilidad
explícitos (7,8). Ahora bien, un modelo ajustado sobre individuos no da por sí solo la prevalencia
de un área: con enlace no lineal, la probabilidad del individuo promedio no equivale a la promedio
de la población (9), de modo que el procedimiento estándar —post-estratificación con regresión
multinivel— predice la probabilidad en cada celda demográfica y la pondera por la población censal
de esa celda (10). El diseño replica el de un estudio análogo del mismo grupo sobre la cascada de
HTA en distritos de Perú, sin su componente temporal por municipio.{{NOTA: Vílchez-Díaz V,
García-Ruiz O, Sifuentes-Vidigal S, Velarde-Mera M, Cárdenas-Golac R. Estimación bayesiana de área
pequeña de la cascada de atención de la hipertensión arterial en los distritos del Perú.
Manuscrito en preparación, no publicado.}}
<!--/SOLO-->

<!--SOLO:EXTENSA-->
El objetivo fue estimar, para cada municipio de México, la prevalencia de cada paso de la cascada
de atención de la HTA en 2021-2024 mediante un modelo BYM2 jerárquico bayesiano de nivel-unidad
post-estratificado sobre la composición censal municipal, y mapear cómo el criterio diagnóstico
(ESH 2023 vs. ACC/AHA 2025) reclasifica esas estimaciones por lugar.
<!--/SOLO-->

<!--SOLO:BREVE-->
El objetivo fue estimar, para cada municipio de México, la prevalencia de cada paso de la cascada
de atención de la HTA en 2021-2024 mediante un modelo BYM2 jerárquico bayesiano de nivel-unidad
post-estratificado sobre la composición censal municipal.
<!--/SOLO-->

## Materiales y métodos

### Diseño y fuente de datos

Estudio ecológico transversal, de estimación de área pequeña, análisis secundario de la ENSANUT
Continua 2021-2024 — las 4 rondas anuales públicas con módulo de enfermedades crónicas y presión
arterial medida (la ronda 2020, especial COVID-19, no incluye estas preguntas). Se usaron el módulo de adultos (diagnóstico y tratamiento
autorreportados) y el de antropometría/tensión arterial (presión medida con esfigmomanómetro
digital Omron HEM907 XL, protocolo de la American Heart Association), enlazados por folio
individual con la geografía del hogar.

### Diseño muestral complejo

Siguiendo la guía metodológica oficial del Instituto Nacional de Salud Pública (12), los años se
trataron como estratos independientes dentro de un diseño complejo combinado
(`svydesign` con conglomerados anidados en `interaction(año, estrato)`), no como un factor de
escala dividido entre los años acumulados.

<!--SOLO:EXTENSA-->
La presión arterial se mide en una submuestra del módulo de adultos, de modo que los ponderadores
originales de ese módulo, aplicados a la muestra analítica, no re-expanden a la población adulta:
sumaban entre 33,1 y 59,8 millones según el año, frente a los 83,5-85,1 millones de adultos
elegibles de cada ronda. Se calibraron por post-estratificación dentro de celdas de año, estrato de
urbanidad, sexo y grupo quinquenal de edad (13). El factor de corrección varió entre 1,12 y 3,67
según la celda: la no respuesta a la medición no fue uniforme. La ronda 2023 —la única— distribuye
un ponderador propio del módulo de tensión arterial, que se usó para validar la calibración: el
calibrado reduce la diferencia media con él de 0,92 a 0,48 puntos porcentuales. Los ponderadores sin calibrar se reportan como sensibilidad
(Tabla S2).
<!--/SOLO-->

<!--SOLO:BREVE-->
La presión arterial se mide en una submuestra del módulo de adultos, de modo que sus ponderadores
originales no re-expanden a la población adulta: sumaban entre 33,1 y 59,8 millones según el año,
frente a los 83,5-85,1 millones de adultos elegibles. Se calibraron por post-estratificación dentro
de celdas de año, estrato de urbanidad, sexo y grupo quinquenal de edad (13), con factores de
corrección de entre 1,12 y 3,67. La ronda 2023, la única con ponderador propio del módulo de
tensión arterial, validó la calibración: el calibrado reduce la diferencia media con él de 0,92 a
0,48 puntos porcentuales. Los ponderadores sin calibrar se reportan como sensibilidad (Tabla S2).
<!--/SOLO-->

### Definición operacional de la cascada

<!--SOLO:EXTENSA-->
La presión arterial se consideró válida por lectura si sistólica ≥80 y diastólica ≥50 mmHg
(criterio oficial ENSANUT), promediando la 2ª y 3ª lectura; las lecturas con sistólica≤diastólica se anularon por
implausibilidad. La HTA se definió como presión arterial medida ≥140/90
mmHg (ESH) o ≥130/80 mmHg (ACC/AHA), o diagnóstico médico previo referido. El diagnóstico previo se definió como
respuesta afirmativa a la pregunta correspondiente, excluyendo el código de diagnóstico exclusivo
del embarazo. El
tratamiento se definió como uso actual referido de medicación antihipertensiva entre los
diagnosticados, y el control como presión por debajo del umbral vigente entre quienes referían
tratamiento; ningún año de ENSANUT pregunta por el control, así que derivarlo de la medición es la
única vía. Los tres pasos quedan anidados. La presión válida se exigió a
toda la muestra analítica, no solo al desenlace de control, congruente con un estudio nacional
previo con los mismos datos (3).
<!--/SOLO-->

<!--SOLO:BREVE-->
La presión arterial se consideró válida por lectura si sistólica ≥80 y diastólica ≥50 mmHg
(criterio oficial ENSANUT), promediando la 2ª y 3ª lectura. La HTA se definió como presión
arterial medida ≥140/90 mmHg (ESH) o ≥130/80 mmHg (ACC/AHA), o diagnóstico médico previo
referido. El diagnóstico previo se definió como respuesta afirmativa a la pregunta
correspondiente, excluyendo el código exclusivo del embarazo. El tratamiento se definió como uso
actual referido de medicación antihipertensiva entre los diagnosticados, y el control como
presión por debajo del umbral vigente entre quienes referían tratamiento; ningún año de ENSANUT
pregunta por el control, así que derivarlo de la medición es la única vía. Los tres pasos quedan
anidados. La presión válida se exigió a toda la muestra analítica, no solo al desenlace de
control (3).
<!--/SOLO-->

<!--SOLO:EXTENSA-->
Esta definición puntual —idéntica en los 4 años, lo que permitió agrupar el periodo— difiere de la
de Campos-Nonato et al. (3), que restringen su cascada a 2023-2024 porque solo esas rondas
identifican uso habitual; aquí se priorizó el tamaño muestral municipal (ver Limitaciones).
<!--/SOLO-->

<!--SOLO:BREVE-->
Esta definición puntual es idéntica en los 4 años, lo que permitió agrupar el periodo y priorizar
el tamaño muestral municipal (ver Limitaciones).
<!--/SOLO-->

Se excluyeron las mujeres con embarazo actual referido y el registro sin ponderador de diseño; el flujo completo de selección está en la Figura 1.

### Covariables

<!--SOLO:EXTENSA-->
Se incluyeron sexo, edad, escolaridad (colapsada en 5 niveles desde el módulo de integrantes del
hogar: sin escolaridad, primaria o menos, secundaria, preparatoria/técnico y superior) y estrato de
urbanidad (rural/urbano/metropolitano, ya incluido en el módulo de adultos) como ajuste demográfico
uniforme en los 5 modelos. El nivel «sin escolaridad» corresponde a un código que el
catálogo oficial no etiqueta y que se verificó contra alfabetismo y edad (68,3% de analfabetismo
frente a 8,7% en primaria; edad mediana 55 años). Como covariables de área candidatas se probaron:
porcentaje de pobreza municipal (Consejo Nacional de Evaluación de la Política de Desarrollo
Social [CONEVAL], 2020), densidad de establecimientos de salud —total y público— (Clave Única de
Establecimientos de Salud [CLUES], filtrada para excluir instituciones no sanitarias), y altitud
media municipal (modelo digital de elevación).
<!--/SOLO-->

<!--SOLO:BREVE-->
Se incluyeron sexo, edad, escolaridad (5 niveles, del módulo de integrantes del hogar: sin
escolaridad, primaria o menos, secundaria, preparatoria/técnico y superior) y estrato de urbanidad
(rural/urbano/metropolitano) como ajuste demográfico uniforme en los 5 modelos. El nivel «sin
escolaridad» corresponde a un código que el catálogo oficial no etiqueta y que se verificó contra
alfabetismo y edad (68,3% de analfabetismo frente a 8,7% en primaria; edad mediana 55 años). Como
covariables de área candidatas se probaron: porcentaje de pobreza municipal (Consejo Nacional de
Evaluación de la Política de Desarrollo Social [CONEVAL], 2020), densidad de establecimientos de
salud —total y público— (Clave Única de Establecimientos de Salud [CLUES], filtrada para excluir
instituciones no sanitarias) y altitud media municipal.
<!--/SOLO-->

### Modelo estadístico

<!--SOLO:EXTENSA-->
Se ajustaron modelos binomiales jerárquicos de nivel-unidad (individuo anidado en municipio) con
un término espacial BYM2 sobre la matriz de vecindad municipal (contigüidad tipo "reina", 2478
municipios), vía la aproximación de Laplace anidada integrada (INLA), con previas penalizadas por complejidad (PC) (14) para la
fracción espacial (Phi) y la precisión total. El grafo resultó conexo: ningún municipio quedó sin vecinos
(mediana 6; mínimo 1), y los insulares —Cozumel e Isla Mujeres— colindan con sus municipios costeros en la
capa del INEGI empleada (Tabla S7). Todos los modelos incluyen el año de la ronda como efecto
fijo: los indicadores se mueven de forma apreciable entre rondas (Tabla S3) y la mayoría de los
municipios se observa en un solo año, de modo que sin ese término el efecto espacial absorbería una
diferencia temporal y la presentaría como diferencia entre lugares. Los modelos se ajustaron sin
los ponderadores del diseño: los tres elementos por los que la selección de la muestra depende del
sujeto —estrato de urbanidad, año y municipio— entran en el modelo, de modo que puede tratarse como
ignorable condicionada a él; las estimaciones nacionales directas sí usan el diseño complejo y
sirven de contraste.
<!--/SOLO-->

<!--SOLO:BREVE-->
Se ajustaron modelos binomiales jerárquicos de nivel-unidad (individuo anidado en municipio) con
un término espacial BYM2 sobre la matriz de vecindad municipal (contigüidad tipo "reina", 2478
municipios), vía la aproximación de Laplace anidada integrada (INLA), con previas penalizadas por
complejidad (PC) (14) para la fracción espacial (Phi) y la precisión total. El grafo resultó
conexo: ningún municipio quedó sin vecinos, incluidos los insulares (Tabla S7). Todos los modelos
incluyen el año de la ronda como efecto fijo, porque la mayoría de los municipios se observa en un
solo año y sin ese término el efecto espacial absorbería una diferencia temporal presentándola
como diferencia entre lugares (Tabla S3). Los modelos se ajustaron sin los ponderadores del
diseño: los tres elementos por los que la selección de la muestra depende del sujeto —estrato de
urbanidad, año y municipio— entran en el modelo, de modo que puede tratarse como ignorable
condicionada a él; las estimaciones nacionales directas sí usan el diseño complejo.
<!--/SOLO-->

<!--SOLO:EXTENSA-->
La selección de covariables de área siguió un protocolo preespecificado: cada candidata se probó
contra el modelo base y se incluyó si mejoraba el criterio de información ampliamente aplicable (WAIC) en al menos 2 unidades. Ese umbral no está
calibrado frente a la incertidumbre de la propia diferencia, así que se reporta además el error
estándar de cada ΔWAIC, obtenido de las contribuciones punto por punto de ambos modelos sobre las
mismas observaciones (15), y el coeficiente posterior de cada covariable (Tabla S4). Las
afirmaciones de asociación se apoyan en el coeficiente y su intervalo, no en la selección: el ΔWAIC
solo responde si la variable mejora la predicción.
<!--/SOLO-->

<!--SOLO:BREVE-->
La selección de covariables de área siguió un protocolo preespecificado: cada candidata se probó
contra el modelo base y se incluyó si mejoraba el criterio de información ampliamente aplicable
(WAIC) en al menos 2 unidades. Ese umbral no está calibrado frente a la incertidumbre de la propia
diferencia, así que se reporta además el error estándar de cada ΔWAIC (15) y el coeficiente
posterior de cada covariable (Tabla S4). Las afirmaciones de asociación se apoyan en el
coeficiente y su intervalo, no en la selección.
<!--/SOLO-->

### Post-estratificación censal y cobertura nacional

<!--SOLO:EXTENSA-->
La prevalencia de cada municipio se obtuvo post-estratificando las predicciones del modelo sobre la
composición de su población adulta (10,11), no evaluándolas en un individuo representativo. Se construyó una tabla de celdas
definidas por sexo, grupo quinquenal de edad (20-24 a 60-64 y 65 o más), escolaridad y estrato de
urbanidad, con la población que el Censo 2020 cuenta en cada celda; se predijo la probabilidad del
desenlace en cada celda y se promedió ponderando por su población. Resultaron 394 514 celdas en 2469
municipios (mediana 190 por municipio), que representan 83,2 millones de adultos. El mismo procedimiento se aplicó a todos los
municipios, tuvieran o no muestra directa; el efecto BYM2 de los que no la tienen se estima por
estructura de vecindad.
<!--/SOLO-->

<!--SOLO:BREVE-->
La prevalencia de cada municipio se obtuvo post-estratificando las predicciones del modelo sobre
la composición de su población adulta (10), no evaluándolas en un individuo representativo. Se
construyó una tabla de celdas definidas por sexo, grupo quinquenal de edad, escolaridad y estrato
de urbanidad, con la población que el Censo 2020 cuenta en cada celda; se predijo la probabilidad
del desenlace en cada celda y se promedió ponderando por su población. El mismo procedimiento se
aplicó a todos los municipios, tuvieran o no muestra directa; el efecto BYM2 de los que no la
tienen se estima por estructura de vecindad.
<!--/SOLO-->

<!--SOLO:EXTENSA-->
El censo publica por localidad los márgenes de sexo × edad y sexo × escolaridad, no la tabla
conjunta; ésta se reconstruyó por ajuste iterativo proporcional (16), con la estructura conjunta
observada en ENSANUT dentro del mismo estrato como semilla. El estrato se obtiene exacto, porque el tabulado
es por localidad y el estrato es función de su tamaño. Del margen de escolaridad, publicado para 15
años y más, se usó solo su forma, aplicada al total de 20 y más; la categoría censal posbásica se
repartió entre preparatoria y superior con la proporción de la encuesta.
<!--/SOLO-->

<!--SOLO:BREVE-->
El censo publica por localidad los márgenes de sexo × edad y sexo × escolaridad, no la tabla
conjunta; ésta se reconstruyó por ajuste iterativo proporcional (16), con la estructura observada
en la encuesta dentro del mismo estrato como semilla.
<!--/SOLO-->

Los intervalos de credibilidad se obtuvieron tomando 1000 muestras de la posterior conjunta y
post-estratificando dentro de cada una, de modo que reflejan la incertidumbre de todos los
parámetros y respetan la correlación entre celdas.

### Reclasificación y validación

<!--SOLO:EXTENSA-->
Se calculó la diferencia de prevalencia suavizada por municipio entre los criterios ESH y ACC/AHA
para diagnóstico y control (el tratamiento es idéntico bajo ambos, porque su definición no depende
del umbral). El modelo se validó con validación cruzada espacial de 5 pliegues por
grupos de municipios (17) comparando el error cuadrático medio (RMSE) y el sesgo contra una línea base
de promedio nacional simple. Se evaluó la
sensibilidad a la definición de la matriz de vecindad ("reina" vs. "torre") en el paso de mayor
fracción espacial, y se compararon las prevalencias nacionales contra las cifras publicadas por
Campos-Nonato et al. (3). Se verificaron los supuestos del modelo (Tabla S5): colinealidad de las
covariables de área, autocorrelación espacial de los residuos, forma del componente no
estructurado y calibración predictiva por la transformada integral de probabilidad (PIT)
aleatorizada (18).
<!--/SOLO-->

<!--SOLO:BREVE-->
Se calculó la diferencia de prevalencia suavizada por municipio entre los criterios ESH y ACC/AHA
para diagnóstico y control (el tratamiento es idéntico bajo ambos, porque su definición no depende
del umbral). El modelo se validó con validación cruzada espacial de 5 pliegues por grupos de
municipios (17), comparando el error cuadrático medio y el sesgo contra un promedio nacional
simple, y se evaluó la sensibilidad a la matriz de vecindad ("reina" vs. "torre"). Se verificaron
los supuestos (Tabla S5): colinealidad, autocorrelación espacial de los residuos, forma del
componente no estructurado y calibración predictiva por la transformada integral de probabilidad
(PIT) aleatorizada (18).
<!--/SOLO-->

<!--SOLO:EXTENSA-->
### Control de divulgación y comunicación de incertidumbre

Se aplicaron dos protecciones para riesgos distintos. Primero, un umbral de control de divulgación:
en los municipios con muestra directa, ninguna estimación basada en menos de 10 encuestados para el
denominador de ese paso se reporta en los mapas ni en las cifras resumen, para evitar la
identificación indirecta desde celdas muy pequeñas; no aplica donde no hay dato individual que
proteger. Segundo, para comunicar la confianza de las
estimaciones —cuyo riesgo no es de identificación sino de sobreinterpretar una predicción
incierta— se generó un mapa con el ancho del intervalo de credibilidad al 95% de cada municipio
(Figura S2), siguiendo la práctica de The DHS Program para superficies modeladas (19).
<!--/SOLO-->

<!--SOLO:BREVE-->
### Control de divulgación y comunicación de incertidumbre

Se aplicaron dos protecciones. En los municipios con muestra directa, ninguna estimación basada en
menos de 10 encuestados en el denominador de ese paso se reporta, para evitar la identificación
indirecta; el umbral no aplica donde no hay dato individual que proteger. Para comunicar la
confianza de cada estimación se generó un mapa del ancho del intervalo de credibilidad al 95 % por
municipio (Figura S2).
<!--/SOLO-->

<!--SOLO:EXTENSA-->
### Aspectos éticos

Este es un análisis secundario de microdatos públicos anonimizados de ENSANUT, sin identificadores
individuales, descargables en https://ensanut.insp.mx/. Por tratarse de una base secundaria de una
encuesta nacional de acceso público, el estudio no requirió aprobación de un comité de ética
institucional, conforme a la política editorial de la revista para este tipo de fuentes. Los procedimientos de entrevista y los formatos de consentimiento de la ENSANUT
fueron revisados por las Comisiones de Ética, Investigación y Bioseguridad del Instituto Nacional
de Salud Pública (12). Se verificó en los microdatos de los 4 años que ningún
archivo distribuye coordenadas ni identificador de geolocalización: `municipio` es la máxima
resolución geográfica pública y la unidad primaria de muestreo es un código administrativo, no una
coordenada. Los autores no recolectaron datos primarios ni contactaron a los participantes.
<!--/SOLO-->

<!--SOLO:BREVE-->
### Aspectos éticos

Análisis secundario de microdatos públicos anonimizados de la ENSANUT (https://ensanut.insp.mx/),
sin identificadores individuales ni coordenadas: el municipio es la máxima resolución geográfica
que se distribuye. Por tratarse de una base secundaria de acceso público, el estudio no requirió
aprobación de un comité de ética. Los procedimientos de entrevista y los formatos de consentimiento
de la ENSANUT fueron revisados por las Comisiones de Ética, Investigación y Bioseguridad del
Instituto Nacional de Salud Pública (12).
<!--/SOLO-->

<!--SOLO:EXTENSA-->
### Software

Todo el análisis se realizó en R 4.6.0 (20) con los paquetes `survey` 4.5 (diseño muestral
complejo) (21), `INLA` 25.10.19 (modelos bayesianos) (22), `spdep` 1.4-2 (23) y `sf` 1.1-1 (24)
(vecindad y geometría), `haven` 2.5.5 (microdatos en formato Stata), `dplyr` 1.2.1, `readr`
2.2.0 y `tidyr` 1.3.2 (manejo de datos) y `ggplot2` 4.0.3 (25) con `ggspatial` 1.1.10 y
`patchwork` 1.3.2 (figuras). El código y el entorno completo están en el
repositorio indicado en la sección de disponibilidad de datos y código.
<!--/SOLO-->

<!--SOLO:BREVE-->
### Software

El análisis se realizó en R 4.6.0 (20) con `survey` 4.5 para el diseño muestral complejo (21) e
`INLA` 25.10.19 para los modelos bayesianos (22); el resto de paquetes, con sus versiones, y el
entorno completo constan en el repositorio.
<!--/SOLO-->

## Resultados

### Muestra

<!--SOLO:EXTENSA-->
De 45 011 adultos entrevistados en 2021-2024, 25 089 (599 municipios distintos) formaron la base
analítica final tras aplicar las exclusiones de presión arterial válida (n=19 600 excluidos),
embarazo actual (n=321) y peso de diseño faltante (n=1 caso) (Figura 1, Tabla 1). De estos, 7 756
tenían HTA bajo criterio ESH (11 611 bajo ACC/AHA); 5 204 estaban diagnosticados y 4 389 en
tratamiento. Ninguna de las cuatro covariables demográficas tuvo dato faltante, de modo que
los modelos no descartaron observaciones por ese motivo.
<!--/SOLO-->

<!--SOLO:BREVE-->
De 45 011 adultos entrevistados en 2021-2024, 25 089 (599 municipios distintos) formaron la base
analítica final tras excluir presión arterial no válida (n=19 600), embarazo actual (n=321) y peso
de diseño faltante (n=1) (Figura 1, Tabla 1). De estos, 7 756 tenían HTA bajo criterio ESH (11 611
bajo ACC/AHA); 5 204 estaban diagnosticados y 4 389 en tratamiento. Ninguna de las cuatro
covariables demográficas tuvo dato faltante.
<!--/SOLO-->

### Prevalencia nacional y comparación con literatura

<!--SOLO:EXTENSA-->
La prevalencia directa nacional de HTA-ESH fue 27,4% (intervalo de confianza al 95% [IC95%]:
26,3-28,5), frente al 29,1-29,4%
reportado por Campos-Nonato et al. con los mismos datos (3) (Tabla S6). El diagnóstico previo
(65,8%, 63,6-67,9) y el control bajo criterio ESH (63,8%, 61,1-66,4) fueron 2,9 y 3,7 puntos
porcentuales más altos que los de ese estudio nacional, y la prevalencia 1,7-2,0 puntos más baja.
Tres diferencias metodológicas explican el sentido de esas brechas: la definición puntual de
tratamiento frente a la de uso habitual —que eleva diagnóstico y control—, la calibración del
ponderador y el promedio de la 2ª y 3ª lectura en vez de las dos primeras —que bajan la
prevalencia—. El promedio nacional de los 5
modelos coincidió con la estimación directa dentro de 1,6 puntos porcentuales en todos los pasos
(Tabla 2):
el suavizado y la post-estratificación no distorsionan el agregado nacional.
<!--/SOLO-->

<!--SOLO:BREVE-->
La prevalencia directa nacional de HTA-ESH fue 27,4% (intervalo de confianza al 95% [IC95%]:
26,3-28,5), frente al 29,1-29,4% reportado por Campos-Nonato et al. con los mismos datos (3)
(Tabla S6). El diagnóstico previo (65,8%, 63,6-67,9) y el control-ESH (63,8%, 61,1-66,4) fueron 2,9
y 3,7 puntos porcentuales (pp) más altos que en ese estudio, y la prevalencia 1,7-2,0 pp más baja.
Tres diferencias metodológicas explican el sentido de las brechas: la definición puntual de
tratamiento frente a la de uso habitual —que eleva diagnóstico y control—, la calibración del
ponderador y el promedio de la 2ª y 3ª lectura en vez de las dos primeras —que bajan la
prevalencia—. El promedio nacional de los 5 modelos coincidió con la estimación directa dentro de
1,6 pp en todos los pasos (Tabla 2).
<!--/SOLO-->

### Modelos municipales

<!--SOLO:EXTENSA-->
Los 5 modelos finales (con las covariables de área seleccionadas por protocolo)
convergieron sin fallos de validación cruzada interna (Tabla S1, material suplementario). La
fracción de varianza espacial estructurada (Phi) fue baja en diagnóstico —0,11 bajo criterio ESH
(IC95%: 0,01-0,50) y 0,06 bajo ACC/AHA (0,00-0,54)— y alta a moderada en los dos pasos
posteriores: 0,81 en tratamiento (0,35-0,98), 0,67 en control-ESH (0,15-0,97) y 0,50 en
control-AHA (0,13-0,89).
<!--/SOLO-->

<!--SOLO:BREVE-->
Los 5 modelos finales convergieron sin fallos de validación cruzada interna. La fracción de
varianza espacial estructurada (Phi) fue baja en diagnóstico (0,06-0,11) y alta a moderada en los
dos pasos posteriores: 0,81 en tratamiento y 0,50-0,67 en control (Tabla S1).
<!--/SOLO-->

<!--SOLO:EXTENSA-->
El protocolo seleccionó la pobreza municipal en 4 de los 5 modelos —diagnóstico bajo ambos
criterios, control-ESH y control-AHA— y la densidad de establecimientos de salud en 3; la altitud,
en ninguno. En tratamiento ninguna candidata alcanzó el umbral y su modelo quedó sin covariables de
área: pese a ser el paso con mayor agrupamiento espacial, ninguna variable municipal probada lo
explica. Ninguna mejora de WAIC alcanzó dos errores estándar (máximo 1,7; Tabla
S4): las ganancias predictivas son pequeñas frente a su incertidumbre y la especificación elegida
apenas altera las estimaciones municipales. Las dos diferencias que sí los superan son deterioros
de la altitud.
<!--/SOLO-->

<!--SOLO:BREVE-->
El protocolo seleccionó la pobreza municipal en 4 de los 5 modelos —diagnóstico bajo ambos
criterios, control-ESH y control-AHA— y la densidad de establecimientos de salud en 3; la altitud,
en ninguno. En tratamiento ninguna candidata alcanzó el umbral y su modelo quedó sin covariables de
área: pese a ser el paso con mayor agrupamiento espacial, ninguna variable municipal probada lo
explica. Ninguna mejora de WAIC alcanzó dos errores estándar (máximo 1,7; Tabla S4) y las dos
diferencias que sí los superan son deterioros de la altitud: la especificación elegida apenas
altera las estimaciones municipales.
<!--/SOLO-->

<!--SOLO:EXTENSA-->
La evidencia de asociación la aporta el coeficiente. El de pobreza excluyó el cero en los cuatro
modelos que la incluyen: por cada 10 puntos porcentuales más de pobreza municipal, la razón de
momios osciló entre 0,92 y 0,95 (IC95% entre 0,87 y 0,99), con probabilidad posterior de efecto
negativo de 0,98 o mayor en los cuatro. El de establecimientos de salud lo excluyó en uno solo
de los tres, de modo que este trabajo no sustenta una asociación con esa densidad. El año sí mostró
efectos claros: frente a 2021, la razón de momios de 2024 fue 1,20 (1,03-1,40) en diagnóstico-ESH,
1,44 (1,19-1,73) en control-ESH y 1,47 (1,23-1,76) en control-AHA (Tabla S3).
<!--/SOLO-->

<!--SOLO:BREVE-->
La evidencia de asociación la aporta el coeficiente. El de pobreza excluyó el cero en los cuatro
modelos que la incluyen: por cada 10 pp más de pobreza municipal la razón de momios osciló entre
0,92 y 0,95, con probabilidad posterior de efecto negativo de 0,98 o mayor. El de establecimientos
de salud lo excluyó en uno solo de los tres, de modo que este trabajo no sustenta esa asociación.
El año mostró efectos claros: razones de momios de 2024 frente a 2021 de entre 1,20 y 1,47 en los
pasos donde el intervalo excluye el 1 (Tabla S3).
<!--/SOLO-->

### Mapa municipal de la cascada y cobertura nacional

<!--SOLO:EXTENSA-->
El modelo alcanzó cobertura en 98,8-99,6% de los 2478 municipios (Figura 2), más allá de los
557-593 con muestra directa. La sensibilidad a la definición de la matriz de
vecindad (reina vs. torre), probada en el paso de mayor Phi (tratamiento), fue mínima: diferencia
de WAIC de 0,24 y de Phi inferior a 0,01.
<!--/SOLO-->

<!--SOLO:BREVE-->
El modelo alcanzó cobertura en 98,8-99,6% de los 2478 municipios (Figura 2), más allá de los
557-593 con muestra directa. La sensibilidad a la matriz de vecindad (reina vs. torre), probada en
tratamiento —el paso de mayor Phi—, fue mínima: 0,24 de diferencia de WAIC y menos de 0,01 de Phi.
<!--/SOLO-->

<!--SOLO:EXTENSA-->
Por el umbral de control de divulgación (n<10, ver Métodos) quedaron sin reportar en la Figura 2,
entre los municipios con muestra directa, 348 de 587 (59,3%) en diagnóstico, 429 de 576 (74,5%) en
tratamiento y 437 de 557 (78,5%) en control: el denominador de tratamiento y control es una
submuestra pequeña dentro de cada municipio.
<!--/SOLO-->

<!--SOLO:BREVE-->
Por el umbral de control de divulgación (n<10, ver Métodos) quedaron sin reportar en la Figura 2,
entre los municipios con muestra directa, 348 de 587 (59,3%) en diagnóstico, 429 de 576 (74,5%) en
tratamiento y 437 de 557 (78,5%) en control.
<!--/SOLO-->

<!--SOLO:EXTENSA-->
El ancho del intervalo de credibilidad al 95% (Figura S2) tuvo una mediana de 27,4 puntos
porcentuales (pp) en
diagnóstico-ESH, 26,0 pp en tratamiento y 17,2 pp en control-ESH, con un máximo de 53,8 pp. La diferencia entre municipios con y sin muestra directa fue
pequeña (25,3 frente a 27,8 pp en diagnóstico-ESH): la incertidumbre dominante viene de los
parámetros del modelo, no de disponer o no de observaciones locales.
<!--/SOLO-->

<!--SOLO:BREVE-->
El ancho del intervalo de credibilidad al 95% (Figura S2) tuvo una mediana de 27,4 pp en
diagnóstico-ESH, 26,0 pp en tratamiento y 17,2 pp en control-ESH, con un máximo de 53,8 pp. La
diferencia entre municipios con y sin muestra directa fue pequeña (25,3 frente a 27,8 pp en
diagnóstico-ESH): la incertidumbre dominante viene de los parámetros del modelo, no de las
observaciones locales.
<!--/SOLO-->

### Reclasificación ESH vs. ACC/AHA

<!--SOLO:EXTENSA-->
El criterio ACC/AHA redujo la prevalencia suavizada de diagnóstico una mediana de 23,0 pp frente
a ESH (rango municipal -40,9 a -10,3 pp, desviación estándar [DE] 2,5 pp, n=2448 municipios) y
la de control una mediana de 25,1 pp (rango -32,3 a -17,3 pp, DE 1,6 pp, n=2448) (Figura 3) — en la dirección esperada
por definición: el umbral más bajo clasifica como hipertensas a más personas, inflando el
denominador sin inflar el numerador.
<!--/SOLO-->

<!--SOLO:BREVE-->
Bajo el criterio ACC/AHA la prevalencia suavizada baja una mediana de 23,0 pp en diagnóstico y
25,1 pp en control (DE 2,5 y 1,6 pp): el umbral más bajo desplaza la cascada de forma pareja, sin
reordenar a los municipios entre sí, en la dirección esperada por definición. La mediana fue
idéntica con y sin muestra directa en diagnóstico (-23,0 pp en ambos) y casi idéntica en control
(-25,3 frente a -25,0 pp).
<!--/SOLO-->

<!--SOLO:EXTENSA-->
El desplazamiento fue amplio pero parejo. En diagnóstico, la mediana fue idéntica con y sin muestra
directa (-23,0 pp en ambos) y su dispersión equivalente (DE 2,2, n=586, frente a 2,6, n=1862); en
control, -25,3 pp (DE 2,2) y -25,0 pp (DE 1,4). Que coincidan verifica internamente el
procedimiento: unos aportan observaciones propias y los otros no, y dan la misma magnitud. La
variación relevante está en los extremos, no en una separación sistemática entre territorios.
<!--/SOLO-->

### Validación cruzada

<!--SOLO:EXTENSA-->
El modelo BYM2 superó a un promedio nacional simple no ajustado en las 5 comparaciones, con
reducciones de RMSE de 7,2% (diagnóstico-ESH), 9,2% (diagnóstico-AHA), 8,9% (tratamiento), 3,7%
(control-ESH) y 3,0% (control-AHA) (Figura S1, material suplementario), y sesgo menor en valor absoluto (0,1-2,1 puntos
porcentuales frente a 0,8-3,2 del promedio simple, siempre positivo). La ganancia fue más modesta en control, el paso
con menor tamaño muestral municipal. Los supuestos se sostienen (Tabla S5): sin colinealidad
(factor de inflación de la varianza ≤1,1), sin autocorrelación espacial residual (I de Moran de
-0,05 a 0,03; p ≥ 0,213) y con PIT aleatorizado uniforme en los cinco modelos.
<!--/SOLO-->

<!--SOLO:BREVE-->
El modelo BYM2 superó a un promedio nacional simple en las 5 comparaciones, con reducciones de
RMSE de 3,0% a 9,2% —más modestas en control, el paso con menor muestra municipal— y sesgo menor
en valor absoluto (Figura S1). Los supuestos se sostienen (Tabla S5): sin colinealidad, sin
autocorrelación espacial residual (p ≥ 0,213) y con PIT aleatorizado uniforme en los cinco modelos.
<!--/SOLO-->

## Discusión

<!--SOLO:EXTENSA-->
Este estudio produjo el primer mapa municipal de la cascada completa de atención de la HTA en
México con marco bayesiano, intervalos de credibilidad, post-estratificación censal y comparación
bajo dos criterios diagnósticos, extendiendo el antecedente de INEGI (4). Sus cifras nacionales
quedaron entre 1,7 y 3,7 pp de las de un estudio independiente con los mismos datos (3), por las
tres decisiones metodológicas ya declaradas y no por los datos de partida.
<!--/SOLO-->

<!--SOLO:BREVE-->
Este estudio produjo el primer mapa municipal de la cascada completa de atención de la HTA en
México con marco bayesiano, intervalos de credibilidad y post-estratificación censal, extendiendo
el antecedente de INEGI (4). Sus cifras nacionales quedaron entre 1,7 y 3,7 pp de las de un estudio
independiente con los mismos datos (3), por las tres decisiones metodológicas ya declaradas y no
por los datos de partida.
<!--/SOLO-->

<!--SOLO:EXTENSA-->
Que la pobreza municipal se asocie con diagnóstico y control pero no con tratamiento, y que
el agrupamiento espacial sea mínimo en el diagnóstico y alto en los pasos que exigen acceso
sostenido a medicación y seguimiento —sin que pobreza, densidad de establecimientos (conteo
simple, no distancia) ni altitud lo expliquen—, es consistente con el patrón descrito en la
cascada del VIH, donde la influencia geográfica se intensifica en las etapas posteriores del
continuo más que en el contacto inicial (26), y con evidencia de que la accesibilidad geográfica a
atención primaria afecta específicamente el tratamiento de la hipertensión (27). Las brechas socioeconómicas y de disponibilidad de medicamentos ya documentadas
en México (28) son un mecanismo plausible, no confirmado aquí: una pregunta abierta.
<!--/SOLO-->

<!--SOLO:BREVE-->
Que la pobreza municipal se asocie con diagnóstico y control pero no con tratamiento, y que el
agrupamiento espacial sea mínimo en el diagnóstico y alto en los pasos que exigen acceso sostenido
a medicación y seguimiento —sin que pobreza, densidad de establecimientos (conteo simple, no
distancia) ni altitud lo expliquen—, es consistente con el patrón descrito en la cascada del VIH,
donde la influencia geográfica se intensifica en las etapas posteriores del continuo (26). Las
brechas socioeconómicas y de disponibilidad de medicamentos ya documentadas en México (28) son un
mecanismo plausible, no confirmado aquí.
<!--/SOLO-->

<!--SOLO:EXTENSA-->
El cambio de criterio desplazó la cascada de forma amplia pero pareja entre municipios. La
implicación práctica es la contraria de la que sugeriría una lectura apresurada del mapa: el
umbral ACC/AHA 2025 reduciría la cobertura aparente de diagnóstico en magnitud similar en casi
todo el país, de modo que las comparaciones entre municipios sobreviven al cambio, mientras que
cualquier meta absoluta de cobertura —del tipo 80-80-80— dejaría de ser comparable con las cifras
del criterio anterior. En personas: los 493 municipios del quintil inferior de diagnóstico —mediana 49,4%, frente a 60,5%
en el superior— reúnen 8,5 millones de adultos, el 10,2% del país. Tan pocos habitantes para tantos
municipios sitúan el déficit en los pequeños: es un problema de equidad territorial, no de volumen.
Esta lectura solo es sostenible porque la estimación se post-estratificó; sin ello, la dispersión
aparente confunde la variación real con la inducida por el método.
<!--/SOLO-->

<!--SOLO:BREVE-->
En personas: los 493 municipios del quintil inferior de diagnóstico —mediana 49,4%, frente a 60,5%
en el superior— reúnen 8,5 millones de adultos, el 10,2% del país. Tan pocos habitantes para tantos
municipios sitúan el déficit en los pequeños: es un problema de equidad territorial, no de volumen.
Esta lectura solo es sostenible porque la estimación se post-estratificó.
<!--/SOLO-->

### Fortalezas

<!--SOLO:EXTENSA-->
El modelo cubre casi todos los municipios del país y declara en cada uno el ancho de su intervalo
de credibilidad (Figura S2), en vez de presentar todas las estimaciones como equivalentes. Se validó de tres formas independientes —validación cruzada espacial, contraste contra un estudio
nacional con los mismos datos, y coincidencia entre municipios con y sin muestra directa—, y el
código completo es público.
<!--/SOLO-->

<!--SOLO:BREVE-->
El modelo cubre casi todos los municipios del país y declara en cada uno el ancho de su intervalo
de credibilidad (Figura S2), en vez de presentar todas las estimaciones como equivalentes. Se
validó de tres formas independientes —validación cruzada espacial, contraste contra un estudio
nacional con los mismos datos y coincidencia entre municipios con y sin muestra directa— y el
código es público.
<!--/SOLO-->

### Limitaciones

<!--SOLO:EXTENSA-->
Este estudio tiene límites. Primero, la presión arterial se mide en una submuestra del módulo de adultos, de modo que 19 600 de los 45 011 entrevistados (43,5%) quedaron
fuera de la muestra analítica. Esa submuestra se selecciona con fracciones de muestreo declaradas, no
según características de salud, y la calibración corrige la no respuesta que depende de sexo, edad,
estrato y año; no puede descartarse que difiera en factores no medidos. Segundo, el diseño rotativo de ENSANUT (la
mayoría de los municipios aparece en un solo año) impide una tendencia temporal por municipio. Los
indicadores no fueron estables en el periodo (Tabla S3), de modo que el año se incluyó como efecto
fijo en todos los modelos y la estimación municipal publicada corresponde al promedio de 2021-2024;
no puede separarse una trayectoria propia de cada municipio. Tercero, la definición de tratamiento (uso
puntual referido) es menos precisa que la de uso habitual de otro estudio con los mismos datos: un
intercambio deliberado a favor del tamaño muestral municipal. Cuarto, la tabla de post-estratificación se reconstruyó
desde los márgenes censales, no desde la tabla conjunta, que no se publica por municipio; y el
margen de escolaridad, disponible para la población de 15 años y más, sesga levemente la
distribución hacia los niveles bajos. Quinto, el componente no estructurado del BYM2 se aparta de la
normalidad que el modelo le supone, con asimetría de 1,1 a 2,5 en cuatro de los cinco modelos, de
modo que los intervalos de los municipios con efectos más extremos pueden quedar mal calibrados.
Sexto, no se intentó un modelo de componente compartido entre los 3 pasos. Séptimo, las asociaciones ecológicas no permiten inferencia
causal a nivel individual. Octavo, la búsqueda de brecha no fue una revisión sistemática.
Noveno, los hallazgos son específicos de México; el patrón general —estructura espacial baja en
diagnóstico y alta en tratamiento y control— es plausible en otros sistemas con gobierno local de
salud, pero no puede asumirse sin verificación.
<!--/SOLO-->

<!--SOLO:BREVE-->
Este estudio tiene límites. Primero, la presión arterial se mide en una submuestra del módulo de
adultos, de modo que 19 600 de los 45 011 entrevistados (43,5%) quedaron fuera de la muestra
analítica; esa submuestra se selecciona con fracciones de muestreo declaradas, no según
características de salud, y la calibración corrige la no respuesta que depende de sexo, edad,
estrato y año, pero no puede descartarse que difiera en factores no medidos. Segundo, el diseño
rotativo de ENSANUT —la mayoría de los municipios aparece en un solo año— impide estimar una
trayectoria propia de cada municipio: como los indicadores no fueron estables en el periodo
(Tabla S3), el año se incluyó como efecto fijo en todos los modelos y la estimación municipal
publicada corresponde al promedio de 2021-2024. Tercero, la definición de tratamiento (uso puntual
referido) es menos precisa que la de uso habitual de otro estudio con los mismos datos: un
intercambio deliberado a favor del tamaño muestral municipal. Cuarto, la tabla de
post-estratificación se reconstruyó desde los márgenes censales, no desde la tabla conjunta, que no
se publica por municipio; y el margen de escolaridad, disponible desde los 15 años, sesga levemente
la distribución hacia los niveles bajos. Quinto, el componente no estructurado del BYM2 se aparta
de la normalidad supuesta, con asimetría de 1,1 a 2,5 en cuatro de los cinco modelos, de modo que
los intervalos de los municipios con efectos más extremos pueden quedar mal calibrados. Sexto, no
se intentó un modelo de componente compartido entre los 3 pasos. Séptimo, las asociaciones
ecológicas no permiten inferencia causal a nivel individual. Octavo, la búsqueda de brecha no fue
una revisión sistemática. Noveno, los hallazgos son específicos de México; el patrón general
—estructura espacial baja en diagnóstico y alta en tratamiento y control— es plausible en otros
sistemas con gobierno local de salud, pero no puede asumirse sin verificación.
<!--/SOLO-->

### Conclusiones

<!--SOLO:EXTENSA-->
La cascada de atención de la hipertensión en México tiene brechas municipales sustanciales, ahora
cuantificables con incertidumbre explícita mediante un modelo bayesiano de área pequeña
post-estratificado. El agrupamiento geográfico se concentra en el tratamiento y el control, no en
el diagnóstico, y no lo explican la pobreza, la densidad de establecimientos ni la altitud: la
planeación local debería atender prioritariamente la continuidad de la atención más que el
contacto inicial. Las comparaciones territoriales son robustas al cambio de umbral diagnóstico;
las metas absolutas de cobertura no lo son.
<!--/SOLO-->

<!--SOLO:BREVE-->
La cascada de atención de la hipertensión en México tiene brechas municipales sustanciales, ahora
cuantificables con incertidumbre explícita mediante un modelo bayesiano de área pequeña
post-estratificado. El agrupamiento geográfico se concentra en el tratamiento y el control, no en
el diagnóstico, y no lo explican la pobreza, la densidad de establecimientos ni la altitud: la
planeación local debería atender prioritariamente la continuidad de la atención.
<!--/SOLO-->

## Expresiones de gratitud

Los autores declaran no tener agradecimientos que declarar.

<!--SOLO:EXTENSA-->
## Disponibilidad de datos y código
Los microdatos de ENSANUT Continua son de acceso público en https://ensanut.insp.mx/ y no se
redistribuyen. El código que reproduce íntegramente el análisis, desde
los microdatos hasta las tablas y figuras, es público en
https://github.com/RodrigoCardenasGolac22/sae-cascada-hta-mexico bajo licencia MIT. La versión
exacta que produjo los resultados aquí presentados está etiquetada como `v1.1`. Las estimaciones de los 2478 municipios, con su intervalo de
credibilidad, se consultan en un mapa interactivo en https://rodrigocardenasgolac22.github.io/sae-cascada-hta-mexico/
<!--/SOLO-->

<!--SOLO:BREVE-->
## Disponibilidad de datos y código

Los microdatos de ENSANUT Continua son de acceso público en https://ensanut.insp.mx/ y no se
redistribuyen. El código que reproduce íntegramente el análisis, desde los microdatos hasta las
tablas y figuras, es público en https://github.com/RodrigoCardenasGolac22/sae-cascada-hta-mexico
bajo licencia MIT; la versión que produjo estos resultados está etiquetada como `v1.1`. Las
estimaciones de los 2478 municipios, con su intervalo de credibilidad, se consultan en
https://rodrigocardenasgolac22.github.io/sae-cascada-hta-mexico/
<!--/SOLO-->

## Declaración de uso de IA

<!--SOLO:EXTENSA-->
Durante la preparación de este trabajo, los autores utilizaron el asistente de inteligencia artificial Claude (Anthropic) con el
fin de asistir en la implementación y depuración del código de análisis estadístico en R, en la
redacción del manuscrito en español y la traducción del resumen y título al inglés (requisito
bilingüe de la revista), y en el formato de las tablas y figuras generadas a partir de los
resultados del análisis. Los autores diseñaron el estudio, ejecutaron y verificaron los análisis, e
interpretaron los resultados; revisaron y editaron íntegramente el contenido producido con esta
asistencia, y asumen la responsabilidad completa por la exactitud, integridad y originalidad del
trabajo.
<!--/SOLO-->

<!--SOLO:BREVE-->
Los autores utilizaron el asistente de inteligencia artificial Claude (Anthropic, modelo Opus 5)
entre el 29 de julio y el 5 de agosto de 2026 para: (a) implementar y depurar el código de
análisis; (b) apoyo de redacción y edición de estilo sobre contenidos definidos por los autores; y
(c) traducir al inglés el título y el resumen. Los autores plantearon la pregunta de investigación,
definieron el diseño y la especificación de los modelos, ejecutaron y verificaron los análisis e
interpretaron los resultados; revisaron todo el contenido y corrigieron los errores detectados en
él. El código y el historial de versiones son públicos, lo que permite verificar cada cifra de
forma independiente. La IA no figura como autora. Los autores asumen la responsabilidad completa
por la exactitud, integridad y originalidad del trabajo.
<!--/SOLO-->

## Referencias bibliográficas

1. Wozniak G, Khan T, Gillespie C, Sifuentes L, Hasan O, Ritchey M, et al. Hypertension Control
   Cascade: A Framework to Improve Hypertension Awareness, Treatment, and Control. J Clin
   Hypertens. 2016;18(3):232-239. doi: 10.1111/jch.12654.
2. Campos-Nonato I, Oviedo-Solís C, Hernández-Barrera L, Márquez-Murillo M, Gómez-Álvarez E,
   Alcocer L, et al. Detección, atención y control de hipertensión arterial. Salud Publica Mex.
   2024;66(4):537-546. doi: 10.21149/15867.
3. Campos-Nonato I, Monterrubio-Flores E, Ramírez-Villalobos D, Arias-Mendoza MA, Gómez-Álvarez E,
   Alcocer-Díaz-Barreiro L, et al. Hipertensión arterial en adultos y brechas de atención a nivel
   nacional y estatal, Ensanut 2021-2024. Salud Publica Mex. 2025;67(6):633-643. doi: 10.21149/17102.
4. Instituto Nacional de Estadística y Geografía (INEGI). Nota metodológica: Prevalencia de
   Obesidad, Hipertensión y Diabetes para los Municipios de México 2018 — Estimación para Áreas
   Pequeñas [Internet]. Aguascalientes: INEGI; 2020 [cited 2026 Jul 28]. Available from:
   https://inegi.org.mx/contenidos/investigacion/pohd/2018/doc/a_peq_2018_nota_met.pdf
5. Mancia G, Kreutz R, Brunström M, Burnier M, Grassi G, Januszewicz A, et al. 2023 ESH Guidelines
   for the management of arterial hypertension. J Hypertens. 2023;41(12):1874-2071.
   doi: 10.1097/HJH.0000000000003480.
6. Jones DW, Ferdinand KC, Taler SJ, Johnson HM, Shimbo D, Abdalla M, et al. 2025
   AHA/ACC/AANP/AAPA/ABC/ACCP/ACPM/AGS/AMA/ASPC/NMA/PCNA/SGIM Guideline for the Prevention,
   Detection, Evaluation, and Management of High Blood Pressure in Adults. Circulation.
   2025;152(11):e114-e218. doi: 10.1161/CIR.0000000000001356.
7. Riebler A, Sørbye SH, Simpson D, Rue H. An intuitive Bayesian spatial model for disease mapping
   that accounts for scaling. Stat Methods Med Res. 2016;25(4):1145-1165.
   doi: 10.1177/0962280216660421.
8. Rue H, Martino S, Chopin N. Approximate Bayesian inference for latent Gaussian models by using
   integrated nested Laplace approximations. J R Stat Soc Series B. 2009;71(2):319-392.
   doi: 10.1111/j.1467-9868.2008.00700.x.
9. Rao JNK, Molina I. Small Area Estimation. 2nd ed. Hoboken: John Wiley & Sons; 2015.
   doi: 10.1002/9781118735855.
10. Zhang X, Holt JB, Lu H, Wheaton AG, Ford ES, Greenlund KJ, et al. Multilevel regression and
    poststratification for small-area estimation of population health outcomes: a case study of
    chronic obstructive pulmonary disease prevalence using the Behavioral Risk Factor Surveillance
    System. Am J Epidemiol. 2014;179(8):1025-1033. doi: 10.1093/aje/kwu018.
11. Greenlund KJ, Lu H, Wang Y, Matthews KA, LeClercq JM, Lee B, et al. PLACES: local data for
    better health. Prev Chronic Dis. 2022;19:E31. doi: 10.5888/pcd19.210459.
12. Romero-Martínez M, Shamah-Levy T, Barrientos-Gutiérrez T, Cuevas-Nasu L, Bautista-Arredondo S,
    Colchero-Aragonés MA, et al. Metodología y análisis de la Encuesta Nacional de Salud y
    Nutrición Continua 2020-2024. Salud Publica Mex. 2024;66(6):879-885. doi: 10.21149/16455.
13. Deville JC, Särndal CE. Calibration estimators in survey sampling. J Am Stat Assoc.
    1992;87(418):376-382. doi: 10.1080/01621459.1992.10475217.
14. Simpson D, Rue H, Riebler A, Martins TG, Sørbye SH. Penalising model component complexity: a
    principled, practical approach to constructing priors. Stat Sci. 2017;32(1):1-28.
    doi: 10.1214/16-STS576.
15. Vehtari A, Gelman A, Gabry J. Practical Bayesian model evaluation using leave-one-out
    cross-validation and WAIC. Stat Comput. 2017;27(5):1413-1432.
    doi: 10.1007/s11222-016-9696-4.
16. Deming WE, Stephan FF. On a least squares adjustment of a sampled frequency table when the
    expected marginal totals are known. Ann Math Stat. 1940;11(4):427-444.
    doi: 10.1214/aoms/1177731829.
17. Roberts DR, Bahn V, Ciuti S, Boyce MS, Elith J, Guillera-Arroita G, et al. Cross-validation
    strategies for data with temporal, spatial, hierarchical, or phylogenetic structure.
    Ecography. 2017;40(8):913-929. doi: 10.1111/ecog.02881.
18. Czado C, Gneiting T, Held L. Predictive model assessment for count data. Biometrics.
    2009;65(4):1254-1261. doi: 10.1111/j.1541-0420.2009.01191.x.
19. Burgert-Brucker CR, Dontamsetti T, Marshall AMJ, Gething PW. Guidance for Use of The DHS
    Program Modeled Map Surfaces [Internet]. DHS Spatial Analysis Reports No. 14. Rockville: ICF
    International; 2016 [cited 2026 Jul 28]. Available from:
    https://dhsprogram.com/pubs/pdf/SAR14/SAR14.pdf
20. R Core Team. R: A Language and Environment for Statistical Computing [Internet]. Vienna: R
    Foundation for Statistical Computing; 2026 [cited 2026 Aug 4]. Available from:
    https://www.R-project.org/
21. Lumley T. Analysis of complex survey samples. J Stat Softw. 2004;9(8):1-19.
    doi: 10.18637/jss.v009.i08.
22. Lindgren F, Rue H. Bayesian spatial modelling with R-INLA. J Stat Softw. 2015;63(19):1-25.
    doi: 10.18637/jss.v063.i19.
23. Bivand R, Wong DWS. Comparing implementations of global and local indicators of spatial
    association. TEST. 2018;27(3):716-748. doi: 10.1007/s11749-018-0599-x.
24. Pebesma E. Simple features for R: standardized support for spatial vector data. R J.
    2018;10(1):439-446. doi: 10.32614/RJ-2018-009.
25. Wickham H. ggplot2: elegant graphics for data analysis. 2nd ed. Cham: Springer; 2016.
    doi: 10.1007/978-3-319-24277-4.
26. Eberhart MG, Yehia BR, Hillier A, Voytek CD, Blank MB, Frank I, et al. Behind the cascade:
    analyzing spatial patterns along the HIV care continuum. J Acquir Immune Defic Syndr. 2013;64
    Suppl 1:S42-51. doi: 10.1097/QAI.0b013e3182a90112.
27. Okuyama K, Akai K, Kijima T, Abe T, Isomura M, Nabika T. Effect of geographic accessibility to
    primary care on treatment status of hypertension. PLoS One. 2019;14(3):e0213098.
    doi: 10.1371/journal.pone.0213098.
28. Servan-Mori E, Heredia-Pi I, Montañez-Hernandez J, Avila-Burgos L, Wirtz VJ. Access to
    medicines by Seguro Popular beneficiaries: pending tasks towards universal health coverage.
    PLoS One. 2015;10(9):e0136823. doi: 10.1371/journal.pone.0136823.
## Tablas y figuras

<!--SOLO:EXTENSA-->
Este manuscrito usa 2 tablas (Tabla 1, Tabla 2) y 3 figuras (Figura 1, Figura 2, Figura 3) en el
cuerpo principal — 5 en total, por debajo del máximo permitido para un Artículo
Original. El material suplementario (7 tablas y 2 figuras:
Tabla S1 a S7, Figura S1, Figura S2) se envía como archivo aparte y no cuenta contra ese límite,
conforme a la sección de la revista sobre material suplementario ("cuya inclusión no es necesaria
en el artículo publicado"). Las tablas y figuras del cuerpo principal van incrustadas a continuación, después de
las referencias. Los títulos/leyendas no van incrustados en los archivos gráficos en sí — van aquí,
junto a cada tabla/figura.
<!--/SOLO-->

<!--SOLO:BREVE-->
El cuerpo principal lleva 2 cuadros y 3 figuras: el máximo que admite un artículo original.
Los cuadros y las figuras se envían en archivos independientes de este texto; aquí constan
sus títulos y leyendas. Los anexos —7 cuadros y 2 figuras suplementarios, citados en el
texto como Tabla S1 a S7 y Figura S1 a S2— no viajan con el manuscrito, porque la revista no
aloja material suplementario: están en el repositorio público del estudio,
https://github.com/RodrigoCardenasGolac22/sae-cascada-hta-mexico, en la carpeta
`SUPLEMENTARIO/`, junto con el código que los genera.
<!--/SOLO-->

<!-- EMBEBER_TABLAS_FIGURAS -->

**Material suplementario** (archivo aparte):
**Tabla S1.** Diagnósticos del modelo (WAIC, Phi, RMSE de validación cruzada, cobertura nacional)
por paso de la cascada.
**Tabla S2.** Efecto de calibrar el ponderador de la submuestra con presión arterial medida sobre
las estimaciones nacionales, y validación contra el ponderador de tensión arterial que la encuesta
publica para 2023.
**Tabla S3.** Efecto del año de la ronda en cada paso de la cascada.
**Tabla S4.** Selección de covariables de área: mejora predictiva con su incertidumbre, y
coeficiente posterior de las seleccionadas.
**Tabla S5.** Verificación de los supuestos de los modelos finales: colinealidad, autocorrelación
espacial de los residuos, forma del componente no estructurado y calibración predictiva.
**Tabla S6.** Comparación de las estimaciones nacionales directas con la literatura nacional
publicada sobre los mismos datos.
**Tabla S7.** Conectividad del grafo de vecindad municipal empleado en el término espacial BYM2,
incluidos los municipios insulares y sus colindantes.
**Figura S1.** Validación cruzada espacial de 5 pliegues: calibración observado-vs-predicho y
reducción de RMSE frente a un promedio nacional simple no ajustado, por paso.
**Figura S2.** Ancho del intervalo de credibilidad al 95% por municipio (diagnóstico, tratamiento,
control), criterio ESH — mapa complementario de incertidumbre, siguiendo la práctica de The DHS
Program para superficies modeladas (Burgert-Brucker et al. 2016).

