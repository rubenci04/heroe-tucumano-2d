extends RefCounted
## Todos los valores de game feel de la arena prototipo. Ajustá acá.

# Hit-stop (frames de render congelados al impactar a un enemigo)
const HITSTOP_FRAMES := 3
const HITSTOP_TIME_SCALE := 0.02

# Screen shake: intensidad en píxeles de pantalla, duración en segundos
const SHAKE_SHOT_INTENSITY := 1.5
const SHAKE_SHOT_DURATION := 0.06
const SHAKE_HURT_INTENSITY := 6.0
const SHAKE_HURT_DURATION := 0.25
const SHAKE_EXPLODE_INTENSITY := 4.0
const SHAKE_EXPLODE_DURATION := 0.18

# Muzzle flash
const MUZZLE_DURATION := 0.06
const MUZZLE_LENGTH := 14.0
const MUZZLE_WIDTH := 5.0
const MUZZLE_COLOR := Color(1.0, 0.92, 0.55)

# Chispas de impacto
const SPARK_COUNT := 7
const SPARK_SPEED := 140.0
const SPARK_LIFE := 0.22
const SPARK_SIZE := 1.5
const SPARK_COLOR := Color(1.0, 0.85, 0.3)

# Flash blanco del enemigo (frames)
const ENEMY_FLASH_FRAMES := 2

# Polvo al correr / aterrizar
const DUST_RUN_MIN_SPEED := 60.0
const DUST_RUN_INTERVAL := 0.12
const DUST_RUN_COUNT := 2
const DUST_LAND_COUNT := 8
const DUST_LAND_MIN_AIR_TIME := 0.15
const DUST_SPEED := 40.0
const DUST_LIFE := 0.35
const DUST_SIZE := 2.5
const DUST_COLOR := Color(0.85, 0.8, 0.7, 0.8)

# Explosión al morir un enemigo
const DEATH_COUNT := 18
const DEATH_SPEED := 160.0
const DEATH_LIFE := 0.45
const DEATH_SIZE := 2.5
const DEATH_BODY_OFFSET := Vector2(0.0, -24.0)
const DEATH_COLORS := [Color(1.0, 0.9, 0.4), Color(1.0, 0.5, 0.15), Color(0.9, 0.2, 0.1)]

# Skin de Ciruja en la arena prototipo (experimento de arte pixelado, no toca los assets originales)
enum CirujaSkin { ORIGINAL, VARIANTE_A_SATURADA, VARIANTE_B_APAGADA }
const CIRUJA_SKIN := CirujaSkin.VARIANTE_B_APAGADA  # cambiar acá: ORIGINAL / VARIANTE_A_SATURADA / VARIANTE_B_APAGADA
const CIRUJA_SKIN_DIRS := {
	CirujaSkin.VARIANTE_A_SATURADA: "var_a_saturada",
	CirujaSkin.VARIANTE_B_APAGADA: "var_b_apagada",
}
