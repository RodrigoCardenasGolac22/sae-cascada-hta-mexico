# Cascada municipal de atención de la hipertensión en México

Repositorio de investigación del estudio **Estimación bayesiana de área pequeña de la cascada de atención de la hipertensión arterial en los municipios de México**, basado en ENSANUT Continua 2021–2024.

Incluye el análisis en R, los resultados agregados, las figuras, la fuente del manuscrito y un [explorador municipal](https://rodrigocardenasgolac22.github.io/sae-cascada-hta-mexico/). Los modelos BYM2 se ajustan con INLA mediante pseudo-verosimilitud ponderada; se consideran los umbrales ESH 2023 y ACC/AHA 2025.

**Estado:** preparación del envío a *Salud Pública de México*. La organización actual parte del commit `af9aacc` del 18 de septiembre de 2026. El [historial](CHANGELOG.md) distingue esta instantánea de las etiquetas anteriores. Este repositorio no acredita aceptación ni envío a una revista.

## Organización

```text
analysis/                  Scripts R, construcción del explorador y preprocesamiento
data/
  raw/                     Microdatos ENSANUT, excluidos de Git
  external/                Geografía INEGI; insumos ITER, CLUES y DEM locales
  processed/               Covariables municipales y grafos
results/
  estimates/               Estimaciones agregadas, validación y sensibilidades
  tables/                  Cuadros y checklist STROBE
  figures/                 Figuras y sus datos en data/
manuscript/                Fuente del manuscrito y suplemento
reproducibility/           Entorno registrado, inventario de rutas y verificaciones
docs/                     Explorador publicado mediante GitHub Pages
RUN_ALL.R                 Ejecutor del análisis desde la raíz
```

- [Fuentes y ubicación de los datos](data/README.md).
- [Procedimiento de reproducción y sus límites](reproducibility/README.md).
- [Guía de resultados](results/README.md).
- [Preparación del manuscrito](manuscript/README.md).
- [Equivalencias entre rutas antiguas y actuales](reproducibility/path_migration.csv).

## Reproducir

El análisis registrado se ejecutó con **R 4.6.0 e INLA 25.10.19**. Las versiones observadas están en [sessionInfo.txt](reproducibility/sessionInfo.txt) y [r-packages.csv](reproducibility/r-packages.csv). No constituyen un archivo de restauración automática. Se requiere además Python 3.10 o posterior para construir el HTML del explorador.

1. Instalar R y los paquetes registrados; INLA se distribuye en su [repositorio oficial](https://www.r-inla.org/download-install).
2. Descargar los microdatos ENSANUT y los insumos ITER y CLUES indicados en [data/README.md](data/README.md). ITER se utiliza desde el paso 02.
3. Ejecutar desde la raíz del repositorio:

```sh
Rscript RUN_ALL.R --list
Rscript RUN_ALL.R
```

Para reconstruir únicamente artefactos después de disponer de las bases e intermedios del análisis:

```sh
Rscript RUN_ALL.R 18 27
```

Los argumentos son **posiciones de la lista**, no números del nombre de archivo. Las posiciones 1–25 conservan el orden histórico; 26 calcula la conectividad y Tabla S7, y 27 construye el HTML. El paso 25 por sí solo genera `docs/datos.json`. Para reconstruir solo el HTML con el JSON versionado:

```sh
python analysis/25_explorador_html.py
```

Para verificar integridad y rutas sin microdatos ni INLA:

```sh
python reproducibility/verify_repository.py
```

Esta última comprobación no vuelve a estimar los modelos ni certifica el cierre científico del manuscrito. Los ajustes INLA y la validación cruzada son los pasos costosos. La reorganización conserva las salidas existentes; no presenta un nuevo ajuste estadístico.

## Datos y alcance

Los microdatos y la base individual derivada no se redistribuyen. Los CSV públicos contienen estimaciones y diagnósticos municipales. Los resultados con `suprimir_privacidad=TRUE` se ocultan en las visualizaciones, pero **los archivos agregados actualmente versionados conservan sus valores**. La marca es un filtro de presentación, no una anonimización ni eliminación de valores del archivo. Véase [results/README.md](results/README.md).

Los mapas presentan estimaciones modeladas y su incertidumbre; no sustituyen mediciones municipales representativas. La cobertura y los municipios sin predicción están documentados en `results/estimates/resumen_cobertura_nacional.csv` y `municipios_sin_cobertura.csv`.

## Autoría

| Autor | ORCID | Roles (taxonomía CRediT) |
|---|---|---|
| Vicente J. Vílchez-Díaz | [0009-0007-3755-8226](https://orcid.org/0009-0007-3755-8226) | Conceptualización, metodología, **software**, análisis formal, curación de datos, validación, visualización, redacción |
| Oriana García-Ruiz | [0000-0002-7233-9703](https://orcid.org/0000-0002-7233-9703) | Investigación, redacción del borrador original, revisión y edición |
| Samar S. Sifuentes-Vidigal | [0009-0006-8564-8317](https://orcid.org/0009-0006-8564-8317) | Investigación, redacción del borrador original |
| Miguel A. Velarde-Mera | [0009-0009-6073-9767](https://orcid.org/0009-0009-6073-9767) | Investigación, redacción del borrador original |
| Rodrigo J. Cárdenas-Golac | [0009-0005-4444-1523](https://orcid.org/0009-0005-4444-1523) | Supervisión, administración del proyecto, recursos, revisión y edición |

El historial de commits de este repositorio corresponde a la cuenta del autor corresponsal, que
fue quien lo publicó; no refleja el reparto de contribuciones, que es el de la tabla anterior.

Durante la preparación del trabajo se utilizó asistencia de inteligencia artificial en la
implementación y depuración del código, la redacción y la traducción al inglés. El detalle está en
la sección «Declaración de uso de IA» del manuscrito. Conforme a las políticas del ICMJE, las
herramientas de IA no figuran como autoras: los autores asumen la responsabilidad
completa por la exactitud, integridad y originalidad del trabajo.

## Citar y reutilizar

Los metadatos de autoría están en [CITATION.cff](CITATION.cff). Para reutilizar esta rama, indique el repositorio y el hash del commit utilizado. Una nueva versión citada en el artículo deberá corresponder al paquete efectivamente enviado; no se ha asignado aquí una nueva etiqueta de publicación.

El código se distribuye bajo la [licencia MIT](LICENSE). Los insumos de ENSANUT, INEGI, CONEVAL y CLUES mantienen sus condiciones de origen. La licencia del código no concede derechos adicionales sobre los datos de terceros ni determina la licencia futura del artículo.
