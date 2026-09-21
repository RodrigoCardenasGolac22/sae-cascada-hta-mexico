# Historial de cambios

## Sin publicar — 2026-09-21

- Integradas las decisiones de los autores hasta `bbbc4fe`: estimando condicional estandarizado y nombres completos; actualizados también los metadatos de citación.
- Ejecutada la corrección del comparador de validación con entrenamiento exclusivo en cada pliegue. Se conservan predicciones BYM2, observados y pliegues; no se reajusta INLA. Actualizados detalle, resumen, estratos, Tabla S1 y Figura S1.
- Añadida la Tabla S8 de características y faltantes por denominador, con generador, CSV, Excel y referencias STROBE.
- Publicado el generador del suplemento y reconstruido el Word. Verificadas celda a celda las tablas previas S2-S7; permanecen sin cambios.
- Armonizada la interpretación en objetivos, resúmenes, texto, Figura 2 y explorador; corregida la descripción del ancho del intervalo y retirada la cita del análisis de efectos compartidos no realizado.
- Actualizados manifiestos y registro `reproducibility/closure_validation.json`. La supresión descargable y el cierre del paquete firmado siguen pendientes; `v1.5` está prevista y no se ha creado.

## Sin publicar — 2026-09-20

- Integradas las correcciones hasta `d1a6e14`: motivo de pobreza faltante en la fuente, precisión del checklist y notas de KS/conectividad en el suplemento. Se mantiene la comunicación temporal incorporada en `main`.
- Restauradas las exclusiones de `_TRABAJO_INTERNO/`, notas internas, insumos y generadores heredados que pueden permanecer al actualizar una copia antigua. Los PDF heredados en la raíz se ignoran; se permiten documentos propios bajo `manuscript/`.
- Integradas las correcciones de los autores de `147d9ef` y `23d0ccd`: panel B de S2, etiquetas y nota de S4, años de S3, p de Moran, ubicaciones STROBE y dos aclaraciones del manuscrito. Se conserva exactamente el contenido publicado por los autores; la integración no acredita el cierre de las observaciones metodológicas.
- Organización en `analysis/`, `data/`, `results/`, `manuscript/` y `reproducibility/`; `docs/` conserva el explorador de GitHub Pages.
- Actualización de rutas y eliminación de las rutas personales del cálculo opcional de altitud.
- Incorporación al ejecutor de la Tabla S7 y de la construcción del HTML del explorador; validación de argumentos y listado de pasos.
- Documentación de insumos, límites de reproducción, migración e integridad.
- Los resultados numéricos, figuras y JSON del explorador conservan el contenido de `af9aacc`. El suplemento y el checklist incorporan las correcciones de `23d0ccd`, registradas como actualizaciones explícitas. No se reajustaron los modelos.
- Se reconstruyó el HTML desde la plantilla vigente: la página conservaba el recuento antiguo de 25 089 participantes, mientras la plantilla ya indicaba 25 088. Esta actualización y las del suplemento/checklist están registradas en `reproducibility/artifact_updates.csv`.

## Referencia de la entrega de septiembre de 2026

La reorganización parte de `af9aacc3a6d843356f6044caa479bbf0c12e024a` (2026-09-18).
La etiqueta histórica `v1.4` apunta a su antecesor `ca627354c1a86c85183bb4e6ec1da217a89aea4e`.
La corrección de Figura 1, la declaración del techo fisiológico y el detalle de herramientas de IA se incorporaron después de esa etiqueta. Las etiquetas históricas se conservan; el cierre editorial deberá citar una nueva versión o el commit exacto que acompañe al envío.
