# Gameplay Restructure Plan

## Decisión de diseño registrada

Tucumán Rush migró de dos carriles a un side-scroller 2D lineal: un solo plano de combate, avance horizontal, salto y plataformas. La primera implementación quedó activa el 2026-09-16; los campos `lane_index` que permanecen existen sólo como compatibilidad deprecated y no filtran gameplay.

Los autos y camiones comunes dejarán de ser tráfico aleatorio y pasarán a ser vehículos estacionados, obstáculos, plataformas y soportes para secretos/coleccionables. Expresbus y Tesa serán los únicos colectivos móviles: aparecerán en aproximadamente dos o tres set pieces diseñados, podrán ser ralentizados por disparos, atropellar al jugador si no se evitan y luego permitirán subir/pasar por encima.

## Estado implementado

- Un `MainGround` en `GROUND_Y=370`, sin input, overlay ni transición de carril.
- Player, enemigos terrestres, boss, proyectiles, daño y respawn operan en `WORLD_LAYER`.
- Drone conserva mira con seguimiento de 0,70 s y lock final aproximado de 0,30 s; su sombra proyecta al suelo principal.
- Cuatro autos comunes funcionan como plataformas estacionarias one-way, sin Hitbox de contacto.
- `TrafficDirector.spawn_now()` está retirado. `spawn_set_piece()` acepta sólo Expresbus y Tesa, deduplica IDs de evento y conserva slowdown al 55 % con recuperación progresiva.
- El entorno usa `fondo_completo.png` como base principal, cerros de apoyo detrás de su transparencia y cuatro props decorativos complementarios. Escalas y profundidad vigentes en `WORLD_SCALE_REFERENCE.md`; no referencia `fusion_fondos*`.

## Sistemas afectados

| Área | Impacto de migración |
|---|---|
| Player | Quitar posteriormente `lane_index`, transición de carril, inputs `lane_up/lane_down`, máscaras por carril y su z-order derivado. Mantener movimiento horizontal, salto, combate, vida, combo y furia. |
| Enemigos, miniboss, boss y drone | Sustituir selección/alineación de carril y filtros de objetivo por una coordenada/plano común; revisar IA, spawn y z-index. |
| Hitbox, Hurtbox y proyectiles | Reemplazar la condición de coincidencia de carril por pertenencia al plano de combate; preservar equipos, daño, ventanas y ownership. |
| Route 38 y suelo | Pasar de dos suelos y dos capas de ruta a un suelo físico principal con plataformas elevadas. |
| EncounterDirector / datos JSON | Convertir `lane` de cada spawn a altura/posición o eliminarlo del contrato; conservar activación X, oleadas y completion. |
| TrafficDirector / TrafficVehicle | Desactivar el tráfico aleatorio; separar actor móvil de set piece y actor estacionario/plataforma. |
| Respawn, checkpoints y seguridad | Reescribir validaciones que buscan carril seguro; mantener checkpoints, limpieza local y persistencia de pickups/encounters. |
| HUD / legibilidad | Retirar señales visuales de lane y advertencias de tráfico genérico; añadir telegrafía de set piece. |

## Sistemas que pueden conservarse

- `EncounterDirector` como estructura de oleadas, activación por X, conteo y finalización.
- `GameSession`, checkpoints, save de encuentros terminados y pickup IDs.
- Componentes Health/Hitbox/Hurtbox/Combo/Special Meter, tras desacoplarlos de `lane_index`.
- Definiciones de ataques y proyectiles, con una adaptación acotada de su filtrado espacial.
- Cámara, progresión horizontal, cinemática y entorno parallax.
- `GenericPlatform` como punto de partida conceptual, no como implementación final: hoy sigue atado a carriles.

## Vehículos y plataformas

1. Crear una representación estática independiente para `auto1`, `auto2`, `auto3` y futuros camiones: colisión superior, laterales bloqueantes, punto de anclaje para pickup y configuración de altura.
2. Usar vehículos estacionados en secuencias de plataformas bajas, obstáculos de combate y rutas opcionales. No deben usar la lógica de daño/movimiento del tráfico actual.
3. Conservar Expresbus (`exprebus.png`) y Tesa (`tesa.png`) exclusivamente para set pieces. Cada set piece necesita: trigger de entrada, telegrafía, velocidad inicial, vida/ralentización por proyectiles, daño/atropello, condición segura para subir y salida.
4. Diseñar 2–3 encuentros concretos antes de programarlos; no reactivar una tabla de tráfico aleatorio con esos dos assets.

## Pickups y exploración

Assets existentes que habilitan una futura evaluación: `empanada.png`, `achilata.png` y `sanguche.png` (más naranja/cascote/botella ya existentes).

- Empanada: candidata a salud, puntuación o recurso contextual.
- Achilata: candidata a mejora temporal/recuperación.
- Sándwich de milanesa: candidato a furia o pickup de alto valor.

No se asigna función, colisión ni spawn en esta etapa. Los pickups sobre vehículos deben tener una altura explícita y ser alcanzables por la física de salto real, no por cambio de carril.

## Oleadas y encuentros

Las oleadas lineales deben alternar combate horizontal, plataformas, pickups y obstáculos, sin pedir cambio de carril. Una plantilla útil:

1. Entrada con plataformas estacionarias y lectura del salto.
2. Oleada en suelo con enemigos que conservan su función actual.
3. Ruta alta con pickup opcional.
4. Set piece Tesa/Expresbus que combina disparo, esquiva y subida.
5. Arena compacta de miniboss/boss sin tráfico aleatorio.

## Riesgos de migración

- Alto: `lane_index` atraviesa Player, enemigos, hitboxes, proyectiles, vehículos, plataformas, spawn, respawn y datos de encounter.
- Alto: los colliders actuales se construyen a partir del frame inicial; migrar sprites nuevos con canvas distinto sin un contrato de pivote/collider rompería el contacto.
- Medio: ventanas de daño y salida de proyectil dependen de duraciones de animaciones que pasarán de 2–5 a 5–13 cuadros.
- Medio: quitar tráfico sin un reemplazo de set pieces puede dejar vacíos de ritmo en Ruta 38.
- Medio: referencias de assets heredadas rotas ya hacen fallar el smoke; conviene estabilizar el baseline antes de una migración amplia.
- Bajo: los props nuevos tienen clasificación inicial pero aún no tienen convenciones de escala, pivot ni colisión.

## Orden de implementación recomendado

1. **Primera tarea recomendada:** corregir de forma aislada el baseline de recursos y definir un manifiesto de animaciones renovadas (nombres, orden, pivote, canvas y offset por acción), sin tocar gameplay ni reconstruir SpriteFrames aún.
2. Aprobar qué assets son canónicos, incluidos duplicados y nombres legacy, sin borrar ni renombrar hasta esa aprobación.
3. Crear una prueba vertical separada de plano único con una plataforma estática y un vehículo estacionado, sin sustituir Route 38.
4. Extraer de los componentes el filtrado por carril y validar combate/proyectiles en el plano único.
5. Migrar Player y un enemigo representativo; después el resto de actores.
6. Convertir datos de oleadas/encounters y el respawn.
7. Sustituir tráfico aleatorio por vehículos estacionarios.
8. Implementar un único set piece de colectivo, validarlo, y sólo entonces ampliar a Expresbus/Tesa restantes.
9. Integrar pickups sobre plataformas, ajuste de cámara y revisión de ritmo.
10. Reconstruir SpriteFrames y escenas runtime únicamente tras aprobar la auditoría y el manifiesto.

## Estado actual

Este documento es una decisión y guía de migración. No cambia Player, enemigos, encounters, tráfico, proyectiles, colliders, escenas runtime, SpriteFrames ni assets.
