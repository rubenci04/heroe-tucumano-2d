# World Scale Reference — Ruta 38

> **ADVERTENCIA LEGACY (27-09-2026):** este documento conserva decisiones y mediciones de sesiones anteriores, pero varios valores ya no coinciden con el runtime actual. No usarlo como fuente de verdad para reescalar. Consultar `docs/ROUTE38_BASELINE.md`, `docs/VISUAL_ASSET_INVENTORY.md` y los recursos/escenas vigentes. Se mantiene sin borrar para preservar el historial de decisiones.

Estado final: 17-09-2026. Referencia visual: Ciruja Idle = 1,0 = 197 px opacos × 0,42 = 82,74 px.
Mediciones alpha > 0,1 del PNG vigente; no confundir tamaño de canvas con altura visible. Las poses animadas pueden variar. Ningún PNG fue modificado.

## Suelo

El archivo vigente mide **330×54**, no 365 px. El período heredado de 363 px dejaba **33 px de hueco**.
Se conserva Y=325, escala 1 y el collider físico de suelo en Y=370.
Dos instancias consecutivas usan el mismo PNG: Road (0,325), RoadMirror (329,325), la segunda reflejada horizontalmente. Se solapan 1 px; el período de la pareja es **658 px**. Así se unen columnas idénticas de cada borde y se evitan cambios bruscos de textura/altura. No se generan texturas ni paisaje.
`route_environment.gd` calcula el paso como ancho real - 1 al cargar; evita volver a desincronizar la repetición si cambia el tamaño importado. Ambos segmentos usan el mismo Y.

## Fondo principal

`MainPanorama`: tres `AtlasTexture` consecutivas del mismo `fondo_completo.png`, sin modificar el PNG. Regiones A/B/C: **2667/2666/2667 × 1024 px**; escala final **0,84 uniforme**, Y **-232,76**, z=-15; parallax horizontal **0,66**, vertical 0.
El borde útil inferior queda en -232,76 + 664×0,84 = 325, detrás de la banquina. Posiciones X: **0 / 2240,28 / 4479,72**; cada posición es la suma exacta de los anchos previos escalados, por lo que no hay huecos.
Ancho final 6720 px; cobertura requerida por el recorrido de cámara: 7200×0,66 + 800 = 5552 px. El panorama conserva relación de aspecto, continuidad y margen suficiente sin repetición ni estiramiento destructivo.
Cielo/cerros auxiliares conservan parallax 0,08 y módulos enfrentados existentes. No se usa fusion_fondos.

## Personajes y vehículos

| Elemento | Escala anterior → final | Altura opaca final | Relación Ciruja |
|---|---|---:|---:|
| Ciruja | 0,42 → 0,42 | 82,74 | 1,00 |
| Hipster con scooter | 0,40 → 0,30 | 84,60 | 1,02 |
| Agente | 0,40 → 0,36 | 86,76 | 1,05 |
| Grandote élite | 0,44 → 0,40 | 105,60 | 1,28 |
| Palermitano | 0,42 → 0,42 | 100,80 | 1,22 |
| Drone | 0,55 → 0,55 | 47,85 | 0,58 |
| auto1 | 1,05 → 0,90 | 73,80 | 0,89 |
| auto2 | 1,05 → 0,90 | 83,70 | 1,01 |
| auto3 | 1,10 → 0,95 | 71,25 | 0,86 |
| camion_limones (referencia, sin instancia) | 0,80 → 0,80 | 132,00 | 1,60 |
| Expresbus | 1,20 → 1,20 | 138,00 | 1,67 |
| Tesa (referencia, sin encuentro nuevo) | 1,10 → 1,10 | 133,10 | 1,61 |

Palermitano se mide, pero no se normaliza a 1,05–1,15: la instrucción posterior explícita prohíbe tocarlo salvo regresión. El miniboss Grandote independiente tampoco se usa en los encuentros actuales; conserva 0,48/126,72 px y su contrato previo. El Grandote élite de las oleadas usa 0,40.
Anclas finales: Hipster Y=-42,3; Agente Y=-50,4; Grandote Y=-57,6. Se mantienen los offsets por cuadro del manifiesto.
Cuerpos/contactos/Hurtboxes de esos enemigos y techos de autos se recalculan con sus mecanismos existentes. No se altera el collider del suelo.
Los autos quedan en X=1900/3100/5000/6700. Anchos finales: auto1 163,8; auto2 202,5; auto3 164,35; camión 230,4; Expresbus 313,2; Tesa 322,3. La jerarquía auto < camión < colectivo queda clara en ancho.
El auto X=3100 sigue permitiendo subir al Expresbus; el smoke comprueba el salto real, aterrizaje seguro y transporte, con las escalas nuevas.

## Plataformas y pickups auditados

| Elemento | Escala anterior = final | Altura opaca final |
|---|---:|---:|
| Kiosco plataforma X=1650 | 0,72 | 95,04 |
| Parada plataforma X=2100 | 0,62 | 108,50 |
| Árbol de naranjas X=520 | 0,85 | 130,90 |
| Montón de cascotes X=1250/4450 | 0,32 | 33,60 |
| Empanada | 0,14 | 26,74 |
| Sánguche | 0,25 | 21,00 |
| Achilata | 0,18 | 33,12 |

Se conservan sus techos, hitboxes y recompensas: no se detectó desalineación que justificara modificarlos. Profundidad: cielo -20, panorama -15, cañas -8, ruta -5, decoración -2, árbol 8, plataformas 10, buses 12, enemigos 14, Player 15, boss 16, pickups 18, proyectiles 20.

## Café del Hipster

Recurso exclusivo `hipster_coffee.tres`: **270 → 220 px/s**, daño 1, vida 3 s, escala 0,25, collider 25,2×29,025. Rotación visual fija **−22°** para compensar la inclinación dibujada en cofee.png; vaso visualmente parado, independiente de la dirección horizontal o diagonal y sin giro continuo.
Ataque: telegraph 0,30 s; 2 vasos separados **0,24 s**; ventana de emisión 0,30 s; recovery **0,45 s**; cooldown de ataque **2,40 s** desde el inicio. Dirección bloqueada para ambos vasos. Separación nominal en vuelo: 220×0,24 = 52,8 px.
Palermitano conserva su recurso coffee, 360 px/s, tiempos, HP y patrones.

## Insolación suspendida

`GameConfig.HEAT_ENABLED = false`, marcado SUSPENDED/deprecated. Conservados código, assets, nodos de HUD y lógica histórica para futura recuperación.
El setter mantiene heat=0, incluso al cargar un estado viejo; no se acumula ni se aplica daño por sun. HUD SOL, alerta y shimmer permanecen ocultos/inactivos. Achilata se sigue recolectando y da **100 puntos**, sin enfriar ni curar. Los demás pickups no cambian.

## Balance y oleadas

| Enemigo | HP anterior → final | Movimiento anterior → final (px/s) |
|---|---|---|
| Hipster | 3 → 3 | 65 → 55 |
| Agente | 5 → 5 | 75 → 52 |
| Grandote élite | 10 → 10 | 100 → 45 |

Naranjazo hace 1 de daño, por lo que son 3/5/10 impactos válidos. Las reducciones son 15,4%/30,7%/55%: se excede el rango orientativo para Agente/Grandote para corregir la jerarquía anterior invertida y dejar Grandote realmente lento/pesado. Palermitano no cambia.

| Trigger X | Grupo, en orden de entrada |
|---:|---|
| 900 | Hipster → Hipster |
| 2200 | Agente |
| 2850 | Expresbus existente, tras completar oleada 2 |
| 3500 | Hipster → Agente → Hipster |
| 4100 | Drone |
| 4700 | Grandote → Agente |
| 5400 | Drone → Drone |
| 6100 | Drone → Agente |
| 7000 | Grandote → Grandote |
| 7425 | Palermitano existente, requiere completar último grupo |

Entradas a 0/1,25/2,50 s; offsets X iniciales 460/570 (grupo 3500: 460/540/620), todos en el plano 0. No empieza otro grupo automático mientras queden enemigos o entradas pendientes; descanso mínimo **1,4 s** tras completar cada grupo. El director existente administra la cola y la elimina al restaurar/reiniciar. Cada entrada pendiente actualiza su origen con la posición actual del Player si éste avanzó, evitando aparecer encima de él; se conserva el límite derecho del nivel. La API de activación explícita conserva su modo inmediato para fixtures; gameplay solicita modo escalonado.
Expresbus sigue pausando la activación y el avance de la cola. No hay tráfico aleatorio, encuentro nuevo de Tesa ni nuevo set piece.

## Punch automático

Mismo input de Naranjazo/Cascotazo: enemigo vivo delante hasta **78 px**, tolerancia posterior 16 px y diferencia vertical máxima 36 px. La selección y cada impacto verifican línea libre contra WORLD_LAYER, incluidos techos one-way.
Animación existente **7 frames a 14 FPS**: startup frames 1–2; hitbox activa **3–5** (índices 2–4); recovery 6–7. Duración 0,50 s y cooldown 0,62 s. Hitbox 78×48, centrada a Y=-38 delante del Player. Daño **1 por enemigo y ataque**; no dispara ni consume munición. No añade combo.
Daño/muerte/respawn cancelan Punch. Fuera de rango vuelve el proyectil normal.

## Validación final

Godot 4.7.2, smoke **744 checks / 0 fallos**. Incluye geometría de melee, daño único, munición, ráfaga de café, calor suspendido, entradas pendientes y set piece de Expresbus con auto reducido.
Perfil **3 ciclos headless / 0 errores**: un Expresbus por ciclo; después de cada restart 260 nodos y 296 recursos, 0 huérfanos y 0 vehículos. Deltas nodos/recursos = 0/0; memoria estática +59140 bytes, sin crecimiento de objetos. Headless no mide rendimiento gráfico.
Capturas 800×450: `rebalance_400.png`, `rebalance_2200.png`, `rebalance_4000.png`, `rebalance_5800.png`, `rebalance_7600.png`, `rebalance_actors.png`, `rebalance_buses.png`, `rebalance_coffee.png` dentro de validation. Comparación previa conservada en `world_scale_actors.png`; auditoría numérica en `rebalance_scale_audit.json`.
Se revisaron visualmente las cinco posiciones: sin huecos, líneas verticales ni escalones en las juntas. El fondo cubre el recorrido sin segmentarlo.
Las ejecuciones iniciales dentro del aislamiento emitían errores de acceso al almacén de certificados/caché de shaders. Se repitieron smoke, perfil y capturas con acceso autorizado fuera del aislamiento: los tres logs finales no contienen errores de motor ni de scripts.


## Cierre de la continuación

Se inspeccionó el working tree antes de editar y se preservaron los cambios anteriores. Entre los archivos relevantes ya modificados o sin seguimiento estaban:

- scripts/actors/player.gd, enemy.gd, projectile.gd, vehicle.gd, platform.gd y pickup.gd.
- scripts/core/game_config.gd, hud.gd, main.gd y route_38.gd.
- scripts/level/encounter_director.gd, traffic_director.gd, expresbus_set_piece.gd y route_environment.gd.
- data/enemies/hipster.tres, agente.tres y grandote.tres; data/projectiles/hipster_coffee.tres.
- scenes/levels/route_38.tscn, route_38_data.json y route_38_environment.tscn.
- tests/migration_smoke.gd, vertical_slice_profile.gd, expresbus_checks.gd, rebalance_checks.gd y capture_world_scale.gd.
- docs/WORLD_SCALE_REFERENCE.md, capturas y resultados de validación.

También había modificaciones históricas de assets, Drone, Palermitano y otras escenas; no se revirtieron ni se editaron en esta continuación.

Cambios adicionales de este cierre exclusivamente:

1. scripts/actors/projectile.gd: compensación fija de −22° para la inclinación presente en el PNG del café del Hipster.
2. scripts/level/encounter_director.gd y scripts/core/route_38.gd: entradas pendientes toman en cuenta el avance actual del jugador.
3. tests/rebalance_checks.gd: tres aserciones adicionales para entrada al correr, exclusión de otros grupos y cancelación diferida de Punch.
4. tests/migration_smoke.gd: expectativa de orientación corregida; 744 checks finales.
5. tests/capture_world_scale.gd: captura adicional de los dos cafés visibles y separados.
6. Este documento y resultados/capturas/logs regenerados. No se creó otro sistema ni se modificaron PNG fuente.

Para repetir, desde el proyecto Godot: ejecutar Godot --headless --path . --script res://tests/migration_smoke.gd y después --script res://tests/vertical_slice_profile.gd. Para las capturas usar --script res://tests/capture_world_scale.gd --resolution 800x450, sin --headless.

Resultado final: sin pendientes funcionales detectados. El perfil usa tres recorridos dirigidos con encuentros y reinicios; no sustituye una sesión larga de evaluación humana de dificultad.
