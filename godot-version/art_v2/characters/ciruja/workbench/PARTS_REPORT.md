# Ciruja cutout — informe de extracción

Fecha: 2026-09-06  
Fuente: `ciruja_cutout_source.png`

## Diagnóstico de la fuente

- Dimensiones: **1473 × 1068 px**.
- Formato leído: **RGBA**.
- Canal alfa: presente; mínimo 0, máximo 255.
- Fondo: **realmente transparente**. Las cuatro esquinas tienen alfa 0, ningún píxel del borde exterior tiene alfa visible y los 1.006.333 píxeles con alfa 0 tienen RGB negro/neutro. No se creó copia procesada.
- Opacidad del arte: 566.831 píxeles tienen alfa mayor que 0. Sólo 2.473 son alfa 255; la mayoría del interior usa alfa 253 y existe antialiasing gradual. Esto significa que el dibujo completo es técnicamente semitransparente por 1–2 niveles, aunque se percibe opaco.
- Separación: a alfa ≥ 8 se detectan exactamente **14 componentes visuales**. A alfa 1–3 aparecen puentes casi invisibles entre algunos componentes cercanos (principalmente cabeza/torso y torso/pierna frontal). La extracción usa límites geométricos en esos espacios y copia los RGBA originales; no modifica color, contorno, escala ni interpolación.
- Resolución: todos los recortes conservan la escala nativa de la fuente. Son crops ajustados con margen transparente, no canvases reescalados.

## 1. Piezas encontradas

| Archivo | Interpretación | Tamaño del recorte |
|---|---|---:|
| `parts/ciruja_head.png` | cabeza completa, gorra, pelo y cuello | 429×387 |
| `parts/ciruja_torso.png` | torso/camiseta con cuello y mangas base | 387×363 |
| `parts/ciruja_arm_front_upper.png` | brazo frontal superior, con manga | 158×291 |
| `parts/ciruja_arm_front_lower.png` | antebrazo frontal tatuado | 147×279 |
| `parts/ciruja_hand_front.png` | mano frontal cerrada alternativa/independiente | 146×167 |
| `parts/ciruja_arm_back_upper.png` | brazo trasero superior, con manga | 179×281 |
| `parts/ciruja_arm_back_lower.png` | antebrazo trasero tatuado | 160×283 |
| `parts/ciruja_hand_back.png` | mano trasera relajada alternativa/independiente | 131×174 |
| `parts/ciruja_leg_front_upper.png` | muslo/pierna frontal superior con franjas, cadena y escudo | 211×292 |
| `parts/ciruja_leg_front_lower.png` | pierna frontal inferior | 172×294 |
| `parts/ciruja_foot_front.png` | pie/zapatilla frontal | 242×129 |
| `parts/ciruja_leg_back_upper.png` | muslo/pierna trasera superior lisa | 179×314 |
| `parts/ciruja_leg_back_lower.png` | pierna trasera inferior lisa | 166×285 |
| `parts/ciruja_foot_back.png` | pie/zapatilla trasera | 239×129 |

La asignación frontal/trasera se contrastó con el master visible: el brazo con tatuaje de calavera y la pierna con franjas/escudo se leen como los miembros frontales; el brazo con tatuaje angular y la pierna lisa, como los traseros.

## 2. Piezas ambiguas

- Los dos antebrazos ya terminan visualmente en una mano dibujada. Las dos manos sueltas parecen variantes, no una división limpia de muñeca. Por eso no se puede montar simultáneamente `lower` + `hand` sin ocultar o duplicar dedos; se necesita decidir si las manos sueltas reemplazan la terminación integrada o se reservan como poses alternativas.
- Cabeza y cuello forman una sola pieza. No hay cuello independiente para rotación con cobertura interna.
- Las mangas aparecen tanto en el torso como en los brazos superiores. Esto ayuda a ocultar juntas, pero exige un orden de capas consistente para evitar doble contorno.
- Los puentes de alfa 1–3 no son contenido visible fiable; no deben utilizarse como solapamiento articular.

## 3. Piezas faltantes

No falta ninguna de las **14 categorías nominales solicitadas**. Sin embargo, faltan separaciones anatómicas limpias en las muñecas: no existen antebrazos inequívocamente terminados antes de la mano. Tampoco hay piezas internas de relleno para cuello, hombros, cadera o articulaciones extremas.

## 4. Solapamiento articular

| Articulación | Evaluación |
|---|---|
| Hombros | **Suficiente para POC.** Manga del torso y manga del brazo superior ofrecen cobertura, con riesgo de doble borde. |
| Codos | **Limitado pero utilizable.** Los extremos redondeados permiten pequeñas rotaciones; poses amplias pueden abrir huecos. |
| Muñecas | **Insuficiente como segmentación limpia.** Las manos integradas en los antebrazos interfieren con las manos sueltas. |
| Caderas | **Marginal/suficiente para POC.** El faldón de la camiseta puede ocultar la unión en un rango moderado. |
| Rodillas | **Limitado pero utilizable.** Hay volumen para solape corto; no para flexiones extremas sin revelar bordes. |
| Tobillos | **Limitado pero utilizable.** El puño del pantalón puede cubrir parcialmente la zapatilla. |

## 5. Viabilidad de rig 2D

**Viable de forma condicionada para un POC de cutout rígido**, con rotaciones moderadas, jerarquía de capas y pruebas de oclusión. No es todavía una fuente lista para un rig de producción: las muñecas/manos, el doble contorno de mangas y la escasa reserva interna en codos, rodillas y tobillos limitarán el rango de movimiento. Una evaluación posterior debería montar primero una pose neutral fuera del runtime y comprobar huecos/duplicaciones; no se recomienda Skeleton2D hasta resolver esa prueba.

No se redibujó ni inventó ninguna pieza. No se aplicó escalado, pixelización, recolor, interpolación ni IA generativa. La fuente original permanece intacta y estos archivos no están integrados al juego.
