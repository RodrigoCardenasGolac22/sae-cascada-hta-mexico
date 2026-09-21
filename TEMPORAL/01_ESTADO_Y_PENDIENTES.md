# Mensaje consolidado de cierre para Rodrigo y su agente

Fecha: 20 de septiembre de 2026. Último paquete inspeccionado: `PARA_VICENTE_REVISION_FINAL_2026-09-20.zip`. Estado de Git contrastado hasta `cf46b0f`.

**La respuesta corrigió los principales defectos del suplemento. Todavía no se ha dado conformidad global de envío.** Lo siguiente consolida las revisiones anteriores e incorpora el último commit para no tratar como abiertos asuntos ya corregidos.

## Cerrado y comprobado

- **S2B:** restaurado con cinco desenlaces y tres estratos de tamaño municipal. Las 45 celdas de datos cotejadas coinciden con los CSV fuente; las sumas de municipios por estrato son correctas.
- **S4:** restauradas las diez etiquetas de densidad CLUES; las 60 celdas numéricas de selección coinciden con el CSV. La nota ya dice 0,69 como mayor razón entre mejoras y cuatro razones superiores a 2, todas deterioros. Se retiró la unidad antigua de «100 establecimientos».
- **S3:** los 15 años se muestran como 2022/2023/2024, sin separador de miles.
- **Moran:** el texto ahora usa `p≥0,168`, concordante con S5.
- **Figuras y cuadros principales:** los tres EPS, sus tres Excel y la relación son idénticos entre las entregas del 18 y 20. En `TABLAS_SPM.xlsx` solo cambian metadatos, no las celdas.
- **`cf46b0f`:** corrige el comentario sobre pobreza faltante en `00_comun.R` y el motivo en STROBE 12c. STROBE 14a ahora reconoce que no se tabulan características sociodemográficas. Esto mejora la precisión del checklist; no añade los descriptivos faltantes.

## Pendientes vigentes

### P1. Definir explícitamente el estimando de los mapas

La frase nueva «La estimación describe así a los adultos censales del municipio, no a sus encuestados» distingue población y muestra, pero no responde a la observación central: se predicen probabilidades dentro de cada denominador clínico y se promedian con la misma composición censal de adultos en general.

Si se conserva el análisis, confirmar que se quieren comunicar probabilidades condicionales estandarizadas a esa composición y mantener esa interpretación en objetivos, métodos, resultados y leyendas. Si se quieren proporciones dentro de los denominadores clínicos municipales, revisar la postestratificación correspondiente. Esta observación no demuestra invalidez del estudio ni cuantifica por sí sola una diferencia.

### P2. Declarar o corregir la referencia de validación cruzada

«El promedio nacional simple asigna a todo municipio el mismo valor ponderado, sin estructura espacial ni covariables» no informa que ese promedio se calcula con toda la muestra, incluidos los municipios evaluados.

`10_validacion_cruzada.R` sigue calculando la referencia antes de separar los pliegues. El ajuste BYM2 sí oculta los desenlaces retenidos: la observación se refiere al comparador. Para una referencia predictiva independiente, calcular el promedio con entrenamiento dentro de cada pliegue y actualizar sus derivados. Si los autores mantienen deliberadamente una referencia global descriptiva, explicitarlo y limitar la interpretación.

Además, indicar qué resultados corresponden a pliegues aleatorios y contiguos; las salidas de ambos existen. El Cuadro II promedia valores ajustados en la encuesta: no es la agregación nacional de los mapas postestratificados.

### P3. Completar la corrección del motivo de pobreza faltante

El último commit corrige comentario y checklist, **pero no modifica `MANUSCRITO_BORRADOR.md`**. La fuente y el Word recibido aún dicen «tres municipios creados después del marco CONEVAL 2020».

Los seis registros excluidos de control pertenecen a dos municipios muestreados; hay tres municipios sin pobreza publicada en el marco nacional. Corregir esa frase en la fuente, regenerar el Word y comprobar la concordancia con el checklist nuevo. No atribuir la ausencia de pobreza a una fecha de creación municipal no sustentada. [CONEVAL, informe 2020, p. 21, nota 5](https://www.coneval.org.mx/InformesPublicaciones/Documents/Informe_Pobreza_Municipios_Mexico_2020.pdf).

### P4. Hacer concordar la supresión declarada y los archivos públicos

La frase «Se omitió toda estimación basada en menos de 10 encuestados…» sigue siendo más amplia que lo implementado. Los CSV nacionales y el JSON/HTML conservan valores marcados para ocultación; figuras y Excel de figuras sí los suprimen visualmente o dejan las celdas vacías.

Decidir si la regla es de visualización o también de publicación de archivos. Según la decisión, armonizar texto y salidas públicas. La revisión demuestra una discrepancia entre declaración y archivos, no una reidentificación demostrada. Una modificación del árbol actual no elimina el contenido histórico; no reescribir historia sin una decisión aparte.

### P5. Completar el reporte al que se refiere STROBE

`cf46b0f` reconoce que faltan descriptivos sociodemográficos y una tabla de faltantes por covariable. Eso corrige parte de la sobredeclaración, pero no satisface el contenido ausente.

Añadir edad, sexo, escolaridad, urbanidad y faltantes relevantes donde corresponda, por ejemplo en un suplemento, o registrar expresamente la decisión editorial y su justificación. Ajustar 12c, 14a, 14b y 16a a ubicaciones reales. No atribuir intervalos de credibilidad al promedio nacional del Cuadro II si allí no se presentan.

### P6. Cerrar versión, rutas y reproducibilidad editorial

El manuscrito aún cita `v1.4`, anterior a las últimas correcciones. Publicar una nueva versión inmutable solo cuando corresponda al paquete aprobado, actualizar cita y rutas y comprobar enlaces. No mover silenciosamente la etiqueta histórica.

Los generadores editoriales completos no están en el Git público: revisar la afirmación «con el código que los genera» y publicar versiones sin datos personales si se quiere mantenerla. Las copias locales antiguas no prueban que sean las usadas para el paquete vigente. La reorganización del PR #1 también cambia la ruta del suplemento a `manuscript/supplement/`.

### P7. Resolver los puntos editoriales pendientes

- El paquete del 20 contiene resúmenes ES 195 / EN 197 palabras. [Normas](https://saludpublica.mx/index.php/spm/normas) permite 200 y la [lista de Envíos](https://saludpublica.mx/index.php/spm/about/submissions) exige 150. Resolver con variantes de hasta 150 o aclaración editorial documentada.
- Confirmar nombres completos cuando la norma pide nombres no abreviados; no deducir expansiones de iniciales.
- La carta y cinco declaraciones se reportaron ya firmadas y fuera del ZIP. La revisión no las inspeccionó: no afirma que falten firmas. Comprobar el juego existente contra la versión final y la declaración de IA.
- El recuento 3 985 corresponde a una selección concreta anterior a las leyendas, no a todo el DOCX. Recontar tras cualquier cambio. El resultado del detector de IA referido en el LEEME no sustituye estos cotejos científicos y editoriales.

### P8. Ajustes finales de precisión ya señalados

- S5 conserva cinco `KS p=0,000`: usar `p<0,001`. El ICAR estructurado también es gaussiano; retirar que el no estructurado sea «el único» componente con ese supuesto.
- S7 deduce una componente de no tener aislados. El grafo **sí fue comprobado como conexo**; informar el resultado calculado sin esa inferencia insuficiente.
- «No hubo» autocorrelación y «ausente» agrupamiento en diagnóstico son más fuertes que no detectar evidencia: preferir formulaciones cautas.
- Sustituir «datos idénticos» frente al comparador publicado por «mismas rondas de ENSANUT», con criterios/muestras analíticas diferentes. No atribuir causalmente todas las brechas a decisiones analíticas sin una descomposición que lo sustente.
- Precisar que 46,7 pp es la mediana del **ancho del intervalo** de diagnóstico ESH. No es una desviación estándar general.
- La referencia 24 describe un enfoque en dos etapas, no demuestra por sí sola un modelo conjunto de los tres eslabones: revisar su ubicación. La limitación de no modelar efectos compartidos puede declararse sin esa cita.

No se solicita comenzar una auditoría nueva. Se pide responder a estos pendientes, conservar los cierres verificados y documentar las decisiones restantes.
