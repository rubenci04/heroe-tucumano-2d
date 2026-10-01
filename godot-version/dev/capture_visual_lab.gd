extends SceneTree
## Reproducible screenshot of the isolated Visual Lab.

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(800,450)
	var lab = load("res://dev/visual_lab.tscn").instantiate()
	root.add_child(lab)
	current_scene = lab
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/baseline/07_visual_lab.png")
	lab.queue_free()
	await process_frame
	quit()
