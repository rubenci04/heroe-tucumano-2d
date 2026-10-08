extends Node
## Prototype only. Lanza un proyectil enemigo (café/botella) en arco hacia donde estaba el jugador al disparar.
## Reutiliza la física del proyectil: solo reescribe su `travel_direction` y `speed` cada frame (balística simple).
## Al salir del árbol por impacto (suelo o jugador) avisa con `landed(position)`.

const CFG = preload("res://scripts/prototype/feel_config.gd")

signal landed(position: Vector2)

var projectile: Area2D
var velocity := Vector2.ZERO
var gravity := 0.0


static func attach(target: Area2D, aim_position: Vector2, kind: String) -> Node:
	var arc: Node = (load("res://scripts/prototype/arc_shot.gd") as GDScript).new()
	arc.name = "ArcShot"
	arc.projectile = target
	target.add_child(arc)
	arc._launch(aim_position)
	arc._shrink(kind)
	target.tree_exiting.connect(arc._on_projectile_exiting)
	return arc


func _launch(aim_position: Vector2) -> void:
	var origin := projectile.global_position
	var target := aim_position + Vector2(randf_range(-CFG.ARC_SCATTER_X, CFG.ARC_SCATTER_X), 0.0)
	var delta := target - origin
	var flight := clampf(absf(delta.x) / CFG.ARC_HORIZONTAL_SPEED, CFG.ARC_TIME_MIN, CFG.ARC_TIME_MAX)
	# La altura del arco fija la gravedad: pico ≈ ARC_APEX_HEIGHT sobre la recta origen-objetivo.
	gravity = 8.0 * CFG.ARC_APEX_HEIGHT / (flight * flight)
	velocity = Vector2(delta.x / flight, delta.y / flight - 0.5 * gravity * flight)
	projectile.remaining_life = maxf(projectile.remaining_life, flight + 1.0)
	_apply_velocity()


func _shrink(kind: String) -> void:
	# Size, collision and outline are applied once by PROJECTILE_FX.decorate.
	# Standalone callers of ArcShot get the same presentation.
	if not projectile.visual.has_node("ReadableOutline"):
		preload("res://scripts/prototype/projectile_fx.gd")._fit_readable_visual(projectile, kind)
	# Estela más fina, sin tocar el perfil compartido.
	var trail := projectile.get_node_or_null("TrailFx")
	if trail != null:
		var profile: Dictionary = trail.profile.duplicate()
		profile["trail_width"] = float(profile.get("trail_width", 2.0)) * CFG.ARC_TRAIL_WIDTH_MULT
		trail.profile = profile


func _physics_process(delta: float) -> void:
	if not is_instance_valid(projectile) or projectile.spent:
		return
	velocity.y += gravity * delta
	_apply_velocity()


func _apply_velocity() -> void:
	projectile.travel_direction = velocity.normalized()
	projectile.speed = velocity.length()


func _on_projectile_exiting() -> void:
	var position := projectile.global_position
	if projectile.spent or position.y >= GameConfig.GROUND_Y - 4.0:
		landed.emit(Vector2(position.x, GameConfig.GROUND_Y))
