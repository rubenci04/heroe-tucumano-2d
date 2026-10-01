extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error(description)

func run() -> void:
	root.size = Vector2i(800, 450)
	var player_scene = load("res://scenes/actors/player.tscn")
	var enemy_scene = load("res://scenes/actors/enemy.tscn")
	var grandote_definition = load("res://data/enemies/grandote.tres")
	var stage := Node2D.new()
	root.add_child(stage)
	var player = player_scene.instantiate()
	player.position = Vector2(454, 370)
	stage.add_child(player)
	player.set_physics_process(false)
	var grandote = enemy_scene.instantiate()
	grandote.enemy_definition = grandote_definition
	grandote.position = Vector2(500, 370)
	stage.add_child(grandote)
	grandote.set_physics_process(false)
	grandote.target = player
	await physics_frame

	var hitbox = grandote.melee_hitbox
	var player_shape: RectangleShape2D = player.hurtbox.collision_shape.shape
	var punch_shape: RectangleShape2D = hitbox.collision_shape.shape
	check(is_equal_approx(player_shape.size.x, 26.208), "Real Player hurtbox is 26.208 px wide")
	check(is_equal_approx(hitbox.collision_shape.position.x, -26.0) and punch_shape.size == Vector2(36, 32), "Punch uses its configured left-facing physical shape")
	check(grandote_definition.preferred_distance < grandote_definition.attack_range and grandote_definition.attack_range < 57.2, "AI initiates inside the physical overlap limit")
	grandote.attack_cooldown = 0.0
	grandote._update_chase(-52.0)
	check(grandote.ai_state == grandote.AIState.TELEGRAPH, "AI starts Punch at a reachable distance")
	grandote._advance_attack_state(grandote_definition.telegraph_duration)
	check(grandote.ai_state == grandote.AIState.ATTACK and hitbox.active, "Punch activates after the unchanged telegraph")
	hitbox.set_physics_process(false)
	hitbox.deactivate()
	await physics_frame

	for sample in [{"name":"HIT claro", "distance":46.0, "damage":true}, {"name":"BORDE", "distance":56.0, "damage":true}, {"name":"MISS claro", "distance":64.0, "damage":false}]:
		player.health_component.restore_full(true)
		player.position.x = grandote.position.x - sample.distance
		hitbox.activate(1.0)
		await physics_frame
		await physics_frame
		var damaged: bool = player.health_component.current_health < player.health_component.max_health
		check(damaged == sample.damage, "%s at %.1f px: expected damage=%s, got damage=%s" % [sample.name, sample.distance, sample.damage, damaged])
		print("GRANDOTE_PUNCH %s distance=%.1f damage=%s" % [sample.name, sample.distance, damaged])
		hitbox.deactivate()
		await physics_frame

	check(is_equal_approx(grandote.definition.visual_scale, 0.372) and is_equal_approx(grandote.definition.visual_offset.y, -53.568), "Approved scale and grounding remain unchanged")
	check(grandote.definition.detection_range == 8000.0 and grandote.definition.move_speed == 45.0, "Detection and movement remain unchanged")
	check(grandote.definition.melee_attack.startup_duration == 0.3 and grandote.definition.melee_attack.active_duration == 0.08 and grandote.definition.melee_attack.recovery_duration == 0.12, "Punch timings remain unchanged")
	print("GRANDOTE_PUNCH_CHECKS %d/%d" % [checks - failures.size(), checks])
	stage.free()
	call_deferred("quit", 0 if failures.is_empty() else 1)
