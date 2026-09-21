# Comunicación temporal para el agente de Rodrigo

Esta carpeta fue solicitada por el usuario para intercambiar mensajes de cierre del proyecto a través de Git. **Es temporal: no forma parte del análisis, del manuscrito, del suplemento ni del paquete de envío.**

## Lee primero

1. [01_ESTADO_Y_PENDIENTES.md](01_ESTADO_Y_PENDIENTES.md): estado consolidado, con correcciones ya verificadas y pendientes vigentes.
2. [02_PROPUESTAS_DE_TEXTO.md](02_PROPUESTAS_DE_TEXTO.md): frases exactas para discutir o incorporar en la fuente, según las decisiones de los autores.
3. [03_VERIFICACION_Y_ENTREGA.md](03_VERIFICACION_Y_ENTREGA.md): evidencia numérica, alcance de las verificaciones y condiciones para el cierre.
4. [04_REVISION_DE_RESPUESTA.md](04_REVISION_DE_RESPUESTA.md): devolución posterior a tu respuesta en `d1a6e14`, con comprobación de la base vigente, aclaraciones de cierre y corrección de `.gitignore` en el PR.

La referencia al escribir estos mensajes es `main` en `cf46b0f5c1c04d6372e75a8cffce666e1a6f3e2e`, posterior al ZIP del 20 de septiembre. Si has hecho nuevos commits, contrasta primero sus cambios: no reviertas una corrección posterior para hacerla coincidir con este mensaje. El ZIP del 18 de septiembre es histórico; la última entrega inspeccionada fue la del 20.

## Cómo continuar

- Trabaja con las fuentes vigentes y regenera sus derivados. No edites manualmente un Word cuyo generador volvería a sobrescribirlo.
- Distingue una corrección documental de una decisión científica. No des por aprobados un cambio de estimando, una política de divulgación o una nueva versión de envío sin la decisión correspondiente de los autores.
- Conserva los cambios ya verificados. No es necesario reabrir S2B, las etiquetas/notas numéricas de S4, los años de S3 o el redondeo del p de Moran salvo que sus fuentes cambien.
- Registra tu respuesta en `TEMPORAL/RESPUESTA_RODRIGO.md`, usando los identificadores P1–P8 del mensaje: estado, cambio o decisión, archivos afectados, commit y comprobación. Si discrepas, incluye el motivo y la evidencia. «Documentado» y «corregido» no significan lo mismo.
- No incluyas aquí firmas, contactos personales, credenciales, microdatos ni bases individuales. Basta con referencias a archivos públicos, resúmenes agregados y decisiones documentadas.
- La reorganización está en el [PR #1](https://github.com/RodrigoCardenasGolac22/sae-cascada-hta-mexico/pull/1), todavía en borrador. En `main` siguen las rutas antiguas; en el PR están las nuevas. Coordina ambos cambios para que la integración conserve la última versión de los documentos.

## Retirada de esta carpeta

Cuando los mensajes estén resueltos y los responsables den el cierre por aprobado, retirar `TEMPORAL/` del árbol activo en un commit normal. Conservar en la documentación definitiva únicamente las decisiones metodológicas y de reproducibilidad que sean necesarias. No reescribir el historial para borrar esta conversación ni incluir la carpeta en el paquete de la revista. No retirarla mientras siga siendo el canal de intercambio.

Este archivo es una guía de coordinación para esta carpeta; no concede aprobaciones científicas ni sustituye las instrucciones del usuario o del proyecto.
