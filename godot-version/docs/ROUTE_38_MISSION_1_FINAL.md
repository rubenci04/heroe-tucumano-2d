# Ruta 38 — Mission 1 final

Estado aprobado el 21 de septiembre de 2026 sobre Godot 4.7.2.

## Flujo jugable cerrado

- Recorrido lineal de 8000 px: selección de personaje, entrada a Ruta 38 y avance hasta el sector final en X=7425.
- Trece microencuentros deterministas: oleadas terrestres, tutorial de 1 Drone, oleada posterior de 5 Drones y Grandote.
- Set pieces únicos: Expresbus y Tesa. Ambos se consumen una vez, salen limpiamente y no se duplican tras respawn.
- Vehículos estacionados y parada funcionan como plataformas; el checkpoint de mitad de ruta conserva encuentros y pickups ya resueltos.
- Pickups activos: naranjo, cascotes, empanadas y sándwiches, incluidos premios sobre techos. Achilata no tiene spawns activos.
- Calor/insolación permanece suspendido mediante `GameConfig.HEAT_ENABLED = false`.
- Palermitano cierra la misión con 90 HP, duración estimada de 56,25 s, triple café, cadena y hasta 2 Agentes.

## Cierre y restart

Al derrotar a Palermitano se bloquea una segunda resolución, se detienen ataques y telegraphs, se limpian summons, enemigos, proyectiles y tráfico, se reproduce el diálogo final y se muestra el resultado una sola vez. El restart crea una misión nueva en X=80, sin encounters completados, tokens, vehículos, proyectiles, boss ni pickups consumidos residuales.

## Validación final

- End-to-end Mission 1: **29/29**.
- Palermitano: **26/26**.
- Progresión de Ruta 38: **15/15**, final limpio en X=7400.
- Smoke completo: **768/768**.
- Asset Baseline V2: **194 PNG** registrados y verificados; manifiesto de galería: **71/71**.

## Asset Baseline V2

`validation/asset_baseline_v2.json` es la línea base aprobada posterior a la renovación controlada. Reemplaza para la validación actual los hashes históricos de la migración inicial, sin restaurar ni modificar PNG. `scripts/tools/verify_integrity.cjs` verifica el conjunto completo, detecta faltantes, cambios y PNG no registrados.
