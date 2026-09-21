# Revisión de la respuesta de Rodrigo — 20 de septiembre de 2026

Revisión de `RESPUESTA_RODRIGO.md` y de los archivos públicos en `d1a6e149cd5573b458c5604be777a5bad920ebec`, incorporando la aclaración posterior sobre resúmenes en `8103987`. Mensaje temporal de coordinación: no constituye aprobación de envío ni decisión de los autores.

## Correcciones confirmadas

- **P3:** el manuscrito fuente ya explica correctamente la falta de pobreza municipal publicada. No reabrir esta frase.
- **P8, S5 y S7:** el suplemento público contiene `KS p<0,001` y la comprobación explícita de una única componente conexa. Corregidos.
- **P7, resúmenes:** se acepta la rectificación de `8103987`. Las [normas oficiales de Salud Pública de México](https://saludpublica.mx/index.php/spm/normas), consultadas directamente en esta revisión, establecen 200 palabras para originales; 150 corresponde a comunicaciones breves. Con los recuentos reportados de 195/197 no hay que recortar ni consultar al editor por este motivo. Queda retirado el pendiente previo.
- **P6, `.gitignore`:** la observación era válida. Se restauraron las exclusiones de notas internas, directorios privados antiguos y PDF de terceros en la raíz del PR #1, sin impedir la publicación de PDF propios en `manuscript/`. El PR incorpora los cambios de `main` hasta `d1a6e14`, en el commit `4d0008583a068b8cf67c58757e4063e5965cf4a3`. Pasaron las comprobaciones de integridad de GitHub, el parseo de 30 scripts R y las pruebas de exclusión de archivos privados.

La propagación al Word privado, el resultado 62/62 y las firmas son comprobaciones reportadas por Rodrigo; esta revisión del commit público no las verificó nuevamente.

## P2 y P5: sí existe una base local compatible con los resultados publicados

El agente que revisa en el espacio de trabajo de Vicente ejecutó una comprobación independiente sobre la base local y sus pesos calibrados. No fue una nueva corrida de INLA ni una ejecución del parche privado de Rodrigo. La fecha local es 17 de agosto, pero la conclusión se basa en el contenido, no en esa fecha:

- 25 088 personas y 599 municipios.
- Reconstrucción de presión sistólica/diastólica a partir de las lecturas 2 y 3, con límites 80–270 y 50–180 mmHg: cero discrepancias con las medias guardadas; 32 lecturas crudas fuera de límites entre las personas retenidas.
- Para los cinco desenlaces y ambos esquemas de validación, coinciden los tamaños municipales, las proporciones observadas y los tamaños efectivos con los archivos públicos, hasta precisión numérica.
- Denominadores individuales: 7735, 11597, 5203, 4382 y 4382.

Identificadores de los insumos privados, que **no se suben a Git**:

| Insumo | SHA-256 |
|---|---|
| Base analítica | `4b913f06974e6b1ccf61e5a0e8882f1689d27af59bd02487ace373a43cc00169` |
| Pesos calibrados | `3c45fabdad6250e66958b4910fbfcd2d8eb2fd3092f43c0410fd2c586427f3a0` |

La evidencia agregada está en [04_EVIDENCIA_BASE_Y_COMPARADOR.json](04_EVIDENCIA_BASE_Y_COMPARADOR.json). El script de comprobación queda en el espacio local de Vicente, dentro de `CIERRE_PROYECTO_2026-09-20/revision_respuesta_rodrigo/`.

Reutilizando las predicciones BYM2 y los pliegues publicados, y calculando el promedio ponderado del comparador exclusivamente con entrenamiento, se reprodujeron las cifras de la devolución anterior:

| Desenlace | Reducción RMSE aleatoria, antes → corregida (%) | Contigua, antes → corregida (%) |
|---|---:|---:|
| Diagnóstico ESH | 6,53 → 6,69 | 5,91 → 6,26 |
| Diagnóstico AHA | 9,81 → 9,88 | 9,30 → 9,34 |
| Tratamiento | 9,84 → 10,07 | 8,37 → 8,98 |
| Control ESH | 2,29 → 2,35 | 1,73 → 1,99 |
| Control AHA | 1,35 → 1,31 | 1,51 → 1,86 |

Estas cifras son una comprobación independiente; **los resultados oficiales todavía no se actualizaron**. La corrección aislada del comparador puede aprovechar las predicciones guardadas y no exige por sí misma reajustar INLA. Esto no sustituye la verificación del código ni una eventual nueva corrida si cambia el modelo o el estimando.

Para cerrar P2 falta compartir el parche como código revisable (hoy está solo en `_TRABAJO_INTERNO/`), incorporarlo y regenerar los resultados, tablas, figuras y texto afectados. La frase actual del manuscrito solo describe un valor ponderado común sin estructura espacial ni covariables: **no dice** que incluye los municipios evaluados ni que sea una referencia exclusivamente descriptiva. Esa parte de la respuesta no coincide con el archivo público. Con el comparador corregido, el texto debe describir explícitamente que se estima en cada pliegue usando solo entrenamiento.

Para P5 puede prepararse la tabla descriptiva y de faltantes con la base verificada en este espacio de trabajo. Hay que definir la población de cada columna y distinguir faltantes de exclusiones; después incorporar la tabla y ajustar las referencias de STROBE. Rodrigo no necesita publicar ni recibir los microdatos por Git para que este trabajo avance.

## Aclaraciones adicionales para el cierre

1. **P1 sigue siendo una decisión científica:** mantener e interpretar las probabilidades condicionales estandarizadas actuales, o cambiar el objetivo de estimación y evaluar el trabajo analítico necesario. No presentar el cambio de interpretación como una corrección ya aprobada.
2. **P4 sigue abierto:** acordar el alcance de la supresión y hacer coincidir manuscrito, CSV, JSON, interfaz y descargas con esa decisión. La verificación de `.gitignore` no resuelve este punto.
3. **P6: crear una etiqueta nueva, no mover `v1.4`.** Primero integrar fuentes y generadores con las rutas definitivas, regenerar y comprobar el paquete; después identificar el commit final con una nueva versión y actualizar su cita. Si hay que actualizar la cita dentro del paquete, fijar previamente el identificador previsto y comprobarlo antes de etiquetar. No congelar el paquete antes de adaptar los generadores.
4. **P7: sí hay iniciales en la fuente:** Vicente J. Vílchez-Díaz, Samar S. Sifuentes-Vidigal, Miguel A. Velarde-Mera y Rodrigo J. Cárdenas-Golac. Si se requieren nombres completos, confirmar con cada autor su forma de firma; no deducir los nombres a partir de las iniciales. Si el Word difiere, documentar la diferencia y armonizar la fuente.
5. **P8:** quedan pendientes las formulaciones cautas, «mismas rondas», la revisión de la referencia 24 y la identificación de 46,7 puntos porcentuales como mediana del ancho del intervalo. Agruparlos en una sola revisión editorial es razonable; deben resolverse antes de congelar el contenido científico.

## Qué devolver en la siguiente ronda

Registrar decisiones P1/P4 y confirmar la forma de firma de los autores; compartir el parche P2 y los generadores necesarios sin datos privados; entregar la tabla descriptiva con sus denominadores; señalar commits y derivados regenerados. Mantener separadas las decisiones pendientes y las comprobaciones efectivamente realizadas. El paquete todavía no está cerrado para envío.
