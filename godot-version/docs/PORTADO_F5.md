# Portado del prototipo al juego completo (F5)

Objetivo: llevar a `route_38` (F5, escena principal) lo que ya funciona en `scripts/prototype/pixel_arena` (F6), sin perder el contenido del juego completo (localidades, vehículos, drones, objetos, combo, diálogos).

Regla de arte: cartoon ilustrado, no pixel art. No se tocan PNG.

## Estado de partida (historial y árbol)

- Rama: `codex/prototype-cartoon-polish`. Último commit: `e141c82 feel_config: afinar estimación de cámara donde entraría el ingenio`.
- Cambios previos sin commitear que **no son de este trabajo** y no se incluyen en los commits: `scripts/prototype/ciruja_skin.gd` (modificado), `assets/campeona empanadas.png` (borrado), y varios PNG y carpetas sin trackear (`assets/*.png`, `characters/lote2_cuadros/*/tira.png`, `assets/prototype/ciruja_pixellab/`).
- Cada commit de este trabajo agrega solo sus archivos (`git add` explícito).

## Tabla de portado

| # | Sistema | Origen (prototipo) | Destino (juego completo) | Riesgos |
|---|---------|--------------------|--------------------------|---------|
| 1 | SpriteFrames de personajes (Ciruja, Agente, Hipster, Grandote, Palermitano, Campeona) | `pixel_arena.gd` → `_apply_batch_frames`, `_copy_animation`, `_anchor_batch_visual`; frames en `assets/animations/generated/*.tres` (generados por `tools/build_character_frames.gd` desde `characters/lote2_cuadros/`) | Extraer la lógica a un helper compartido (`scripts/prototype/batch_visuals.gd`) y llamarlo desde `route_38.gd` (`spawn_enemy`, `spawn_palermitano`, `_spawn_miniboss_grandote`) y `main.gd`/`route_38.gd` para el jugador | El batch copia animaciones por nombre (alias `run_animation`, `attack_animation`, `Death`); hay que mapear los nombres de `data/enemies/*.tres` y `data/characters/san_martin.tres`. Los offsets legacy (`_visual_frame_offsets`, `_visual_offset_profiles`) deben limpiarse como hace el prototipo. Si se cambia el SpriteFrames del jugador, cambia la hitbox implícita de `CollisionFactory.add_shape` (usa `character_visual_scale`). |
| 2 | Escala por proporción (`feel_config.target_height`) | `character_scale.gd` (`remember`, `apply`, `apply_npc`) | Mismo helper, llamado al spawnear en `route_38.gd` | El juego completo es 800×450 de mundo y el prototipo 400×225 escalado ×2. Con las mismas unidades de mundo, los personajes se verán en la mitad del tamaño relativo a la pantalla. Es el riesgo principal de escala: ver "Ajustes de escala a probar". Además `definition.visual_scale` (0.34–0.55) y `attack_range` / `preferred_distance` se multiplican por el factor en `apply` (ya lo hace el prototipo). |
| 3 | Vehículos, carteles y objetos del decorado | `vehicle.tscn` (`Sprite2D`), `platform.tscn`, `generic_platform.tscn` con `image_scale` fijos en `route_38.gd` (p. ej. `add_generic_platform(... 0.50 ...)`) | Escalar de forma proporcional al nuevo tamaño de personajes (medir alto visible antes y después) | Hay muchas llamadas con escalas a mano en `route_38.gd` y `route_38_data.json`. Cambiar escalas puede mover la lógica de colisión de techos (`_platform_roof_y`) y los carriles del `traffic_director`. |
| 4 | Sombras de contacto | `contact_shadow.gd` (`_add_contact_shadow`) | Se agrega en `route_38.gd` tras cada spawn de actor, `z_index = -1` | Los drones no pisan el suelo: no sombrear o sombrear con altura de vuelo. Las plataformas no llevan sombra. |
| 5 | Impactos: hit-stop, shake, flash, knockback | `feel_director.gd` + `feel_fx.gd` + `IMPACT_PROFILES` de `feel_config.gd`; se engancha con `feel.watch_enemy` | Mismo `feel_director`, enganchado a `enemy.gd`/`palermitano_boss.gd`/`miniboss_grandote.gd` vía `route_38.gd`. Shake sobre la `Camera2D` de `main.tscn` | **Conflicto de `Engine.time_scale`**: el Tucumanazo (`player.gd`, ~l.450–465) ya usa `Engine.time_scale` para su hit-stop. Hay que decidir una sola fuente de time_scale. El feel_director espera `$ViewportContainer` (estructura del prototipo); habrá que adaptarlo a `Main/Camera2D`. |
| 6 | Cámara lenta y polvo en muertes grandes; cuerpo que persiste | `procedural_anim.gd` (tweens de `Death`, `DEATH_SLOWMO`, `DEATH_DUST`) | `enemy.gd` ya tiene muerte por tween (`defeated.emit` ~l.534). Reemplazar esa muerte por el helper compartido, o engancharse a `defeated` | Duplicación: hay dos sistemas de muerte. Hay que mantener los puntos de ganancia (`defeated(points)`) y los eventos de `encounter_director` (`_on_enemy_defeated`). Slow-mo comparte el riesgo de time_scale del punto 5. |
| 7 | Proyectiles con presencia (giro, rebote, estela, sombra) y disparo en arco de café/botella | `projectile_fx.gd` (`PROJECTILE_FX`), `arc_shot.gd`, `ARC_KINDS` | `projectile.gd` del juego completo, con `kind` de `data/projectiles/*.tres` | El arco cambia el gameplay de café/botella (antes en línea recta). Hay que verificar que el hitbox siga el arco. `PROJECTILE_FX` usa claves (`bottle`, `hipster_coffee`, `coffee`, `agent_orb`, `bullet`, `orange`, `stone`) que deben coincidir con los `kind` reales. |
| 8 | Manchas de café en el piso (lentitud y quemadura) | `coffee_stain.gd`, `stain_manager.gd`, `STAIN_*` | `route_38.gd` conecta `ARC_SHOT.landed` a `add_stain` | Requiere modificar la velocidad de `player.gd` (factor `STAIN_SLOW`) y una quemadura que no baja la vida de 1 (`STAIN_CAN_KILL = false`). Es el único punto que toca movimiento del jugador. |
| 9 | HUD cartoon (texto con borde, panel, barra de jefe, banner) | `prototype_hud.gd` (`CFG.HUD_*`) | Reemplaza el texto de `ui/hud.tscn` y `scripts/core/hud.gd` manteniendo **todos** los datos: vidas, puntos, monedas, naranjas, cascotes, localidad, combo | La HUD del juego completo (`hud.gd`) expone métodos que usa `route_38.gd`/`main.gd` (`show_result`, `show_notice`, `set_location`, `bind_combo`, `bind_special`, `bind_health`, `bind_game_session`, `bind_player_status`, `bind_boss_health`). La HUD cartoon (`prototype_hud.gd`) solo tiene barra de jefe, banner, panel de vidas/puntos y overlay. Hay que verificar que cada dato actual (naranjas, cascotes, combo, monedas, localidad) tenga su equivalente antes de reemplazar. |
| 10 | **Bug del "00000"** | `prototype_hud.gd` muestra `player.score`, pero nadie suma puntos en la arena del prototipo | En el juego completo, `route_38._on_enemy_defeated` hace `player.score += points`; el prototipo no conecta `enemy.defeated` ni el jefe | Causa confirmada: en `pixel_arena.gd` no hay conexión a `defeated(points)`. Solo las recogidas (`player.gd` ~l.668–678) suman en el jugador, y en la arena no hay recogidas. Falta el mismo cableado que `route_38`. |
| 11 | Jefe Palermitano: intro, barra de vida, fase 2, derrota | `boss_director.gd` + `boss_aura.gd` + `BOSS_*` de `feel_config.gd`; el jefe usa `palermitano_boss.tscn` | `route_38.spawn_palermitano`, `_on_palermitano_defeated`, `_on_palermitano_exiting`; `main.gd` `_on_final_boss_defeated` | El director espera `Camera2D` y `hud.show_boss_bar/set_boss_health/hide_boss_bar/show_banner`. El juego completo tiene un flujo de salida al ingenio (`_on_palermitano_exiting`) que compite con la derrota del prototipo. El corte de nivel ("huye al ingenio") debe quedar donde hoy: en `main.gd`. |
| 12 | Campeona: forcejea y es arrastrada al inicio de la intro | `pixel_arena.gd` → `_spawn_campeona`, `_take_campeona` y `CAMPEONA_*` | Se aparece en la ruta junto a la Campeona de la intro (`scenes/cinematics/intro_famailla.tscn`) y se activa con `boss_director.intro_started` | La Campeona actual del juego completo está en la cinemática; no hay un actor persistente en la ruta. Hay que decidir si se muestra en la ruta o solo en la cinemática (duplicar causaría dos instancias). |

## Textos de pantalla final

- Se mantienen los textos del juego completo (`main.gd` ~l.150, ~l.388, ~l.439). No se usan los de `feel_config.gd` (`HUD_GAME_OVER_TEXT`, `HUD_VICTORY_TEXT`), que son del prototipo.
- Los textos finales del juego completo ya muestran `Puntaje` y `Monedas`, así que el fix del punto 10 corrige también la pantalla final del prototipo.

## Nombre del ingenio

Decidido: "Ingenio La Providencia" en todo el proyecto (HUD_VICTORY_TEXT, main.gd, diálogos, datos de ruta, docs y comentarios). Ya no queda "Arcor".

## Ajustes de escala a probar (recomendación previa)

1. Probar `REFERENCE_VISIBLE_HEIGHT` (74) como alto visible en mundo de 800×450 y, alternativamente, un zoom de cámara ×2 en `Camera2D` de `main.tscn` para igualar el encuadre del prototipo.
2. Revisar `HIPSTER_TARGET_HEIGHT` (92) y `CHARACTER_PROPORTIONS` (grandote 1.25, palermitano 1.3) contra Ciruja en el tramo de Famaillá.
3. Medir vehículos y carteles de `route_38.gd` contra la altura de Ciruja, con capturas en esos mismos puntos.

## Riesgos generales

- Tests existentes (`godot-version/tests/*_checks.gd`) asumen sprites y tamaños viejos. Hay que actualizar los que dependan de ellos (paso 5).
- La ruta depende de `scenes/levels/route_38_data.json` (encuentros, `enemy_id`, `grandote` en dos tramos). Cambiar escalas no debe mover encuentros.
- Hay un solo `Engine.time_scale` (riesgo 5). Un hit-stop y el Tucumanazo no deben pisarse.

## Orden de trabajo

0. Este documento (sin cambios de código).
1. Personajes (helper compartido + escalas + hitboxes + vehículos).
2. Sombras, impactos, cámara lenta, polvo, proyectiles, manchas (reuso del prototipo).
3. HUD cartoon y pantallas (corrección del "00000").
4. Jefe Palermitano en Río Seco (intro, barra, fase 2, derrota, corte de nivel).
5. Verificación: Godot headless con la consola, tests, capturas en `docs/capturas/`.

---

## Estado de los pasos

| Paso | Estado | Commit |
|------|--------|--------|
| 0. Plan (este documento) | Hecho | `a3eed02` |
| 1. Personajes, escala, hitboxes, puntos de lanzamiento, vehículos y cinemática | Hecho | `db5c65e` |
| 2. Sombras, impactos, cámara lenta, polvo, proyectiles, manchas de café | Hecho | `214ac93` |
| 3. HUD cartoon compartida y corrección del "00000" | Hecho | `42cf245` |
| 4. Jefe Palermitano del prototipo en Río Seco | Hecho | `2f1c65c` |
| 5. Verificación y capturas | Parcial (ver abajo) | — |

## Decisiones tomadas (revisar)

1. **Escala en la ruta 38: solo visual e hitbox.** `batch_visuals.attach(..., scale_actor=false)` deja `actor.scale = 1` y no toca `attack_range` ni `preferred_distance`. Los tiempos de ataque no cambian. El prototipo sigue escalando el actor como antes (`scale_actor=true`). Alturas visibles en la ruta: agente 74 px, hipster 92, grandote 92.5, palermitano 96, según `feel_config`.
2. **Autos y paradas estacionados ×1.223** (`DECOR_VEHICLE_SCALE` en `route_38.gd`) = 0.95 / 0.777, la escala del auto1 del prototipo sobre la de la ruta. Los pickups no cambian.
3. **Café en arco y con giro también en el juego completo** (lo pedía el paso 2). Eso cambia velocidad y colisión del café. Los tests `player_progression_qol_checks` y `hipster_coffee_checks` pasaban a verificar el arco en vez de valores fijos.
4. **Intro de Famailla**: Ciruja, Champion y Palermitano usan los cuadros nuevos. La referencia rota a `assets/campeona empanadas.png` (renombrado a `campeona_empanadas.png`) se reemplazó por `characters/lote2_cuadros/campeona/idle/f_00.png`.
5. **Campeona**: en la ruta no hay Campeona persistente; solo aparece en la cinemática. No se agregó una segunda instancia.
6. **Intro del jefe** arranca al aparecer el Palermitano (`trigger_x = -INF`), no al cruzar X=400 como en la arena. Durante la intro la cámara se bloquea (`route.camera_locked`) y `main` vuelve a seguir al jugador al terminar.
7. **Shake**: el feel delega en la cámara de `main` (`screen_shake_requested`), sin un contenedor propio.
8. **Time scale**: el feel no toca `Engine.time_scale` mientras el Tucumanazo está activo o en su hit-stop, y tiene una red de seguridad que devuelve 1.0 si nadie es dueño. Esto corrige un bug real: el Super capturaba el 0.02 del hit-stop como "valor previo" y lo dejaba pegado.
9. **Re-aplicación de cuadros**: `main` reaplica la definición del jugador al elegir personaje y al restaurar checkpoint; después llama a `route.refresh_player_visuals()` para volver a poner los cuadros nuevos.

## Tests (estado al cierre)

- Actualizados por cambios intencionales: `agent_orb_checks` (punto de lanzamiento medido sobre el cuadro nuevo), `player_progression_qol_checks` y `hipster_coffee_checks` (café en arco).
- Actualizados porque la intro del jefe bloquea controles 2 s: `palermitano_boss_checks`, `super_headbutt_checks`, `route_38_end_to_end` (llaman a `boss_director.skip_intro()`).
- Pendientes: `enemy_lifecycle_checks` (el primer disparo del Agente sale 2 ticks, 33 ms, antes del mínimo del telegraph; causa no identificada) y `migration_smoke` (contratos de visuales legacy que cambiaron a propósito, y un cuelgue no resuelto en el tramo de diálogo de la intro).
- No son tests ejecutables con `--script` (no heredan de `SceneTree`, igual que antes de estos cambios): `arcade_pacing_checks`, `expresbus_checks`, `rebalance_checks`.

## Pendiente de decisión del usuario

- (resuelto) Nombre del ingenio: "Ingenio La Providencia".
- Si el café en arco y con giro es el comportamiento deseado en la ruta (punto 3).
- Si la escala del decorado (×1.223) y la de personajes (tabla) quedan así, o se prueba el zoom de cámara ×2 para igualar el encuadre del prototipo.
- Carteles de localidad: no se encontraron como sprites escalables en la ruta; quedan sin cambios.

## Depuración y estado de tests

- **F9** (solo builds de desarrollo, `OS.is_debug_build()`): teletransporta a Ciruja a x=7300 (Río Seco, antes del jefe) con vidas y vida llenas. Sin HUD, sin tocar checkpoints ni puntaje; inactiva en builds exportadas.
- **Hay 4 tests en rojo conocidos** que se dejan como están (por ejemplo `enemy_lifecycle_checks` y `migration_smoke`, ver arriba). Verificación headless del juego completo: sin errores nuevos.
