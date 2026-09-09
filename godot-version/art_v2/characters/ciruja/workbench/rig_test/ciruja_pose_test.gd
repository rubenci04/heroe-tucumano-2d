extends Node2D

const PARTS_ROOT := "res://art_v2/characters/ciruja/workbench/parts/"
const VALIDATION_ROOT := "res://art_v2/characters/ciruja/workbench/rig_test/"
const MAX_MANUAL_ROTATION := 15.0

@export var show_joint_debug: bool = true

var selected_joint: int = 0
var validation_failed: bool = false

var joint_paths: Array[NodePath] = [
	^"RigRoot/BodyPivot/FrontShoulder",
	^"RigRoot/BodyPivot/FrontShoulder/FrontElbow",
	^"RigRoot/BodyPivot/BackShoulder",
	^"RigRoot/BodyPivot/BackShoulder/BackElbow",
	^"RigRoot/FrontHip",
	^"RigRoot/FrontHip/FrontKnee",
	^"RigRoot/FrontHip/FrontKnee/FrontAnkle",
	^"RigRoot/BackHip",
	^"RigRoot/BackHip/BackKnee",
	^"RigRoot/BackHip/BackKnee/BackAnkle",
]

var endpoint_paths: Dictionary = {
	^"RigRoot/BodyPivot/FrontShoulder": ^"RigRoot/BodyPivot/FrontShoulder/FrontElbow/FrontWrist",
	^"RigRoot/BodyPivot/FrontShoulder/FrontElbow": ^"RigRoot/BodyPivot/FrontShoulder/FrontElbow/FrontWrist",
	^"RigRoot/BodyPivot/BackShoulder": ^"RigRoot/BodyPivot/BackShoulder/BackElbow/BackWrist",
	^"RigRoot/BodyPivot/BackShoulder/BackElbow": ^"RigRoot/BodyPivot/BackShoulder/BackElbow/BackWrist",
	^"RigRoot/FrontHip": ^"RigRoot/FrontHip/FrontKnee/FrontAnkle/FrontFootSprite",
	^"RigRoot/FrontHip/FrontKnee": ^"RigRoot/FrontHip/FrontKnee/FrontAnkle/FrontFootSprite",
	^"RigRoot/FrontHip/FrontKnee/FrontAnkle": ^"RigRoot/FrontHip/FrontKnee/FrontAnkle/FrontFootSprite",
	^"RigRoot/BackHip": ^"RigRoot/BackHip/BackKnee/BackAnkle/BackFootSprite",
	^"RigRoot/BackHip/BackKnee": ^"RigRoot/BackHip/BackKnee/BackAnkle/BackFootSprite",
	^"RigRoot/BackHip/BackKnee/BackAnkle": ^"RigRoot/BackHip/BackKnee/BackAnkle/BackFootSprite",
}

var texture_bindings: Dictionary = {
	^"RigRoot/BodyPivot/HeadSprite": "ciruja_head.png",
	^"RigRoot/BodyPivot/TorsoSprite": "ciruja_torso.png",
	^"RigRoot/BodyPivot/FrontShoulder/FrontUpperArmSprite": "ciruja_arm_front_upper.png",
	^"RigRoot/BodyPivot/FrontShoulder/FrontElbow/FrontLowerArmSprite": "ciruja_arm_front_lower.png",
	^"RigRoot/BodyPivot/FrontShoulder/FrontElbow/FrontWrist/FrontHandVariant": "ciruja_hand_front.png",
	^"RigRoot/BodyPivot/BackShoulder/BackUpperArmSprite": "ciruja_arm_back_upper.png",
	^"RigRoot/BodyPivot/BackShoulder/BackElbow/BackLowerArmSprite": "ciruja_arm_back_lower.png",
	^"RigRoot/BodyPivot/BackShoulder/BackElbow/BackWrist/BackHandVariant": "ciruja_hand_back.png",
	^"RigRoot/FrontHip/FrontUpperLegSprite": "ciruja_leg_front_upper.png",
	^"RigRoot/FrontHip/FrontKnee/FrontLowerLegSprite": "ciruja_leg_front_lower.png",
	^"RigRoot/FrontHip/FrontKnee/FrontAnkle/FrontFootSprite": "ciruja_foot_front.png",
	^"RigRoot/BackHip/BackUpperLegSprite": "ciruja_leg_back_upper.png",
	^"RigRoot/BackHip/BackKnee/BackLowerLegSprite": "ciruja_leg_back_lower.png",
	^"RigRoot/BackHip/BackKnee/BackAnkle/BackFootSprite": "ciruja_foot_back.png",
}


func _ready() -> void:
	_load_cutout_textures()
	queue_redraw()
	var user_arguments := OS.get_cmdline_user_args()
	if user_arguments.has("--pose-validation"):
		_run_validation.call_deferred()
	elif user_arguments.has("--run-poc-validation"):
		_run_run_poc_validation.call_deferred()
	else:
		$AnimationPlayer.play(&"run_poc")


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_D:
			show_joint_debug = not show_joint_debug
			queue_redraw()
		KEY_TAB:
			selected_joint = (selected_joint+1)%joint_paths.size()
			queue_redraw()
		KEY_LEFT:
			_rotate_selected(-5.0)
		KEY_RIGHT:
			_rotate_selected(5.0)
		KEY_0:
			$AnimationPlayer.stop()
			_reset_pose()
		KEY_SPACE:
			if $AnimationPlayer.is_playing():
				$AnimationPlayer.pause()
			else:
				$AnimationPlayer.play(&"run_poc")


func _draw() -> void:
	if not show_joint_debug:
		return
	for index in range(joint_paths.size()):
		var joint := get_node_or_null(joint_paths[index]) as Node2D
		if joint == null:
			continue
		var marker_position := to_local(joint.global_position)
		var marker_color := Color(1.0,0.82,0.15,0.95) if index == selected_joint else Color(0.1,0.9,1.0,0.9)
		draw_circle(marker_position,5.0,marker_color)
		draw_line(marker_position-Vector2(8,0),marker_position+Vector2(8,0),marker_color,1.5)
		draw_line(marker_position-Vector2(0,8),marker_position+Vector2(0,8),marker_color,1.5)
	var selected := get_node_or_null(joint_paths[selected_joint])
	if selected != null:
		draw_string(ThemeDB.fallback_font,Vector2(16,424),"Articulación: %s · %.1f°" % [selected.name,rad_to_deg(selected.rotation)],HORIZONTAL_ALIGNMENT_LEFT,420,14,Color.WHITE)


func _load_cutout_textures() -> void:
	for node_path: NodePath in texture_bindings:
		var sprite := get_node_or_null(node_path) as Sprite2D
		if sprite == null:
			push_error("POC cutout: falta Sprite2D %s" % node_path)
			continue
		var image := Image.new()
		var error := image.load(PARTS_ROOT+String(texture_bindings[node_path]))
		if error != OK:
			push_error("POC cutout: no se pudo cargar %s" % texture_bindings[node_path])
			continue
		sprite.texture = ImageTexture.create_from_image(image)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _rotate_selected(delta_degrees: float) -> void:
	var joint := get_node(joint_paths[selected_joint]) as Node2D
	var next_degrees := clampf(rad_to_deg(joint.rotation)+delta_degrees,-MAX_MANUAL_ROTATION,MAX_MANUAL_ROTATION)
	joint.rotation = deg_to_rad(next_degrees)
	queue_redraw()


func _reset_pose() -> void:
	for joint_path in joint_paths:
		(get_node(joint_path) as Node2D).rotation = 0.0
	$RigRoot/BodyPivot.position = Vector2(0,145)
	$RigRoot/BodyPivot.rotation = 0.0
	queue_redraw()


func _run_validation() -> void:
	$AnimationPlayer.stop()
	_reset_pose()
	await get_tree().process_frame
	await get_tree().process_frame
	show_joint_debug = false
	queue_redraw()
	await get_tree().process_frame
	_save_viewport("pose_neutral.png")
	show_joint_debug = true
	queue_redraw()
	await get_tree().process_frame
	_save_viewport("pose_debug.png")
	for joint_path in joint_paths:
		_validate_joint(joint_path)
	_reset_pose()
	for index in range(joint_paths.size()):
		(get_node(joint_paths[index]) as Node2D).rotation = deg_to_rad(15.0 if index%2 == 0 else -15.0)
	show_joint_debug = false
	queue_redraw()
	await get_tree().process_frame
	_save_viewport("pose_joint_sweep.png")
	_reset_pose()
	print("POSE_TEST_RESULT: %s" % ("FAILED" if validation_failed else "PASSED"))
	get_tree().quit(1 if validation_failed else 0)


func _run_run_poc_validation() -> void:
	var animation_player := $AnimationPlayer as AnimationPlayer
	var animation := animation_player.get_animation(&"run_poc")
	if animation == null:
		push_error("RUN_POC: falta la animación run_poc")
		get_tree().quit(1)
		return
	var expected_duration := 8.0/12.0
	if not is_equal_approx(animation.length,expected_duration) or not is_equal_approx(animation.step,1.0/12.0) or animation.loop_mode == Animation.LOOP_NONE:
		validation_failed = true
		push_error("RUN_POC: duración, step o loop incorrectos")
	for track_index in range(animation.get_track_count()):
		if animation.track_get_key_count(track_index) != 8:
			validation_failed = true
			push_error("RUN_POC: track %d no tiene ocho claves" % track_index)
		if animation.track_get_type(track_index) == Animation.TYPE_VALUE and animation.value_track_get_update_mode(track_index) != Animation.UPDATE_DISCRETE:
			validation_failed = true
			push_error("RUN_POC: track %d no es discreto" % track_index)
	show_joint_debug = false
	animation_player.play(&"run_poc")
	animation_player.pause()
	await get_tree().process_frame
	for frame_index in range(8):
		animation_player.seek(float(frame_index)/12.0,true)
		queue_redraw()
		await get_tree().process_frame
		_save_viewport("run_poc_%02d.png" % frame_index)
		print("RUN_POC_FRAME %02d time=%.4f" % [frame_index,float(frame_index)/12.0])
	animation_player.stop()
	_reset_pose()
	print("RUN_POC_RESULT: %s length=%.4f frames=8 fps=12 tracks=%d discrete=true loop=%s" % ["FAILED" if validation_failed else "PASSED",animation.length,animation.get_track_count(),animation.loop_mode != Animation.LOOP_NONE])
	get_tree().quit(1 if validation_failed else 0)


func _validate_joint(joint_path: NodePath) -> void:
	var joint := get_node(joint_path) as Node2D
	var endpoint := get_node(endpoint_paths[joint_path]) as Node2D
	var baseline := endpoint.global_position
	joint.rotation = deg_to_rad(15.0)
	var plus_delta := endpoint.global_position.distance_to(baseline)
	joint.rotation = deg_to_rad(-15.0)
	var minus_delta := endpoint.global_position.distance_to(baseline)
	joint.rotation = 0.0
	var passed := plus_delta > 1.0 and minus_delta > 1.0
	validation_failed = validation_failed or not passed
	print("POSE_JOINT %s +15=%.2fpx -15=%.2fpx %s" % [joint.name,plus_delta,minus_delta,"PASS" if passed else "FAIL"])


func _save_viewport(file_name: String) -> void:
	var viewport_texture := get_viewport().get_texture()
	if viewport_texture == null:
		validation_failed = true
		push_error("POC cutout: el renderer actual no expone una textura de viewport")
		return
	var image := viewport_texture.get_image()
	if image == null or image.is_empty():
		validation_failed = true
		push_error("POC cutout: el renderer actual no permite capturar el viewport")
		return
	var error := image.save_png(VALIDATION_ROOT+file_name)
	if error != OK:
		validation_failed = true
		push_error("POC cutout: no se pudo guardar %s" % file_name)
