# Auditoría READ-ONLY — Tucumán Rush (2026-10-01)

Método: árbol + búsquedas + muestra (Ciruja run2, Hipster scooter2, suelo_ruta, manifests). No se ejecutó Godot (no está en PATH); los resultados de tests son los JSON de `validation/`, no una corrida nueva. Estimaciones de % = criterio de auditor, no métrica.

## 1. Árbol resumido y estado

```
tuco_hero2d/                      (git: raíz + godot-version SIN trackear en gran parte)
├─ INFORME DE HANDOFF.docx
├─ AGENTS.md, .gitignore          (marcados D en git status: borrados del working tree, siguen en HEAD)
├─ assets/ (raíz, ~100 PNG)       LEGACY: Phaser original. Borrados del working tree (145 "D"); viven copiados en godot-version/assets
└─ godot-version/                 ← ACTIVO (69 MB; .godot 35 MB ignorado)
   ├─ project.godot  800×450, canvas_items, GL Compatibility, filtro nearest
   ├─ scripts/ actors(14) core(8) components(6) data(6) level(6) dialogue cinematics ui tools(*.cjs)
   ├─ scenes/ actors, components, levels(route_38 + data.json), cinematics, main.tscn
   ├─ data/ enemies(5) projectiles(8) attacks(10) characters(2) dialogues(3)
   ├─ assets/ 194 PNG + animations/*.tres (SpriteFrames) + asset_manifest.json  (+ ~237 .import)
   ├─ art_v2/ solo Ciruja: master, 1 idle sheet, workbench (28 partes cutout, rig_test) — experimento, no integrado
   ├─ tests/ 36 scripts (migration_smoke 1758 líneas) · validation/ 24 JSON · docs/ 28 .md · dev/ visual_lab
   └─ export_templates/ feature_profiles/ text_editor_themes/ shaders/ tilesets/  → vacíos o solo README (muertos)
```

**Activo:** `main.tscn → Route38`, player/enemy/drone/boss/miniboss/vehicle/projectile/pickup, `EncounterDirector`, `TrafficDirector`, `ExpresbusSetPiece`, components, data `.tres`, HUD, dialogue, intro, `route_38_data.json`.
**Legacy/duplicado:**
- `assets/` raíz + `index.html/main.js/*.js` Phaser (AGENTS.md: referencia, no tocar; `main.js` figuraba en conflicto `UU`, ahora el working tree no los tiene).
- `ciruja_run{0..4} - copia.png` (5 duplicados con nombre "copia"), animaciones duplicadas en `player.tres` (alias `correr/idle/salto/...` + `Idle/Run/Jump/...`, 0 AtlasTexture, 1 ext_resource por frame).
- Capa física 2 "Carril legacy (sin uso)"; `GameConfig.LANES=[370,370]` (carriles colapsados) pero `lane_index`, `LANE_DURATION`, `lane_up/down`, `LANE_SYSTEM_AUDIT.md` (describe 2 carriles de 45 px) siguen → **doc obsoleto, código con cadáver**.
- Sistema de calor (suspendido, `HEAT_ENABLED=false`), achilata, Atletico (`selectable=false`, sin arte), `Hit/Death/Fall` sin arte (placeholder Idle/Jump).
- Muchos docs de auditoría superpuestos (28 .md); `migration_report.md` 419 líneas (de la migración Phaser→Godot).
- Pipeline `scripts/tools/*.cjs` requiere Node y el HTML padre (ya no está) → no ejecutable hoy.
**Riesgo de repo:** `godot-version/` y casi todo está sin commitear; el último commit refiere a la estructura vieja. Hacer commit/tag antes de cualquier cambio.

## 2. Handoff vs repo

| Punto | Estado |
|---|---|
| Godot 4.7.2, 800×450 | Confirmado |
| Ruta del proyecto | Confirmado |
| Hipster: café 115 px/s, cd 4.5, 2 HP | Confirmado (`move_speed` 55) |
| Agente: 3 HP, cd 3.2, orb 170 px/s, collider 10×10 | Confirmado |
| Grandote 6 HP, 45 px/s, slam 13 frames, impacto f10 | Confirmado |
| Drone 3 HP, cd 2.8, aim 0.70, relevo 0.75 | Confirmado (bolt 175 sin verificar línea a línea) |
| Boss 90 HP | Confirmado |
| Punch 78 px, 2 daño, 14 fps | Confirmado |
| Calor suspendido | Confirmado (flag + código vivo) |
| Triggers 450…6800; drones 4100/6100 | Confirmado (13 encuentros; Tesa 4400 y expresbus 2850 son set pieces aparte, no en el JSON) |
| Expresbus 240 px/s, mín 55 % | Confirmado (BASE_SPEED 240, `minimum_speed_multiplier` 0.55); Tesa 225 no verificado |
| Fondo 8000×1024 | Confirmado; suelo `suelo_ruta.png` **330×108** (handoff: 330×54) → cambió |
| Animaciones Ciruja: Run 7, Jump 6, Orange 7, Stone 6, Headbutt 4, Punch 7 | Confirmado (`animation_manifest.json`) |
| Hit/Death "fallbacks" | Confirmado: no hay arte |
| Tests 768 | Cambió: **771 checks, 0 errores**; integridad 194 assets OK; route_progression 15 |
| Carriles | **No mencionado en handoff**: el código ya está en un único plano (370) |
| Estructura de carpetas | Confirmado y ampliada (components/, data/, ui/, art_v2/) |
| Hipster 1.16×, Agente 1.05×, Grandote 1.40× Ciruja | Necesita inspección (visual_scale 0.34/0.36/0.372 vs Ciruja 0.42; lienzo 300 vs 200 px) |

## 3. Gameplay: conservar vs simplificar

**Conservar tal cual (alto valor, probado):** `EncounterDirector` (tokens, regla offscreen, presupuesto de proyectiles), `HealthComponent`/`Hitbox`/`Hurtbox`, `ProjectileDefinition` + `projectile.gd` (barrido anti-tunneling), vehículos-plataforma con capas one-way y slowdown, `route_38_data.json` + checkpoints/restore, enemy AI por datos (`EnemyDefinition`), drone (aim→lock→fire), boss, `GameSession`, diálogos, HUD por señales, toda la suite de tests.
**Simplificar/quitar:** carriles (código muerto en player/enemy/proyectiles), calor, Atletico, alias duplicados de animación, `AnimationOffsetProfile` (los offsets por frame existen **porque los frames IA no están alineados** — con arte nuevo se elimina), hit-stop del Tucumanazo (única pieza de game feel), `player.gd` (788 líneas, mezcla input, anim, melee, tokens), `main.gd`/`route_38.gd` (447/618), Tucumanazo/combo/furia si no entran en el prototipo.
**Faltante (no existe):** capa de game-feel: 0 partículas, shake solo en 3 archivos (`main.gd` 24 coincidencias incl. flash/modulate), sin muzzle flash, polvo, impactos, muerte animada, destrucción.

## 4. Animaciones

| Actor | Frames | Canvas | Observación |
|---|---|---|---|
| Ciruja | Idle 1, Run 7, Jump 6, Orange 7, Stone 6, Headbutt 4, Punch 7, Eat 1 | 200×200 pero **varios 122–192 × 195–211** (run2 143×195, run4 158×198, cascote 3–5 ≈ 122–139) | Tamaños irregulares → el recorte hace "saltar" al sprite; los pies varían 192–199 px |
| Hipster | Idle 1, Ride 5, Shoot 8 | 200×300 | 10 fps en Ride |
| Agente | Idle 1, Run 8, Shoot 5, Punch 7 | 200×300 | bounds hasta x 0..199: sprites tocan el borde (recortados) |
| Grandote | Run 8, Punch 7, Slam 13 | 200×300 | offsets Y de 0 a 44 px: el pie "baila" |
| Boss | 6–10 frames por acción | 200×300 / 300×300 | joke8/10 excluidos por ser basura |

**Pivots:** no hay pivot real; se compensa con `frame_offsets` (±44 px) calculados desde puntos de suelo por frame (`ground_anchor`). Es un parche que lo evidencia: los frames no comparten línea de suelo ni centro.
**Por qué no se siente arcade:** (1) Hit y Death inexistentes (fallbacks Idle/Jump); (2) idle de 1 frame → estatua; (3) ciclos de 5–8 frames dibujados de forma independiente por IA, sin consistencia de anatomía/rostro entre frames; (4) sin anticipación/follow-through ni squash/stretch; (5) fps bajos (10–12 en run) y sin timing por frame (todos los frames duran igual); (6) ni enemigos reaccionando al impacto ni partículas; (7) movimiento: velocidades constantes sin ease, hitboxes más pequeñas que sprite sin feedback visual; (8) cada actor escalado distinto (0.34–0.55) → texel density inconsistente.

## 5. Estado artístico de los PNG

Muestra: Ciruja y Hipster son ilustración vectorial/cartoon suave con contorno grueso y degradados; no pixel art (confirmado, ~0 %). Suelo: textura pintada con parches de pasto. Fondo: panorama 8000×1024 de 2,4 MB en otra dirección.
- **Reemplazar:** todo personaje (Ciruja, Hipster, Agente primero), FX (inexistentes), suelo, fondo.
- **Mantener temporalmente como placeholder/referencia:** Grandote, boss, drone, props, vehículos (auto1 189×85, bus, camión), HUD/retratos.
- **Aprovechable como referencia de diseño:** siluetas, paleta y accesorios (gorra roja, lentes, cicatriz).
- `art_v2/ciruja/workbench` (cutout de partes + rig test) es un camino distinto (rig recortado de arte IA): útil solo como estudio, **no** como base de pixel art.

## 6. Godot vs Three.js

**Recomendación: A+B — conservar Godot y rehacer presentación.** Evidencia:
- 36 tests y 771 checks verdes y toda la lógica (tokens, offscreen, plataformas one-way, restore) está en GDScript tipado y data-driven; migrarla a Three.js es reescribir ~7,5 k líneas de gameplay y 2,6 k de tests sin ganar nada visual.
- El repo ya hizo el viaje inverso: Phaser/JS → Godot (`migration_report.md`) y existe otro intento `tucuman_rush_3d` junto a este; el patrón histórico es reiniciar plataformas.
- Pixel art nítido depende de assets y viewport; Godot ya trae `texture_filter=0` (nearest), AnimatedSprite2D, partículas 2D, shaders, hitstop/cámara y export web.
- Three.js solo ganaría en distribución web nativa; Godot 4 exporta Web. No hay requisito 3D.
Revisar Three.js solo si el requisito pasa a ser web ligero (<10 MB).

## 7. Plan del prototipo "arena 10–20 s"

Nueva escena `scenes/prototype/arena_v2.tscn` (sin tocar `route_38`), un solo plano, 1 pantalla de cámara fija.
1. **Datos/arte** (nuevo, `art_v2/`): sprite sheets con **celdas fijas** (p. ej. 64×64 humanos, 80×64 scooter) y pivote común en el centro-bajo; Ciruja: idle 4, run 8, jump 4, shoot 3, punch 4, hurt 2, death 6; Hipster: ride 6, throw 5, hurt 2, death 5; Agente: run 6, aim 2, shoot 3, hurt 2, death 5; FX: muzzle, impacto naranja, orbe, spark, polvo, mini-explosión; escenario: tile de ruta, césped, naranjo, poste, auto, casa.
2. **Escena:** reutilizar `player`, `enemy`, `projectile`, `hitbox/hurtbox`, `health_component`, `vehicle` con `SpriteFrames` nuevos (sin `AnimationOffsetProfile`).
3. **Guion de 15 s:** 0–2 s Ciruja entra · 2–5 Hipster en scooter, lanza café · 5–9 Agente, telegraph + orbe · 8–12 el auto cruza y sirve de plataforma/cobertura · 12–15 muerte de ambos con FX. Spawns por `EncounterDirector` con un JSON propio.
4. **Game feel:** hit-flash (shader), hit-stop 3–4 frames, shake 2 px, retroceso de arma, muzzle flash, spark, polvo en pasos/aterrizaje, muerte de 5–6 frames + parpadeo.
5. **Aceptación:** captura/GIF de 15 s; tests existentes siguen verdes.
Costo: arte ~70 % del esfuerzo; código ~2–4 días de trabajo.

## 8. 800×450 vs 400×225 ×2

- Hoy `viewport 800×450`, sprites 84–110 px de alto en pantalla: demasiado grandes para pixel art "Metal Slug" (allí el protagonista ocupa ~16–20 % del alto = 70–90 px a 450p… pero dibujado a mitad de resolución y escalado).
- **A) 800×450 + pixel-perfect:** cero cambios de física/colisión/cámara, coordenadas actuales (370, 78 px, 8000 px, 800 de ancho) intactas; más píxeles por sprite → más trabajo y más fácil de inconsistir; pixel art a escala 1:1.
- **B) 400×225 interno ×2:** el mundo pasa a la mitad: hay que dividir por 2 (o escalar el nodo mundo ×0.5) velocidades, gravedad, alturas, rangos (punch 78→39), triggers x del JSON, `GROUND_Y`, hitboxes y todos los tests con valores absolutos. Ventajas: arte 4× más barato (64–72 px de alto por humano), estilo pixel genuino, un frame por celda cuesta mucho menos, y se mantiene el mismo FOV si se escala el mundo, no la cámara.
- **Recomendación para este repo:** prototipar en **B con `Camera2D.zoom = 2` / `stretch/mode=viewport` y sub-viewport**, dejando 800×450 como ventana: usar `canvas_items` con `window 800×450` y escena del prototipo en un `SubViewport 400×225` evita tocar el juego actual. Si el resultado convence, migrar el mundo (escala ×0.5) en una pasada de datos. Costo B de migración: **medio**; tests con constantes hay que reparametrizar (`GameConfig` central ayuda).

## 9. Reutilización aproximada

| Área | % reutilizable |
|---|---|
| Código gameplay (director, combate, componentes, vehículos, boss) | ~75 % (más refactor de `player.gd`/`main.gd`) |
| Datos (`.tres`, JSON de ruta, definiciones) | ~85 % (escalas y offsets cambian) |
| Tests | ~65 % (algunos acoplados a pixeles/offsets/carriles; 771 checks) |
| Assets gráficos | ~5–10 % (solo referencia y placeholders) |
| Animaciones/SpriteFrames | ~10 % (estructura de nombres y manifest sí, frames no) |
| Audio (11 wav) | ~70 % |

## 10. Roadmap

| Fase | Contenido | Costo |
|---|---|---|
| 0 | Commit/tag del estado actual; limpiar `.gitignore`/duplicados "copia"; confirmar corrida de tests en Godot | Bajo |
| 1 | Guía de estilo pixel (paleta, celda, resolución, outline) + decisión 800 vs 400 con 2 capturas | Bajo |
| 2 | Arena prototipo: Ciruja + Hipster + Agente + auto + FX + game feel (sección 7) | Medio–Alto (arte) |
| 3 | Limpieza de código muerto (carriles, calor, offset profile) y partir `player.gd` | Medio |
| 4 | Reemplazar arte de enemigos restantes (Grandote, Drone, boss) y fondo/suelo | Alto |
| 5 | Capa game feel global (partículas, hit-stop, shake, destrucción de props, muerte) + audio | Medio |
| 6 | Re-balance de ritmo (cambios de mecánica cada 15–25 s) y spawn diegético | Medio |
| 7 | Contenido nuevo (nivel 2, armas, montura) | Alto |

**Decisión recomendada:** continuar en Godot; la prueba de éxito es la arena de la fase 2; no migrar a Three.js.
