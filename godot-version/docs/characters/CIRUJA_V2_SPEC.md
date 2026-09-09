# CIRUJA V2 — Especificación artística y técnica

## Propósito y alcance

Este documento es la fuente de verdad para reconstruir a **Ciruja**, el protagonista hincha de San Martín de Tucumán, como arte definitivo V2. Define la producción de sprites y animaciones; no autoriza todavía su integración en escenas, scripts, `SpriteFrames` ni recursos de Godot.

El arte existente se conserva como **LEGACY/REFERENCE**. Todo archivo definitivo futuro de Ciruja deberá vivir bajo `art_v2/characters/ciruja/`.

## Dirección visual

Ciruja es una caricatura lateral de un hincha de San Martín de Tucumán: compacto, desalineado, agresivo al entrar en acción y simpático al leerlo en reposo. Su silueta debe reconocerse aun a escala de gameplay por la gorra baja, los lentes oscuros, los hombros encorvados y la postura lista para avanzar.

Rasgos obligatorios:

- camiseta de San Martín de Tucumán y ropa deportiva popular;
- gorra negra gastada, con desgaste y una rotura pequeña legible;
- lentes oscuros baratos;
- cicatrices visibles;
- tatuajes visibles y consistentes;
- varios dientes faltantes, mostrados sólo cuando la boca se abre;
- físico compacto, postura agresiva y apariencia desalineada;
- expresión caótica pero querible, nunca desagradable ni realista.

Debe cumplir el lenguaje de `ART_BIBLE.md`: pixel art arcade 16/32 bits de alta calidad, contorno oscuro uniforme, luz superior izquierda, sombras limpias y paleta cálida, saturada y subtropical. Los colores de camiseta, gorra, lentes, piel y calzado se fijan al aprobar el master; no deben variar entre frames.

## Escala y registro técnico

La configuración actual de Player usa un `AnimatedSprite2D` de 200 × 200 px con `scale = Vector2(0.42, 0.42)` y `position = Vector2(0, -42)`. No se cambia esta relación durante la producción V2.

| Parámetro | Especificación V2 |
| --- | --- |
| Canvas por frame | **200 × 200 px**, transparente, sin recortes por frame |
| Altura visual objetivo en juego | **84 px** (200 px × escala actual 0.42), dentro del rango aprobado de 80–100 px |
| Altura de figura dentro del canvas | Aproximadamente 188 px en pose neutral, con aire técnico superior |
| Punto de apoyo de pies | `(100, 200)` en coordenadas del canvas |
| Origin de SpriteFrames | Canvas centrado por Godot: centro técnico `(100, 100)` |
| Nodo visual actual a conservar en integración | `position = (0, -42)`, `scale = (0.42, 0.42)` |
| Margen libre neutral | mínimo 12 px arriba, 16 px laterales; base de pies en y = 200 |
| Margen en poses de acción | toda extensión debe permanecer dentro de 200 × 200; no recortar cabeza, gorra, puños, naranja ni pies |

El punto `(100, 200)` es la referencia de suelo de todos los PNG, incluso cuando el personaje está en el aire o caído. Los frames no se deben recortar, recentrar, escalar ni desplazar individualmente. El desplazamiento visual de salto, impacto o caída se dibuja dentro del canvas; el registro de exportación siempre permanece fijo.

El master y las animaciones usan píxeles enteros, transparencia limpia y filtro nearest. El `idle` deberá seguir representando el volumen general ya usado para colisión, para que una futura sustitución no altere accidentalmente el espacio físico del jugador.

## Orientación canónica y espejo

La orientación canónica es **lateral hacia la derecha**. Es compatible con la dirección positiva actual del jugador y permite usar `flip_h` para mirar hacia la izquierda.

Para que el espejo sea seguro:

- la camiseta debe usar una identidad visual legible sin texto ni un escudo detallado en un único lado; usar un emblema simplificado centrado o una solución que no se vuelva incorrecta al espejarse;
- las cicatrices, tatuajes y roturas importantes deben estar en zonas centrales o diseñarse como rasgos visualmente equivalentes al invertirse;
- la gorra puede tener visera lateral, pero la rotura no debe comunicar una lateralidad narrativa fija;
- lentes, cordones, calzado y bordes de ropa deben mantener una lectura suficientemente simétrica;
- evitar textos, números direccionales, parches de hombro, logos o accesorios en un solo costado.

Si en una fase posterior se aprueba un detalle que no pueda espejarse, se requerirán variantes izquierda/derecha y una tarea de integración específica. No se resuelve con un cambio de arte parcial.

## Regla de master

Antes de producir cualquier animación debe existir y estar aprobado el archivo futuro:

`art_v2/characters/ciruja/master/ciruja_master_side.png`

`ciruja_master_side` será una única pose lateral neutral, a la derecha, con el canvas, paleta, ropa, anatomía, punto de apoyo y contorno definitivos. Sirve como referencia canónica de cada generación posterior. Ninguna animación V2 se inicia antes de su aprobación.

La revisión del master debe validar silueta, altura, camiseta, gorra, lentes, cara, cicatrices, tatuajes, calzado, colores, luz y el registro `(100, 200)`.

## Animaciones V2 requeridas

Todas las secuencias deben mostrar cambios claros de poses, brazos, piernas, torso y peso. No se aceptan secuencias donde sólo cambien detalles menores mientras la anatomía principal permanece prácticamente igual. Todos los frames conservan el mismo canvas, registro y pivot técnico.

| Animación | Frames | FPS inicial | Objetivo visual y poses clave | Brazos, piernas, torso y centro de gravedad | Pivot |
| --- | ---: | ---: | --- | --- | --- |
| `idle` | 4 | 6 | Reposo alerta: base, respiración, ajuste mínimo de hombros/cabeza, regreso. | Brazos pesados pero listos, rodillas algo flexionadas; torso sube/baja 1–2 px; peso alterna levemente sobre ambos pies. | Igual en los 4 frames. |
| `run` | 8 | 12 | Ciclo completo: contacto, compresión, paso, elevación y repetición contraria. | Contrabalanceo amplio de brazos; zancadas claramente alternadas; torso inclinado hacia adelante y con rebote visible; peso pasa de una pierna a la otra. | Igual en los 8 frames. |
| `jump` | 4 | 10 | Preparación, despegue, piernas recogidas y ápice. | Brazos impulsan hacia atrás/arriba; piernas comprimen, extienden y se recogen; torso se eleva con decisión; centro de gravedad asciende dentro del canvas. | Igual en los 4 frames. |
| `fall` | 2 | 8 | Descenso legible: controlado y luego preparado para tocar suelo. | Brazos abiertos para equilibrio; piernas bajan y se preparan para absorber; torso desciende; centro de gravedad vuelve hacia la base. | Igual en los 2 frames. |
| `land` | 3 | 10 | Contacto, squash de absorción y recuperación. | Brazos acompañan hacia adelante y vuelven; rodillas flexionan mucho y se extienden; torso baja y rebota; peso cae a ambos pies. | Igual en los 3 frames. |
| `cabezazo` | 6 | 14 | Guardia, carga hacia atrás, arranque, impacto frontal, seguimiento y retorno. | Brazos se retraen y luego protegen/equilibran; piernas empujan el cuerpo; torso y cabeza avanzan con fuerza; centro de gravedad se desplaza hacia adelante y bajo. | Igual en los 6 frames. |
| `naranjazo` | 6 | 16 | Preparación, carga de brazo, giro, liberación de naranja, seguimiento y recuperación. | Brazo lanzador recorre un arco completo y el otro compensa; piernas fijan la base; torso rota y vuelve; peso carga atrás y termina adelante. | Igual en los 6 frames. |
| `hit` | 3 | 10 | Impacto, retroceso comprimido y recuperación breve. | Brazos reciben el golpe y buscan balance; piernas se afirman; torso se va hacia atrás y vuelve; centro de gravedad retrocede antes de recuperar base. | Igual en los 3 frames. |
| `death` | 8 | 10 | Sacudida, pérdida de equilibrio, rodilla, caída, impacto en suelo y asentamiento. | Brazos pierden control; piernas ceden secuencialmente; torso rota y termina en el suelo; centro de gravedad desciende de forma continua. | Igual en los 8 frames. |
| `victory` | 6 | 10 | Reconocimiento, elevación, festejo, golpe de puño y cierre orgulloso. | Brazos se elevan y realizan gesto amplio; piernas cambian apoyo y dan un pequeño salto o pisotón; torso se abre; centro de gravedad rebota hacia arriba. | Igual en los 6 frames. |
| `tucumanazo` | 8 | 12 | Lectura de poder de área: carga amplia, compresión, acumulación, descarga, extensión y recuperación. | Brazos reúnen energía y explotan hacia afuera; piernas anclan con una compresión fuerte; torso gira y se proyecta; centro de gravedad baja antes de la descarga y recupera base. | Igual en los 8 frames. |

`naranjazo` debe contener el frame de liberación con la mano vacía inmediatamente después del lanzamiento. La naranja es un elemento de acción de ese frame, no un cambio de vestuario. `cabezazo` y `tucumanazo` deben distinguirse por pose, alcance y energía corporal, aunque ambas partan de una postura agresiva.

## Consistencia obligatoria entre frames

Cada frame debe conservar exactamente:

- ropa y combinación de colores aprobadas;
- gorra, lentes, cicatrices y tatuajes importantes;
- proporciones de cabeza, torso, brazos, piernas y físico compacto;
- calzado, tono de piel, grosor de contorno, lenguaje de sombra y altura general;
- escala, canvas, punto de apoyo, pivot y alineación vertical.

Las variaciones sólo pueden responder al movimiento: squash controlado, inclinación, giro, expresión, pliegues y deformación propia de la acción. No se permiten cambios accidentales de indumentaria, número de dientes, forma de gorra, largo de extremidades, color de camiseta o posición del suelo.

## Estructura de producción propuesta

La estructura se documenta ahora; no se crean todavía carpetas ni imágenes de arte V2.

```text
art_v2/
└── characters/
    └── ciruja/
        ├── master/
        │   └── ciruja_master_side.png
        ├── animations/
        │   ├── idle/
        │   ├── run/
        │   ├── jump/
        │   ├── fall/
        │   ├── land/
        │   ├── cabezazo/
        │   ├── naranjazo/
        │   ├── hit/
        │   ├── death/
        │   ├── victory/
        │   └── tucumanazo/
        └── portraits/
```

## Nomenclatura de archivos

Se usará minúsculas, guion bajo y numeración de dos dígitos:

```text
ciruja_master_side.png
ciruja_idle_00.png
ciruja_idle_01.png
ciruja_run_00.png
ciruja_cabezazo_05.png
ciruja_tucumanazo_07.png
ciruja_portrait_select.png
```

Cada frame se exporta como PNG transparente de 200 × 200 px. La numeración inicia en `00`, no salta valores y refleja el orden de reproducción.

La futura integración deberá mapear estos nombres de producción a las animaciones runtime actuales: `idle` → `Idle`, `run` → `Run`, `jump` → `Jump`, `naranjazo` → `Throw Orange`, `cabezazo` → `Headbutt`, `hit` → `Hit`, `death` → `Death`. `fall`, `land`, `victory` y `tucumanazo` quedan preparados para una tarea posterior de mapeo explícito.

## Criterio de aceptación para integración futura

Ciruja V2 sólo puede proponerse para integración cuando:

1. `ciruja_master_side` está aprobado y todos los PNG requeridos existen.
2. Las once animaciones definidas tienen la cantidad exacta de frames y movimiento corporal legible.
3. Cada frame conserva canvas de 200 × 200 px, registro `(100, 200)`, altura en juego de 84 px y el pivot actual.
4. Vestuario, paleta, proporciones, detalles identificatorios, contorno y sombreado son consistentes.
5. El personaje se lee con claridad a resolución interna 800 × 450 y mantiene su silueta lateral.
6. Las poses de ataque no recortan elementos y respetan la futura lectura de dirección con `flip_h`.
7. La futura tarea de integración valida los nombres runtime restantes sin cambiar física, colisiones ni escala de gameplay.

## Dependencias y problemas técnicos detectados

- El runtime actual sólo define `Idle`, `Run`, `Jump`, `Throw Orange`, `Throw Stone`, `Headbutt`, `Hit` y `Death`. Las animaciones V2 `fall`, `land`, `victory` y `tucumanazo` requieren un mapeo posterior, fuera de esta tarea.
- `Throw Stone` sigue siendo un requisito del `CharacterDefinition` actual, pero no forma parte de las once animaciones V2 aprobadas para esta especificación. Debe mantenerse en legacy hasta que se apruebe su producción o su tratamiento de integración.
- La escena actual aplica escala y offset desde la definición de personaje; cambiar canvas, pivot, `visual_scale` o `visual_offset` durante la sustitución alteraría la lectura visual y puede desalinear la colisión dinámica. La futura integración debe preservar primero los valores actuales y validar en juego.
- Los emblemas o tatuajes con lateralidad rígida pueden hacer inseguro `flip_h`; el master debe resolverlos antes de producir el resto de las animaciones.
