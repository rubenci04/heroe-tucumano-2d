# Asset Rebuild Audit

Fecha de auditoría: 2026-09-16. Alcance: inventario de solo lectura de `assets/`, `godot-version/assets/` y `godot-version/art_v2/`, más las referencias runtime del proyecto Godot. No se modificaron assets, escenas, scripts ni SpriteFrames.

> Estado posterior (misma fecha): esta evidencia conserva el baseline previo. Las referencias rotas de Drone, `fusion_fondos.png` y Grandote fueron corregidas después; las cinco familias prioritarias se integraron mediante `ANIMATION_CANONICAL_MANIFEST.md`. Los PNG originales auditados no se borraron ni editaron durante la reconstrucción.

## Resumen

- Archivos raster PNG auditados: **331**: 102 en `assets/` (legacy raíz), 201 en `godot-version/assets/` (proyecto activo) y 28 en `godot-version/art_v2/` (workbench/arte reservado).
- El conjunto activo renovado se reconoce por las secuencias 200x300 y por sus conteos mayores. La raíz contiene el set legacy mayoritariamente 200x200.
- Secuencias de personaje nuevas o ampliadas detectadas: **22** (Ciruja 8, Agente 3, Hipster 3, Grandote 3, Palermitano 5; algunas son variantes de una misma familia). No hay una secuencia nueva verificable para Drone ni animación jugable de Campeona.
- Formato dominante: PNG RGBA de 32 bits. Excepciones relevantes: `fondo_cerros.png`, `suelo_ruta.png`, `suelo_ruta2.png`, `final_boss_joke8.png` y `final_boss_joke10.png` son RGB de 24 bits.

## Convención usada

“Nuevo” significa presente en `godot-version/assets/` y diferente del set legacy de la raíz por nombre, dimensión, cantidad o disponibilidad. El orden probable es numérico ascendente; un prefijo sin número se considera pose inicial cuando existe. “Canvas consistente” se refiere a dimensiones de archivo, no al pivote visual interno.

## Personajes y secuencias disponibles

| Personaje | Acción / nombres exactos | Frames y orden probable | Canvas / color | ¿Consistente? | Huecos | Lectura runtime |
|---|---|---:|---|---|---|---|
| CIRUJA | `ciruja_idle.png` | 1 | 200x200 RGBA | Sí | — | Reemplaza `Idle` actual (1), aunque es visualmente distinto del set nuevo 200x300 de enemigos. |
| CIRUJA | `ciruja_run0.png`…`ciruja_run6.png` | 7, 0→6 | mixto: 143x195, 158x198 y 200x200 RGBA | **No** | No | Candidato de reemplazo para `Run` (5 runtime). Hay además `ciruja_run0 - copia.png`…`ciruja_run5 - copia.png` (6, 186–200x216), material alternativo/no clasificado. |
| CIRUJA | `ciruja_salto.png`, `ciruja_salto1.png`…`ciruja_salto5.png` | 6, sin número→1→5 | 200x200 RGBA | Sí | No | Amplía/reemplaza `Jump` (4 runtime). No se separó `Fall`. |
| CIRUJA | `ciruja_punch0.png`…`ciruja_punch6.png` | 7, 0→6 | 200x200 RGBA | Sí | No | Melee nuevo no conectado; no existe animación melee runtime dedicada. |
| CIRUJA | `ciruja_cabezazo0.png`…`ciruja_cabezazo3.png` | 4, 0→3 | 200x200 RGBA | Sí | No | Amplía `Headbutt`/`cabezazo_anim` (3 runtime). |
| CIRUJA | `ciruja_disparo_naranja0.png`…`ciruja_disparo_naranja6.png` | 7, 0→6 | 134–200 x 195–200 RGBA | **No** | No | Amplía `Throw Orange` (6 runtime); requiere normalización de canvas/pivote antes de adoptar. |
| CIRUJA | `ciruja_disparo_cascote0.png`…`ciruja_disparo_cascote5.png` | 6, 0→5 | 122–192 x 199–211 RGBA | **No** | No | Amplía `Throw Stone` (5 runtime); requiere normalización de canvas/pivote. |
| CIRUJA | `ciruja comiendo.png` | 1 | 200x200 RGBA | Sí | — | Acción nueva no documentada; probable recoger/consumir, no enlazada. |
| DECA | No se encontraron nombres/recursos de personaje DECA. | 0 | — | — | — | No aplicable. |
| AGENTE | `agente_idle.png` | 1 | 200x300 RGBA | Sí | — | Idle nuevo; el runtime no declara idle para este enemigo. |
| AGENTE | `agente_run0.png`…`agente_run7.png` | 8, 0→7 | 200x300 RGBA | Sí | No | Reemplazo de `agente_run` (3 runtime). Duplicados binarios: 0=5, 1=6, 2=7. |
| AGENTE | `agente_punch1.png`…`agente_punch7.png` | 7, 1→7 | 200x300 RGBA | Sí | No | Melee nuevo no conectado. |
| AGENTE | `agente_disparo_bala1.png`…`agente_disparo_bala5.png` | 5, 1→5 | 200x300 RGBA | Sí | No | Amplía `agente_disparar` (2 runtime). |
| AGENTE | `agente_salto.png` solo existe en la raíz legacy | 1 | 200x200 RGBA | Sí | — | La referencia runtime a ese nombre queda ausente del proyecto activo, pero no se usa por la definición actual. |
| HIPSTER | `hipster_scooter_idle.png` | 1 | 200x300 RGBA | Sí | — | Nuevo idle de variante scooter. |
| HIPSTER | `hipster_scooter0.png`…`hipster_scooter4.png` | 5, 0→4 | 200x300 RGBA | Sí | No | Nueva locomoción scooter; probable sustituto conceptual de `hipster_run` (3 runtime), no conexión literal. |
| HIPSTER | `hipster_scooter_disparocafe1.png`…`hipster_scooter_disparocafe8.png` | 8, 1→8 | 200x300 RGBA | Sí | No | Ataque direccional/de café nuevo, candidato para `hipster_lanzar` (2 runtime). Frame 1 duplica `hipster_scooter_idle.png`. |
| GRANDOTE | `grandote_idle.png` | 1 | 200x300 RGBA | Sí | — | Idle nuevo no conectado. |
| GRANDOTE | `grandote_run1.png`…`grandote_run8.png` | 8, 1→8 | 200x300 RGBA | Sí | No | Amplía `grandote_run` (2 runtime); 1=7 por hash. |
| GRANDOTE | `grandote_punch1.png`…`grandote_punch7.png` | 7, 1→7 | 200x300 RGBA | Sí | No | Amplía `grandote_punch` (3 runtime); 1=7 por hash. |
| GRANDOTE | `grandote_smash1.png`…`grandote_smash13.png` | 13, 1→13 | 200x300 RGBA | Sí | No | Ataque especial probable / candidato a `grandote_ground_slam` (3 runtime). 2=13 por hash. |
| DRONE | `drone_1.png`, `drone_2.png`, `drone_3.png` | 3 individuales: idle, aim, fire | 151x151; 150x150; 150x150 RGBA | **No** | — | Runtime ya los usa como 1 frame por animación. No hay renovación/expansión detectada. |
| PALERMITANO | `final_boss_idle.png` | 1 | 200x300 RGBA | Sí | — | Idle nuevo no conectado. |
| PALERMITANO | `final_boss_run1.png`…`final_boss_run7.png` | 7, 1→7 | 200x300 RGBA | Sí | No | Amplía `boss_run` (3 runtime). |
| PALERMITANO | `final_punch1.png`…`final_punch10.png` | 10, 1→10 | 300x300 RGBA | Sí | No | Sustituto probable de `boss_punch` (2 runtime); 3=6 y 2=7 por hash. |
| PALERMITANO | `final_boss_cofee1.png`…`final_boss_cofee6.png` | 6, 1→6 | frame 1: 200x300; 2–6: 300x300 RGBA | **No** | No | Amplía `boss_cofee` (2 runtime); exige canvas/pivote uniforme. |
| PALERMITANO | `final_boss_joke1.png`…`final_boss_joke10.png` | 10, 1→10 | 300x300; 8 y 10 RGB, resto RGBA | Dimensión sí; modo no | No | Amplía `boss_joke` (2 runtime). Hash: 7=9, 8=10. |
| PALERMITANO | `final_orden_ataque1.png`…`final_orden_ataque4.png` | 4, 1→4 | 300x300 RGBA | Sí | No | Nueva acción no documentada; posible orden/summon. |
| CAMPEONA | `campeona empanadas.png`; `secuestro_campeona.png` | 1 + 1 | 200x200 RGBA | Sí | — | Assets narrativos estáticos, usados por la cinemática; no se detectó secuencia de acción nueva. |

No se encontraron assets explícitos de Walk, Fall, Hurt o Death para los conjuntos renovados. La ausencia es deliberadamente reportada; no se infiere que deba reciclarse Idle.

## Comparación runtime actual

| Animación runtime actual | Assets nuevos disponibles | Cantidad antigua runtime | Cantidad nueva | Acción recomendada |
|---|---|---:|---:|---|
| Player `Idle` | `ciruja_idle` | 1 | 1 | Mantener por ahora; revisar origen/pivote con el resto antes de migrar. |
| Player `Run` | `ciruja_run0..6` | 5 | 7 | Preparar mapeo nuevo después de normalizar canvas. |
| Player `Jump` | `ciruja_salto`, `salto1..5` | 4 | 6 | Separar salto/caída en una decisión posterior. |
| Player `Throw Orange` | `ciruja_disparo_naranja0..6` | 6 | 7 | No conectar hasta resolver canvas heterogéneo. |
| Player `Throw Stone` | `ciruja_disparo_cascote0..5` | 5 | 6 | No conectar hasta resolver canvas heterogéneo. |
| Player `Headbutt` | `ciruja_cabezazo0..3` | 3 | 4 | Candidato directo, pendiente de timing de hitbox. |
| Player `Hit` / `Death` | Ninguno verificable | 1 / 1 | 0 | Conservar placeholders; solicitar arte. |
| Agente `agente_run` | `agente_run0..7` | 3 | 8 | Migración futura; retirar duplicados sólo con autorización posterior. |
| Agente `agente_disparar` | `agente_disparo_bala1..5` | 2 | 5 | Migración futura, revisar timing de proyectil. |
| Hipster `hipster_run` | `hipster_scooter0..4` | 3 (archivos legacy ausentes del proyecto) | 5 | Crear decisión de arquetipo scooter antes de mapear. |
| Hipster `hipster_lanzar` | `hipster_scooter_disparocafe1..8` | 2 (ausentes) | 8 | Crear decisión de proyectil café/dirección antes de mapear. |
| Grandote `grandote_run` | `grandote_run1..8` | 2 | 8 | Migración futura; SpriteFrames actual conserva UIDs inválidos de otros frames. |
| Grandote `grandote_punch` | `grandote_punch1..7` | 3 | 7 | Migración futura, sincronizando ventanas de daño. |
| Grandote `grandote_ground_slam` | `grandote_smash1..13` | 3 | 13 | Validar equivalencia artística/funcional antes de declarar reemplazo. |
| Drone `idle`/`aim`/`fire` | mismos tres PNG | 1 / 1 / 1 | 1 / 1 / 1 | No cambio de frames; corregir baseline de dimensiones sólo en una tarea autorizada. |
| Boss `boss_run` | `final_boss_run1..7` | 3 | 7 | Migración futura. |
| Boss `boss_punch` | `final_punch1..10` | 2 | 10 | Candidato probable, validar nomenclatura. |
| Boss `boss_joke` | `final_boss_joke1..10` | 2 | 10 | Migración futura; homogeneizar RGB/RGBA si es necesario. |
| Boss `boss_cofee` | `final_boss_cofee1..6` | 2 | 6 | Migración futura; corregir canvas heterogéneo antes. |

### Runtime inspeccionado

- SpriteFrames: `assets/animations/player.tres`, `agente.tres`, `hipster.tres`, `grandote.tres`, `drone.tres`, `boss.tres` y `asset_library.tres`.
- Escenas: `scenes/actors/player.tscn`, `enemy.tscn`, `drone.tscn`, `miniboss_grandote.tscn`, `palermitano_boss.tscn`, `scenes/levels/route_38*.tscn` y cinemática.
- Los visuales runtime son principalmente `AnimatedSprite2D`; la introducción usa `AnimationPlayer`.
- Referencias PNG rotas o heredadas: `hipster_*`, `agente_salto`, `grandote_salto`, `grandote_golpe_suelo*`, `final_boss_punch*`, `final_boss_salto*`, `juntar_*` y `fusion_fondos.png` son solicitadas por recursos/galería, pero no están en `godot-version/assets/`. Muchos sobreviven sólo en `assets/` de la raíz, fuera de `res://`.

## Props y entorno disponibles en `godot-version/assets/`

Las categorías son una clasificación propuesta de producción, no una modificación runtime.

| Clasificación | Assets |
|---|---|
| BACKGROUND | `fondo_cerros.png`, `fondo_cerros - copia.png`, `fondo_arboleda.png`, `fusion_fondosanime.png`, `acheral.png`, `ingenio.png`, `leon_rouges.png`, `monteros.png`, `villa_quinteros.png`, `rio_seco.png`, `puente.png`, `sol.png` |
| MIDGROUND | `cañas.png`, `cañas_solas.png`, `arbol_comun.png`, `arbol_naranjas.png`, `palmera.png`, `gruta_virgen.png`, `montaña_cascote.png` |
| ROADSIDE PROP | `casa1.png`, `casa2.png`, `poste_luz.png`, `pilar_cableado.png`, `pilar_cableado2.png`, `semaforo1.png`, `semaforo2.png`, `parada_colectivo.png`, `parada_colectivo2.png`, `kiosco_coca.png`, `kiosco_coca2.png`, `cartel_famailla.png` |
| PLATFORM (candidato) | `auto1.png`, `auto2.png`, `auto3.png`, `parada_colectivo2.png`, `puente.png` |
| VEHICLE | `auto1.png`, `auto2.png`, `auto3.png`, `exprebus.png`, `tesa.png` |
| PICKUP | `empanada.png`, `achilata.png`, `sanguche.png`; además existentes `naranja.png`, `cascote.png`, `botella_agua.png` |
| GAMEPLAY PROP (candidato) | `suelo_ruta.png`, `suelo_ruta2.png`, `suelo_ruta - copia.png`, `suelo_ruta2copia.png` |
| UNUSED/UNKNOWN | `campeona empanadas.png`, `secuestro_campeona.png` (narrativos, no props ambientales) |

Los props individuales nuevos más relevantes para la reestructuración son: casas, árbol común, cañas solas, ambos pilares de cableado, ambos semáforos, segunda parada, segundo kiosco, los tres autos, Tesa, Expresbus y los tres pickups futuros.

## `art_v2` reservado

Hay 28 PNG existentes bajo `art_v2`, todos del workbench de Ciruja: master/cutout, hoja de idle 2172x724, rig test `run_poc_00..07`, poses y 14 partes de rig. No se los considera secuencias runtime listas: tienen tamaños heterogéneos y el directorio continúa reservado según la regla del proyecto.

## Inconsistencias y riesgos detectados

1. Hay canvas heterogéneo en `ciruja_run`, ambos disparos de Ciruja y `final_boss_cofee`; cambiar SpriteFrames sin pivotes/offsets por animación produciría saltos visuales y colliders desalineados.
2. Hay duplicados binarios dentro del set activo (Agente, Grandote, Palermitano, suelo) y copias con nombre libre. Se documentan, pero no se eliminan ni renombran.
3. `grandote.tres` conserva UIDs que Godot reporta inválidos para assets ausentes `grandote_salto` y `grandote_golpe_suelo*`.
4. El Hipster runtime sigue referenciando un set legacy que no existe dentro de `res://assets`; los nuevos assets son una variante scooter con nombres y acción distintos.
5. `asset_library.tres` referencia `res://assets/fusion_fondos.png`, inexistente; el asset nuevo disponible se llama `fusion_fondosanime.png` y no debe sustituirse durante esta auditoría.
6. El test espera tres drones exactamente 150x150, pero `drone_1.png` es 151x151.

## Smoke baseline

Comando ejecutado: Godot 4.7.2 headless con `tests/migration_smoke.gd`.

- Resultado: **falló**; 640/642 checks aprobaron.
- Fallos: dimensión de los PNG del drone; carga/importación de `fusion_fondos.png` inexistente.
- Warnings adicionales: root certificate store de Windows; UIDs inválidos en `grandote.tres` con fallback por path.
- Log: `validation/audit_smoke_baseline.log` (generado como evidencia del baseline; no se modificó runtime).
