# Tucumán Rush — Godot 4

Abrí `project.godot` con **Godot 4.7.2** y presioná **F5**. El juego no necesita Phaser, navegador, npm ni JavaScript en ejecución.

## Controles

| Acción | Tecla |
|---|---|
| Mover | Izquierda/derecha o A/D |
| Carril | Arriba/abajo o W/S |
| Saltar | Espacio; soltar acorta el salto |
| Naranja | Z, después del naranjo de Famaillá |
| Piedra | X, después de recoger cascotes |
| Tucumanazo | V; comienza cada partida con 5 usos |
| Visor de assets/animaciones/audio | F1 |
| Pausa / cerrar visor | Esc |
| Reiniciar | R |

## Alcance

Primer nivel de Famaillá a Río Seco, con escape del jefe al Ingenio Arcor. Nivel 2 dentro de la fábrica pendiente. Se conservan los 100 PNG, 11 efectos, 30 definiciones de actores y 100 poses. Hit/Death son provisionales sobre cuadros existentes. Las empanadas alimentan el contador de monedas.

Ver [migration_report.md](migration_report.md) para cada archivo creado, diferencias con Phaser y resultados de pruebas.

## Validar

Desde esta carpeta, con Godot y Node 22/24 en PATH:

    godot --headless --path . --import --log-file ./validation/import.log
    godot --headless --path . --script res://tests/migration_smoke.gd --log-file ./validation/tests.log
    node scripts/tools/verify_integrity.cjs

## Regenerar recursos

    node scripts/tools/import_legacy.cjs
    godot --headless --path . --import --log-file ./validation/import.log
    node scripts/tools/verify_integrity.cjs
    node scripts/tools/build_report.cjs

La reimportación regenera copias y derivados dentro de godot-version. Necesita el HTML original en la carpeta padre. El proyecto Godot ya generado puede moverse y ejecutarse sin el HTML.
