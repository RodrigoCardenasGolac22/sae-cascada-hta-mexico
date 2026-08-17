# Estimación bayesiana de área pequeña de la cascada de atención de la hipertensión arterial en los municipios de México

Código de análisis y resultados derivados del estudio, basado en la Encuesta Nacional de Salud y
Nutrición (ENSANUT) Continua 2021-2024.

Se estima la prevalencia municipal de cada paso de la cascada de atención de la hipertensión
—diagnóstico previo, tratamiento y control— mediante modelos bayesianos espaciales BYM2 de
nivel-unidad ajustados con una pseudo-verosimilitud ponderada en INLA, bajo dos criterios
diagnósticos (ESH 2023, ≥140/90 mmHg; ACC/AHA 2025, ≥130/80 mmHg), con extensión de la predicción
a los municipios sin muestra directa de encuesta.

## Contenido

| Carpeta | Qué contiene |
|---|---|
| `CODIGO/` | Scripts públicos de análisis, tablas, figuras y explorador |
| `RUN_ALL.R` | Punto de entrada: corre el pipeline completo o un rango de pasos |
| `RESULTADOS/` | Resultados numéricos (estimaciones municipales, validación, resúmenes de modelo) |
| `TABLAS/` | Tablas del manuscrito y checklist STROBE, en `.csv` y `.xlsx` |
| `FIGURAS/` | Figuras en `.png`, `.svg` y `.pptx` editable |
| `COVARIABLES/` | Covariables municipales ya construidas (pobreza, establecimientos de salud, altitud) |
| `DATOS_GEO_MEXICO/` | Geometría municipal INEGI, grafos de vecindad y el script que calcula la altitud media municipal a partir del modelo digital de elevación (`scripts_verificacion/`) |
| `MANUSCRITO_BORRADOR.md` | Fuente pública del texto; la conversión editorial se ejecuta localmente |
| `sessionInfo.txt` | Entorno de R y versiones de paquetes de la última corrida |

## Cómo reproducir el análisis

### 1. Requisitos

R ≥ 4.6 con los paquetes listados en `sessionInfo.txt`. La instalación de **R-INLA** no está en CRAN:

```r
install.packages("INLA", repos = c(INLA = "https://inla.r-inla-download.org/R/stable"), dep = TRUE)
```

### 2. Descargar los insumos externos

Ninguno de los dos se redistribuye aquí: ambos son públicos y se obtienen de la fuente oficial.

**a) Microdatos ENSANUT Continua** — https://ensanut.insp.mx (en cada ronda: *Descargar bases*).
Colocar en `DATOS_ENSANUT/microdatos_por_anio/<año>/` los tres módulos de cada año (adultos,
antropometría/tensión arterial e integrantes del hogar). Los nombres de archivo exactos que espera
el pipeline están en la lista `files` de `CODIGO/01_base_analitica.R`:

| Año | Adultos | Antropometría | Integrantes |
|---|---|---|---|
| 2021 | `ensadul2021_entrega_w_15_12_2021.csv` | `ensaantro21_entrega_w_17_12_2021.csv` | `integrantes_ensanut2021_w_12_01_2022.csv` |
| 2022 | `ensadul2022_entrega_w.csv` | `ensaantro2022_entrega_w.csv` | `integrantes_ensanut2022_w.csv` |
| 2023 | `adultos_ensanut2023_w_n.csv` | `Antropometria_HTA_4mar24.csv` | `integrantes_ensanut2023_w_n.csv` |
| 2024 | `adultos_ensanut2024_w.dta` | `antropometria_ensanut2024_w.csv` | `integrantes_ensanut2024_w_ICB.dta` |

La ronda 2020 no se usa: su módulo de adultos no incluye las preguntas de diagnóstico y tratamiento
de hipertensión. Los archivos de 2024 se leen en formato Stata (`haven`).

**b) Censo de Población y Vivienda 2020, tabulado ITER nacional** —
https://www.inegi.org.mx/programas/ccpv/2020/ (*Datos abiertos* → ITER, entidad 00). Necesario en el
paso 09 para la composición de población por estrato de urbanidad de cada municipio. Colocar en
`DATOS_GEO_MEXICO/iter_00_cpv2020/` o indicar su ruta con la variable de entorno `ITER_CSV`.

### 3. Correr el pipeline

Desde la **raíz del repositorio** (todos los scripts usan rutas relativas a ella):

```bash
Rscript RUN_ALL.R          # pipeline completo
Rscript RUN_ALL.R 18 25    # solo figuras, tablas, STROBE y datos del explorador
```

Los pasos 06 a 12c ajustan o reutilizan modelos con INLA y son la parte lenta (decenas de minutos
en total; el paso 10 corre validación cruzada de 5 pliegues sobre 5 desenlaces). Los pasos 13 a 24
producen figuras, tablas, STROBE y los datos del explorador a partir de resultados ya calculados.
`RUN_ALL.R` ejecuta únicamente artefactos públicos y actualiza `sessionInfo.txt` solo después de
una corrida completa.

### 4. Qué genera el pipeline y no está versionado aquí

- Los modelos INLA ajustados (`RESULTADOS/*.rds`, ~121 MB): los reconstruyen los pasos 05-09.
- La base analítica a nivel individual (`RESULTADOS/base_analitica_adultos_2021_2024.csv`): la
  reconstruye el paso 01 a partir de los microdatos.

## Orden del pipeline

| Paso | Script | Qué hace |
|---|---|---|
| 01 | `01_base_analitica.R` | Base analítica 2021-2024 y flujo de selección STROBE |
| 02 | `02_covariable_clues.R` | Establecimientos de salud por municipio (CLUES) |
| 02b | `02b_calibrar_ponderador.R` | Calibra el ponderador de la submuestra con presión arterial válida y lo valida contra el `t_ponde` que ENSANUT 2023 publica |
| 03 | `03_verificar_covariables.R` | Control de calidad del cruce de covariables municipales |
| 04 | `04_estimaciones_directas.R` | Prevalencia directa por municipio, con diseño complejo |
| 05 | `05_grafo_vecindad.R` | Matrices de vecindad municipal (contigüidad reina y torre) |
| 06 | `06_modelos_univariados.R` | Modelos BYM2 base, sin covariables de área |
| 07 | `07_seleccion_covariables.R` | Selección ponderada de covariables por ΔWAIC, log-CPO y fallos CPO |
| 08 | `08_modelos_finales.R` | Modelos finales desde una especificación compartida y reclasificación ESH vs. ACC/AHA |
| 08b | `08b_coeficientes.R` | Efecto del año y coeficientes de área, desde los modelos ya ajustados |
| 09 | `09_extension_nacional.R` | Post-estratificación censal y predicción en municipios sin muestra directa |
| 10 | `10_validacion_cruzada.R` | Validación cruzada espacial de 5 pliegues |
| 06b | `06b_baseline_iid.R` | Comparación IID frente a BYM2 con las mismas filas, pesos y pliegues |
| 11 | `11_benchmark_nacional.R` | Comparación con las cifras nacionales publicadas |
| 12 | `12_sensibilidad_vecindad.R` | Sensibilidad a la definición de vecindad |
| 12b | `12b_diagnosticos_supuestos.R` | Diagnósticos de los modelos finales |
| 12c | `12c_sensibilidad_ponderada.R` | Modelo principal ponderado frente a sensibilidad sin ponderar |
| 13-17 | `13_fig1_*` … `17_figS2_*` | Figuras 1-3 y S1-S2 |
| 18 | `18_tablas.R` | Tablas 1, 2, 2b y S1 |
| 20 | `20_checklist_strobe.R` | Checklist STROBE |
| 24 | `24_datos_explorador.R` | Datos derivados para el explorador municipal |

La construcción de manuscritos `.docx`, material suplementario y paquetes de envío se mantiene en
scripts locales ignorados por Git. Esos scripts consumen `MANUSCRITO_BORRADOR.md` y las salidas
versionadas, pero no forman parte del pipeline reproducible público.
El marcador de correspondencia del borrador se completa localmente desde
`LEEME_CORRESPONDENCIA.txt`, también ignorado, para no publicar dirección, teléfono ni correo.

## Fuentes de datos

| Fuente | Uso | Acceso |
|---|---|---|
> El insumo crudo de CLUES (26 MB) no se versiona: el análisis usa el derivado
> `clues_conteo_municipal.csv`, que sí está aquí. El crudo se descarga del catálogo oficial de
> la Secretaría de Salud, igual que los microdatos de ENSANUT.

| ENSANUT Continua 2021-2024 (INSP) | Microdatos individuales: presión arterial medida, diagnóstico y tratamiento autorreportados | https://ensanut.insp.mx |
| Censo de Población y Vivienda 2020 (INEGI) | Composición de población por estrato de urbanidad | https://www.inegi.org.mx/programas/ccpv/2020/ |
| Marco Geoestadístico (INEGI) | Geometría de los 2 478 municipios | Incluido en `DATOS_GEO_MEXICO/` |
| CONEVAL 2020 | Pobreza municipal | Incluido en `COVARIABLES/coneval_pobreza_municipal_2020.csv` (ver nota abajo) |
| CLUES (Secretaría de Salud) | Establecimientos de salud | Crudo en `COVARIABLES/clues_establecimientos_salud.xlsx`, procesado por el paso 02 |

**Nota sobre CONEVAL.** A diferencia de CLUES, este archivo se versiona ya derivado: no hay script
que lo construya. Procede de las *Medición de la pobreza a nivel municipal 2020* de CONEVAL
(https://www.coneval.org.mx/Medicion/Paginas/Pobreza-municipio-2010-2020.aspx), de la que se
tomaron dos columnas: la clave de municipio y el porcentaje de población en situación de pobreza.
El pipeline la usa como `pobreza_pct` y sólo depende de esas dos columnas.

## Ponderadores

La medición de presión arterial se hace en una submuestra del módulo de adultos, así que la base
analítica es una submuestra de respondentes dentro del marco de adultos elegibles. La ronda **2023**
—y sólo esa— publica un ponderador propio del módulo de tensión arterial (`t_ponde`, «Ponderador
THA»), que re-expande esa submuestra a la población adulta. Para poder aplicar la misma corrección
en los cuatro años, el paso **02b** calibra el ponderador por celdas de post-estratificación
(año × estrato × sexo × grupo de edad) contra el marco de elegibles que produce el paso 01, y
**valida el resultado contra `t_ponde` en 2023**, el único año donde existen los dos. Las salidas
de esa validación (`RESULTADOS/validacion_calibracion_2023.csv` y
`comparacion_ponderadores_nacional.csv`) son las que sustentan qué ponderador se usa en el análisis
principal.

En los modelos, `ponde_cal` se normaliza a media 1 dentro de cada municipio después de aplicar el
denominador analítico de cada desenlace. El peso resultante (`peso_modelo`) conserva la composición
relativa de la muestra sin tratar la suma de pesos poblacionales como tamaño de muestra. Esta
pseudo-verosimilitud ponderada se usa en modelos base, selección, modelos finales, validación,
comparación IID, sensibilidad de vecindad y diagnósticos. El paso 12c reajusta los cinco desenlaces
sin ponderar como análisis de sensibilidad y reporta la discrepancia por tamaño muestral municipal.

## Licencia

El código de este repositorio se distribuye bajo la **licencia MIT** (ver `LICENSE`): se puede
usar, copiar, modificar y redistribuir libremente, citando la autoría. Es compatible con la
licencia de acceso abierto bajo la que se publique el artículo, que depende de la revista
que lo acepte.

Los microdatos de ENSANUT Continua **no** se redistribuyen aquí: son de acceso público en
https://ensanut.insp.mx y se rigen por los términos del Instituto Nacional de Salud Pública.

## Explorador municipal

**<https://rodrigocardenasgolac22.github.io/sae-cascada-hta-mexico/>**

Es un mapa consultable de los 2478 municipios: los tres pasos de la cascada bajo
los dos criterios, cada uno con su intervalo de credibilidad, y una vista que colorea por **ancho
del intervalo** en vez de por estimación.

Existe por una razón medible: el mapa impreso resuelve 3,2 km por píxel, así que **63 municipios
ocupan menos de un píxel y 1305 no llegan a 5×5**. En papel, la mitad del país son puntos. Aquí no.

Se genera con `24_datos_explorador.R` (datos) y `25_explorador_html.py` (página). Es **un solo
archivo sin dependencias externas**: funciona servido por GitHub Pages y también abriéndolo desde
el disco. No sustituye al artículo; es su complemento consultable.

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

## Cómo citar

Si se usa este código, citar el artículo asociado:

> Vílchez-Díaz VJ, García-Ruiz O, Sifuentes-Vidigal SS, Velarde-Mera MA, Cárdenas-Golac RJ.
> Estimación bayesiana de área pequeña de la
> cascada de atención de la hipertensión arterial en los municipios de México (ENSANUT Continua
> 2021-2024). *Rev Peru Med Exp Salud Publica*. [en evaluación].
