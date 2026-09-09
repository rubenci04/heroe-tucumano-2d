# PROJECT HANDOFF — Tucumán Rush

Fecha de corte: 2026-09-06. Este documento describe el estado inspeccionado después de las 22 tareas del vertical slice; no es una autorización para integrar arte ni ampliar la campaña.

## Estado actual

`godot-version/` es el proyecto Godot 4 activo, ejecutable en Godot **4.7.2 stable** con renderer **OpenGL/Compatibility**, resolución interna **800×450** y `main.tscn` como escena inicial. El vertical slice técnico está **READY para fase artística y pulido visual**: el flujo completo funciona y las validaciones están en verde. La campaña completa no está implementada.

El repositorio está deliberadamente sucio: `godot-version/` y `AGENTS.md` aún figuran como no rastreados y `main.js` de la versión HTML/Phaser raíz figura `UU` (conflicto anterior). No resolver, añadir ni mezclar ese conflicto al trabajar en Godot sin una tarea explícita. La versión raíz HTML/Phaser (`index.html`, `main.js`, `server.ps1`, `assets/`) es referencia y no debe tocarse para tareas Godot.

## Arquitectura relevante

```text
project.godot
  autoload: GameSession + AudioManager
  main.tscn / main.gd
    Route38 (route_38.tscn / route_38.gd)
      Environment, Terrain, Objects, Vehicles, Enemies, Projectiles
      EncounterDirector + TrafficDirector + Checkpoint + Player
    Camera2D
    HUD, CharacterSelect, DialogueBox, AssetGallery, IntroFamailla
```

- `main.gd` orquesta el flujo, cámara, pausa, diálogo, respawn, cierre y resultado; no concentra reglas de combate.
- `GameSession` persiste elección, puntaje/monedas y snapshot de checkpoint entre reinicios de escena. Estados: `CHARACTER_SELECT → INTRO → GAMEPLAY → PAUSED → RESULT`.
- `Player`, enemigos y miniboss son `CharacterBody2D`; proyectiles/pickups/hitbox/hurtbox son `Area2D`; plataformas/vehículos estáticos usan `StaticBody2D`.
- Datos tipados: `CharacterDefinition`, `EnemyDefinition`, `AttackDefinition`, `ProjectileDefinition`, `DialogueSequence` y `TucumanazoDefinition`; instancias `.tres` viven en `data/`.
- Comunicación predominante por señales. HUD se actualiza por eventos, no hace polling integral del jugador por frame.
- Capas físicas: carril superior/inferior, jugador, enemigos, objetos y proyectiles. El cambio de carril evita interacción cruzada.

## Las 22 tareas completadas

1. Criterios de aceptación, alcance y ruta reproducible documentados.
2. `GameSession` y flujo formal de demo implementados.
3. `CharacterDefinition` y contrato de protagonista introducidos.
4. Selector de personaje creado; San Martín es seleccionable y Atlético queda reservado.
5. Salud, invulnerabilidad y muerte comunes extraídas a `HealthComponent`.
6. `Hitbox`/`Hurtbox` y contrato de ataque por facción/carril implementados.
7. Cabezazo con ventana temporal y hitbox frontal implementado.
8. Proyectiles configurables por recursos, barrido anti-tunneling y caducidad implementados.
9. Combo por impactos válidos, ventana y rotura por daño/tiempo implementado.
10. Tucumanazo parametrizable con carga, estado propio, feedback y cancelaciones implementado.
11. Hipster, Agente y Grandote básico configurados por datos con IA simple.
12. `EncounterDirector` activa, completa y restaura oleadas determinísticamente.
13. Checkpoint único y respawn con snapshots de jugador, pickups y encuentros implementados.
14. HUD dirigido por señales para salud, sesión, inventario, combo, especial y miniboss.
15. Diálogo reutilizable basado en datos, con bloqueo/restauración de controles y skip seguro.
16. Intro Famaillá reproducible u omitible, con estado inicial equivalente.
17. Miniboss `El Grandote` con telegráfica, embestida, puñetazo y golpe al suelo.
18. Composición ambiental/parallax y landmarks legacy de Ruta 38 organizados en escena.
19. Tráfico acotado: spawn fuera de cámara, aviso, carril, daño, límite y despawn.
20. `AudioManager` con buses Music/SFX, voces SFX y transición segura de estados; aún no hay música final registrada.
21. Cierre único tras el miniboss, diálogo final, RESULT, reinicio y salida.
22. Perfilado y pulido: tres ciclos completos sin residuos ni crecimiento de nodos/recursos.

## Sistemas y contenido de juego

**Jugador.** Ciruja / hincha de San Martín es el único héroe jugable con visual legacy actual: movimiento lateral, salto variable, dos carriles, Naranjazo, Cascotazo, Cabezazo, combo, Tucumanazo, daño, vidas, invulnerabilidad, Furia Milanesa, calor e inventario. Naranjo desbloquea naranjas infinitas; cascotes suman munición; empanada suma puntos/moneda; sánguche cura/recupera vida y activa Furia; achilata baja calor y suma puntos. Hit y Death siguen usando fallback legacy, no animación dedicada.

**Segundo protagonista.** Atlético/Deca existe como definición y opción visible de contrato, pero `data/characters/atletico.tres` tiene `selectable = false`, sin `SpriteFrames`, retrato ni voz. No habilitarlo ni inventarle/reasignarle arte legacy sin aprobación artística e integración dedicada.

**Enemigos.** Hipster (rango/botella, 3 HP), Agente de seguridad (rango/bala, 5 HP) y Grandote legacy (melee, 10 HP). El empresario palermitano legacy también existe como boss de Ruta 38 (90 HP, café, escape a Ingenio Arcor), pero el cierre técnico actual del slice ocurre tras el miniboss.

**Miniboss.** El Grandote tiene escena y script propios, barra HUD y tres patrones no solapables: charge, punch y ground slam. Su derrota concede 1200 puntos, completa su encuentro una vez, limpia la arena y dispara el cierre.

**Ruta 38/Famaillá.** `route_38_data.json` contiene seis localidades sobre mundo de 8000 px: Famaillá 0, Acheral 1400, Monteros 2800, León Rougés 4200, Villa Quinteros 5400 y Río Seco 6600; son umbrales de diseño, no distancias geográficas. Hay seis oleadas y el encuentro miniboss (x=7100). El checkpoint está en x=3600. La demo resultante anuncia Acheral; no pretende entregar un Acheral completo ni el resto de la ruta/campaña.

## Estado del vertical slice

Flujo verificado: selección → intro/secuestró o skip → gameplay → checkpoint → muerte/respawn → encuentros y tráfico → El Grandote → diálogo de cierre → RESULT → reinicio/salida. El criterio técnico está cumplido, pero el contenido artístico y la evaluación humana de sensación/duración siguen pendientes. Objetivo de diseño: 10–15 minutos primera partida; debe validarse con playtest, no con el arnés.

## Arte, `art_v2` y legacy

La dirección vigente está en `docs/ART_BIBLE.md`: pixel art arcade 16/32-bit, lectura a 800×450, contorno oscuro, luz superior-izquierda, paleta subtropical cálida, transparencias y pivots documentados. Todo arte final nuevo debe vivir en `res://art_v2/`; no borrar, mover ni reemplazar legacy hasta una tarea explícita de integración.

`art_v2/` contiene la estructura de familias y, actualmente, sólo dos entregas de Ciruja sin integrar:

- `art_v2/characters/ciruja/master/ciruja_master_side.png.png` (1254×1254).
- `art_v2/characters/ciruja/animations/idle/ciruja_idle_sheet.png.png` (2172×724).

Ambos nombres/dimensiones no cumplen todavía la convención de entrega runtime de `docs/characters/CIRUJA_V2_SPEC.md` (frames PNG transparentes de 200×200, nombres sin doble extensión, pivot `(100,200)`, master `ciruja_master_side.png`). No existen el set completo de once animaciones ni un recurso V2 de Godot; por tanto no están aprobados ni conectados al juego. Son el último punto concreto de trabajo posterior al cierre técnico: material fuente/arte de Ciruja V2 depositado para revisión, no integración.

El runtime usa 100 PNG legacy copiados en `godot-version/assets/`, cinco recursos de animación y 11 WAV derivados. Mantener especialmente `assets/animations/player.tres`, `hipster.tres`, `agente.tres`, `grandote.tres`, `boss.tres`, fondos `fusion_fondos.png`/`fondo_*`, suelos, props, vehículos, pickups y proyectiles mientras no exista reemplazo V2 aprobado. Los WAV son aproximación sintetizada de parámetros legacy, no paridad bit a bit con navegador. Los 19 PNG legacy no cargados y los duplicados históricos se preservan por integridad.

## Estructura importante

```text
godot-version/
  scenes/actors, scenes/cinematics, scenes/components, scenes/level, scenes/levels
  scripts/actors, scripts/components, scripts/core, scripts/data, scripts/dialogue, scripts/level
  data/{attacks,characters,dialogues,enemies,projectiles}
  ui/                         # HUD, selección, diálogo, visor
  assets/ + audio/             # legacy/reference utilizado por runtime
  art_v2/                      # producción nueva aislada; no integrada
  docs/                        # diseño, alcance, arte, inventario, informes
  tests/                       # smoke y perfil
  validation/                  # resultados y evidencia
```

## Documentación existente

- `README.md`: ejecución, controles y comandos de validación/regeneración.
- `migration_report.md`: migración Phaser→Godot, inventario legacy, física y limitaciones iniciales.
- `docs/VERTICAL_SLICE_PLAN.md`: plan original de las 22 tareas y decisiones de arquitectura.
- `docs/VERTICAL_SLICE_ACCEPTANCE.md`: alcance, exclusiones y ruta de aceptación.
- `docs/VERTICAL_SLICE_TECHNICAL_REPORT.md`: resultados técnicos finales.
- `docs/GAME_DESIGN.md` y `docs/WORLD_01.md`: visión, campaña y dirección de Famaillá/Ruta 38; no confundir visión futura con contenido implementado.
- `docs/ART_BIBLE.md`, `docs/ASSET_INVENTORY.md`, `docs/ART_V2_PRODUCTION_PLAN.md` y `docs/characters/CIRUJA_V2_SPEC.md`: fuente de verdad artística y protocolo de sustitución.

## Tests y profiling realizados

- `tests/migration_smoke.gd`: **550 checks, 0 fallos**, Godot 4.7.2; cubre los sistemas del slice, intro completa/skip, checkpoint, miniboss, cierre y reinicio.
- `validation/integrity_results.json`: **104 originales** y **100 imágenes copiadas** comprobadas; 0 errores.
- `tests/vertical_slice_profile.gd` / `validation/vertical_slice_profile.json`: tres ciclos completos; siete encuentros por ciclo; 0 errores del arnés.
- Rendimiento estable medido en Ryzen 5 7600 + Intel Arc B580: ~100 FPS (límite del entorno), proceso 10.42–10.80 ms y física 0.21–0.41 ms en ciclos 2–3, con seis enemigos y dos vehículos. En reposo: 271 nodos; carga: 339. Tras tres reinicios: +0 nodos, +0 recursos (189 estables), 0 huérfanos y sin duplicación de conexiones/reproductores.
- Pendientes de QA: gamepad físico, hardware mínimo, sensación/balance/duración, revisión visual y auditiva humana.

## Decisiones técnicas que se deben conservar

- Godot 4.7.2, Compatibility/OpenGL, 800×450, filtro nearest y escalado canvas.
- Dos carriles físicos (Y≈370 y 415), `CharacterBody2D`/`move_and_slide`, cámara suave y límites 8000 px.
- Sin behavior trees, ECS, EventBus global ni pooling preventivo: el perfil no los justifica.
- `CollisionFactory` deriva bounds desde alfa legacy y cachea; no es colisión por píxel. No recalcular/alterar colisiones por un cambio visual sin pruebas.
- Proyectiles, ataques, enemigos y personajes usan datos; integrar visuales no debe cambiar sus contratos, hitboxes, escala o pivots sin validación.
- Checkpoint persiste IDs de encuentros/pickups y estado de jugador; reinicio completo es distinto de respawn.
- Música puede no existir: `AudioManager` debe fallar silenciosa y seguramente, sin duplicar loops.

## Deuda y decisiones pendientes

- Arte final completo V2, integración progresiva y revisión 800×450.
- Deca/Atlético jugable, retrato, voz y paridad visual/animaciones.
- Música original y evaluación auditiva de SFX; controles/gamepad con dispositivo real.
- Playtest de balance, duración, hit feel, Tucumanazo y hardware mínimo.
- Animaciones finales Hit/Death, Cascotazo V2 y mapeo de fall/land/victory/Tucumanazo.
- Campaña posterior, Ingenio Arcor, guardado, multijugador, builds/exportación y los sistemas avanzados de tráfico/IA quedan fuera.
- Algunos documentos de migración describen el antiguo boss final de Río Seco; el estado de demo vigente es el cierre tras El Grandote. Antes de reactivar el boss legacy, reconciliar diseño, `route_38.gd`, encuentros y aceptación.

## NEXT AGENT NOTES

- No modificar `main.js`, `index.html`, `server.ps1` ni `assets/` de la raíz; `main.js` tiene un conflicto Git previo.
- No habilitar Atlético, ni sustituir visuales legacy, ni conectar `art_v2` sin revisar primero `ART_BIBLE`, `CIRUJA_V2_SPEC` y `ART_V2_PRODUCTION_PLAN`.
- No renombrar, recortar, escalar, mover pivots ni eliminar PNG/WAV legacy: los manifiestos e integridad dependen de ellos.
- No cambiar `project.godot`, capas de colisión, escala/offset de Player, `route_38_data.json`, checkpoint o los contratos de datos sin ejecutar smoke y perfil de ciclo completo.
- No convertir la visión de campaña en alcance actual: el slice termina tras El Grandote y apunta a Acheral.
- No introducir pooling, BT/ECS o refactor global sin una métrica que lo justifique.
- Antes de cualquier integración V2, validar nombre, canvas, transparencia, ground point/pivot, escala 800×450, cobertura de animaciones y regresión de combate/carriles.
