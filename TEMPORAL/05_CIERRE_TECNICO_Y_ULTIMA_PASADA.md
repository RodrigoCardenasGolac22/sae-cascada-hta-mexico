# Cierre técnico y última pasada — 21 de septiembre de 2026

Revisadas tus rondas 2–4, hasta `bbbc4fe`. Para evitar otro intercambio de observaciones, ejecutamos las tareas que podían resolverse aquí y dejamos una secuencia concreta para terminar.

**Los cambios técnicos están publicados en el [PR #1](https://github.com/RodrigoCardenasGolac22/sae-cascada-hta-mexico/pull/1), commit `36e16a0606fae5f92869731963196d9a87248845`, rama `cierre-proyecto-2026-09-20`. Todavía no están integrados en `main`.** Hacer `pull` de `main` permite leer este mensaje; para revisar los resultados nuevos hay que abrir el PR o traer esa rama.

## Resuelto en esta entrega

### P2 — código ejecutado y derivados actualizados

Se ejecutó `analysis/10_validacion_cruzada.R` con la base y pesos cuyos SHA-256 ya compartimos, usando `CV_REUTILIZAR_BYM2=1`. Este modo aplica el comparador de entrenamiento y reutiliza las predicciones BYM2 publicadas. No simula una corrida ni vuelve a ajustar INLA: conserva explícitamente los ajustes guardados, después de comprobar observados, conteos y tamaños efectivos municipales. El modo normal del script sigue realizando los ajustes completos.

Comprobación independiente: coinciden los diez resultados con el cálculo previo, a precisión numérica. Se preservan las predicciones BYM2, observados, n, n efectivo, vecinos y pliegues. Se actualizan los diez detalles CV, el resumen, los estratos, Tabla S1, Figura S1 y su mención en español e inglés. `pred_naive_global` queda como referencia descriptiva separada.

| Desenlace | Reducción de RMSE, aleatoria (%) | Contigua (%) |
|---|---:|---:|
| Diagnóstico ESH | 6,7 | 6,3 |
| Diagnóstico AHA | 9,9 | 9,3 |
| Tratamiento | 10,1 | 9,0 |
| Control ESH | 2,4 | 2,0 |
| Control AHA | 1,3 | 1,9 |

**No hace falta repetir INLA para esta corrección aislada.** La evidencia agregada está en `reproducibility/closure_validation.json` y las instrucciones de ejecución en `reproducibility/README.md` del PR.

### P5 — Tabla S8 entregada e incorporada

Generados `TablaS8_descriptivos.csv`, `TablaS8_faltantes.csv` y `TablaS8_descriptivos_faltantes.xlsx` en `results/tables/`, mediante `analysis/18c_descriptivos_muestra.R`. Incluyen edad, sexo, urbanidad, escolaridad y año para la base total y los denominadores clínicos, además de faltantes por covariable. Las columnas son poblaciones elegibles y se superponen: no son grupos independientes ni los tamaños finales de todos los modelos.

Se explicitan conteos no ponderados, porcentajes y medias ponderados, y DE descriptiva —no error estándar ni IC de encuesta—. Los ceros de faltantes corresponden a la base ya seleccionada; la Figura 1 conserva las exclusiones previas. En control: 4388 elegibles, seis sin pobreza, 4382 analizados.

S8 ya está en el suplemento Word, se cita en el manuscrito y STROBE 12c/14a/14b remite a su contenido. No se necesitan microdatos publicados ni una transferencia de la base por Git.

### P1/P7/P8 — concordancia y edición

- Se acepta la decisión de Rodrigo sobre el estimando. Armonizados objetivos, resúmenes, métodos, interpretación, leyenda del mapa y explicación del explorador en español e inglés. Las estimaciones directas de encuesta siguen distinguiéndose de las probabilidades condicionales estandarizadas.
- Nombres completos conservados y propagados a `CITATION.cff`. No se vuelven a solicitar.
- Cambiado el rango de mejora de CV a 1,3–10,1%; corregida también la conclusión inglesa que todavía decía `absent for awareness`.
- Aclarado que 46,7 pp es la mediana del **ancho del intervalo de credibilidad**; reducida la frase para recuperar margen editorial.
- Retirada la cita de Hogg del enunciado sobre efectos compartidos no ajustados, junto con su entrada. El preparador local resolvió bloques y renumeró las referencias. No se añadió otra referencia ni se cambió el análisis.
- Actualizada la mención de versión como **prevista** `v1.5`, sin afirmar que la etiqueta ya existe. Añadida la utilización del asistente de OpenAI en esta revisión para que la declaración de herramientas refleje el trabajo realizado.

## Suplemento y verificaciones

Se incorporó al PR el generador público `analysis/21_material_suplementario.R`, adaptado a las rutas nuevas y contrastado contra el suplemento de `bbbc4fe`. El nuevo Word contiene S1–S8 y figuras S1–S2. **Se comprobaron, celda a celda, las tablas previas S2A, S2B, S3, S4, S5, S6 y ambos paneles de S7: no cambian.** Se mantienen las correcciones de años, etiquetas, KS y conectividad.

Pasaron la verificación de integridad, el parseo de 32 scripts R y la revisión de cambios de Git. Se comprobaron visualmente las figuras modificadas y la página de S8 renderizada como PDF. Los cinco archivos NACIONAL y el JSON de datos del explorador se conservan byte a byte: no se aplicó una decisión de P4 de forma implícita.

El Word local **de revisión**, construido con los generadores disponibles, tiene **3953 palabras** con referencias y preámbulo de anexos; resumen **196**, abstract **199**. No es el paquete firmado final ni constituye una repetición del auditor privado 62/62. El generador definitivo de Rodrigo debe comprobar su propio Word una vez, después de integrar todos estos cambios.

## Lo que queda para terminar, en una sola pasada

1. **P4, única decisión científica/editorial de contenido aún abierta:** confirmar si se suprimen las cifras también en archivos/descargas o si la política es solo visual. La pregunta ya está planteada a Vicente. No dar por aprobada una opción por silencio. Si se elige supresión descargable, revisar también datos de figuras y derivados; no basta con modificar el HTML. No reescribir historial por cuenta propia.
2. **Integrar el PR y generar el paquete desde la fuente integrada.** Los insumos están en `manuscript/manuscript.md`, `results/tables/`, `results/figures/` y `manuscript/supplement/`. Los generadores privados deben leer esas rutas y conservar sus salidas fuera de Git. La versión de revisión disponible sirve como contraste; no sustituir las cartas firmadas ni los formularios por copias antiguas.
3. **Armonizar las leyendas que estén escritas dentro del generador privado del Word.** En nuestra copia de `19_manuscrito_docx.R` seguían fuera del `.md`. Para Figura 2, sustituir «Prevalencia municipal suavizada (modelo BYM2) de cada paso de la cascada» por «Probabilidad condicional municipal estandarizada a la composición adulta censal (modelo BYM2), por paso de la cascada». Para Figura 3, usar «Diferencia en puntos porcentuales de probabilidad condicional estandarizada al cambiar del criterio ESH 2023 al ACC/AHA 2025». El resto de la leyenda sobre supresión debe concordar con la decisión P4.
4. **Firmas:** recoger las firmas de las versiones con nombres completos que ya preparaste y reemplazar las anteriores en el paquete privado. No pegar firmas antiguas automáticamente. Este punto depende de las personas firmantes.
5. **Congelar la entrega:** comprobar una vez el Word definitivo (conteo, nombres, referencias, cifras y archivos acompañantes), resolver cualquier comprobación editorial interna pendiente y crear `v1.5` sobre el commit final integrado. En ese momento cambiar «versión prevista» por la versión efectivamente etiquetada. Mantener `v1.4` intacta. Retirar `TEMPORAL/` cuando deje de ser necesaria, con un commit normal y sin incluirla en el envío.

Para la siguiente respuesta basta con confirmar P4, el commit integrado y la situación de firmas/paquete. No hace falta reabrir P2/P5 ni pedir otra vez la base, los nombres o un recorte a 150 palabras. Si alguna comprobación falla, indicar el archivo y la diferencia concreta.
