# Ruta 38 — diagnóstico y plan de Art Polish / Gameplay Polish

Fecha de auditoría: 27-09-2026. Esta fase es exclusivamente documental. No se modificaron escenas, scripts, recursos ni assets.

## 1. Estado y arquitectura actual

El proyecto corre a 800×450, usa un único plano jugable (`GROUND_Y = 370`) y conserva los PNG de `assets/` como LEGACY/REFERENCE. `art_v2/` es el único destino aprobado para arte definitivo según `docs/ART_BIBLE.md`.

| Área | Fuente principal | Responsabilidad actual |
|---|---|---|
| Arranque y escena principal | `project.godot`, `scenes/main.tscn`, `scripts/core/main.gd` | Instancia Ruta 38, UI, selección, diálogo, proyectiles, cámara, respawn y cierre de misión. |
| Nivel | `scenes/levels/route_38.tscn`, `scripts/core/route_38.gd` | Compone entorno, terreno, objetos, vehículos, enemigos, pickups, set pieces, miniboss y boss. |
| Datos del recorrido | `scenes/levels/route_38_data.json` | Localidades, 13 encounters, activaciones X, entradas escalonadas, descansos y trigger del boss. |
| Dirección de encuentros | `scripts/level/encounter_director.gd` | Cola, activación serial, spawn seguro, límite de población, descansos, tokens de ataque, caps de proyectiles, retiro detrás de cámara y restart. |
| Enemigos terrestres | `scenes/actors/enemy.tscn`, `scripts/actors/enemy.gd`, `data/enemies/*.tres` | Hipster, Agente y Grandote mediante un actor genérico y `EnemyDefinition`. |
| Drones | `scenes/actors/drone.tscn`, `scripts/actors/drone.gd` | Actor aéreo independiente con entrada, patrulla, aim/lock, disparo y cooldown. |
| Disparos | `scenes/actors/projectile.tscn`, `scripts/actors/projectile.gd`, `data/projectiles/*.tres` | Definiciones por proyectil, movimiento, orientación, collider, lifetime, equipos y barrido anti-tunneling. `Main` actúa como fábrica. |
| Vehículos | `platform.gd`, `generic_platform.gd`, `vehicle.gd`, `traffic_director.gd`, `expresbus_set_piece.gd` | Nueve vehículos estacionados, techos one-way, grounding por alfa y los set pieces Expresbus/Tesa. |
| Props | `route_38_environment.tscn`, `route_environment.gd`, `route_38.gd` | Panorama, cerros, ruta, cañas, cartel, poste, semáforo, parada, pickups y vehículos. |
| Cámara | `scenes/main.tscn`, `scripts/core/main.gd` | Seguimiento X suavizado, límites 0–8000, shake y límites temporales de arenas. |
| Fondo/parallax | `route_38_environment.tscn` | Cerros a 0,08; panorama A/B/C a 0,66; ruta a 1,0; z-index por grupos. |
| Boss final | `palermitano_boss.tscn`, `palermitano_boss.gd`, `palermitano_chain.tres` | State machine local con intro, decisión, telegraph, ataque, recovery y muerte. Patrones: triple café, cadena y summon. |
| Escala/pivots | `CharacterDefinition`, `EnemyDefinition`, escenas, `animation_manifest.json`, `animation_offset_profile.gd`, `CollisionFactory` | Escala runtime y offset base por actor; compensación por frame desde manifiesto; colliders derivados del primer frame/bounds alfa. |

### Flujo runtime

`Main` recibe solicitudes de disparo del Player y de `Route38`, instancia el proyectil y controla cámara/UI. `Route38` lee el JSON, configura `EncounterDirector`, crea plataformas y pickups, y conecta enemigos con el Player. El director activa una entrada por vez, mantiene hasta 7 actores, coloca entradas por delante del viewport y retira actores completamente detrás de Player y cámara.

Actualmente hay 13 encounters entre X=450 y X=6800. Las entradas normales se separan 0,45 s; los descansos van de 0,8 a 2,5 s. Expresbus se activa cerca de X=2850, Tesa en X=4400, Drone tutorial en X=4100, oleada de cinco Drones en X=6100 y Palermitano en X=7425 después de `route_wave_06`.

El presupuesto ofensivo vigente es más restrictivo que la densidad visual: un token terrestre o un token aéreo, nunca ambos pools simultáneamente; cap general de 3 proyectiles hostiles y cap 2 para la oleada aérea. Esta separación ya es una base adecuada para aumentar presencia sin crear una pared de disparos.

## 2. Diagnóstico

### Escala y pivots

- Ciruja es la referencia correcta: escala 0,42 y aproximadamente 83 px opacos, dentro del objetivo de 80–100 px de la Art Bible.
- Las escalas se encuentran en varios niveles: `CharacterDefinition`, `EnemyDefinition`, nodos de escenas, `STATIONARY_VEHICLES`, escenas de entorno y set pieces. No existe una única ficha de escala consumible por Visual Lab y runtime.
- Los valores actuales relevantes son: Hipster 0,34, Agente 0,36, Grandote 0,44, Drone 0,55, Palermitano 0,42 y miniboss Grandote 0,48. Los vehículos estacionados usan nueve escalas diferentes entre 0,70 y 0,95; Expresbus 1,20 y Tesa 1,10.
- `WORLD_SCALE_REFERENCE.md` conserva partes históricas que ya no coinciden con los recursos actuales. En futuras decisiones se debe medir el runtime, no copiar esa tabla sin regenerarla.
- Los actores combinan `visual_offset` base con `frame_offsets` del manifiesto. Esto estabiliza pies visuales, pero el body/hurtbox se calcula una sola vez desde el primer frame de carrera. Un frame extremo puede alejarse visualmente del collider aunque sus pies queden alineados.
- Vehículos y plataformas ya usan bounds alfa y un nodo posicionado en el ground point. Los props decorativos del entorno todavía dependen de posiciones Y manuales y no declaran un ground point común.

### Grounding

- La referencia física es Y=370; la textura de ruta comienza en Y=325 y el suelo físico se crea en Y=376 con una forma de 12 px.
- Player/enemigos anclan el body a los pies; plataformas exponen `get_ground_anchor_world_y()` y vehículos móviles exponen techo/grounding propio.
- El problema pendiente no es un único offset global, sino la falta de una convención compartida para: punto de apoyo, punto de muzzle, punto de contacto, techo útil y sombra. Esto favorece correcciones locales que luego divergen.
- Las compensaciones por frame deben mover sólo el visual. Ground point y collider principal deben permanecer estables salvo una acción que requiera hitbox dedicada.

### Profundidad, fondo y cámara

- La segmentación A/B/C de `fondo_completo.png` es no destructiva y continua: regiones 2667/2666/2667×1024, escala uniforme 0,84, X 0/2240,28/4479,72, Y −232,76 y parallax 0,66.
- Hay tres velocidades principales: cerros 0,08, panorama 0,66 y ruta 1,0. El grupo `MidgroundBuildings` tiene z=-8, pero no posee movimiento parallax propio. Cartel, poste y semáforo comparten z=-2 aunque su perspectiva y distancia aparente no son equivalentes.
- La composición funciona para 8000 px, pero no está preparada todavía para un recorrido de 4:30–5:00: el panorama tiene cobertura calculada para el ancho actual y no debe estirarse.
- La cámara sigue directamente la X del Player con smoothing; no tiene look-ahead, dead zone contextual ni encuadres de lectura para entradas, plataformas o telegraphs. Las arenas sólo cambian clamps.

### Enemigos y telegraphing

- Enemigos terrestres: `CHASE → TELEGRAPH → ATTACK → RECOVERY`. Drones: `ENTRY → IDLE → AIM → FIRE → COOLDOWN`.
- Falta representar explícitamente en tierra `ENTRY → REACTION → PREPARE`. Hoy un actor puede aparecer, caminar y solicitar ataque en cuanto cumple distancia/cooldown. La visibilidad y los tokens evitan injusticias, pero no crean una puesta en escena consistente.
- Los tiempos viven en `EnemyDefinition`, mientras los puntos expresivos viven en las animaciones/manifiesto. Salvo Ground Slam, la emisión se decide por temporizador, no por un marcador de frame como `projectile_frame` o `impact_frame`.
- El telegraph se apoya principalmente en pose de ataque, pausa de movimiento y señales puntuales. Drone posee retícula dedicada y Palermitano tint/audio; no hay un lenguaje visual común por clase de amenaza.
- Los muzzle offsets de Hipster y Agente son constantes en `enemy.gd`; Player y boss tienen offsets propios. Es funcional, pero no es un socket por animación/frame y puede desalinearse al reemplazar sprites.

### Boss

- Palermitano tiene 90 HP y una duración estimada validada cercana a 56 s.
- State machine: `INTRO → DECIDE → TELEGRAPH → ATTACK → RECOVERY`; patrones triple café, cadena y summon de un Agente por patrón, con máximo absoluto de dos vivos.
- Ya impide triple café con summons/proyectiles activos y evita cadena/summon con proyectiles hostiles. Es una base sólida de legibilidad.
- No existen fases por vida, transición de fase ni una curva dramática explícita. La selección sólo considera distancia, cooldown, último patrón, summons y proyectiles.
- La entrada dura 1 s. Triple café usa telegraph 0,55 s, separación 0,28 s y recovery 0,80 s; cadena usa startup 0,48 s, active 0,14 s y recovery 0,75 s.

## 3. Plan de normalización visual

### 3.1 Escala

Medir altura y ancho **opacos a escala runtime**, no canvas. Usar Ciruja idle/run como 1,00 y registrar por asset: canvas, bounds alfa, escala runtime, altura aparente, ground point, pivot, collider y capa de profundidad.

Ratios provisionales aprobados para validar en Visual Lab, no valores automáticos:

- Ciruja: 1,00.
- Enemigo normal: 0,95–1,05.
- Agente alto: 1,05–1,10.
- Grandote: 1,15–1,22.
- Boss: 1,15–1,25.
- Moto: 0,65–0,75.
- Auto: 0,70–0,82.
- Pickup: 0,80–0,90.
- Camión: 1,10–1,25.
- Colectivo: 1,25–1,40.
- Props de fondo/midground: escala determinada por perspectiva; nunca por su canvas aislado.

La fuente futura debe ser un manifiesto de presentación por familia, consumible por Visual Lab. Los recursos runtime continuarán definiendo gameplay; no se debe introducir un singleton global de escala.

### 3.2 Ground points

Convención propuesta por asset:

- `ground_point`: pies, ruedas o base estructural.
- `visual_pivot`: origen estable del sprite.
- `muzzle_points`: sockets por ataque y orientación.
- `roof_line`: sólo para objetos utilizables como plataforma.
- `contact_bounds`: volumen de gameplay independiente del alfa ornamental.

Primero medir; después corregir el visual respecto del nodo, sin mover el nodo físico salvo error real. Agregar una captura técnica con línea Y=370, crosshair de pivot, bounds alfa, collider/hurtbox y roof line.

## 4. Parallax y profundidad

Mantener `fondo_completo` como base y sus regiones continuas. La futura expansión debe usar módulos de composición y repetición controlada, nunca estirar el PNG.

Capas objetivo:

1. cielo/cerros: 0,05–0,12, z≤−20;
2. panorama lejano: 0,45–0,65, z≈−15;
3. vegetación/arquitectura media: 0,70–0,88, z≈−10…−6;
4. roadside: 0,92–1,00, z≈−4…8 según oclusión;
5. gameplay: 1,00, jerarquía existente de plataformas, actores, pickups y proyectiles;
6. foreground excepcional: >1,00, sólo si no tapa amenazas ni UI.

Separar `MidgroundBuildings`, landmarks y roadside en contenedores con profundidad declarada. Cada sector debe tener zonas cargadas y zonas de descanso. Validar transiciones a 800×450 y durante scroll, no sólo en capturas estáticas.

## 5. Contrato de comportamiento enemigo

Flujo propuesto para todos los arquetipos, conservando sus diferencias:

`ENTRY → REACTION → PREPARE → ATTACK → RECOVERY → REPOSITION`

- **ENTRY:** entrada desde un punto seguro; no ataca.
- **REACTION:** reconoce al Player con una pose/pausa breve; permite identificar silueta y dirección.
- **PREPARE:** solicita token, bloquea intención/dirección y ejecuta telegraph.
- **ATTACK:** hitbox o proyectil aparece en el frame documentado.
- **RECOVERY:** sin nuevo ataque; ventana clara para responder.
- **REPOSITION:** vuelve a su distancia o patrón antes de solicitar otro token.

No convertirlo en una state machine global rígida. Añadir las fases comunes al actor genérico y mapear Drone/Grandote/boss a la misma semántica de lectura. Los tokens siguen administrando simultaneidad; no deben sustituir las fases visuales.

## 6. Telegraphing de disparos

Definir un lenguaje pequeño y consistente:

- cambio de pose antes de apuntar;
- pausa de locomoción y dirección bloqueada;
- señal en muzzle/arma o retícula para tiros dirigidos;
- audio breve compartido por categoría, sin texto HUD;
- emisión en `projectile_frame` del manifiesto;
- recovery visible antes de volver a correr.

Hipster debe levantar/preparar café; Agente debe alinear el arma y mostrar el origen; Drone conserva retícula y lock; Grandote anticipa cuerpo/suelo; Palermitano usa poses diferenciadas por patrón. Evitar tintar todo el personaje como solución final cuando la silueta y el frame puedan comunicar la intención.

Pruebas futuras: tiempo mínimo visible antes de daño, un disparo por marcador, muzzle dentro de tolerancia, cancelación al morir/salir, token liberado y ninguna emisión durante ENTRY/REACTION/RECOVERY.

## 7. Extensión del recorrido a 4:30–5:00 antes del boss

El mapa actual mide 8000 px; caminarlo a 230 px/s sin combate requiere unos 35 s. El end-to-end automatizado alcanza el preboss en aproximadamente 72,5 s con resolución acelerada de enemigos. Llegar a 270–300 s requiere más recorrido **y** más verbos, no sólo más copias de oleadas.

Objetivo de graybox inicial aprobado: **16.500 px**, ajustado después por telemetría humana. Es una referencia provisional y todavía no se implementa. No fijar el ancho final hasta medir tres recorridos: primera partida, jugador competente y speedrun razonable.

Presupuesto orientativo previo al boss:

| Tiempo | Función |
|---|---|
| 0:00–0:30 | Orientación, primer pickup y amenaza simple. |
| 0:30–1:15 | Hipster/Agente, alternancia de lados y primer techo. |
| 1:15–1:45 | Anticipación y set piece Expresbus; descompresión. |
| 1:45–2:20 | Drone tutorial, verticalidad y recompensa elevada. |
| 2:20–2:50 | Tesa y cruce/plataforma móvil. |
| 2:50–3:35 | Encuentros mixtos controlados, props/plataformas y decisiones de altura. |
| 3:35–4:10 | Oleada aérea de cinco y presión terrestre escalonada, nunca sincronizada. |
| 4:10–4:35 | Grandote como pico de intensidad y adds legibles. |
| 4:35–5:00 | Aproximación a Río Seco, recompensa, silencio y lectura del boss. |

Variación sin enemigos ni arte nuevos: entradas desde borde derecho/izquierdo diseñadas, alturas conocidas, techo de vehículo, pickup protegido, cruce bajo amenaza aérea, enemigo que entra pero espera token, breve arena, desplazamiento sobre colectivo y descanso ambiental. Cada bloque debe cambiar al menos uno de: dirección, altura, amenaza, movilidad, objetivo o ritmo.

## 8. Estructura de encuentros y microeventos

Reorganizar por actos, manteniendo IDs estables cuando sea posible:

1. **Aprendizaje:** Hipster solo, Agente solo, mezcla corta.
2. **Ruta activa:** coches/plataformas y entradas frecuentes con baja presión de fuego.
3. **Expresbus:** espacio exclusivo, telegraph, cruce y recompensa.
4. **Verticalidad:** Drone tutorial y pickup en techo.
5. **Tesa:** segundo cambio de verbo, sin oleada simultánea.
6. **Escalada:** encuentros mixtos, oleada aérea y tierra controlada.
7. **Peso:** Grandote solo, luego Grandote con adds escalonados.
8. **Preboss:** 20–30 s de lectura, recursos y framing de Río Seco.

Cada encounter debe declarar: intención, duración prevista, máxima población, máximo de atacantes, lados de entrada, altura, recompensa, condición de limpieza y tiempo de descanso. El JSON actual describe spawn/completion, pero no estas metas de diseño; agregarlas como metadatos validados antes de aumentar contenido.

## 9. Rediseño de Palermitano en tres fases

Conservar HP inicial mientras no haya telemetría que justifique cambiarlo. Las fases cambian selección y puesta en escena, no daño arbitrario.

### Fase 1 — Presentación (100–70 %)

- Intro 1–1,5 s.
- Enseñar cadena y triple café por separado.
- Sin dos summons; como máximo un Agente después de que ambos ataques hayan sido vistos.
- Recoveries completas y movilidad contenida.

### Fase 2 — Control del espacio (70–35 %)

- Alternar ataque propio y summon; un Agente primero, segundo sólo en un patrón posterior.
- Reducir triple café mientras haya summon/proyectiles.
- Reposicionamiento más marcado antes de cadena; mantener rango actual.
- Transición con pausa breve, feedback visual y limpieza de intención pendiente.

### Fase 3 — Clímax legible (35–0 %)

- Mantener máximo dos Agentes y presupuesto global de proyectiles.
- Secuencias más decididas, pero nunca cadena + triple café + dos Agentes disparando.
- Reducir moderadamente tiempos muertos, no telegraph esencial.
- Último patrón seleccionable con reglas deterministas para evitar loops o spam.

Cada transición debe cancelar hitboxes/telegraphs del patrón anterior, bloquear summon inmediato y ofrecer 0,8–1,2 s de lectura. La implementación debe permanecer local a `PalermitanoBoss`; no crear un director global de bosses.

## 10. Escena `visual_lab`

Crear en una fase posterior `scenes/debug/visual_lab.tscn` y su script, separados del nivel runtime. Debe reutilizar recursos existentes y no duplicar SpriteFrames.

Funciones mínimas:

- selector de familia/asset/animación;
- vista 1× y escala runtime lado a lado;
- Ciruja como silueta de referencia;
- línea de suelo, pivot, ground point, bounds alfa, body, hurtbox, hitbox, muzzle y roof line;
- flip izquierda/derecha, frame step, play/pause y fondo claro/oscuro;
- comparación de dos assets simultáneos;
- preset 800×450 con capas de profundidad y captura reproducible;
- reporte de canvas, bounds, altura opaca, escala y offsets sin escribir assets.

El preview actual sólo cubre animaciones de Ciruja a escala fija 1,5; debe conservarse hasta que Visual Lab cubra esa función y sus pruebas.

## 11. Pipeline para sprites nuevos conforme a `ART_BIBLE.md`

1. **Brief:** familia, rol, silueta, escala objetivo, luz arriba/izquierda, paleta y lista de acciones.
2. **Ubicación:** archivo fuente y export final dentro de la subcarpeta correcta de `art_v2/`; nunca reemplazar `assets/` durante producción.
3. **Entrega técnica:** PNG transparente, canvas consistente por secuencia, nombre canónico, FPS, loop, ground point, pivot, muzzle/impact frame y bounds esperados.
4. **Control automático:** dimensiones, alpha/color mode, numeración, huecos, duplicados, hashes y consistencia de canvas.
5. **Visual Lab:** comparar contra Ciruja y familia, revisar contorno, luz, lectura 800×450, grounding y jitter por frame.
6. **Recurso:** construir SpriteFrames y manifiesto V2 en una tarea de integración separada; no inferir gameplay desde el nombre del archivo.
7. **Colisión:** body estable, hurtbox coherente y hitboxes sólo en frames activos. Ornamentación no agranda el collider.
8. **Captura y aprobación:** idle, movimiento, telegraph, impacto y recovery sobre un fondo real de Ruta 38.
9. **Integración controlada:** sustituir una familia por vez, con tests específicos, smoke y comparación antes/después.
10. **Baseline:** actualizar hashes sólo después de aprobación visual y funcional; conservar legacy/reference.

## 12. Orden exacto recomendado de implementación

1. **Congelar baseline funcional y capturas:** smoke, end-to-end, progresión y capturas 800×450 en posiciones fijas.
2. **Crear Visual Lab sin alterar runtime.**
3. **Generar inventario de presentación:** mediciones de escala, ground points, pivots, sockets y profundidad para todos los actores/vehículos/props.
4. **Aprobar ratios de escala en Visual Lab:** primero personajes, luego vehículos, finalmente props por profundidad.
5. **Normalizar grounding y pivots:** aplicar una familia por vez; validar colliders, techos, pickups y muzzle.
6. **Ordenar capas del entorno y parallax:** separar lejano/midground/roadside/gameplay; conservar panorama A/B/C.
7. **Pulir cámara:** look-ahead/dead zone suave y encuadres de entrada; validar que no rompa spawn safety ni arenas.
8. **Completar lifecycle enemigo:** ENTRY, REACTION y PREPARE antes de tocar dificultad o densidad.
9. **Unificar telegraphs y marcadores de animación:** proyectil/impacto vinculados a frames documentados.
10. **Graybox de extensión:** ampliar recorrido y medir 4:30–5:00 con bloques funcionales, sin arte nuevo.
11. **Recomponer encounters/microeventos:** aplicar la estructura por actos y ajustar recompensas/descansos con telemetría.
12. **Implementar las tres fases de Palermitano:** localmente, manteniendo caps y cleanup existentes.
13. **Integrar arte V2 por familia:** sólo después de que escala, pivots y lifecycle estén estables.
14. **Cierre:** tests específicos, end-to-end, smoke, perfil de lifecycle, capturas comparativas y nuevo baseline de assets aprobado.

Este orden evita compensar sprites nuevos con offsets temporales, evita balancear sobre telegraphs incompletos y evita extender un mapa cuya cámara/profundidad todavía no estén listas para el nuevo ancho.

## 13. Criterios de salida de la fase

- Todos los actores y props relevantes tienen escala aparente, ground point y profundidad documentados.
- No hay jitter de pies ni objetos flotantes en reproducción a 800×450.
- Ningún ataque causa daño antes de su señal visual; cada ataque tiene recovery observable.
- El Player alcanza el preboss en 4:30–5:00 en primera partida objetivo, con cambios de verbo regulares y sin tramos de relleno.
- Expresbus/Tesa conservan espacio exclusivo y lifecycle determinista.
- Palermitano presenta tres fases distinguibles sin exceder caps ni dejar nodos pendientes.
- Visual Lab reproduce comparaciones y capturas sin depender del nivel principal.
- El pipeline V2 conserva legacy, produce metadatos completos y sólo actualiza baseline tras aprobación.
