# Animation Canonical Manifest

Fecha: 2026-09-16. Fuente estructurada: `res://data/animation_manifest.json`.

## Contrato del pipeline

- Los PNG originales no se redimensionan ni se recortan.
- `AnimatedSprite2D.offset` estabiliza el punto de apoyo por cuadro; collider, Hurtbox e Hitbox quedan separados del arte.
- El orden canónico es el listado explícito del JSON, nunca el orden lexicográfico (`10` no precede a `2`).
- Los bounds opacos usan alpha > 8 y son aproximados/inclusivos.
- El evento visual recomendado no cambia por sí mismo el instante de gameplay. Proyectiles y daño conservan su lógica hasta una migración explícita.
- Duplicados binarios permanecen en disco y en el manifiesto. No se eliminan automáticamente.

## Estado por personaje

| Personaje | Secuencias canónicas | Estado runtime |
|---|---|---|
| Ciruja | Idle 1; Run 7; Jump 6; Throw Orange 7; Throw Stone 6; Headbutt 4; Punch 7; Eat 1 | Integrado como benchmark. Hit/Death conservan placeholder; no existe arte Fall separado. Offsets por cuadro activos. |
| Agente | Idle 1; Run 8; Shoot 5; Punch 7 | Integrado. Run y disparo reemplazan las secuencias legacy; Punch queda disponible sin cambiar la IA a melee. Duplicados Run 0=5, 1=6, 2=7 preservados. |
| Hipster | Idle 1; Ride 5; Shoot Coffee 8 | Integrado. Scooter conserva IA y timing; `Shoot Coffee` emite `hipster_coffee.tres` a 270 px/s con daño 1. Palermitano conserva `coffee.tres` a 360 px/s. |
| Grandote | Idle 1; Run 8; Punch 7; Ground Slam 13 | Integrado. La onda del ground slam conserva sus datos y se emite en el frame canónico 10 (base cero). |
| Palermitano | Idle 1; Run 7; Punch 10; Coffee 6; Joke 8 útiles; Order Attack 4 | Integrado. Triple café, summons y cadena se conservan. Joke 8/10 permanecen en disco pero no entran al runtime por ser RGB opacos defectuosos. |

## Ciruja benchmark

El ancla visual recomendada es `(0, 98)` en coordenadas relativas al centro de textura. Los offsets exactos por cuadro están en el JSON y se aplican únicamente al nodo `Visual`. FPS iniciales: Run 12, Jump 10, naranja 28, cascote 24, Headbutt 8 y Punch 14. Naranja/cascote conservan una duración aproximada de 0,25 s usando todos sus frames.

Eventos visuales recomendados: naranja frame 3, cascote frame 3, Headbutt frame 2 y Punch frame 4 (índices base cero). El Tucumanazo mantiene su onda procedural y su timing de datos; no se inventa una secuencia PNG.

## Decisiones de integración

- Ciruja: no hay Walk, Fall, Hurt ni Death nuevos verificables.
- Agente: el salto legacy falta del proyecto activo; no se inventó reemplazo. Los offsets de apoyo de las cuatro familias están activos desde el JSON.
- Hipster: scooter/café reemplaza la presentación de `hipster_run`/`hipster_lanzar`; desde el playtest del 17-09-2026, el disparo usa café visible (`cofee.png`) y no la botella legacy. La IA general no cambió.
- Agente: `agente_disparar` conserva su presentación canónica y emite una ráfaga acotada de 3 balas, separadas por 0,13 s, con cooldown de 2,6 s.
- Grandote: `smash1..13` reemplaza el ground slam de tres cuadros. El evento de onda se alinea con `grandote_smash11.png`.
- Palermitano: Coffee mezcla canvas 200x300 y 300x300 y se estabiliza con offsets. `final_boss_joke8.png` (personaje sobre blanco opaco) y `final_boss_joke10.png` (blanco vacío) se excluyen como cuadros claramente defectuosos, sin borrar ni modificar los PNG.
- `AnimationOffsetProfile` aplica los offsets del manifiesto sólo al `AnimatedSprite2D`; colliders, Hurtboxes e Hitboxes no dependen del canvas visual.
