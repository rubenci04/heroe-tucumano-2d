extends Node2D
## Prototype only. Líneas de velocidad radiales y parpadeantes alrededor del jefe en fase 2.
const CFG = preload("res://scripts/prototype/feel_config.gd")
var _time := 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	for i in CFG.BOSS_PHASE2_AURA_LINES:
		var angle := TAU * float(i) / CFG.BOSS_PHASE2_AURA_LINES + sin(_time * 3.0 + i) * 0.15
		var pulse := 0.5 + 0.5 * sin(_time * 14.0 + i * 1.7)
		var from := Vector2.from_angle(angle) * CFG.BOSS_PHASE2_AURA_RADIUS.x
		var to := Vector2.from_angle(angle) * lerpf(CFG.BOSS_PHASE2_AURA_RADIUS.x, CFG.BOSS_PHASE2_AURA_RADIUS.y, pulse)
		var color: Color = CFG.BOSS_PHASE2_AURA_COLOR
		color.a *= 0.4 + 0.6 * pulse
		draw_line(from, to, color, 1.5)
