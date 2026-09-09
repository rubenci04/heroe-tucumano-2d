# Ciruja cutout — informe `run_poc`

Fecha: 2026-09-06  
Escena: `ciruja_pose_test.tscn`  
Animación: `AnimationPlayer/run_poc`  
Estado: **POC técnico válido; resultado visual limitado por el arte fuente**

## Configuración

- Ocho poses clave a **12 FPS**.
- Duración Godot: **0,666667 s**.
- Loop: habilitado.
- 12 tracks, todos con ocho claves y modo de actualización **discreto**; no existe interpolación automática entre poses.
- Las manos independientes permanecen ocultas; se usan las manos integradas en ambos antebrazos.
- `BodyPivot` agrupa cabeza, torso y hombros para aplicar inclinación y rebote sin alterar las cadenas de piernas.
- El GIF usa retardos de 80/90 ms por la resolución temporal propia del formato: ciclo de 670 ms, equivalente a 11,94 FPS. Las ocho capturas PNG corresponden exactamente a las claves Godot de 12 FPS.

Convención de la tabla: ángulos positivos son giros horarios en Godot; `Y` es desplazamiento vertical del `BodyPivot` respecto de su base neutral. FH/FK/FA = cadera/rodilla/tobillo frontal; BH/BK/BA = traseros; FS/FE y BS/BE = hombro/codo frontal y trasero.

## 1. Ángulos aproximados por frame

| Frame | Pose | Y | Torso | FH | FK | FA | BH | BK | BA | FS | FE | BS | BE |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 00 | contacto A | 0 px | +2° | -18° | +4° | +4° | +18° | +24° | -8° | +22° | -18° | -22° | +18° |
| 01 | compresión A | +6 px | +3° | -12° | +20° | +8° | +12° | +28° | -10° | +18° | -22° | -18° | +22° |
| 02 | paso A | -2 px | +2° | +2° | +26° | -4° | -5° | +16° | +5° | -2° | -20° | +5° | +20° |
| 03 | elevación A | -5 px | +1° | +16° | +28° | -10° | -18° | +8° | +8° | -20° | -15° | +22° | +15° |
| 04 | contacto B | 0 px | +2° | +18° | +24° | -8° | -18° | +4° | +4° | -22° | +18° | +22° | -18° |
| 05 | compresión B | +6 px | +3° | +12° | +28° | -10° | -12° | +20° | +8° | -18° | +22° | +18° | -22° |
| 06 | paso B | -2 px | +2° | -5° | +16° | +5° | +2° | +26° | -4° | +5° | +20° | -2° | -20° |
| 07 | elevación B | -5 px | +1° | -18° | +8° | +8° | +16° | +28° | -10° | +22° | +15° | -20° | -15° |

Los límites respetan el encargo: caderas ≤18°, rodillas ≤28°, tobillos ≤10°, hombros ≤22°, codos 15–22° y torso 1–3°. El rebote es de 11 px nativos de extremo a extremo, equivalente a 3,74 px en la vista de laboratorio a escala 0,34.

## 2. Articulaciones que aguantan bien

- **Hombros:** el contrabalanceo se transmite correctamente a cada brazo y el rango de 22° no abre la raíz.
- **Caderas:** las cadenas alternan de forma simétrica y el torso oculta las uniones durante todo el ciclo.
- **Codos:** no aparecen huecos graves dentro de 15–22°; las manos integradas permanecen conectadas.
- **Jerarquía corporal:** inclinación y rebote mueven cabeza, torso y brazos como una unidad sin arrastrar las piernas.
- **Loop técnico:** el frame 07 conduce al 00 sin un salto de valores fuera de los rangos planeados; el patrón contrario se repite a mitad de ciclo.

## 3. Articulaciones que abren huecos o deslizan

- **Tobillos/pies:** la zapatilla rota como bloque rígido y pierde una línea de apoyo constante. Se observa flotación/deslizamiento, especialmente en elevaciones y cambios de contacto.
- **Rodillas:** no se abren completamente, pero las formas redondeadas se superponen como tubos. En las zancadas extremas cambian el volumen y se perciben cruces, no flexión anatómica lateral.
- **Piernas/caderas:** la perspectiva frontal de pantalón y pelvis convierte parte del movimiento adelante/atrás en apertura lateral. Los pies se cruzan o separan en el plano de pantalla.
- **Codos/manos:** los antebrazos con manos horneadas producen arcos rígidos. No hay giro de muñeca ni pose de puño específica para carrera.
- **Mangas:** el doble contorno entre manga de torso y brazo superior puede vibrar entre claves.

## 4. Lectura de carrera

El ciclo comunica **locomoción enérgica y alternancia de miembros**, y a 12 FPS tiene ritmo arcade. Sin embargo, no se lee todavía como una carrera lateral limpia: se acerca a una marcha rápida/rebote frontal en el lugar. Las poses de contacto, compresión y repetición contraria existen, pero el plano frontal/¾ de torso, pantalón y extremidades contradice la dirección lateral de la cabeza.

## 5. Origen principal del problema

El problema principal está en **el arte fuente**, no en el sistema de animación. La jerarquía, el loop, las claves discretas, el contrabalanceo y los rangos funcionan como fueron configurados. Lo que limita la lectura es:

- piernas diseñadas para una pose frontal, no para zancada lateral;
- muslos, pantorrillas y pies sin relleno suficiente detrás de las articulaciones;
- zapatillas con base horizontal rígida;
- manos integradas y mangas duplicadas;
- inconsistencia de perspectiva entre cabeza lateral y cuerpo frontal/¾.

Ajustar más ángulos en este rig no corrige esas restricciones y empezaría a exceder los rangos seguros.

## 6. Recomendación

1. **Regenerar únicamente las piernas primero.** Es la intervención de mayor impacto: dos juegos laterales de muslo, pantorrilla y pie, con reservas de solape en cadera/rodilla/tobillo y siluetas diferenciadas para contacto y recuperación.
2. **No seguir afinando intensivamente el rig actual** hasta probar esas piernas; sólo conservarlo como banco de timings y jerarquía.
3. **Regenerar brazos/manos después**, si las piernas confirman el método. Separar manos reales de antebrazos y entregar mangas sin doble contorno.
4. **No abandonar el método cutout todavía.** El POC demuestra que la técnica funciona; el bloqueo es la preparación de piezas y su perspectiva, no Node2D ni AnimationPlayer.

No se recomienda exportar SpriteFrames ni integrar este ciclo. `run_poc` es evidencia experimental, no animación V2 final.

## Evidencia

- `run_poc.gif`: loop de revisión rápida.
- `run_poc_00.png` … `run_poc_07.png`: ocho poses capturadas desde sus claves exactas.
- `run_poc.log`: Godot 4.7.2/OpenGL; `PASSED`, 0,6667 s, ocho frames, 12 FPS, 12 tracks discretos y loop activo.

Todos los archivos de esta fase están dentro de `art_v2/characters/ciruja/workbench/rig_test/`. No se modificó runtime ni legacy.
