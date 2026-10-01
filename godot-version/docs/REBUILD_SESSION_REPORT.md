# Rebuild Session Report

Fecha: 2026-09-16.

Actualización vigente 17-09-2026: ver [WORLD_SCALE_REFERENCE.md](WORLD_SCALE_REFERENCE.md).
La base principal ahora es `assets/fondo_completo.png`, a escala 0,5 y parallax 0,44, con cuatro props decorativos complementarios.
Grandote, Palermitano y vehículos están normalizados respecto de Ciruja; se corrigieron anclas por alpha y geometría de colectivos.
Hipster usa `hipster_coffee.tres` a 270 px/s; Palermitano conserva café a 360 px/s.
Smoke final: **642 checks, 0 fallos**. Las secciones siguientes conservan el historial de reconstrucción y sus baselines anteriores.

## Resultado

El proyecto quedó ejecutable como side-scroller 2D lineal, con un único plano de combate, animaciones renovadas para las cinco familias prioritarias, entorno modular y tráfico móvil limitado a Expresbus/Tesa mediante eventos explícitos. No se creó arte, no se recreó `fusion_fondos.png` y no se modificaron PNG durante esta reconstrucción.

Inventario auditado: **331 PNG** (102 legacy raíz, 201 activos, 28 en `art_v2`). Secuencias nuevas/ampliadas detectadas: **22**. La galería legacy quedó reducida de 100 a **72 referencias existentes**: se retiraron `fusion_fondos.png` y otras 27 entradas cuyos PNG ya no estaban en el set renovado; no se borró ningún archivo.

## Etapas terminadas

1. Baseline reparado: Drone acepta 151×151/150×150/150×150; se retiró la referencia obsoleta a `fusion_fondos.png`; Grandote usa recursos actuales sin UIDs rotos.
2. Manifiesto canónico: documentación y JSON con orden, canvas, bounds, ground points, offsets, FPS, loop y eventos. Preview aislado de Ciruja disponible.
3. Ciruja benchmark: Idle 1, Run 7, Jump 6, naranja 7, cascote 6, Headbutt 4, Punch 7 y Eat 1. Hit/Death siguen como fallback existente; no hay Fall dedicado.
4. Plano único: input y overlay de lane retirados; Player, enemigos, daño, proyectiles, respawn y oleadas comparten `WORLD_LAYER`. `lane_index` permanece sólo como compatibilidad inerte.
5. Drone: enemigo aéreo sin asignación de lane; seguimiento de mira 0,70 s, lock final aproximado 0,30 s y sombra proyectada a `GROUND_Y`.
6. Plataformas y vehículos: cuatro autos estacionarios tienen techo one-way y no causan daño. Los props genéricos continúan atravesables desde abajo y estables al aterrizar.
7. Expresbus/Tesa: `spawn_now()` no genera tráfico aleatorio. `spawn_set_piece()` acepta sólo esos dos assets, deduplica IDs de evento, conserva techo móvil, impacto, slowdown acumulativo hasta 55 % y recuperación.
8. Entorno modular: se retiró del runtime el panorama 8000×1024 `fusion_fondosanime.png`. La escena usa 41 sprites independientes: cerros, ocho módulos regionales, casas, cañaveral, árboles, pilares, semáforos, kiosco y parada.
9. Enemigos renovados, con smoke entre cada integración:
   - Agente: Idle 1, Run 8, Shoot 5, Punch 7.
   - Hipster: Idle 1, Ride 5, Shoot Coffee 8.
   - Grandote: Idle 1, Run 8, Punch 7, Ground Slam 13; la onda sale en índice 10.
   - Palermitano: Idle 1, Run 7, Punch 10, Coffee 6, Joke 8 útiles, Order Attack 4. Triple café, summons y cadena conservados.

## Props y pickups utilizados

- Background: `fondo_cerros.png` y capas de ruta repetibles.
- Midground: `casa1.png`, `casa2.png`, `cañas_solas.png`.
- Roadside: `arbol_comun.png`, `pilar_cableado*.png`, `semaforo*.png`, `kiosco_coca2.png`, `parada_colectivo2.png`, además de los landmarks ya vigentes.
- Plataformas: `auto1.png`, `auto2.png`, `auto3.png`, kiosco y parada genéricos.
- Pickups existentes: empanada, achilata y sándwich de milanesa (`sanguche.png`). No se inventaron assets.

## Estado de sistemas

| Sistema | Estado |
|---|---|
| Plano único / Player | Activo; movimiento horizontal, salto, caída, ataques y disparos operativos. |
| Enemigos terrestres | Activos en un plano; Agente, Hipster y Grandote con arte renovado. |
| Proyectiles | Trayectoria, anti-tunneling, velocidades, daño y multidirección preservados; sin filtro de lane. |
| Drone | Activo, aéreo, telegraph/lock preservados. |
| Plataformas | Ground único, vehículos estacionados y props one-way validados. |
| Expresbus/Tesa | Arquitectura determinista lista; encuentros de pacing aún no diseñados. |
| Palermitano | Arte renovado; triple café, summons y cadena conservados. |
| Entorno | Modular; sin fondos fusionados en runtime. |

## Validación final

- Smoke completo: **626 checks, 0 errores, passed=true** en Godot 4.7.2.
- Perfil vertical: **3 ciclos completos, 8 encuentros completados por ciclo, 0 errores, passed=true**; delta de nodos y recursos tras restart: 0.
- Warning externo persistente: Godot no puede leer el almacén raíz de certificados de Windows en ejecución headless. No afecta gameplay ni carga local.
- Integridad histórica: `verify_integrity.cjs` ya no encuentra archivos faltantes en las 72 referencias activas, pero informa 67 diferencias contra hashes legacy (4 originales raíz y 63 copias activas). Es esperable tras la renovación masiva y no debe “arreglarse” restaurando arte viejo; requiere aprobación para crear un baseline V2.

## Inconsistencias y deuda técnica

- `final_boss_joke8.png` tiene fondo blanco RGB opaco y `final_boss_joke10.png` es blanco/vacío. Se conservaron en disco y se excluyeron del runtime.
- Persisten duplicados binarios documentados en Agente, Grandote, Palermitano, Ciruja y suelos. No se borraron ni renombraron.

## Ajustes de playtest — 17-09-2026

- Hipster en scooter: `bottle.tres` fue sustituido por `coffee.tres`; conserva `Shoot Coffee`, daño 1 e IA general.
- Agente: `bullet.tres` pasó de escala visual 0,20 y collider 31,04×6,12 a escala 0,11 y collider 16×4. Dispara 3 balas rectas cada 0,13 s dentro de una ráfaga, con cooldown 2,6 s.
- Ruta 38: la referencia inexistente a `suelo_ruta2.png` fue retirada. Una única tira `suelo_ruta.png` de 652 px repite cada 650 px, con solape de 2 px y sin segunda calzada apilada.
- Fondos: `fondo_cerros.png` forma la capa lejana; `fondo_arboleda.png`, `monteros.png`, `leon_rouges.png`, `villa_quinteros.png`, `ingenio.png`, `rio_seco.png`, `puente.png` y `acheral.png` forman la secuencia regional. Sus calzadas internas se recortan en escena, sin editar los PNG ni recrear `fusion_fondos.png`.
- Parallax horizontal: cerros 0,08; sectores regionales 0,62; edificios intermedios 0,82; suelo/roadside/gameplay 1,00.
- Smoke de esta corrección: 636 checks ejecutados. Los checks nuevos de café, ráfaga, duplicados, huérfanos, collider de bala y continuidad modular pasan. El resultado global sigue en rojo por cinco aserciones previas de vehículos renovados (techos Expresbus/Tesa y Auto1), fuera del alcance autorizado de esta corrección.
- Los campos y métodos de lane deprecated siguen presentes en varias firmas para evitar un refactor global riesgoso; no controlan interacción runtime.
- Falta revisión visual humana de offsets, escalas y densidad de props a resolución de juego.
- Expresbus/Tesa tienen arquitectura, no los 2–3 encuentros finales con pacing, cámara y telegrafía específica.

## Próximos 3 pasos

1. Hacer un playtest visual de Ruta 38 y del preview de animaciones; registrar sólo correcciones de offset/escala, sin tocar colliders.
2. Implementar el primer trigger diseñado de Expresbus como recurso/encounter de datos, con señal de aproximación, ventana de slowdown y salida determinista.
3. Aprobar el corpus gráfico V2 y generar un baseline de hashes nuevo separado del histórico; después evaluar duplicados sin borrar automáticamente.

La **primera tarea de implementación recomendada** es el trigger del primer set piece de Expresbus, ya que la infraestructura y sus contratos están verdes.
