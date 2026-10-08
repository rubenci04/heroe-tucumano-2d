# Inventario de assets — fusión VIEJO + NUEVO

Generado con `tools/audit_assets.gd` (solo lectura) y revisión del código. Rama `codex/prototype-cartoon-polish`.
**NUEVO** = `characters/lote2_cuadros/` (cuadros 320×256, pies en y=240, vía `assets/animations/generated/*.tres`).
**VIEJO** = `assets/` del primer proyecto (cuadros sueltos de distinto tamaño, vía `assets/animations/{player,agente,hipster,grandote,boss,drone}.tres`).

## a) Animaciones existentes

Alto visible = alto de píxeles opacos del primer cuadro. Ciruja: VIEJO ≈ 195–198 px, NUEVO ≈ 173–191 px (idle 191).

### VIEJO (assets/)

| Personaje | Animación | Cuadros | fps | Tamaño cuadro | Alto visible (px) | Ruta |
|---|---|---|---|---|---|---|
| player | Death | 1 | 1 | 200x200 | 197 | assets |
| player | Eat | 1 | 1 | 200x200 | 169 | assets |
| player | Headbutt | 4 | 8 | 200x200 | 197 | assets |
| player | Hit | 1 | 1 | 200x200 | 197 | assets |
| player | Idle | 1 | 1 | 200x200 | 197 | assets |
| player | Jump | 6 | 10 | 200x200 | 198 | assets |
| player | Punch | 7 | 14 | 200x200 | 196 | assets |
| player | Run | 7 | 12 | 200x200 | 195 | assets |
| player | Throw Orange | 7 | 28 | 134x197 | 195 | assets |
| player | Throw Stone | 6 | 24 | 192x210 | 195 | assets |
| player | cabezazo_anim | 4 | 8 | 200x200 | 197 | assets |
| player | correr | 7 | 12 | 200x200 | 195 | assets |
| player | disparar_cascote | 6 | 24 | 192x210 | 195 | assets |
| player | disparar_naranja | 7 | 28 | 134x197 | 195 | assets |
| player | idle | 1 | 1 | 200x200 | 197 | assets |
| player | salto | 6 | 10 | 200x200 | 198 | assets |
| agente | agente_disparar | 5 | 15 | 200x300 | 253 | assets |
| agente | agente_idle | 1 | 1 | 200x300 | 241 | assets |
| agente | agente_punch | 7 | 14 | 200x300 | 241 | assets |
| agente | agente_run | 8 | 12 | 200x300 | 262 | assets |
| hipster | hipster_idle | 1 | 1 | 200x300 | 282 | assets |
| hipster | hipster_lanzar | 8 | 16 | 200x300 | 282 | assets |
| hipster | hipster_run | 5 | 10 | 200x300 | 278 | assets |
| grandote | grandote_ground_slam | 13 | 13 | 200x300 | 276 | assets |
| grandote | grandote_idle | 1 | 1 | 200x300 | 264 | assets |
| grandote | grandote_punch | 7 | 12 | 200x300 | 251 | assets |
| grandote | grandote_run | 8 | 10 | 200x300 | 267 | assets |
| boss | boss_cofee | 6 | 12 | 200x300 | 256 | assets |
| boss | boss_idle | 1 | 1 | 200x300 | 240 | assets |
| boss | boss_joke | 8 | 10 | 300x300 | 273 | assets |
| boss | boss_order | 4 | 8 | 300x300 | 280 | assets |
| boss | boss_punch | 10 | 15 | 300x300 | 285 | assets |
| boss | boss_run | 7 | 12 | 200x300 | 256 | assets |
| drone | aim | 1 | 1 | 150x150 | 98 | assets |
| drone | fire | 1 | 1 | 150x150 | 106 | assets |
| drone | idle | 1 | 1 | 151x151 | 87 | assets |

Notas: `player.tres` repite animaciones con nombre en español (`correr`, `idle`, `salto`, `disparar_naranja`, `disparar_cascote`, `cabezazo_anim`) como alias de las inglesas. `Eat` (`ciruja comiendo.png`) es una escena con mesa, no un cuadro de personaje. Cuadros VIEJOS de Ciruja de lanzar tienen lienzo recortado (134×197, 168×198, 142×199, 192×210…): el pie y el eje horizontal cambian de un cuadro a otro.

### NUEVO (characters/lote2_cuadros/)

| Personaje | Animación | Cuadros | fps | Tamaño cuadro | Alto visible (px) | Ruta |
|---|---|---|---|---|---|---|
| ciruja | ajustar_gorra | 5 | 8 | 320x256 | 191 | characters/lote2_cuadros/ciruja/ajustar_gorra |
| ciruja | correr | 8 | 12 | 320x256 | 173 | characters/lote2_cuadros/ciruja/correr |
| ciruja | embestida | 4 | 10 | 320x256 | 191 | characters/lote2_cuadros/ciruja/embestida |
| ciruja | grito | 4 | 8 | 320x256 | 186 | characters/lote2_cuadros/ciruja/grito |
| ciruja | idle | 8 | 6 | 320x256 | 191 | characters/lote2_cuadros/ciruja/idle |
| ciruja | muerte | 8 | 10 | 320x256 | 188 | characters/lote2_cuadros/ciruja/muerte |
| ciruja | patada | 7 | 12 | 320x256 | 190 | characters/lote2_cuadros/ciruja/patada |
| ciruja | pinazo | 6 | 12 | 320x256 | 180 | characters/lote2_cuadros/ciruja/pinazo |
| agente | agarrar | 6 | 10 | 320x256 | 187 | characters/lote2_cuadros/agente/agarrar |
| agente | correr | 8 | 12 | 320x256 | 181 | characters/lote2_cuadros/agente/correr |
| agente | disparar | 7 | 12 | 320x256 | 183 | characters/lote2_cuadros/agente/disparar |
| agente | muerte | 8 | 10 | 320x256 | 185 | characters/lote2_cuadros/agente/muerte |
| agente | punio | 6 | 12 | 320x256 | 181 | characters/lote2_cuadros/agente/punio |
| hipster | avanzar_idle | 4 | 6 | 320x256 | 191 | characters/lote2_cuadros/hipster/avanzar_idle |
| hipster | caida | 7 | 10 | 384x256 | 187 | characters/lote2_cuadros/hipster/caida |
| hipster | tirar_botella | 7 | 10 | 320x256 | 191 | characters/lote2_cuadros/hipster/tirar_botella |
| hipster | tirar_cafe | 8 | 10 | 320x256 | 191 | characters/lote2_cuadros/hipster/tirar_cafe |
| grandote | correr | 8 | 12 | 320x256 | 180 | characters/lote2_cuadros/grandote/correr |
| grandote | golpe_piso | 7 | 10 | 320x256 | 187 | characters/lote2_cuadros/grandote/golpe_piso |
| grandote | muerte | 9 | 10 | 384x256 | 150 | characters/lote2_cuadros/grandote/muerte |
| grandote | punio | 8 | 12 | 320x256 | 163 | characters/lote2_cuadros/grandote/punio |
| palermitano | correr | 8 | 12 | 320x256 | 181 | characters/lote2_cuadros/palermitano/correr |
| palermitano | derrota | 9 | 10 | 384x256 | 186 | characters/lote2_cuadros/palermitano/derrota |
| palermitano | golpe | 7 | 12 | 320x256 | 185 | characters/lote2_cuadros/palermitano/golpe |
| palermitano | golpe_v2 | 7 | 12 | 320x256 | 183 | characters/lote2_cuadros/palermitano/golpe_v2 |
| palermitano | golpes_recibidos | 7 | 10 | 320x256 | 183 | characters/lote2_cuadros/palermitano/golpes_recibidos |
| palermitano | idle | 4 | 6 | 320x256 | 190 | characters/lote2_cuadros/palermitano/idle |
| palermitano | idle_v2 | 4 | 6 | 320x256 | 191 | characters/lote2_cuadros/palermitano/idle_v2 |
| campeona | forcejeo | 9 | 10 | 320x256 | 193 | characters/lote2_cuadros/campeona/forcejeo |
| campeona | hornear | 14 | 6 | 320x256 | 192 | characters/lote2_cuadros/campeona/hornear |
| campeona | idle | 6 | 4 | 256x256 | 191 | characters/lote2_cuadros/campeona/idle |
| campeona | pose_manos_cintura | 1 | 1 | 320x256 | 196 | characters/lote2_cuadros/campeona/pose_manos_cintura |
| campeona | relajarse_agradecer | 9 | 8 | 320x256 | 190 | characters/lote2_cuadros/campeona/relajarse_agradecer |
| campeona | saludar | 10 | 6 | 256x256 | 191 | characters/lote2_cuadros/campeona/saludar |

### Proyectiles y efectos (solo existen como arte VIEJO)

| Sprite | Tamaño | Uso |
|---|---|---|
| `assets/naranja.png` | 197×187 | proyectil naranja (data/projectiles/orange.tres) |
| `assets/cascote.png` | 198×198 | proyectil piedra (stone.tres) |
| `assets/bala.png` | 190×190 | bala del Agente |
| `assets/cofee.png` | 177×177 | café del Hipster / Palermitano |
| `assets/botella_agua.png` | 139×149 | botella del Hipster |

El paquete NUEVO no trae proyectiles: todos salen del arte VIEJO.

## b) Estados que el código pide hoy

| Personaje | Estados (nombre de animación pedido) | Dónde |
|---|---|---|
| Ciruja | `Idle`, `Run`, `Jump`, `Throw Orange`, `Throw Stone`, `Headbutt` (super/embestida), `Punch`, `Hit`, `Death` | `character_definition.gd`, `player.gd` (~l.265-290, 496, 534, 597) |
| Agente | `agente_run`, `agente_disparar`, `Punch`, `Death` | `data/enemies/agente.tres`, `batch_visuals.enemy_aliases` |
| Hipster | `hipster_run`, `hipster_lanzar`, `Death` | `hipster.tres` |
| Grandote / miniboss | `grandote_run`, `grandote_punch`, `grandote_ground_slam`, `Death` | `grandote.tres`, `miniboss_grandote.gd` |
| Palermitano (jefe) | `boss_run`, `boss_idle`, `boss_punch`, `boss_cofee`, `boss_joke`, `boss_order`, `idle_v2`, `golpe_v2` (rugido), `golpes_recibidos`, `Death` | `palermitano_boss.gd`, `boss_director.gd`, `batch_visuals.boss_aliases` |
| Campeona (NPC) | `idle`, `saludar`, `forcejeo`, `hornear`, `relajarse_agradecer` | cinemáticas (`attach_npc`) |
| Drone | `idle`, `aim`, `fire` | solo arte VIEJO (no hay paquete nuevo) |

No existe en el código un estado de agacharse.

## c) Cobertura estado × personaje — ANTES de este cambio

| Personaje | Estado | Origen hoy | Observación |
|---|---|---|---|
| Ciruja | Idle | NUEVO (`idle`, 8 cuadros) | |
| Ciruja | Run | NUEVO (`correr`) | |
| Ciruja | Punch | NUEVO (`pinazo`) | |
| Ciruja | Headbutt | NUEVO (`embestida`) | |
| Ciruja | Death | NUEVO (`muerte`) | |
| Ciruja | Throw Orange | **FALLBACK SILENCIOSO → `idle`** | existe VIEJO (`ciruja_disparo_naranja0-6`, 7 cuadros) y estaba bloqueado por alias |
| Ciruja | Throw Stone | **FALLBACK SILENCIOSO → `idle`** | existe VIEJO (`ciruja_disparo_cascote0-5`, 6 cuadros) |
| Ciruja | Jump | VIEJO sin normalizar | solo ancla los pies; sin ajuste de altura ni eje horizontal |
| Ciruja | Hit | VIEJO sin normalizar | 1 cuadro |
| Agente | run / disparar / Punch / Death | NUEVO | |
| Hipster | run / lanzar / Death | NUEVO (`avanzar_idle`, `tirar_cafe`, `caida`) | |
| Grandote | run / punch / ground_slam / Death | NUEVO | |
| Palermitano | boss_run / idle / Death / golpes | NUEVO | |
| Palermitano | boss_punch | **fallback → `idle`** (`BOSS_CHAIN_ANIMATED=false`, decisión previa) | existe `golpe_v2` |
| Palermitano | boss_joke, boss_order | fallback → `idle_v2` | sin animación propia nueva |
| Palermitano | boss_cofee | VIEJO sin normalizar | no hay café nuevo |
| Drone | idle / aim / fire | VIEJO (único) | |

## d) Carpetas y archivos duplicados

Hay **un solo `project.godot`** (`godot-version/`); no existe un `godot-version` anidado ni una segunda copia de `characters/`. Lo que sí hay:

| Hallazgo | Estado | Acción |
|---|---|---|
| `characters/lote2_cuadros/ciruja/ciruja/idle/` (8 PNG + .import) | **idéntica byte a byte** a `ciruja/idle/`; nada en `res://` la referencia | mover a `_archivo/` |
| `characters/lote2_cuadros/paquete_unico_cuadros.zip` (18 MB, sin versionar) | los 293 cuadros son idénticos a los extraídos; solo `meta.json` difiere (el extraído es más nuevo) | mover a `_archivo/` |
| `assets/` en la raíz (102 PNG, versión HTML/Phaser) | 3 idénticos a `godot-version/assets/`, 69 con el mismo nombre pero **contenido distinto**, 30 solo en la raíz | **no se mueve**: `AGENTS.md` lo protege y `index.html` lo carga |
| `godot-version/assets/ciruja_run{0-5} - copia.png` | difieren de `ciruja_run{0-5}.png`; figuran en `validation/asset_baseline_v2.json` | pendiente de decisión |
| `assets/fusion_fondos - copia.png`, `juntar_cascote5 - copia.png`, `fondo_cerros - copia`, `suelo_ruta - copia` (raíz) | copias con contenido distinto | pendiente (raíz protegida) |
| `godot-version/assets/campeona empanadas.png` → `campeona_empanadas.png` | renombre en curso del usuario (sin commitear) | no se toca |
| ~45 `.png.import` sin PNG en `godot-version/assets/` (p. ej. `bus1-4`, `hipster_run1-3`, `juntar_*`) | huérfanos inofensivos (Godot los ignora) | pendiente |
| `validation/*.log` baseline/final idénticos | salidas de tests, no assets | no se tocan |

Lo que el proyecto carga realmente: `res://` = `godot-version/`; personajes NUEVOS por `res://characters/lote2_cuadros/**` (a través de `assets/animations/generated/*.tres`) y VIEJOS por `res://assets/*.png`.
