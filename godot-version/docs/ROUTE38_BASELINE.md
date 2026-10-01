# Ruta 38 — baseline previo a Art Polish / Gameplay Polish

Baseline congelado el 27-09-2026. La fuente de verdad de esta medición es el runtime actual: escenas, recursos `.tres`, scripts y overrides cargados por Godot. No se aplicaron los ratios provisionales ni la futura longitud de graybox.

## Contrato general

| Propiedad | Estado actual |
|---|---|
| Resolución interna | 800×450, `canvas_items`, nearest por defecto |
| Longitud del mundo | 8000 px |
| Futuro graybox aprobado | 16.500 px, sólo referencia; no implementado |
| Plano principal | único plano, `GROUND_Y = 370` |
| Posición inicial | Player en (80, 370) |
| Checkpoint | X=3600, escena en Y=392,5; respawn configurado por checkpoint |
| Entrada al boss | trigger X=7425; Palermitano aparece en X=7600 |
| Arena Grandote | X=6900–7750 |
| Arena Palermitano | X=7000–7950 |
| Cámara | viewport 800×450; límites 0/0/8000/450; seguimiento X entre 400 y 7600; smoothing activo; Y fija en 225 |
| Gameplay | Ruta 38 lineal, calor suspendido, tráfico aleatorio retirado |

## Escala runtime de actores

Ciruja es la referencia: `ciruja_idle.png`, bounds opacos 96×197, escala efectiva 0,42, altura aparente 82,74 px = 1,00.

| Actor | Fuente runtime | Escala efectiva | Offset base | Altura representativa | Ratio/Ciruja |
|---|---|---:|---:|---:|---:|
| Ciruja | `san_martin.tres` | 0,42 | (0, −42) | 82,74 px | 1,00 |
| Hipster scooter | `hipster.tres` | 0,34 | (0, −47,94) | 94,52 px, primer frame Ride | 1,14 |
| Agente | `agente.tres` | 0,36 | (0, −50,4) | 94,32 px, primer frame Run | 1,14 |
| Grandote común | `grandote.tres` | 0,44 | (0, −63,36) | 117,48 px, primer frame Run | 1,42 |
| Drone | `drone.tres` | 0,55 | vuelo a −145 px | 47,85 px | 0,58 |
| Grandote miniboss | `miniboss_grandote.tscn` | 0,48 | (0, −69,12) | 128,16 px | 1,55 |
| Palermitano | `palermitano_boss.tscn` | 0,42 | (0, −60,9) | 107,52 px, primer frame Run | 1,30 |

Los actores genéricos reciben escala/offset desde `EnemyDefinition`. Player recibe esos valores desde `CharacterDefinition`. Palermitano y Grandote miniboss usan valores directos de escena. `animation_manifest.json` agrega offsets por frame sobre el offset base, pero no cambia el collider principal.

## Enemigos y ataques presentes

- Hipster: ranged, café propio, 2 HP, movimiento 55 px/s.
- Agente: ranged, orb propio, 3 HP, movimiento 52 px/s.
- Grandote común: melee + Ground Slam, 6 HP, movimiento 45 px/s.
- Drone: ranged aéreo, 3 HP, movimiento 105 px/s, entry delay 1 s, aim/lock y retícula.
- Grandote miniboss: escena dedicada con charge, punch y ground slam.
- Palermitano: 90 HP; triple café, cadena y summon de hasta dos Agentes.

Enemigos terrestres usan `CHASE → TELEGRAPH → ATTACK → RECOVERY`; Drone usa `ENTRY → IDLE → AIM → FIRE → COOLDOWN`; Palermitano usa `INTRO → DECIDE → TELEGRAPH → ATTACK → RECOVERY`.

## Vehículos y plataformas

| Asset | Uso | X | Escala |
|---|---|---:|---:|
| auto1 | estacionado/plataforma | 700 | 0,90 |
| camioneta1 | estacionada/plataforma | 1500 | 0,82 |
| auto3 | estacionado/plataforma | 2300 | 0,95 |
| auto3 | estacionado/plataforma | 3100 | 0,95 |
| camioneta2 | estacionada/plataforma | 3900 | 0,72 |
| camion_limones | estacionado/plataforma | 4650 | 0,80 |
| auto2 | estacionado/plataforma | 5450 | 0,90 |
| camioneta3 | estacionada/plataforma | 6200 | 0,70 |
| camioneta4 | estacionada/plataforma | 6900 | 0,78 |
| Expresbus | set piece móvil | trigger 2850 | 1,20; 240 px/s |
| Tesa | set piece móvil | trigger 4400 | 1,10; 225 px/s |
| parada_colectivo2 | plataforma roadside | 2700, Y=350 | 0,50 |

Plataformas estacionarias y móviles anclan el borde opaco inferior al origen físico. El techo one-way se calcula desde los bounds alfa y pertenece a `PLAYER_PLATFORM_LAYER`; proyectiles no colisionan con ese layer.

## Localidades

| Localidad | X |
|---|---:|
| Famaillá | 0 |
| Acheral | 1400 |
| Monteros | 2800 |
| León Rougés | 4200 |
| Villa Quinteros | 5400 |
| Río Seco | 6600 |

## Encounters actuales

| ID | Trigger X | Composición | Descanso |
|---|---:|---|---:|
| route_wave_01 | 450 | 4 Hipsters | 0,8 s |
| route_micro_01 | 900 | 3 Hipsters + 3 Agentes | 0,8 s |
| route_micro_02 | 1350 | 3 Hipsters + 3 Agentes | 0,8 s |
| route_wave_02 | 1800 | 4 Agentes | 1,0 s |
| route_wave_03 | 3500 | 3 Hipsters + 3 Agentes | 1,0 s |
| route_micro_03 | 3800 | 3 Hipsters + 3 Agentes | 0,8 s |
| route_drone_01 | 4100 | 1 Drone tutorial | 1,5 s |
| route_micro_04 | 5100 | 3 Hipsters + 3 Agentes | 0,8 s |
| route_wave_04 | 5400 | Grandote + 2 Hipsters + 2 Agentes | 2,0 s |
| route_micro_05 | 5750 | 3 Hipsters + 3 Agentes | 0,8 s |
| route_drone_02 | 6100 | 5 Drones escalonados | 2,0 s |
| route_micro_06 | 6450 | 3 Hipsters + 3 Agentes | 0,8 s |
| route_wave_06 | 6800 | Grandote + 2 Hipsters + 3 Agentes | 2,5 s |

Entradas normales están separadas 0,45 s; Drones de la oleada, 0,55 s. `EncounterDirector` limita población activa a 7, usa un token ofensivo por pool, cap general de 3 proyectiles hostiles, cap 2 para la oleada Drone, spawn delante del viewport y retiro seguro detrás de cámara.

## Fondo y parallax

| Capa | Configuración |
|---|---|
| Cerros/cielo | `Parallax2D`, scroll X=0,08, z=−20, repetición 1806 |
| Panorama principal | A/B/C de `fondo_completo.png`, scroll X=0,66, z=−15 |
| Regiones panorama | 2667/2666/2667×1024; escala uniforme 0,84 |
| Posiciones panorama | X=0 / 2240,28 / 4479,72; Y=−232,76 |
| Midground | cañas X=1180, Y=298,45, escala 0,45, z=−8; sin Parallax2D propio |
| Ruta | scroll X=1,0, z=−5; dos módulos de 330 px con overlap de 1 px, período 658 |
| Landmarks/props | cartel z=−2 escala 0,80; semáforo z=−2 escala 0,70; poste z=−2 escala 0,75 |

## Overrides que afectan composición

- `CharacterDefinition` y `EnemyDefinition` sobrescriben el aspecto declarado inicialmente por sus escenas genéricas.
- `STATIONARY_VEHICLES` en `route_38.gd` es la fuente runtime de escala/posición para los nueve vehículos estacionados.
- `TrafficDirector.SET_PIECE_CONFIGS` define escalas de colectivos; `ExpresbusSetPiece` y el nodo Tesa sobrescriben sus velocidades con 240/225 px/s.
- `route_38.gd` fija escala y posición de parada/pickups mediante código.
- Player, enemigos y boss tienen muzzle offsets hardcodeados en scripts.
- Props del entorno usan escala/Y/z directos de escena y no comparten una definición de ground point.
- `data/enemies/boss.tres` pertenece al actor genérico legacy; el boss final vigente es la escena dedicada `palermitano_boss.tscn`.
- `WORLD_SCALE_REFERENCE.md` contiene mediciones históricas y ya no es fuente de verdad.

## Capturas reproducibles

Generadas a 800×450 mediante `dev/capture_route38_baseline.gd`, con gameplay detenido sólo dentro del fixture:

- `docs/baseline/01_start.png`
- `docs/baseline/02_expresbus_sector.png`
- `docs/baseline/03_tesa_midpoint.png`
- `docs/baseline/04_drone_sector.png`
- `docs/baseline/05_preboss.png`
- `docs/baseline/06_runtime_scale_lineup.png`
- `docs/baseline/07_visual_lab.png`

Para regenerarlas: ejecutar Godot con `--path . --script res://dev/capture_route38_baseline.gd --resolution 800x450` y luego `res://dev/capture_visual_lab.gd`.

## Validación al congelar el baseline

- Visual Lab estructural: 70/70.
- Agent orb: 7/7.
- Grounding/parallax: 13/13.
- Legibilidad de combate: 19/19.
- Drone: 20/20.
- Café Hipster: 10/10.
- Palermitano: 26/26.
- Disparo junto a vehículos: 30/30.
- End-to-end Mission 1: 29/29.
- Progresión: 15/15.
- Tesa: 12/12.
- Plataformas/vehículos: 11/11.
- Smoke completo: 768/768.

`arcade_pacing_checks.gd`, `expresbus_checks.gd` y `rebalance_checks.gd` son helpers `RefCounted`, no runners autónomos; sus comprobaciones se ejecutan dentro de `migration_smoke.gd`. Se corrigió una expectativa legacy del test Hipster que aún exigía café de Palermitano a 360 px/s: el contrato vigente, ya validado por el test específico del boss, es 300 px/s. No se modificó el recurso ni el ataque.
