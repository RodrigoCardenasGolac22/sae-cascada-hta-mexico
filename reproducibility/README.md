# Reproducibilidad

## Qué está registrado

- `sessionInfo.txt`: registro original de R 4.6.0, INLA 25.10.19 y paquetes de la corrida disponible. Se conserva sin atribuirlo a una ejecución nueva.
- `r-packages.csv`: extracción de versiones de ese registro; no es un `renv.lock` ni garantiza disponibilidad de todos los binarios.
- `path_migration.csv`: equivalencia de cada archivo versionado antes y después de reorganizarlo, con el SHA-256 de su contenido original en Git (`af9aacc`). La referencia usa los blobs de Git, independientes de la conversión automática LF/CRLF de Windows.
- `artifact_updates.csv`: cambios documentados respecto de la migración, incluidos el comparador corregido, las figuras, el suplemento y STROBE; registra hash anterior, posterior y motivo. Los hashes de `path_migration.csv` permanecen como referencia histórica.
- `verify_repository.py`: comprobación de integridad de artefactos conservados y rutas del repositorio, sin dependencias externas.

## Ejecutar y verificar

Desde la raíz:

```sh
python reproducibility/verify_repository.py
Rscript RUN_ALL.R --list
Rscript RUN_ALL.R
```

`RUN_ALL.R` necesita R y Python 3.10 o posterior. La variable `PYTHON` permite indicar el ejecutable de Python. ITER puede ubicarse fuera del repositorio mediante `ITER_CSV`.

Una corrida parcial `Rscript RUN_ALL.R 18 30` presupone que ya existen los intermedios que consume: por ejemplo, `18_tablas.R` necesita la base analítica individual y `24_datos_explorador.R` necesita `postestratificacion_censal.csv`. Esos archivos no se redistribuyen. La construcción aislada del HTML sí funciona con el JSON ya suprimido: `python analysis/25_explorador_html.py`.

El registro `sessionInfo.txt` solo se actualiza tras una corrida completa. La comprobación automática de GitHub verifica organización e integridad, no ejecuta modelos INLA, no descarga microdatos y no evalúa la validez de los supuestos científicos.

## Límites conocidos

La rama de cierre conserva los modelos y las predicciones BYM2 de la corrida disponible. Corrige el comparador de validación, recalculado exclusivamente en entrenamiento, y añade descriptivos y faltantes. No se realizó un nuevo ajuste de INLA. Las versiones exactas de las descargas externas y el preprocesamiento original de CONEVAL no están completamente documentados. El cálculo opcional de altitud requiere `terra` y `geodata`, que no figuran en la sesión original del análisis principal.

En Windows se había documentado que INLA puede fallar bajo rutas con caracteres acentuados. Para reproducir los ajustes, use una ruta local ASCII y PowerShell. Esta precaución proviene del entorno del estudio, no de una nueva prueba de todas las versiones de INLA.

El generador público `analysis/21_material_suplementario.R` reconstruye el suplemento completo desde las tablas y figuras, incluida S8. Los generadores privados de cartas, firmas y del paquete de envío no forman parte de esta rama.

## Corrección del comparador sin reajustar INLA

Con la misma base, pesos, especificación, pliegues y predicciones guardadas de la corrida verificada, ejecutar en PowerShell:

```powershell
$env:CV_REUTILIZAR_BYM2 = "1"
Rscript analysis/10_validacion_cruzada.R
Remove-Item Env:CV_REUTILIZAR_BYM2
Rscript analysis/16_figS1_validacion.R
Rscript analysis/18_tablas.R
Rscript analysis/18c_descriptivos_muestra.R
$env:REVISTA = "SPM"
Rscript analysis/20_checklist_strobe.R
Rscript analysis/21_material_suplementario.R
python analysis/26_publicar_datos.py
```

El modo de reutilización valida coincidencia municipal de observados, conteos y tamaños efectivos antes de recalcular el promedio de entrenamiento. Conserva `pred_bym2` y añade `pred_naive_global` como referencia descriptiva. Debe usarse únicamente para esta corrección del comparador sobre los mismos ajustes guardados, no después de cambiar el modelo. Sin la variable se ejecuta la validación completa con INLA. Los insumos individuales permanecen excluidos de Git.

Después de la publicación con supresión, el detalle completo para ese modo se lee de `results/private/publication_inputs/results/estimates/`, si existe. Una descarga pública no contiene esas copias. Para recalcular métricas con todos los municipios hay que disponer de esos insumos privados o reproducir la corrida completa; no interpretar los blancos públicos como ceros.

`TablaS8_descriptivos.csv` y `TablaS8_faltantes.csv` describen las poblaciones elegibles antes de excluir covariables faltantes; sus columnas se superponen. Los conteos no están ponderados. Medias, dispersión descriptiva y porcentajes usan el ponderador calibrado; no son errores estándar ni intervalos del diseño de encuesta.

## Publicar con supresión

`analysis/26_publicar_datos.py` es el último paso obligatorio antes de publicar una regeneración. Omite todos los campos numéricos de las filas municipales protegidas en 29 CSV, conserva identificadores y marcas, suprime valores/intervalos/n en el JSON y reconstruye el HTML. Las reclasificaciones se protegen si lo requiere cualquiera de sus desenlaces. Los originales locales se guardan bajo `results/private/publication_inputs/`, excluido de Git.

Las figuras aplican el umbral también en su código de construcción. Figura S1 muestra solo puntos con n≥10, pero las métricas de su panel B mantienen todos los municipios evaluados; Figura S2 omite anchos de celdas protegidas. Los datos de figuras en Excel se verifican junto con los CSV y el explorador. No se cambian los modelos ni los resúmenes agregados del análisis por este control de publicación.

```sh
python reproducibility/publication_privacy.py --check
python reproducibility/test_publication_privacy.py
python reproducibility/verify_repository.py
```

CI ejecuta estas comprobaciones para impedir la reintroducción accidental de cifras o tamaños exactos. El alcance es el árbol de publicación: las versiones históricas anteriores a `v1.5` no se reescriben. La comunicación temporal y las firmas no forman parte del árbol de la versión.
