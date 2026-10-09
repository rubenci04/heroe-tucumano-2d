extends SceneTree
## Cobertura real estado × personaje (NUEVO / VIEJO / FALTA) del juego completo, leída de la meta
## "batch_origins" que deja BatchVisuals.attach en cada actor.
## Uso: Godot --headless --path godot-version --script res://tools/audit_coverage.gd

func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	var route = scene.get_node("Route38")
	var counts := [0, 0, 0]
	var actors := {"ciruja": route.get_node("Player")}
	for archetype in ["agente", "hipster", "grandote"]:
		actors[archetype] = route.spawn_enemy(archetype, 1500, 0)
	actors["palermitano"] = route.spawn_palermitano(1800, 0)
	print("| Personaje | Estado | Origen |")
	print("|---|---|---|")
	for character in actors:
		var origins: Dictionary = actors[character].visual.get_meta("batch_origins", {})
		for state in origins:
			var origin: int = origins[state]
			counts[origin] += 1
			print("| %s | %s | %s |" % [character, state, route.BATCH_VISUALS.ORIGIN_NAMES[origin]])
	print("TOTAL NUEVO=%d VIEJO=%d FALTA=%d" % counts)
	quit()
