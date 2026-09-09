# NEXT CONTENT AUDIT — Tucumán Rush

Fecha de auditoría: 2026-09-06. Alcance: inspección de solo lectura del proyecto Godot activo. Este documento no propone aplicar cambios todavía.

## Resumen ejecutivo

El vertical slice ya tiene pickups funcionales, combate cuerpo a cuerpo, un especial por carga, tráfico, proyectiles, dos carriles físicos y plataformas de techo. La mayoría del material solicitado ya existe como arte legacy, pero no todo está conectado al runtime: las animaciones de recoger están dentro de `assets/animations/player.tres`, aunque el pickup actual se resuelve instantáneamente y nunca las reproduce. Los buses y Exprebus son assets inventariados, no vehículos activos. No hay dron ni infraestructura aérea completa; sí hay bloques reutilizables para ataque a distancia, telegraph, encounter y proyectil.

## 1. Naranjas: arte, secuencia e inventario actual

| Elemento | Ruta / estado | Tamaño y frames | Uso actual |
| --- | --- | --- | --- |
| Árbol/naranjo | `res://assets/arbol_naranjas.png` | 182×159, 1 imagen | Visual ambiental repetido cinco veces en `route_38_environment.tscn` (escala 0.85) y pickup interactivo único creado por `route_38.gd` en x=520, escala 0.85. |
| Recoger naranjas | `res://assets/juntar_naranjas1.png` a `juntar_naranjas5.png` | 200×200 cada una, 5 frames a 10 FPS | `SpriteFrames` legacy `res://assets/animations/player.tres`, animación `juntar_naranjas`. No hay llamada runtime a esa animación. |
| Disparo naranja | `ciruja_disparo_naranja0.png` a `5.png` | 200×200 cada una, 6 frames a 24 FPS | Sí: `Throw Orange` del `SpriteFrames` actual; `Player.throw_projectile("orange")` la reproduce durante 0.25 s. |
| Proyectil/inventario | `res://assets/naranja.png`; `data/projectiles/orange.tres` | PNG 200×200; visual de proyectil definido en recurso | `Player.oranges_unlocked` (bool) bloquea/desbloquea munición infinita; HUD muestra `NARANJAS —/∞`; `Pickup.orange_tree` lo vuelve `true`. |

El pickup de naranjo es un `Area2D` genérico (`scenes/actors/pickup.tscn` / `scripts/actors/pickup.gd`). Al tocarlo a ras de suelo y en el carril correcto llama `Player.collect("orange_tree")`, reproduce el SFX actualmente asociado a `empanada`, mantiene el árbol visible con modulación tenue y emite el aviso `¡NARANJAS LISTAS!`. No existe una acción de sacar, agarrar o guardar naranjas separada ni estado de inventario numérico.

Conclusión: hay una secuencia visual reutilizable de cinco frames, pero conectar una recogida animada exigiría introducir un estado de pickup/acción en Player y sincronizar el momento de concesión. No conviene limitarse a reproducirla desde `pickup.gd`, porque el Player seguiría pudiendo moverse/disparar durante la pose.

## 2. Cascotes: arte, secuencia e inventario actual

| Elemento | Ruta / estado | Tamaño y frames | Uso actual |
| --- | --- | --- | --- |
| Pila de cascotes | `res://assets/montaña_cascote.png` | 200×200, 1 imagen | Dos pickups runtime: x=1450 y x=4400, carril 0, escala 0.65. |
| Recoger cascotes | `res://assets/juntar_cascote1.png` a `juntar_cascote5.png` | 200×200 cada una, 5 frames a 10 FPS | `SpriteFrames` legacy `player.tres`, animación `juntar_cascotes`; no hay llamada runtime. |
| Disparo cascote | `ciruja_disparo_cascote0.png` a `4.png` | 200×200 cada una, 5 frames a 20 FPS | Sí: `Throw Stone`; `Player.throw_projectile("stone")` la usa. |
| Proyectil/inventario | `res://assets/cascote.png`; `data/projectiles/stone.tres` | PNG 200×200 | `Player.stones` es entero; cada pila concede +20 y cada Cascotazo consume 1. HUD muestra el contador. |

El flujo coincide con el naranjo: `Pickup` detecta contacto, `Player.collect("stone_pile")` suma 20 y oculta permanentemente la pila al recogerla; `Route38` muestra `¡20 CASCOTES! Tirálos con X`. La secuencia legacy está disponible pero desconectada. Tampoco existe una animación distinta de guardar cascotes ni un objeto de inventario visual separado.

## 3. Insolación / calor

### Implementación localizada

| Área | Ubicación | Estado actual |
| --- | --- | --- |
| Variables y daño | `scripts/actors/player.gd` | `heat` (0–100) y `heat_damage_time`. Con controles activos y `position.x > 3200`, suma 2.1 por segundo; a 100 aplica 1 daño cada 2 s con fuente `sun`. Se persiste en `get_respawn_state`/`respawn_at`. |
| HUD | `scripts/core/hud.gd` y nodo `Interface/HUD` de `scenes/main.tscn` | Señal `hud_status_changed(lives, stones, oranges_unlocked, heat)`; el texto de localidad renderiza `SOL n%`. No hay barra independiente de calor. |
| Pickups | `scripts/core/route_38.gd`, `scripts/actors/pickup.gd`, `scripts/actors/player.gd` | Seis pickups `achilata` (x=3200, 3600, 4300, 5400, 6500, 7200; carriles alternados; escala 0.24). Cada uno da +100 puntos y reduce `heat` en 50, sin curar vida. |
| Recursos visuales/sonido | `assets/sol.png` (162×159), `assets/achilata.png` (200×230), `AudioManager`/SFX `achilata` | `achilata` se instancia como pickup; `sol.png` está en inventario/asset library, pero no tiene referencia de escena o script runtime. |
| Señales y sesión | `Player.hud_status_changed`, `Player.status_changed`, `Main` enlaza HUD | No hay señal dedicada de calor ni estado de `GameSession` independiente: se guarda dentro del diccionario de respawn del Player. |
| Tests | `tests/migration_smoke.gd` | Comprueba tasa invariante a 30/60/120 FPS y que Achilata lleve 80→30 sin cambiar vida. El smoke también cubre restauración/flujo que arrastra el estado del Player. |

### Desactivación temporal segura (sin hacerla ahora)

No borrar assets, pickup ni campos. La vía de menor riesgo sería añadir una única bandera de diseño (por ejemplo, en `GameConfig`) y condicionar exclusivamente el bloque de incremento/daño de calor de `Player._physics_process`. Conservar `heat`, la señal y el formato HUD en 0 evita romper los snapshots de checkpoint, la interfaz y los consumidores existentes. Luego habría que decidir por diseño si Achilata permanece como pickup de puntos/SFX o se desactiva como spawn; esta segunda decisión afecta `Route38._ready` y su prueba. También deben adaptarse los dos asserts específicos de calor/Achilata de `migration_smoke.gd` y ejecutarse los smoke/profile. No se debe eliminar el campo de estado ni cambiar la firma de `hud_status_changed` mientras el HUD y el checkpoint sigan conectados.

## 4. Cabezazo y Tucumanazo

### Estado actual

| Aspecto | Cabezazo | Tucumanazo |
| --- | --- | --- |
| Input | `headbutt`: C / gamepad X | `tucumanazo`: V / gamepad Y |
| Recurso | `data/attacks/cabezazo.tres` (`AttackDefinition`) | `data/attacks/tucumanazo.tres` (`TucumanazoDefinition`, hereda `AttackDefinition`) |
| Valores | 5 daño; startup 0.08 s, activo 0.08 s, recovery 0.09 s; rectángulo 90×90, offset (45,-45) | 5 daño; 0.12/0.15/0.35 s; círculo radio 150, offset (0,-45); hit-stop 0.08 s a escala 0.08 y shake 8/0.25 s |
| Carga | No consume munición; cada impacto válido aumenta combo y 1 carga especial | Requiere medidor lleno: 8 impactos válidos; `consume_full()` lo vacía al arrancar |
| Hitbox | Nodo `HeadbuttHitbox`, `Hitbox` reutilizable; se espeja según orientación y sólo afecta enemigos del mismo carril | Nodo `TucumanazoHitbox`; área circular, mismo carril, un impacto por objetivo/activación |
| Visual/SFX | `CharacterDefinition.headbutt_animation` = `Headbutt` (3 frames legacy); SFX `cabezazo` | Reutiliza la misma animación `Headbutt`, SFX `alerta`, frase `¡VAMO' URA!`, SFX `golpe` al primer impacto, shake y hit-stop |
| HUD | Indirectamente muestra combo | `SpecialMeterComponent` enlazado a `HUD.SpecialBar/SpecialStatus`: `TUCUMANAZO n/8` o `LISTO` |

`Player` bloquea ambos durante cambio de carril, muerte, otro especial o cooldown. Daño, muerte y pausa cancelan estados/hitboxes; el daño rompe combo, pero preserva carga ya acumulada salvo que el especial ya se hubiera consumido. `main.gd` enlaza combo, medidor y feedback con HUD/cámara.

Las pruebas son extensas en `tests/migration_smoke.gd`: validez de ambos recursos, bindings de input, ventanas startup/active/recovery, espejo, carril, combo/carga, HUD, área del especial, hit-stop/shake, pausa, daño/muerte y reinicio. `tests/vertical_slice_profile.gd` además inicia/cancela ambos por ciclo.

### Alcance de un futuro rediseño: 5 Tucumanazos consumibles

Para el diseño previsto, el Cabezazo dejaría de ser acción/estado/recurso independientes y el Tucumanazo pasaría a tener contador inicial 5, decrementado al disparar. Habría que revisar conjuntamente:

1. `InputSetup`, `Player` (enum/fases, `HeadbuttHitbox`, `start/cancel/update_headbutt`, cooldowns y cancelaciones), `player.tscn` y `data/attacks/cabezazo.tres`; no basta con ocultar el botón.
2. `SpecialMeterComponent`, su conexión desde `main.gd`, `HUD.SpecialBar/SpecialStatus` y los tests, para sustituir carga por un contador explícito y una semántica `5…0`. Conviene decidir si el contador vive en Player o GameSession antes de persistirlo en checkpoint.
3. `TucumanazoDefinition` y su hitbox pueden conservarse como base del cabezazo potente; el `Hitbox` circular, la cámara, hit-stop y el feedback son reutilizables. La onda expansiva requiere un visual/efecto nuevo sincronizado con la fase activa, no existe actualmente.
4. Arte/animación: hay una sola animación legacy de cabezazo de tres frames compartida por ambos. El nuevo efecto puede comenzar con esa pose, pero no hay asset de onda ni de cinco unidades de inventario.
5. Assertions de ambos archivos de test y el perfil deben migrarse en la misma entrega para no dejar el vertical slice validando una mecánica eliminada.

## 5. Vehículos

El `TrafficDirector` sólo rota `auto1`, `auto2` y `camion_limones`. Las cuatro plataformas estacionarias se crean en `Route38._ready`: `auto1` x=1900 escala 0.95, `camion_limones` x=3100 escala 2.35, `auto2` x=5000 escala 0.95 y `auto3` x=6700 escala 0.95. Los móviles no son `StaticBody2D`: son `Node2D` con hitbox de impacto; por ello no se puede saltar sobre ellos.

| Vehículo | PNG | Escala Godot / tamaño visual aproximado | Collider / uso | Escala vs Player |
| --- | --- | --- | --- | --- |
| Auto rojo `auto1` | 186×83 | 0.95 → 177×79 px | Estático: techo one-way de ~141×8 px; móvil: hitbox ~145×57 px | Coherente con Player visual ~84 px alto. |
| Auto amarillo `auto2` | 200×60 | 0.95 estacionario → 190×57; 0.90 móvil → 180×54 | Estático: ~152×8; móvil: ~148×39 | Bajo/deportivo pero coherente. |
| Segundo modelo auto `auto3` (blanco) | 200×85 | 0.95 → 190×81 | Sólo plataforma: techo ~152×8; no entra al tráfico | Coherente. |
| Camión de limones | 190×88 | 2.35 estacionario → 447×207; 0.90 móvil → 171×79 | Estático: ~357×8; móvil: ~140×57 | Inconsistencia deliberada o pendiente: el mismo asset cambia ~2.6× entre plataforma y tráfico; la plataforma es gigantesca frente al Player. |
| Bus rojo `bus1` | 189×81 | Sin instancia runtime; natural 189×81 | Sin collider | Disponible, no integrado. |
| Bus amarillo `bus2` | 200×80 | Sin instancia runtime; natural 200×80 | Sin collider | Disponible, no integrado. |
| Bus blanco `bus3` | 191×76 | Sin instancia runtime; natural 191×76 | Sin collider | Disponible, no integrado. |
| Bus rojo/blanco `bus4` | 189×76 | Sin instancia runtime; natural 189×76 | Sin collider | Disponible, no integrado. |
| Exprebus | 200×71 | Sin instancia runtime; natural 200×71 | Sin collider | Disponible, no integrado. |
| Camionetas u otros | No se encontraron otros PNG de vehículo ni referencias runtime | — | — | — |

Los tamaños de collider se derivan en ejecución desde PNG opaco: plataforma = 80% del ancho escalado y 8 px de alto, apoyada sobre el techo; tráfico = 82%×72% del PNG escalado, centrado visualmente. El Player usa escala 0.42 sobre frames 200×200 y una colisión derivada de ancho 65%; comparar silueta, no canvas bruto. Buses/Exprebus sólo figuran en `asset_library.tres`, manifiesto y hashes de integridad: no están en `TrafficDirector`, escenas de nivel ni plataformas.

## 6. Drones: reutilización posible y límites

Existe infraestructura reutilizable:

- `EnemyDefinition` ya modela salud, detección, distancia preferida, telegraph, cooldown, animaciones run/attack y modo `PROJECTILE`.
- `Enemy` ya emite `shot_requested`; `Main._spawn_projectile`, `ProjectileDefinition` y `projectile.tscn` resuelven proyectil, barrido anti-tunneling, carril, impacto y daño. El `bullet.tres` existente puede ser referencia de un disparo enemigo, aunque no es rojo por definición.
- `EncounterDirector` activa oleadas por x, contabiliza nodos con señal `defeated` y no depende de una clase concreta; `Route38.spawn_enemy` es el punto que actualmente sí instancia siempre `enemy.tscn` salvo el miniboss.

No existe dron, estado de vuelo, ruta de entrada aérea, seguimiento de objetivo, mira creciente, ni tres estados visuales. El `Enemy` actual es un `CharacterBody2D` de suelo: aplica gravedad, floor snap, carriles físicos y persigue horizontalmente. Por tanto, reutilizar `EnemyDefinition`/proyectil/EncounterDirector es razonable, pero reutilizar sin adaptar `enemy.gd` no lo es. La opción segura es una escena/script aéreo separado que exponga `defeated`, use un `EnemyDefinition` extendido o una definición específica, y sea seleccionado explícitamente desde `Route38.spawn_enemy`; así no se altera la física de los enemigos terrestres. La mira roja debe ser un nodo/efecto nuevo con su propio telegraph y no puede inferirse de `attack_visual`, que actualmente sólo es un contador sin dibujo.

## 7. Escenario interactivo y estructuras saltables

| Sistema | Ubicación | Estado |
| --- | --- | --- |
| Suelo/carriles | `Route38._ready` | Crea dos `StaticBody2D` (`GroundLane0/1`) con floors de 8400×12, layers por carril. |
| Plataforma saltable | `scenes/actors/platform.tscn`, `scripts/actors/platform.gd` | `StaticBody2D`; Sprite legacy y techo `CollisionShape2D` one-way calculado a partir de bounds opacos. Ya lo usan vehículos estacionarios. |
| Vehículos | `Route38`, `TrafficDirector`, `vehicle.tscn` | Los estacionarios son plataformas; tráfico es sólo peligro con hitbox. |
| Paradas/kioscos/edificios | `route_38_environment.tscn` | Paradas, naranjos, palmeras, postes, cartel, gruta y kiosco son `Sprite2D` puramente decorativos; no tienen `StaticBody2D` ni colisión. No se encontraron edificios jugables adicionales. |
| Pruebas | `migration_smoke.gd` | Valida que Player aterriza en un techo generado y que la forma es one-way. |

La manera más segura de incorporar una nueva estructura saltable sin tocar Player es reutilizar el contrato de `platform.tscn`: una instancia independiente por estructura, `lane_index` correcto, `collision_layer = 1 << lane_index`, máscara 0 y sólo una superficie one-way superior. Para una estructura con arte no vehicular, el script actual presupone `res://assets/<asset>.png`; conviene crear una variante genérica o parametrizar la textura en una tarea futura, en vez de forzar kiosco/parada dentro de la lógica de vehículos. Validar con saltos desde ambos carriles, cambio de carril cerca de la estructura y proyectiles: `projectile.gd` consume proyectiles al tocar cualquier `StaticBody2D`.

## Riesgos y orden recomendado para la próxima etapa

1. Las animaciones legacy y Player tienen canvas de 200×200 y pivots/escala ya validados; conectar recogidas o especial debe respetar `CharacterDefinition`, offsets y colisiones existentes.
2. Cambiar Cabezazo y Tucumanazo afecta input, Player, HUD, recursos, checkpoint y una parte amplia de los smoke tests. Debe tratarse como una migración atómica, no como cambios de texto en HUD.
3. Desactivar calor sin bandera deja datos/HUD/tests en estado incoherente; no borrar Achilata ni la firma de señal.
4. La escala de `camion_limones` estacionario (2.35) es la principal inconsistencia visual/collider detectada. No igualarla a tráfico sin revalidar el salto y composición Route 38.
5. Añadir un `StaticBody2D` sin limitarlo a un carril puede bloquear indebidamente el otro; añadir colisión a una parada/kiosco también hará que los proyectiles se destruyan al golpearla.
6. Un dron no debe heredar a ciegas la gravedad y lane-follow de `enemy.gd`; separar el actor protege a los enemigos terrestres y el vertical slice.

## Confirmación de alcance

Esta auditoría no modificó gameplay, escenas runtime, scripts, recursos, tests, configuraciones ni assets. El único artefacto creado es este informe.
