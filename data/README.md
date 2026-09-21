# Datos y procedencia

Las rutas se interpretan desde la raíz del repositorio. No se requiere subir microdatos para consultar las estimaciones existentes.

| Fuente | Ruta esperada | Uso y distribución |
|---|---|---|
| ENSANUT Continua 2021–2024, INSP | `data/raw/ensanut/<año>/` | Microdatos locales; paso 01. [Fuente](https://ensanut.insp.mx/). |
| Censo 2020, ITER nacional, INEGI | `data/external/iter/conjunto_de_datos_iter_00CSV20.csv` | Local; población adulta desde paso 02 y postestratificación en 09. Se admite `ITER_CSV`. [Fuente](https://www.inegi.org.mx/programas/ccpv/2020/). |
| Catálogo CLUES, Secretaría de Salud | `data/external/clues/clues_establecimientos_salud.xlsx` | Local; requerido en 02 y 03. El conteo derivado sí está versionado. [Fuente](https://www.dgis.salud.gob.mx/contenidos/intercambio/clues_gobmx.html). |
| Geografía INEGI | `data/external/inegi/MapaBaseMultiescala.gpkg` | Archivo conservado del repositorio original; capa `municipios_4m`, 2 478 municipios. |
| CONEVAL, pobreza municipal 2020 | `data/processed/covariates/coneval_pobreza_municipal_2020.csv` | Derivado conservado. No se dispone en este repositorio del programa original de extracción. [Fuente](https://www.coneval.org.mx/Medicion/Paginas/Pobreza-municipio-2010-2020.aspx). |
| Elevación, geodata | `data/processed/covariates/altitud_municipal_DEM.csv` | Derivado conservado. Regeneración opcional: `analysis/preprocessing/calcular_altitud_municipal.R`; requiere `terra` y `geodata`. |

## Archivos ENSANUT requeridos

| Año | Adultos | Antropometría / presión arterial | Integrantes |
|---|---|---|---|
| 2021 | `ensadul2021_entrega_w_15_12_2021.csv` | `ensaantro21_entrega_w_17_12_2021.csv` | `integrantes_ensanut2021_w_12_01_2022.csv` |
| 2022 | `ensadul2022_entrega_w.csv` | `ensaantro2022_entrega_w.csv` | `integrantes_ensanut2022_w.csv` |
| 2023 | `adultos_ensanut2023_w_n.csv` | `Antropometria_HTA_4mar24.csv` | `integrantes_ensanut2023_w_n.csv` |
| 2024 | `adultos_ensanut2024_w.dta` | `antropometria_ensanut2024_w.csv` | `integrantes_ensanut2024_w_ICB.dta` |

El pipeline conserva los nombres de origen; véase la lista `files` de `analysis/01_base_analitica.R`. La ronda 2020 no se analiza.

## Derivados y archivos locales

`data/processed/geography/` contiene los grafos reina/torre y la correspondencia entre índice y municipio. `data/processed/covariates/` contiene pobreza, CLUES y altitud. Los insumos locales no se incluyen en Git: tampoco la base individual, sus ponderadores ni los modelos `.rds`, que por compatibilidad se generan en `results/estimates/`.

La reconstrucción exacta necesita las mismas ediciones de los insumos originales. Las páginas oficiales pueden actualizarse: conserve localmente las descargas y sus comprobantes. No se ha inventado una fecha de descarga ni una versión de catálogo que no conste en los archivos disponibles.
