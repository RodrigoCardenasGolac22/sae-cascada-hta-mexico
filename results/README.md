# Resultados de investigación

| Carpeta / patrón | Contenido |
|---|---|
| `estimates/NACIONAL_*.csv` | Estimaciones postestratificadas municipales, incertidumbre, cobertura y marca de supresión visual. |
| `estimates/directa_*.csv` | Estimaciones directas de encuesta y tamaños de muestra municipales. |
| `estimates/cv_*.csv` | Pliegues, validación y resúmenes de error. |
| `estimates/resumen_*.csv` | Resúmenes de modelos, cobertura y estimaciones. |
| `estimates/sensibilidad_*.csv` | Sensibilidades de ponderación y vecindad. |
| `tables/` | Cuadros CSV/Excel, STROBE y diagnóstico de conectividad. |
| `figures/` | Figuras PNG/SVG/PPTX/EPS; `data/` contiene los datos Excel asociados. |

Las siglas `AWARE_ESH`, `AWARE_AHA`, `TRAT`, `CONTROL_ESH` y `CONTROL_AHA` identifican los cinco desenlaces. Las columnas `prev`, `prev_q025` y `prev_q975` de los CSV nacionales están en escala 0–1; las figuras y sus leyendas expresan porcentajes cuando corresponde. No confundir estimaciones nacionales directas, predicciones ajustadas en la muestra y predicciones municipales postestratificadas.

## Supresión visual

En los CSV nacionales, `suprimir_privacidad=TRUE` identifica municipios con muestra directa menor que 10 para el desenlace. Las figuras y el explorador ocultan su estimación en pantalla; los CSV y el JSON del explorador actualmente conservan los valores. Por tanto, estos archivos no implementan supresión de datos en su contenido. Una política futura de supresión también en descargas requiere revisar CSV, JSON, HTML embebido y el historial público en conjunto.

El cierre conserva las estimaciones municipales y corrige el comparador de validación para calcularlo solo con entrenamiento. Se añade la Tabla S8 de características y faltantes. La política existente de divulgación no se modifica sin la decisión de los autores.
