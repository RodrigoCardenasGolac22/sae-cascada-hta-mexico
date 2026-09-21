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

## P7. Puntos editoriales

- **Resúmenes (195/197 palabras) — cerrado, no había discrepancia.** Corrijo algo que dije
  mal en la ronda anterior: afirmé que la revista se contradecía entre 150 y 200 palabras.
  Era un error mío, por leer un fragmento suelto sin su contexto. Releí el párrafo completo
  de la página "Normas" (`_norma_normas.txt`, líneas 250-264): "La extensión máxima del
  resumen es de 200 palabras para artículos originales **y de 150 para comunicaciones
  breves**"; el abstract en inglés repite la misma distinción. El "150" de
  `_norma_envios.txt` (líneas 45-50) pertenece al párrafo de "Artículo breve" (otra
  sección, máximo 1200 palabras en total) — un tipo de trabajo que no es el nuestro. Verifiqué
  además contra la versión 2012 de las normas (Salud Publica Mex 2012;54(1):68-77, misma
  distinción: 150 para original, 100 para breve en ese entonces), así que no es un artefacto
  de la página actual. Nuestros resúmenes, 195 y 197 palabras, están dentro del límite de
  200. No hay nada que acortar ni que consultar con el editor.
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
4. Confirmación de que `MANUSCRITO_SPM_vU1_pobreza_S5_S7.docx` puede subirse a Turnitin antes
   de darlo por definitivo.

---

# Ronda 2 — respuesta a 04_REVISION_DE_RESPUESTA.md

## P2 — corregido lo que señalaron con razón

Tenían razón en dos cosas y las corregí:

1. **El parche no era código revisable.** Vivía como `.diff` dentro de `_TRABAJO_INTERNO/`,
   que está en `.gitignore` — nadie fuera de mi sesión podía verlo. Lo apliqué directamente
   a `CODIGO/10_validacion_cruzada.R` (que sí está versionado) y lo comenté como "pendiente
   de correr", con la fecha y el motivo. Confirmé que el R parsea sin error. **No lo
   ejecuté** — sigo sin la base vigente. Commit de esta ronda.
2. **La frase del manuscrito no describía completo el comparador actual.** Decía "sin
   estructura espacial ni covariables" pero no decía que se calcula sobre toda la muestra,
   incluidos los municipios evaluados. La corregí:

   > "...sin estructura espacial ni covariables, que incluye los municipios evaluados: no
   > es una predicción independiente del entrenamiento."

   Repropagado al paquete: auditor 62/62, 3997/4000 palabras. Guardé la versión exacta como
   `MANUSCRITO_SPM_vV1_comparador_completo.docx` en `PRUEBAS_2026-09-18/`. **Pendiente
   Turnitin** antes de darla por definitiva.

Sobre la comprobación independiente que hicieron (SHA-256 de la base y los pesos, 25 088
personas, 599 municipios, denominadores 7735/11597/5203/4382/4382, discrepancia cero en
las medias de PA): coincide exactamente con lo que yo mismo había calculado sobre mi copia
desactualizada del 2 de agosto en un mensaje anterior de esta sesión (mismos denominadores).
Eso sugiere que la base no cambió entre el 2 de agosto y el 17 de agosto en las columnas que
importan para esto — pero no lo doy por cerrado solo por esa coincidencia: cuando se corra
el parche de verdad, que la reducción de RMSE resultante coincida con la tabla que ya
compartieron (6,53→6,69 en diagnóstico-ESH, etc.) es la prueba real.

## P4 — sigue abierto, sin cambios

De acuerdo en que la corrección de `.gitignore` no resuelve esto. Sigue pendiente de
decisión de Rodrigo.

## P6 — corrijo mi plan: crear `v1.5`, no mover `v1.4`

Tenían razón. "Mover" una etiqueta ya publicada en GitHub es reescribir una referencia
pública — evitable y evitado por norma en este proyecto. El plan correcto es crear una
etiqueta nueva sobre el commit final, una vez integradas las fuentes y los generadores con
las rutas de la reorganización y regenerado el paquete. Actualizo mi nota anterior.

## P7 — nombres sin abreviar: hallazgo nuevo, se lo paso a Rodrigo tal cual

Tienen razón en que hay iniciales de segundo nombre en la portada del manuscrito (Vicente
**J.** Vílchez-Díaz, Samar **S.** Sifuentes-Vidigal, Miguel **A.** Velarde-Mera, Rodrigo
**J.** Cárdenas-Golac) y que la norma pide "nombres no abreviados". **No es algo que yo
pueda resolver**: no sé qué nombre completo corresponde a cada inicial, y no voy a
inventarlo. Necesito que cada autor confirme cómo quiere que figure su nombre completo.

## P8 — sin cambios

Sigo de acuerdo en agruparlos en una sola ronda de prueba antes de congelar el contenido
científico.

## Repropagado en la ronda 2

- `CODIGO/10_validacion_cruzada.R`: parche del comparador aplicado, sin correr.
- `MANUSCRITO_BORRADOR.md`: frase del comparador completada.
- Paquete regenerado: auditor 62/62, 3997/4000 palabras.
- Pendiente: Turnitin de `MANUSCRITO_SPM_vV1_comparador_completo.docx`; nombres completos
  de los cuatro autores con inicial de segundo nombre; P1 y P4 siguen siendo decisiones de
  Rodrigo.
