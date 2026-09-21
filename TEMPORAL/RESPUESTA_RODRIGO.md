# Respuesta a 01_ESTADO_Y_PENDIENTES.md

Referencia: mensaje de Vicente hasta `cf46b0f`, comparado contra el estado tras pullear
`e2d9d95`. Verifiqué de forma independiente las cifras que cito abajo (grafo, celdas
suprimidas, contenido de los CSV) antes de aceptarlas; no las doy por buenas solo porque
las reporta el mensaje.

## P1. Estimando de los mapas — **pendiente, decisión de autores**

No apliqué ningún cambio. La observación es correcta: el modelo estima dentro de cada
denominador clínico (hipertensos/diagnosticados/tratados) y se post-estratifica con la
composición censal de adultos en general, no con la del denominador clínico. Eso hace que
la cifra publicada sea una probabilidad condicional estandarizada, no una prevalencia
municipal directa.

**No es algo que yo pueda decidir por los autores.** Necesito que Rodrigo confirme: ¿el
estimando que quieren comunicar es la probabilidad condicional estandarizada (como está
hoy) o prefieren re-especificar la post-estratificación para que sea una proporción dentro
del denominador clínico municipal? La segunda opción implica tocar `09_extension_nacional.R`
y volver a correr INLA, no solo redactar.

## P2. Comparador de validación cruzada — **parcial, bloqueado por datos**

Confirmé el defecto: en `10_validacion_cruzada.R`, `promedio_nacional` se calcula sobre
`sub$y_real` completo, antes de separar pliegues, así que el comparador ve los municipios
que luego evalúa.

Preparé el parche que separa el comparador (promedio ponderado de los pliegues de
entrenamiento) del promedio nacional descriptivo, en
`_TRABAJO_INTERNO/patch_10_comparador_en_pliegue.diff`. **No lo apliqué ni lo corrí**
porque mi copia local de `RESULTADOS/base_analitica_adultos_2021_2024.csv` es del
2026-08-02, anterior al techo fisiológico (270/180 mmHg) que sí está en
`01_base_analitica.R` desde el 2026-08-06 — con esa base el modelo no reproduce el que
publicamos. No tengo los microdatos ENSANUT para regenerarla desde cero. Necesito que
alguien con la base vigente (Vicente, si la tiene regenerada) corra el parche y regenere
`cv_detalle_*`, `resumen_validacion_cruzada.csv`, `cv_rmse_estratificado.csv`, Tabla S1 y
Figura S1.

Mientras tanto, corregí la frase del manuscrito para que declare la referencia como
descriptiva y no como comparador predictivo independiente (ver `MANUSCRITO_BORRADOR.md`,
párrafo de Reclasificación y validación — commit previo `23d0ccd`, sin cambios en esta
ronda). Si la tabla que trae `03_VERIFICACION_Y_ENTREGA.md` (reducción de RMSE 6,5%→6,7% en
diagnóstico-ESH, etc.) es de una corrida real, dime si la corriste tú o Vicente y con qué
base, para poder verificarla contra la fuente antes de citarla en cualquier parte.

## P3. Motivo de pobreza faltante — **cerrado**

Corregido en `MANUSCRITO_BORRADOR.md` (commit de esta ronda). Adopté tu redacción, más
clara que mi intento anterior:

> "En control se excluyeron seis de 4388 registros por falta de pobreza municipal
> publicada; CONEVAL carece de esta estimación en tres municipios del marco (Tabla S1)."

Verificado contra `COVARIABLES/coneval_pobreza_municipal_2020.csv`: los tres municipios con
"n.d" son 04012 (Seybaplaya), 07125 (Honduras de la Sierra) y 29048 (La Magdalena
Tlaltelulco). De esos, solo 04012 y 29048 tienen registros en la base analítica de control
(1 y 5, total 6); 07125 no tiene ningún registro. La frase nueva ya no afirma que los seis
registros vengan de "tres" municipios, así que no reintroduce esa imprecisión.
**Repropagado al paquete** (`0_ENVIO_SPM/MANUSCRITO_SPM.docx`), auditor 62/62, 3985/4000
palabras. **Pendiente:** volver a correr Turnitin — guardé la versión exacta como
`_TRABAJO_INTERNO/TURNITIN_INFORMES/PRUEBAS_2026-09-18/MANUSCRITO_SPM_vU1_pobreza_S5_S7.docx`,
que difiere de la última versión confirmada en `*%` (vS1) solo en este párrafo.

## P4. Concordancia entre supresión declarada y archivos públicos — **pendiente, decisión de autores**

Confirmé tu cifra: 1876 celdas marcadas `suprimir_privacidad=TRUE` en los cinco
`NACIONAL_*.csv` conservan valor, IC y n (351+220+429+438+438=1876). El JSON del
explorador también los trae completos (comprobado antes en esta sesión con el municipio
Jesús María, n=3).

No es algo que yo pueda resolver solo: implica decidir si la política es "no mostrar en
pantalla" (lo que ya cumplimos) o "no publicar el valor en ningún archivo descargable" (lo
que no cumplimos). Si Rodrigo elige la segunda, hay que blanquear valor/IC/n en los CSV,
el JSON y las descargas del explorador — y ese cambio, aplicado sobre commits ya públicos
en GitHub, no borra el valor del historial. Reescribir el historial es una operación
destructiva aparte, que no voy a hacer sin que Rodrigo la pida explícitamente.

## P5. Contenido que STROBE remite — **pendiente**

`cf46b0f` corrigió la ubicación declarada (ya no dice que el Cuadro I trae descriptivos
que no tiene), pero no agrega la tabla de características/faltantes por covariable que
STROBE 14a/14b piden. Construirla (edad, sexo, escolaridad, urbanidad, con faltantes) es
factible con `RESULTADOS/base_analitica_adultos_2021_2024.csv`, pero con la salvedad de
arriba: mi copia local es anterior al techo fisiológico. Puedo prepararla en cuanto haya
una base vigente confirmada, como Tabla S8.

## P6. Versión, rutas y reproducibilidad — **sin cambios, en el orden ya acordado**

No moví la etiqueta `v1.4` ni mergeé el PR #1. Sigue el orden: Vicente termina su revisión
→ armamos el paquete final → movemos la etiqueta → mergeamos la reorganización (con el
`.gitignore` corregido, que actualmente en el PR deja de ignorar notas internas y PDF de
terceros) → actualizo mis generadores a las rutas nuevas.

## P7. Puntos editoriales — **pendiente de decisión/contacto con la revista**

- **Resúmenes (195/197 palabras):** la incoherencia 150 vs 200 está en las propias
  instrucciones de la revista (Normas dice 200 para artículo original; Envíos, en un
  fragmento suelto, dice 150). No la puedo resolver por mi cuenta — o consultamos al editor,
  o recortamos a 150 por seguridad. Decisión de Rodrigo.
- **Nombres completos:** no encontré ninguna abreviatura deducida por iniciales en el
  manuscrito actual; si Vicente tiene un caso concreto, dime cuál.
- **Firmas:** confirmado que las cinco declaraciones y la carta están firmadas (lo verifiqué
  extrayendo las imágenes incrustadas antes de esta ronda). No hay nada pendiente ahí salvo
  que cambie el texto de la carta, en cuyo caso se vuelve a firmar.

## P8. Ajustes finales de precisión

- **S5, "KS p=0,000":** corregido a "KS p<0,001" cuando el valor redondeado es 0
  (`CODIGO/21_material_suplementario.R`). El p real no cambia, solo la notación.
- **S7, conectividad:** corregido. Hice un BFS independiente sobre
  `DATOS_GEO_MEXICO/municipios.graph` (no reutilicé el resultado de `05b_conectividad_grafo.R`):
  2478 nodos, **1 sola componente conexa**, 0 aristas asimétricas. La nota ya no infiere
  conexidad de "cero municipios aislados" (lógicamente insuficiente); ahora reporta el
  resultado verificado.
- **"No hubo"/"ausente" vs. formulaciones cautas, "datos idénticos" → "mismas rondas",
  referencia 24, "46,7 pp" como mediana del ancho del IC:** no los toqué. Son cambios de
  registro/redacción del cuerpo principal, cerca de zonas que Turnitin ya marcó en el
  pasado; prefiero agruparlos en una sola ronda de prueba en vez de tocarlos uno por uno,
  para no gastar intentos de Turnitin. Dime si quieres que los prepare como variante.

## Repropagado y verificado en esta ronda

- `MANUSCRITO_BORRADOR.md` (P3), `CODIGO/21_material_suplementario.R` (S5, S7) →
  `0_ENVIO_SPM/MANUSCRITO_SPM.docx`, `SUPLEMENTARIO/MATERIAL_SUPLEMENTARIO.docx`
  regenerados. Auditor: 62/62. Palabras: 3985/4000.
- No se tocó `TABLAS_SPM.xlsx`, `STROBE_Checklist.xlsx` (ya corregidos en `cf46b0f`) ni las
  figuras.

## Lo que necesito de vuelta

1. Decisión P1 (estimando).
2. Confirmar si alguien tiene la base analítica vigente (post-techo fisiológico) para correr
   el parche de P2 y, si aplica, la Tabla S8 de P5.
3. Decisión P4 (alcance de la supresión: solo pantalla, o también archivos descargables).
4. Decisión P7 (resumen a 150 o consulta a la revista).
5. Confirmación de que `MANUSCRITO_SPM_vU1_pobreza_S5_S7.docx` puede subirse a Turnitin antes
   de darlo por definitivo.
