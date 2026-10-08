# Tucumán Rush — correcciones visuales del 8 de octubre de 2026

Godot 4.7.2. Rama `codex/prototype-cartoon-polish`. Siete commits, uno por punto; `main` permanece en `00c52c3`. Los cambios locales previos de assets y `ciruja_skin.gd` se preservaron y no se incluyeron.

| Punto | Cambio y archivos principales | Evidencia antes del commit |
|---|---|---|
| 1 | Idle neutro de 8 cuadros/6 fps/bucle; metadata, SpriteFrames regenerados, alias en `batch_visuals.gd`, intro y retrato HUD. `ajustar_gorra` queda disponible como gesto. El generador ignora copias anidadas de paquetes. | `p1_idle.png`, 11/11 comprobaciones headless. |
| 2 | Escala visual constante en la ruta; squash/stretch e inclinación desactivados allí mediante `feel_config.gd` y `procedural_anim.gd`. Los tiros usan el canvas nuevo en lugar de cambiar al antiguo. No había escala por profundidad/carril en los cuatro scripts revisados. | Tres tiros reales a Y=370/330/290, 106/106 comprobaciones: misma altura visible. |
| 3 | `CHARACTER_PROPORTIONS` centraliza las alturas; ajuste de visual/cuerpo/hurtbox sin escalar el actor ni sus rangos de ataque. La intro usa las mismas proporciones. Se reparó el acceso obsoleto al registro de sprites del chequeo de polish y su anclaje de acciones legacy. | `p3_proportions.png`: Ciruja 80,22; Agente 85; Hipster 92; Grandote 108; Palermitano 112; Campeona 76. 22/22. |
| 4 | Café 18, botella 20, naranja 14 px, incluyendo contorno oscuro de 2 px. Alturas/color/contorno en `PROJECTILE_FX*`; visual y colisión proporcional se aplican una sola vez. | `p4_projectiles.png`, 6/6; café 10/10 y feel 75/75. |
| 5 | Bases opacas de cartel, poste, semáforo/bastón y Virgencita sobre la vereda a Y=340; constante `BACKDROP_*` por tramo y sombras de contacto. La Virgencita legacy estaba disponible pero no instanciada: se colocó en Acheral. Parada de colectivo también anclada a esa línea. | Seis capturas de localidades/props; 9/9 anclajes y grounding 13/13. |
| 6 | Campeona y proxies en el piso; secuestro con fade, ocultamiento explícito al terminar/cancelar y eliminación de Campeona en la arena. | `p6_campeona_grounded.png`, `p6_campeona_clean_exit.png`; 5/5. |
| 7 | Llegadas a ≥140 px de cualquier enemigo vivo, máximo 4 al inicio/6 desde X=4200, pares como máximo y 1,2 s entre grupos. Se conserva la selección de lado existente. Entrada escalonada por defecto; `staggered=false` es explícito en fixtures que necesitan actores instantáneos. | `p7_wave_cap_4.png`, `p7_wave_cap_6.png`; 2193/2193, incluyendo exceso pendiente, liberación de cupo y delta grande. |

Las alturas son unidades de mundo compartidas con la arena de viewport 400×225. La ruta F5 conserva su viewport de 800×450 y la escala original 0,42 de Ciruja. Las capturas de la ruta se guardaron a 800×450. Ninguna escala de vehículo estacionado cambió.

La separación puede colocar llegadas por delante del final de la cámara: se extendió únicamente el piso físico de entrada hasta X=9400 y los actores nuevos caminan hasta entrar en cuadro. Así Grandote no queda esperando fuera de su rango de detección y ningún actor se atasca en el borde del piso ni necesita un teleport vertical.

Los rangos de ataque no se ajustaron. Las pruebas de altura/vereda ahora consultan la configuración; las pruebas de ritmo esperan los pares pendientes y el delay. La travesía automatizada termina los encuentros antes de pasar los sectores de colectivos. La disponibilidad temporal puede alterar el orden relativo de encuentros con distintos umbrales, por eso se comprueba que todos se activen y completen exactamente una vez. Las pruebas de visibilidad usan cámara y jugador coherentes.

## Archivos creados

- `characters/lote2_cuadros/ciruja/idle/f_00..f_07.png` y sus imports, a partir del paquete provisto `idle_ciruja.zip`.
- `tests/cartoon_revision_checks.gd`, `tests/shared_suite_checks.gd`, `tests/run_headless_suites.ps1`.
- `tests/screenshots/cartoon_revision/*.png`: evidencia por punto y `final_famailla`, `final_acheral`, `final_monteros`, `final_villa_quinteros`, `final_jefe`.
- Este informe y `validation/polish_baseline_results.json`, `polish_final_results.json`, `polish_comparison.json`.

Los demás archivos modificados se detallan por punto arriba y en cada commit. Los cambios a pruebas compartidas permiten ejecutarlas independientemente del smoke antiguo.

## Corrida final headless

| Suite | Resultado |
|---|---|
| agent_orb_checks | PASS |
| background_grounding_checks | PASS |
| cartoon_revision_checks | 2352/2352 PASS |
| combat_readability_checks | PASS |
| drone_encounter_checks | PASS |
| enemy_lifecycle_checks | PASS |
| grandote_punch_checks | PASS |
| hipster_coffee_checks | PASS |
| migration_smoke | 16 errores previos, mismos diagnósticos que la corrida inicial; aborto por referencia nula. |
| palermitano_boss_checks | PASS |
| player_progression_qol_checks | PASS |
| player_vehicle_shot_checks | PASS |
| route_38_end_to_end | 29/29 PASS; ruta, ambos colectivos, jefe, resultado y reinicio. |
| route_progression | 15/15 PASS; todos los encuentros terminan sin enemigos invisibles pendientes. |
| shared_suite_checks | 79/79 PASS: rebalance 20/20, arcade pacing 31/31, Expresbus 28/28. |
| super_headbutt_checks | PASS |
| tesa_set_piece_checks | PASS |
| vehicle_platform_checks | PASS |
| vertical_slice_profile | 2 errores previos de respawn del ciclo 1; antes había 15 errores. Tres ciclos llegan a RESULT. |
| tools/prototype_feel_checks | 75/75 PASS |
| tools/prototype_polish_checks | 486/486 PASS |

**19/21 suites verdes. Cero diagnósticos nuevos**, comprobados contra los logs iniciales en `polish_comparison.json`. El runner devuelve código 1 mientras existan las dos suites con fallos previos; no los oculta ni los considera aprobados. Los logs completos están en `validation/polish_final_*.log` (ignorados por Git).

Pendiente: actualizar/corregir el smoke legacy, que todavía espera visuales y cuadros antiguos y aborta al acceder a un proyectil inexistente; revisar las dos expectativas previas de respawn en `vertical_slice_profile` (`Drone death...` y `wave death...`). Ninguno de los siete puntos se revirtió porque sus verificaciones pasaron. La captura OpenGL emite un aviso de caché de shaders por permisos de `user://`; las imágenes se renderizaron y guardaron correctamente.

## Cómo probar

F5 en `godot-version/project.godot` abre el juego completo (`main` → `route_38`). Para repetir todas las suites:

```powershell
& .\godot-version\tests\run_headless_suites.ps1
```

Para un punto específico o las cinco capturas finales, usando el ejecutable de Godot:

```text
Godot --headless --path godot-version --script res://tests/cartoon_revision_checks.gd -- --point=7
Godot --path godot-version --script res://tests/cartoon_revision_checks.gd -- --point=8 --capture
```

Omitir `--point` ejecuta los siete puntos. Omitir `--headless` y agregar `--capture` produce la evidencia gráfica.
