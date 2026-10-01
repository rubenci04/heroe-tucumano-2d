# Player progression & quality of life

- **Milanesa:** ya utilizaba `HealthComponent.restore_full()`. Se conserva el full heal, consumo con HP completo, vida extra y furia existentes. Sin energía ni Súper Cabezazo nuevo.
- **Una vida:** conserva progreso, pickups, boss y encuentros. `Route38.last_safe_position` se actualiza vivo, grounded sobre suelo principal y sin peligro. Se reutiliza si está a ≤96 px y sigue siendo seguro; si no, busca el punto más cercano cada 16 px, como máximo 96 px atrás o 256 px adelante. Nunca vuelve al checkpoint. Si todo está bloqueado, limpia amenazas transitorias próximas y espera una apertura local en vez de teletransportar lejos. Invulnerabilidad existente: **1,25 s**.
- **Game Over:** R reinicia desde el snapshot (inicio X=80 si no alcanzó checkpoint), con HP completo y vidas iniciales del CharacterDefinition. Scene reload limpia proyectiles, enemigos, tokens y vehículos móviles. Los set pieces consumidos no se repiten; pickups conservan IDs. Score, monedas, munición y desbloqueos vuelven al snapshot. Sin guardado en disco.
- **Checkpoints:** `data/checkpoints/route_38.json` reutiliza `Checkpoint` y `GameSession`. Sólo avanzan, grounded, sin enemigos activos ni entradas pendientes ni colectivos en tránsito. La activación espera un respiro si se atraviesan durante combate. El snapshot sólo conserva encuentros completados con trigger anterior al punto de respawn; no saltea el tramo final aunque la activación se demore.

| Checkpoint | X / Y | Sector | Criterio |
|---|---|---|---|
| Inicio | 80 / 370 | Famaillá | Baseline de nueva partida |
| route_midpoint | 3600 / 370 | Monteros | Expresbus consumido y route_wave_02 completo; respiro seguro |
| route_after_heavy | 5600 / 370 | Villa Quinteros | Tesa consumida y route_wave_04 completo; después del primer Grandote, antes del tramo aéreo/final |

- **Pausa:** Esc / Start alternan pausa y gameplay. SceneTree detiene Ruta 38; UI permanece activa. Continuar y reiniciar desde checkpoint con confirmación reutilizan el flujo existente. Al continuar expiran dos physics frames de input UI. Música continúa y SFX se suspenden como antes. Sin menú principal ficticio.
- **Coffee del boss:** el visual seguía el vector de vuelo y hacia la izquierda rotaba ≈180°. Ahora usa −22° fijo (compensa inclinación del PNG), sin flip vertical ni giro. No cambian 300 px/s, daño 1, collider, trayectoria ni patrones.
- **Pruebas:** `tests/player_progression_qol_checks.gd` cubre comida, seguridad local, ambos checkpoints, Game Over, pausa/reinicio y café; runners existentes cubren integración.
