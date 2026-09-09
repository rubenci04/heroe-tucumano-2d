extends SceneTree
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/route_preview.png")
	scene.get_node("Interface/AssetGallery").show()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/gallery_preview.png")
	scene.get_node("Interface/AssetGallery").hide()
	var route = scene.get_node("Route38")
	route.set_physics_process(false)
	var player = route.get_node("Player")
	player.position = Vector2(7400,415)
	player.lane_index = 1
	player.collision_mask = 2
	player.invulnerability = 100.0
	player.oranges_unlocked = true
	player.stones = 20
	route.boss = route.spawn_enemy("boss",7650,1)
	scene.get_node("Interface/HUD").show_notice("RIO SECO - BATALLA FINAL")
	scene.get_node("Camera2D").position = Vector2(7400,225)
	scene.get_node("Camera2D").reset_smoothing()
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://validation/rio_seco_preview.png")
	scene.queue_free()
	await process_frame
	quit()
