# Tucumán Rush — reglas permanentes

## Proyecto

- Videojuego arcade 2D de acción ambientado en Tucumán, Argentina.
- Motor: Godot 4.
- Inspiración jugable: arcades run-and-gun de los años 90.
- El proyecto actual es un prototipo funcional.

## Estructura y assets

- `godot-version/` es el proyecto Godot 4 activo.
- `index.html`, `main.js`, `server.ps1` y `assets/` en la raíz son la versión HTML/Phaser original; no se modifican para tareas de Godot salvo instrucción explícita.
- Los assets gráficos actuales son LEGACY/REFERENCE.
- No borrar, mover ni reemplazar assets legacy sin una tarea específica.
- `godot-version/art_v2/` queda reservado para arte nuevo aprobado; no se debe poblar sin una tarea que lo requiera.

## Forma de trabajo

- No modificar sistemas que no sean necesarios para cumplir la tarea actual.
- No realizar refactors globales sin autorización.
- Antes de crear un sistema nuevo, comprobar si ya existe.
- Evitar duplicación de scripts y escenas.
- Trabajar en cambios pequeños, verificables y reversibles.
- Priorizar bajo consumo de contexto y tokens: leer únicamente los archivos relevantes para cada tarea.
- No volver a analizar todo el repositorio salvo que se solicite expresamente.

## Entrega de cada tarea

Al terminar cada tarea informar únicamente:

1. archivos creados,
2. archivos modificados,
3. cómo probarlo,
4. errores o decisiones pendientes.
