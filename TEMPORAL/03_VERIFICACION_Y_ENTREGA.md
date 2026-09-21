# Evidencia y entrega esperada

## Datos que ya se comprobaron

- Selección: 45 011 − 19 601 − 321 − 1 = **25 088 personas**, 599 municipios distintos.
- Modelos: diagnóstico ESH 7 735; diagnóstico AHA 11 597; tratamiento 5 203; control 4 382, frente a 4 388 elegibles.
- Calibración 2023: diferencias absolutas promedio 0,9217 frente a 0,4833 pp, redondeadas a 0,92 y 0,48.
- S2B: cinco desenlaces y sus tres estratos, concordantes con `sensibilidad_ponderada.csv` y `sensibilidad_ponderada_por_n.csv`.
- S4: 20 filas, 60 celdas numéricas de selección concordantes con `resumen_covariables_waic_cpo.csv`; máximo entre mejoras de 0,69 y cuatro razones de deterioro mayores de 2.
- Grafo: recorrido independiente del `.graph` verificó 2 478 nodos, una componente y cero aristas asimétricas. No hace falta suponer conectividad a partir de cero aislados.
- Supresión: en los cinco CSV nacionales, **1 876** celdas marcadas conservan la estimación: ESH diagnóstico 351; AHA diagnóstico 220; tratamiento 429; ESH control 438; AHA control 438. El JSON también contiene esos valores.

## Efecto de recalcular solo la referencia de CV

La revisión anterior reutilizó predicciones BYM2 y pliegues guardados, y recalculó únicamente el promedio de referencia usando entrenamiento. No volvió a ajustar INLA ni cambió los resultados oficiales:

| Desenlace | Reducción aleatoria guardada | Referencia solo de entrenamiento | Contigua guardada | Contigua con referencia de entrenamiento |
|---|---:|---:|---:|---:|
| Diagnóstico ESH | 6,5% | 6,7% | 5,9% | 6,3% |
| Diagnóstico AHA | 9,8% | 9,9% | 9,3% | 9,3% |
| Tratamiento | 9,8% | 10,1% | 8,4% | 9,0% |
| Control ESH | 2,3% | 2,4% | 1,7% | 2,0% |
| Control AHA | 1,3% | 1,3% | 1,5% | 1,9% |

El efecto es pequeño y mantiene la dirección. Si se adopta la corrección, reproducirla en el pipeline y actualizar CSV, S1, Figura S1 y rangos citados. Esta tabla de comunicación no reemplaza esa regeneración. La selección de covariables se hizo antes de la CV: esta evalúa la especificación final fija, no todo el proceso de selección.

## Equivalencia de rutas

| `main` al preparar este mensaje | Rama de reorganización / PR #1 |
|---|---|
| `CODIGO/` | `analysis/` |
| `RESULTADOS/` | `results/estimates/` |
| `TABLAS/` | `results/tables/` |
| `FIGURAS/` | `results/figures/` |
| `MANUSCRITO_BORRADOR.md` | `manuscript/manuscript.md` |
| `SUPLEMENTARIO/` | `manuscript/supplement/` |
| `sessionInfo.txt` | `reproducibility/sessionInfo.txt` |

El PR #1 integró las correcciones hasta `23d0ccd` en `e2d8dbe`. El commit posterior `cf46b0f` debe conservarse al sincronizarlo antes de la integración definitiva. La carpeta `TEMPORAL/` se añade a `main` solo para comunicación: no fusiona el PR ni reorganiza por sí misma el árbol principal.

Las comprobaciones de la reorganización pasaron: sintaxis R/Python, referencias estáticas, exclusiones privadas, artefactos y construcción del explorador. El verificador del PR usa un manifiesto de referencia y actualizaciones explícitas: si cambian artefactos, registrar motivo y hashes; no alterar el hash histórico para ocultar una diferencia.

## Qué devolver en `RESPUESTA_RODRIGO.md`

Para cada P1–P8, indicar **cerrado / parcial / pendiente / discrepancia justificada**, y añadir:

1. Cambio aplicado o decisión de los autores.
2. Ruta y commit de la fuente modificada.
3. Derivados regenerados y cotejo realizado.
4. Limitación o acción que aún falta, si corresponde.

Para el cierre final, hacer concordar fuente, Word, cuadros, figuras, suplemento, STROBE y versión pública; recontar palabras y revisar maquetación. Confirmar el juego firmado existente y la aprobación de los autores por el canal privado correspondiente. Crear una versión nueva e inmutable que identifique ese conjunto y comprobar sus enlaces.

La revisión realizada es textual, numérica y de código; no certifica todas las páginas renderizadas, firmas, uso histórico de herramientas de IA ni una nueva reproducción completa de INLA. No atribuir a estas comprobaciones un alcance mayor.

Esta carpeta no debe aparecer en el paquete de envío. Retirarla del árbol activo cuando termine el intercambio, de acuerdo con `CLAUDE.md`.
