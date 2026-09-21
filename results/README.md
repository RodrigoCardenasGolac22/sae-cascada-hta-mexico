# Resultados de investigación

| Carpeta / patrón | Contenido |
|---|---|
| `estimates/NACIONAL_*.csv` | Estimaciones postestratificadas municipales, incertidumbre, cobertura y marca de supresión en publicación. |
| `estimates/directa_*.csv` | Estimaciones directas de encuesta y tamaños de muestra municipales. |
| `estimates/cv_*.csv` | Pliegues, validación y resúmenes de error. |
| `estimates/resumen_*.csv` | Resúmenes de modelos, cobertura y estimaciones. |
| `estimates/sensibilidad_*.csv` | Sensibilidades de ponderación y vecindad. |
| `tables/` | Cuadros CSV/Excel, STROBE y diagnóstico de conectividad. |
| `figures/` | Figuras PNG/SVG/PPTX/EPS; `data/` contiene los datos Excel asociados. |

Las siglas `AWARE_ESH`, `AWARE_AHA`, `TRAT`, `CONTROL_ESH` y `CONTROL_AHA` identifican los cinco desenlaces. Las columnas `prev`, `prev_q025` y `prev_q975` de los CSV nacionales están en escala 0–1; las figuras y sus leyendas expresan porcentajes cuando corresponde. No confundir estimaciones nacionales directas, predicciones ajustadas en la muestra y predicciones municipales postestratificadas.

## Supresión en publicación

Desde `v1.5`, `suprimir_privacidad=TRUE` identifica celdas municipales cuyo denominador clínico tiene menos de 10 personas. Se omiten estimación, intervalos, ancho y n exacto en los CSV, JSON, HTML y datos de figuras; se conservan identificadores y marcas de supresión. La misma política abarca estimaciones directas, validación, sensibilidad y reclasificaciones derivadas. Una reclasificación se suprime si cualquiera de sus dos desenlaces está protegido. Los municipios sin muestra directa no están sujetos a ese umbral.

Los gráficos de calibración omiten las celdas protegidas; las métricas agregadas de validación se calculan con todos los municipios evaluados. El mapa de incertidumbre también omite sus anchos. Los originales analíticos locales quedan en `results/private/publication_inputs/`, excluidos de Git, y no forman parte de la descarga pública. Los valores publicados antes de `v1.5` siguen en los commits y etiquetas históricos: no se reescribió el historial.

El cierre conserva los ajustes de los modelos, corrige el comparador de validación para usar solo entrenamiento y añade S8. Los CSV públicos suprimidos no bastan para reconstruir todas las métricas agregadas: para ello se requieren los insumos analíticos completos, obtenidos al reproducir el estudio con los microdatos.
