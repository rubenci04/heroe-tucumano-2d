# Ciruja cutout — informe de pose neutral

Fecha: 2026-09-06  
Escena: `ciruja_pose_test.tscn`  
Estado: **POC aislado aprobado con limitaciones**

## Resultado visual

Las 14 piezas se cargan desde `workbench/parts/` y reconstruyen una figura coherente, sin modificar los PNG. Cabeza, torso, cuatro segmentos de brazos, cuatro segmentos de piernas y dos pies están visibles; las dos manos independientes están cargadas pero ocultas como variantes porque los antebrazos ya incluyen manos.

La cabeza se lee claramente de perfil hacia la derecha. El torso y la pelvis conservan la perspectiva frontal/¾ de la fuente, por lo que el conjunto no puede convertirse en un perfil lateral estricto sin redibujar. Para este POC se mantuvo esa limitación en vez de deformar el arte.

En neutral no aparecen huecos graves en hombros, codos, caderas, rodillas ni tobillos. La superposición de las mangas resuelve los hombros, el faldón del torso tapa las caderas y los volúmenes de pantalón cubren rodillas y tobillos.

## Estructura de nodos

```text
CirujaPoseTest
├── Backdrop / Title / GroundGuide
└── RigRoot (escala de visualización 0.34)
    ├── BackHip
    │   ├── BackUpperLegSprite
    │   └── BackKnee
    │       ├── BackLowerLegSprite
    │       └── BackAnkle
    │           └── BackFootSprite
    ├── BackShoulder
    │   ├── BackUpperArmSprite
    │   └── BackElbow
    │       ├── BackLowerArmSprite
    │       └── BackWrist
    │           └── BackHandVariant (oculta)
    ├── FrontHip
    │   ├── FrontUpperLegSprite
    │   └── FrontKnee
    │       ├── FrontLowerLegSprite
    │       └── FrontAnkle
    │           └── FrontFootSprite
    ├── TorsoSprite
    ├── HeadSprite
    └── FrontShoulder
        ├── FrontUpperArmSprite
        └── FrontElbow
            ├── FrontLowerArmSprite
            └── FrontWrist
                └── FrontHandVariant (oculta)
```

No existe `Skeleton2D`, `Bone2D`, `AnimationPlayer` ni referencia a Player/runtime. Las texturas se leen como imágenes del workbench y se asignan a `Sprite2D` en memoria. La escala 0,34 pertenece sólo a la vista de laboratorio 800×450; no altera las imágenes ni ninguna escala runtime.

## Pivots usados

Las posiciones están expresadas en coordenadas nativas del rig. Cada articulación es un `Node2D`; sus descendientes heredan traslación y rotación.

| Articulación | Posición respecto del padre | Función |
|---|---:|---|
| `FrontShoulder` | (-140, -110) desde `RigRoot` | giro del brazo frontal completo |
| `FrontElbow` | (-32, 210) desde hombro | giro de antebrazo/mano integrada |
| `FrontWrist` | (0, 235) desde codo | reserva para mano frontal alternativa |
| `BackShoulder` | (140, -115) desde `RigRoot` | giro del brazo trasero completo |
| `BackElbow` | (75, 205) desde hombro | giro de antebrazo/mano integrada |
| `BackWrist` | (75, 235) desde codo | reserva para mano trasera alternativa |
| `FrontHip` | (-55, 145) desde `RigRoot` | giro de pierna frontal completa |
| `FrontKnee` | (-25, 245) desde cadera | giro de pierna inferior frontal |
| `FrontAnkle` | (-10, 250) desde rodilla | giro del pie frontal |
| `BackHip` | (55, 145) desde `RigRoot` | giro de pierna trasera completa |
| `BackKnee` | (25, 255) desde cadera | giro de pierna inferior trasera |
| `BackAnkle` | (15, 240) desde rodilla | giro del pie trasero |

## Orden de capas

De fondo a frente:

1. fondo de laboratorio (`z = -100`);
2. pierna trasera (`BackHip`, `z = -3`);
3. brazo trasero (`BackShoulder`, `z = -2`);
4. pierna frontal (`FrontHip`, `z = -1`);
5. torso (`z = 0`), que oculta uniones de cadera y parte de hombros;
6. cabeza (`z = 1`), superpuesta al cuello;
7. brazo frontal (`FrontShoulder`, `z = 2`);
8. marcadores de debug, dibujados por encima del rig.

Este orden evita cruces incorrectos entre miembros. El doble contorno de manga no desaparece por completo porque está pintado tanto en torso como en brazos superiores.

## Modo de debug y validación

- `D`: muestra/oculta pivots.
- `Tab`: selecciona la articulación siguiente.
- Flechas izquierda/derecha: rotan la articulación elegida en pasos de 5°, limitada a ±15°.
- `0`: restaura la pose neutral.
- El argumento `--pose-validation` ejecuta el barrido automatizado y guarda `pose_neutral.png`, `pose_debug.png` y `pose_joint_sweep.png`.

Resultado automatizado en Godot 4.7.2/OpenGL Compatibility: **10/10 articulaciones PASS**. Todos los extremos descendientes se desplazaron en ambos sentidos, confirmando la jerarquía parent-child. Desplazamientos observados a ±15°: hombros 39,60–41,26 px; codos 20,86–21,89 px; caderas 47,54–48,39 px; rodillas 25,85–26,12 px; tobillos 6,40–6,77 px (valores de pantalla con escala de laboratorio).

## Articulaciones que funcionan bien

- **Hombros:** permanecen cubiertos a ±15°; el torso oculta la raíz y los brazos siguen correctamente al pivot.
- **Caderas:** el faldón mantiene las raíces cerradas y ambas cadenas de piernas responden de forma independiente.
- **Codos:** las mangas/cuffs y el solape del antebrazo soportan el rango probado sin huecos graves.
- **Rodillas:** el volumen holgado del pantalón disimula la unión en neutral y en ±15°.
- **Jerarquía completa:** hombro→codo→muñeca y cadera→rodilla→tobillo→pie propagan correctamente.

## Articulaciones problemáticas

- **Muñecas:** no hay una división limpia. Los antebrazos contienen manos terminadas y las manos sueltas duplicarían dedos; permanecen ocultas.
- **Mangas/hombros:** existe doble contorno visible por duplicación de manga entre torso y brazo superior. Es tolerable en neutral, pero puede vibrar visualmente en movimiento.
- **Tobillos:** funcionan a ±15°, aunque el solape es corto y empieza a sentirse como deslizamiento de zapatilla; conviene usar un rango menor durante apoyo.
- **Rodillas:** flexiones mayores de 15° probablemente revelen bordes redondeados y cambios de volumen.
- **Perspectiva:** cuerpo frontal/¾ con cabeza lateral. Un `run` no corregirá esta inconsistencia de origen.
- La carga directa mediante `Image.load` es deliberadamente de laboratorio y Godot advierte que no es una ruta exportable. No afecta esta prueba ni autoriza integración.

## Recomendación

**Sí se recomienda avanzar a una animación `run` de prueba, únicamente como POC aislado**, porque la jerarquía y los solapes básicos sobreviven ±15°. Debe limitarse primero a poses clave rígidas, usar las manos integradas, mantener rotaciones de tobillo pequeñas y revisar silueta cuadro por cuadro. Este resultado no aprueba un `run` final, un rig de producción ni integración al Player; si el ciclo exige ángulos mayores o muestra popping, harán falta piezas con relleno articular/redibujo aprobado.

No se modificó ningún archivo runtime o legacy.
