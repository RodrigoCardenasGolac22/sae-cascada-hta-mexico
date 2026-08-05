# -*- coding: utf-8 -*-
"""Arma docs/index.html embebiendo docs/datos.json en la plantilla.

Un solo archivo, sin CDN ni peticiones: igual que el explorador de Peru. Asi funciona tambien
abriendolo desde el disco, no solo servido por GitHub Pages -- y no depende de que un servidor
externo siga vivo dentro de cinco anos.
"""
import io, json, os, sys
sys.stdout.reconfigure(encoding="utf-8")
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

datos = io.open("docs/datos.json", encoding="utf-8").read()
plant = io.open("CODIGO/plantilla_explorador.html", encoding="utf-8").read()

MARCA = "/*__DATOS__*/"
if plant.count(MARCA) != 1:
    raise SystemExit("la plantilla debe tener exactamente una marca %s" % MARCA)

# El JSON se inyecta tal cual dentro de un <script>. Lo unico que puede romperlo es la secuencia
# "</script>" dentro de una cadena; se escapa. Es el unico caso, y no es teorico: un nombre de
# municipio con "<" bastaria.
datos = datos.replace("</", "<" + chr(92) + "/")

i18n = io.open("CODIGO/i18n_explorador.json", encoding="utf-8").read()
MARCA_I = "/*__I18N__*/"
if plant.count(MARCA_I) != 1:
    raise SystemExit("la plantilla debe tener exactamente una marca %s" % MARCA_I)

# Las dos versiones tienen que llevar las MISMAS claves: si al traducir se olvida una, la pagina
# escribe "undefined" en ingles y nadie lo ve hasta que un lector se lo encuentra.
d = json.loads(i18n)
faltan = set(d["es"]) ^ set(d["en"])
if faltan:
    raise SystemExit("claves que no estan en los dos idiomas: %s" % sorted(faltan))

html = plant.replace(MARCA, datos).replace(MARCA_I, i18n)
io.open("docs/index.html", "w", encoding="utf-8", newline="\n").write(html)

mb = os.path.getsize("docs/index.html") / 1024**2
n = json.loads(io.open("docs/datos.json", encoding="utf-8").read())["n_muni"]
print("Guardado: docs/index.html (%.2f MB, %d municipios, sin dependencias externas)" % (mb, n))
