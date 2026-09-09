# Diagnóstico visual de animaciones — Ruta 38

Fecha: 2026-09-08. Alcance: inspección de PNG, recursos y código runtime. No se modificaron assets, escenas, scripts, recursos de animación, tests ni gameplay.

## A. Recogidas: `juntar_naranjas` y `juntar_cascotes`

### Referencia runtime

- Player normal: canvas 200×200, `visual_scale = 0.42`, `visual_offset = (0,-42)`, Sprite2D centrado.
- Recogidas: los dos clips tienen cinco frames a 10 FPS (0,5 s) y se reproducen con multiplicador visual 1,25: escala efectiva **0,525**. El pivot sigue siendo el mismo `(0,-42)`.
- Idle ocupa 88×192 px opacos; renderiza ~80,6 px de alto. Run ocupa 104–143×194–200 px; renderiza ~81,5–84 px de alto. Sus pies quedan a 0–2 px del ground point runtime.

### Medición de PNG y alineación

Los bounds alfa de las recogidas incluyen árbol/cascotes y no permiten aislar automáticamente sólo al personaje. La altura de figura indicada es una lectura visual aproximada de la silueta de Ciruja; el resto de las columnas se midió directamente desde alfa.

| Clip / frame | Canvas | Bounds opacos | Alto opaco runtime | Fondo transparente bajo el bounds | Base runtime con pivot actual | Figura Ciruja visible |
| --- | --- | --- | ---: | ---: | ---: | --- |
| `juntar_naranjas1` | 200×200 | (7,19)–(188,173), 182×155 | 81,4 px | 26 px | -3,7 px | ~126 px fuente / ~66 px runtime |
| `juntar_naranjas2` | 200×200 | (3,10)–(199,184), 197×175 | 91,9 px | 15 px | +2,1 px | ~130 px / ~68 px |
| `juntar_naranjas3` | 200×200 | (9,13)–(199,183), 191×171 | 89,8 px | 16 px | +1,6 px | ~128 px / ~67 px |
| `juntar_naranjas4` | 200×200 | (2,13)–(199,181), 198×169 | 88,7 px | 18 px | +0,5 px | ~126 px / ~66 px |
| `juntar_naranjas5` | 200×200 | (9,13)–(199,179), 191×167 | 87,7 px | 20 px | -0,5 px | ~124 px / ~65 px |
| `juntar_cascote1` | 200×200 | (4,21)–(194,179), 191×159 | 83,5 px | 20 px | -0,5 px | ~130 px / ~68 px |
| `juntar_cascote2` | 200×200 | (7,38)–(196,179), 190×142 | 74,6 px | 20 px | -0,5 px | ~126 px / ~66 px |
| `juntar_cascote3` | 200×200 | (0,38)–(195,157), 196×120 | 63,0 px | 42 px | -12,1 px | ~119 px / ~62 px |
| `juntar_cascote4` | 200×200 | (6,44)–(199,180), 194×137 | 71,9 px | 19 px | 0 px | ~124 px / ~65 px |
| `juntar_cascote5` | 200×200 | (4,26)–(199,173), 196×148 | 77,7 px | 26 px | -3,7 px | ~127 px / ~67 px |

La base runtime es la distancia vertical desde el suelo lógico: negativo significa que el último píxel opaco queda sobre el suelo; positivo, que se extiende bajo él. Se calcula con `-42 + (bottom_y - 100) × 0,525`.

### Diagnóstico

La causa es una **combinación de dibujo dentro del canvas, anchor variable y estilo incompatible**, no una escala global insuficiente.

1. La figura de Ciruja dentro de ambos clips mide aproximadamente 62–68 px en juego, frente a 81–84 px de Idle/Run. El multiplicador 1,25 ya compensó parte del problema; aumentar aún más escala también haría crecer el árbol o la montaña, no sólo al personaje.
2. Los clips son composiciones completas: Ciruja queda a un costado y el objeto recogible ocupa la mayor parte del canvas. No son poses de personaje equivalentes a Idle/Run.
3. El ground point no es estable. El cascote 3 se eleva ~12 px respecto de la línea de apoyo; naranja fluctúa ~6 px entre sus extremos. Esto introduce flotación incluso antes de evaluar estilo.
4. La paleta y el acabado no coinciden. Idle/Run contienen ~8,9k–12,1k colores RGB; naranjas ~13,5k–16,2k por el tratamiento detallado del árbol; cascotes sólo 253–255 colores, con contorno rojo/verde visible y sombreado más plano. El grosor de línea, proporciones y densidad de detalle de Ciruja también divergen de Idle/Run.

### Corrección recomendada

**Menor riesgo técnico:** sustituir en una tarea posterior la pose durante la recogida por Idle (o una pose de Player coherente) y mantener el árbol/pila como objeto independiente con feedback temporal. No requiere tocar colisiones, pivot de Player ni PNG existentes.

**No recomendado como solución final:** seguir aumentando `COLLECTION_VISUAL_SCALE_MULTIPLIER`. Puede acercar la altura aparente de Ciruja, pero agranda indebidamente árbol/cascotes, conserva el desplazamiento vertical entre frames y no corrige estilo, contorno ni proporciones.

**Solución artística final:** regenerar los 10 frames como poses de Ciruja aisladas, mismo canvas 200×200, figura ~192–200 px de alto, pies en y=198–199 y paleta/contorno compatibles con Idle/Run. Árbol y cascotes deben permanecer como props runtime separados.

| Opción | ¿Resuelve técnicamente? | ¿Requiere sprites? | Riesgo / costo |
| --- | --- | --- | --- |
| Escala global mayor | Parcial; empeora composición | No | Bajo / bajo; no recomendable |
| Offset/escala por frame | Corrige el apoyo, no el estilo | No | Medio / bajo-medio; paliativo |
| Idle + feedback del pickup | Sí, elimina el choque visual | No | Bajo / bajo |
| Regenerar poses aisladas | Sí, solución completa | Sí, 10 frames | Bajo técnico / medio artístico |

## B. El Grandote — `grandote_ground_slam`

### Runtime real y orden

El Grandote élite usa `scripts/actors/enemy.gd`, no la escena legacy `miniboss_grandote.tscn`. Su recurso `assets/animations/grandote.tres` carga exactamente, en este orden:

1. `grandote_golpe_suelo1.png` — frame 0, telegraph / startup, **0,24 s**.
2. `grandote_golpe_suelo2.png` — frame 1, estado activo, **0,10 s**.
3. `grandote_golpe_suelo3.png` — frame 2, recovery, **0,30 s**.

El `SpriteFrames` declara velocidad 1 FPS, pero el runtime lo pausa y asigna `visual.frame` manualmente: esa velocidad no gobierna el ataque. Al pasar de activo a recovery, fija frame 2 y llama `_emit_ground_wave()` una vez. Por ello la onda se crea en el mismo cambio que muestra `golpe_suelo3`, no al comienzo de la animación ni al entrar al frame 1.

### Medición de PNG, escala y ground point

La referencia Grandote normal usa `visual_scale = 0,72`, `visual_offset = (0,-72)` y tiene pies prácticamente sobre el suelo (run 1: bottom y=199; run 2: y=198).

| Frame | Bounds opacos | Alto opaco | Bottom fuente | Base runtime con pivot actual | Paleta RGB |
| --- | --- | ---: | ---: | ---: | ---: |
| `grandote_run1` | (2,6)–(196,199) | 194 px | 199 | -0,7 px | 12.040 |
| `grandote_run2` | (27,0)–(160,198) | 199 px | 198 | -1,4 px | 10.633 |
| `golpe_suelo1` | (9,2)–(185,197) | 196 px | 197 | -2,2 px | 254 |
| `golpe_suelo2` | (0,7)–(198,188) | 182 px | 188 | -8,6 px | 254 |
| `golpe_suelo3` | (0,32)–(199,159) | 128 px | 159 | **-29,5 px** | 12.867 |

La base runtime se calcula como `-72 + (bottom_y - 100) × 0,72`. Es la evidencia principal del salto: el tercer frame queda ~28 px de pantalla más alto que la pose normal, aunque representa el contacto con el suelo.

### Diagnóstico

El movimiento se siente poco natural por tres causas acumuladas:

1. **Ground points incompatibles:** frame 1 apoya casi correctamente; frame 2 se levanta ~6 px (plausible como anticipación aérea); frame 3, el supuesto impacto, queda ~29 px elevado. Con un pivot fijo centrado, el golpe parece flotar.
2. **Semántica visual y timing desalineados:** el asset 2 se lee como salto/lunge; el asset 3 contiene el puño, polvo e impacto. Sin embargo el código reserva 0,10 s al frame 2 y genera onda al entrar al frame 3/recovery. La onda visual aparece junto al impacto, pero el daño/estado activo ya concluyó, lo que reduce la sensación de causa-efecto.
3. **Incompatibilidad de acabado:** frames 1 y 2 tienen paleta indexada de 254 colores; frame 3 tiene 12.867 colores y antialias/detalle notablemente distintos. El corte visual entre 2→3 es evidente, además del desplazamiento de silueta.

### Corrección recomendada

**Paliativo técnico de bajo riesgo:** en una tarea posterior, mantener el orden actual pero aplicar offsets verticales específicos de frame para preservar el ground point: aproximadamente +6 px para frame 2 y +29 px para frame 3 en pantalla (equivalentes a +9 y +41 px en fuente antes de escala). También sincronizar la onda con el inicio del frame 3 de forma explícita; esto conserva daño, collider, carril y cooldown.

**Corrección de timing recomendada:** tratar `golpe_suelo3` como impacto (no recovery): al entrar en ese frame, emitir onda y empezar su ventana activa; recovery posterior debe usar una pose coherente o retornar suavemente a run. Esto requiere una decisión de gameplay/lectura posterior, por eso no se aplicó aquí.

**Solución artística final:** regenerar o normalizar los tres sprites con canvas 200×200, ground point y=198–199, escala/paleta/contorno compatibles, y secuencia inequívoca: anticipación, contacto, recuperación. El asset de impacto debe conservar polvo/onda o convivir con una onda procedural alineada.

| Opción | ¿Resuelve técnicamente? | ¿Requiere sprites? | Riesgo / costo |
| --- | --- | --- | --- |
| Offset por frame + onda en frame 3 | Corrige flotación y sincronía visual | No | Bajo-medio / bajo |
| Reordenar fases activo/recovery | Mejora lectura causa-efecto | No | Medio / bajo |
| Regenerar los 3 sprites | Resuelve anchor y estilo | Sí, 3 frames | Bajo técnico / medio artístico |

## Conclusión

Las recogidas no se arreglan de forma satisfactoria con más escala: son ilustraciones de interacción completas, no sprites de Player compatibles. El ground slam sí admite una corrección técnica puntual de offsets, pero también requiere arte normalizado para eliminar el cambio de estilo entre frames. Ninguna de estas correcciones debe hacerse sin una tarea específica de implementación y validación a 800×450.
