extends SceneTree
## Compara encuadres (zoom) en Famaillá, Acheral, Monteros y Río Seco con HUD, Ciruja y enemigos entrando. Con ventana.
##   Godot --path godot-version --fixed-fps 60 --script res://tests/capture_camera_zoom.gd
const OUT := "res://tests/screenshots/camera_zoom/"
const ZOOMS := [1.0, 1.25, 1.4, 1.55]
const PLACES := {"famailla": 300.0, "acheral": 1700.0, "monteros": 3100.0, "rio_seco": 6700.0}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(800, 450)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	var route = scene.get_node("Route38")
	var player = route.player
	route.encounter_director._rest_remaining = 1000000.0
	for zoom in ZOOMS:
		scene.route_zoom_override = zoom
		for place in PLACES:
			player.position = Vector2(PLACES[place], GameConfig.GROUND_Y)
			scene._update_route_camera(0.0, true)
			scene.camera.reset_smoothing()
			for child in route.get_node("Enemies").get_children():
				child.queue_free()
			await process_frame
			var right: float = scene.camera.position.x + 400.0/zoom
			for pair in [["agente", right-70.0], ["hipster", right+30.0], ["grandote", right+140.0]]:
				var e = route.spawn_enemy(pair[0], pair[1], 0)
				e.set_physics_process(false)
			for i in 4:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "z%d_%s.png" % [int(zoom*100), place]))
			var h: float = player.visual.sprite_frames.get_frame_texture(player.visual.animation, player.visual.frame).get_height()
			print("ZOOM %.2f %s cam=%.0f player_screen_x=%.2f" % [zoom, place, scene.camera.position.x, (player.position.x-(scene.camera.position.x-400.0/zoom))/(800.0/zoom)])
	quit()
