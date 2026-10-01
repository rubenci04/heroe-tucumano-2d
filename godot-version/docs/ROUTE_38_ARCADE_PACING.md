# Ruta 38 — pacing arcade

Estado: 18-09-2026. Sin arte ni enemigos nuevos. Fondo, ataques, daño, proyectiles y Palermitano conservan sus contratos. Se reutiliza EncounterDirector; no hay un segundo scheduler.

## Mapa de encuentros

Las X son umbrales mínimos, no spawns absolutos. El siguiente grupo espera a que termine el anterior y su descanso; avanzar rápido no apila encuentros.

| X | Contenido / orden de entrada | Máx. activos | Máx. atacantes | Función, respiro y recompensa |
|---|---|---:|---:|---|
| 0–900 | Orientación; árbol X520 | 0 | 0 | Aprender movimiento y disparo |
| 900 | 2 Hipsters; 0 / 0,65 s | 2 | 2 | Presentación ranged; 2 s |
| 1250–2100 | Cascotes, kiosco, auto X1900, parada | 0 | 0 | Recarga y verticalidad |
| 2200 | 1 Agente; inmediato | 1 | 1 | Presentar ráfaga; 2 s |
| 2700–3200 | Empanada, sándwich, auto X3100 | 0 | 0 | Preparación para el vehículo |
| 2850–3500 | Expresbus; aviso 1 s | 0 enemigos | 0 | Set piece exclusivo; salida + 3 s |
| 3500 | Hipster + Agente / Hipster; 0 / 0,65 / 2,45 s | 3 | 2 | Primera mezcla, pausa interna 1,8 s; 2 s |
| 4100 | Drone solo; inmediato | 1 | 1 exclusivo | Leer apuntado aéreo; 2 s; empanada X4100 existente |
| 4700 | Drone / Hipster; 0 / 1,8 s | 2 | 1 exclusivo | Mezcla aire/suelo controlada; 3 s; achilata X5400 protegida |
| 5400 | Grandote / Agente; 0 / 3,2 s | 2 | 1 | Pesado solo primero, luego add; 3 s |
| 6100 | Drone / Agente; 0 / 0,65 s | 2 | 1 exclusivo | Cambio de verbo controlado; 3 s; sándwich X6200 protegido |
| 6200–6700 | Auto, achilata, sándwich | 0 | 0 | Reposición y plataforma |
| 6800 | Grandote / Agente / Hipster / Agente; 0 / 2,4 / 3,05 / 3,7 s | 4 (límite global tardío 5) | 3 | Único tramo intenso; 3,5 s; achilata X7200 protegida |
| 7200–7425 | Antesala | 0 | 0 | Descompresión; boss espera descanso y wave_06 |
| 7425 | Palermitano en X7600 | Sin cambios | Fuera del pool | Boss existente, sin modificaciones |

Se conserva Expresbus antes de la primera mezcla terrestre para respetar su zona aprobada y los IDs de checkpoint. No se fuerza literalmente la gramática solicitada. Tesa sigue sin evento y el tráfico aleatorio deshabilitado.

## Coordinación de ataques

- Pool compartido en EncounterDirector: 2 menores; 3 solamente con `intense=true` y umbral >=4000 (wave_06).
- Se reserva al iniciar telegraph; se mantiene durante toda la ráfaga y recovery. Se libera por recovery, muerte, salida del árbol y reset. Las referencias son débiles.
- Separación mínima entre concesiones: 0,22 s. Un enemigo esperando conserva movimiento/CHASE, no dispara. No se conceden nuevos ataques fuera de cámara +40 px.
- Drone reserva exclusivamente el pool desde aim hasta terminar cooldown: no puede coexistir con una ráfaga terrestre ni otro Drone. Cancelar apuntado libera su reserva.
- Los summons del boss no pertenecen al director y mantienen su balance anterior; Palermitano no se modifica.
- Los tokens limitan atacantes, no balas en vuelo. Velocidades, daño, ráfagas y lifetime no cambian.

## Entradas, densidad y retirada

Entrada derecha >= borde de cámara +80 px y >= Player +60% del ancho del viewport. Los retrasos recalculan el origen con la posición actual de Player. Cerca del final no se comprime el margen contra el límite X7900; los actores pueden entrar desde fuera del terreno, manteniendo altura de entrada hasta regresar al mundo.

Las entradas pendientes esperan si hay 4 actores activos en el primer tramo o 5 en el segundo (cuenta conservadora que incluye pesados/Drone). El mayor grupo diseñado tiene 4. La API explícita no escalonada se conserva para fixtures y depuración; el gameplay usa activación serial escalonada.

Retirada sin puntos sólo cuando el actor está detrás de cámara izquierda menos 180 px **y** detrás de Player más 80% del viewport. A 800 px: margen personal 640 px. No se retira un actor visible ni delante. Se actualiza el contador del encuentro al salir del árbol.

## Recompensas y persistencia

Achilata X5400 espera route_drone_02; sándwich X6200 espera route_drone_03; achilata X7200 espera wave_06. Se muestran/habilitan sólo sin amenazas activas a menos de 500 px. Se reutilizan pickups y sus IDs/estado `used`, sin duplicar premios. El resto de recursos de orientación permanece disponible.

Reset limpia pendientes, descanso y tokens; checkpoint conserva IDs completados. El respawn local conserva enemigos vivos y sus ciclos de ataque, sin crear tokens ni actores nuevos. Expresbus mantiene su contrato: muerte consume evento, sin duplicación; reinicio completo permite una nueva ejecución.

## Duración y validación

Objetivo orientativo: 2–4 minutos antes del boss, según puntería, avance y plataformas. Cambios de verbo buscados cada 15–25 s; no es una duración medida de playtest ni se añaden esperas artificiales para imponerla. Un speedrun puede ser sensiblemente más corto.

Smoke incorpora `tests/arcade_pacing_checks.gd`: caps 2/3, muerte/recovery/salida/reset, exclusión Drone, spawn con avance rápido, espaciado, duplicación, descanso y leash. Se mantienen pruebas del Expresbus y el resto del juego. Perfil de tres ciclos mide cada grupo con entradas escalonadas, además del bus, muerte local, boss y restart. Las métricas headless no certifican FPS de render ni estética.

Comandos desde la raíz, sustituyendo `godot` por el ejecutable local:

```text
godot --headless --path godot-version --script res://tests/migration_smoke.gd
godot --headless --path godot-version --script res://tests/vertical_slice_profile.gd
```

Pendiente de playtest humano: dificultad efectiva, tiempo de 15–25 s entre verbos y legibilidad de las transiciones con avance lento/rápido. El test del panorama ahora comprueba asset activo y cobertura sin imponer la escala antigua: se conserva la transformación manual actual de la escena, que no se editó para esta tarea.
