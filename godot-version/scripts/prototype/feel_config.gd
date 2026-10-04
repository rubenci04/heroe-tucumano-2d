extends RefCounted
## Todos los valores de game feel de la arena prototipo. Ajustá acá.

# Visible content, viewport 400x225; not the transparent canvas. Ciruja stays unchanged.
const REFERENCE_VISIBLE_HEIGHT := 74.0
const CHARACTER_PROPORTIONS := {
	"ciruja": 1.0, "agente": 1.0, "campeona": 0.95,
	"hipster": 0.9, "grandote": 1.25, "palermitano": 1.3,
}

static func target_height(character: String) -> float:
	return REFERENCE_VISIBLE_HEIGHT * float(CHARACTER_PROPORTIONS[character])

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
const CIRUJA_SKIN := CirujaSkin.ORIGINAL  # cambiar acá: ORIGINAL / VARIANTE_A_SATURADA / VARIANTE_B_APAGADA
const CIRUJA_SKIN_DIRS := {
	CirujaSkin.VARIANTE_A_SATURADA: "var_a_saturada",
	CirujaSkin.VARIANTE_B_APAGADA: "var_b_apagada",
}

# Carrera de Ciruja generada con PixelLab (8 cuadros en bucle). Solo reemplaza "Run"; el resto de animaciones no cambia.
const CIRUJA_RUN_PIXELLAB := false         # Keep the illustrated source; no pixel-art fallback.
const CIRUJA_RUN_PIXELLAB_CORREGIDO := true # true = gorra roja + piel morocha / false = colores originales de PixelLab
const CIRUJA_RUN_PIXELLAB_FPS := 10.0

# --- Animación procedural (solo sprites visuales, no hitbox) ---
# Ciruja: inclinación al correr (grados), respiración en idle, stretch/squash en salto/aterrizaje
const RUN_LEAN_DEG := 6.0
const RUN_LEAN_SMOOTH := 14.0
const BREATH_SPEED := 2.4          # ciclos por segundo
const BREATH_AMOUNT := 0.025       # variación de escala (0.025 = 2.5%)
const JUMP_STRETCH := 0.14         # estiramiento vertical al subir (a velocidad de salto completa)
const FALL_STRETCH := 0.06         # estiramiento al caer
const STRETCH_SMOOTH := 18.0
const LAND_SQUASH := 0.22          # aplastamiento al aterrizar
const LAND_SQUASH_TIME := 0.22
const LAND_MIN_AIR_TIME := 0.08
# Retroceso al disparar (Ciruja)
const PLAYER_SHOT_KICK := 3.0      # px hacia atrás
const PLAYER_SHOT_KICK_IN := 0.03
const PLAYER_SHOT_KICK_OUT := 0.12
# Enemigos
const ENEMY_ANTIC_PULL := 4.0      # px hacia atrás durante la anticipación
const ENEMY_ANTIC_SQUASH := 0.12   # agacharse
const ENEMY_ANTIC_LEAN_DEG := 7.0  # inclinación hacia atrás
const ENEMY_HIT_PUSH := 6.0        # px de empujón al recibir impacto
const ENEMY_HIT_LEAN_DEG := 8.0
const ENEMY_HIT_IN := 0.03
const ENEMY_HIT_OUT := 0.16
# Muerte de enemigos (copia del sprite animada con tweens)
const ENEMY_DEATH_DURATION := 0.7
const ENEMY_DEATH_SPIN_DEG := 100.0
const ENEMY_DEATH_PUSH := 28.0     # px hacia atrás
const ENEMY_DEATH_HOP := 14.0      # salto inicial
const ENEMY_DEATH_FALL := 6.0      # cuánto baja respecto al punto inicial
const ENEMY_DEATH_FADE_DELAY := 0.3
