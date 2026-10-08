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

## Nombre "Ingenio Arcor" (decisión pendiente del usuario)

El nombre aparece en estos lugares y hay que decidir cuál queda:

- `scripts/prototype/feel_config.gd` → `HUD_VICTORY_TEXT`: "Próximo destino: Ingenio Arcor."
- `scripts/core/main.gd` ~l.151: "PRÓXIMO DESTINO: INGENIO ARCOR · CONTINUARÁ…"
- `scripts/core/main.gd` ~l.439: "EL PALERMITANO HUYE AL INGENIO" + "Nivel 2: interior de la fábrica · Próximamente"
- `scripts/prototype/feel_config.gd` (comentarios del fin del nivel 1): "Ingenio Providencia" (nombre del cartel de `fondo_completo.png`)

Hay dos nombres distintos para el mismo ingenio ("Arcor" y "Providencia"). Esto queda sin cambiar hasta que decidas.

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
