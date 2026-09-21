# Reproducibilidad

## Qué está registrado

- `sessionInfo.txt`: registro original de R 4.6.0, INLA 25.10.19 y paquetes de la corrida disponible. Se conserva sin atribuirlo a una ejecución nueva.
- `r-packages.csv`: extracción de versiones de ese registro; no es un `renv.lock` ni garantiza disponibilidad de todos los binarios.
- `path_migration.csv`: equivalencia de cada archivo versionado antes y después de reorganizarlo, con el SHA-256 de su contenido original en Git (`af9aacc`). La referencia usa los blobs de Git, independientes de la conversión automática LF/CRLF de Windows.
- `artifact_updates.csv`: excepciones explícitas a la conservación del hash. Registra la reconstrucción del HTML desde la plantilla y los datos versionados, con hash anterior, posterior y motivo.
- `verify_repository.py`: comprobación de integridad de artefactos conservados y rutas del repositorio, sin dependencias externas.

## Ejecutar y verificar

Desde la raíz:

```sh
python reproducibility/verify_repository.py
Rscript RUN_ALL.R --list
Rscript RUN_ALL.R
```

`RUN_ALL.R` necesita R y Python 3.10 o posterior. La variable `PYTHON` permite indicar el ejecutable de Python. ITER puede ubicarse fuera del repositorio mediante `ITER_CSV`.

Una corrida parcial `Rscript RUN_ALL.R 18 27` presupone que ya existen los intermedios que consume: por ejemplo, `18_tablas.R` necesita la base analítica individual y `24_datos_explorador.R` necesita `postestratificacion_censal.csv`. Esos archivos no se redistribuyen. La construcción aislada del HTML sí funciona con el JSON versionado: `python analysis/25_explorador_html.py`.

El registro `sessionInfo.txt` solo se actualiza tras una corrida completa. La comprobación automática de GitHub verifica organización e integridad, no ejecuta modelos INLA, no descarga microdatos y no evalúa la validez de los supuestos científicos.

## Límites conocidos

La rama de cierre cambia rutas y ejecución de artefactos; conserva los resultados de la corrida disponible. No se realizó un nuevo ajuste completo de INLA durante esa reorganización. Las versiones exactas de las descargas externas y el preprocesamiento original de CONEVAL no están completamente documentados. El cálculo opcional de altitud requiere `terra` y `geodata`, que no figuran en la sesión original del análisis principal.

En Windows se había documentado que INLA puede fallar bajo rutas con caracteres acentuados. Para reproducir los ajustes, use una ruta local ASCII y PowerShell. Esta precaución proviene del entorno del estudio, no de una nueva prueba de todas las versiones de INLA.

Los generadores editoriales completos no forman parte de esta rama; la reproducción de los análisis y la construcción del paquete de envío son procesos distintos.
