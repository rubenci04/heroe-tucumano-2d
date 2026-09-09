extends Area2D
signal collected(kind: String)
signal collected_with_id(pickup_id: StringName, kind: String)
var pickup_id: StringName = &""
var kind: String = "empanada"
var asset: String = "empanada"
var image_scale: float = 0.14
var lane_index: int = 0
var used: bool = false
var interaction_active: bool = false
var interaction_body: Node2D
var halo_time: float = 0.0
var halo_strength: float = 0.0

func _ready() -> void:
	collision_layer = GameConfig.OBJECT_LAYER
	collision_mask = GameConfig.PLAYER_LAYER
	var texture: Texture2D = load("res://assets/"+asset+".png")
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_frame("idle",texture)
	$Visual.sprite_frames = frames
	$Visual.animation = &"idle"
	$Visual.scale = Vector2.ONE*image_scale
	$Visual.position.y = -texture.get_height()*image_scale*0.5
	z_index = int(position.y)
	CollisionFactory.add_shape(self,texture,image_scale,true,0.8)
	body_entered.connect(_on_body_entered)
	set_collected_state(used)


func _process(delta: float) -> void:
	if kind != "orange_tree":
		return
	halo_time += delta
	_update_orange_halo()
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if used or interaction_active or not body.has_method("collect") or body.lane_index != lane_index or body.get_height()>30.0:
		return
	if kind in ["orange_tree","stone_pile"] and body.has_method("begin_pickup_interaction"):
		interaction_active = true
		interaction_body = body
		set_deferred("monitoring",false)
		if body.begin_pickup_interaction(kind,self):
			return
		interaction_active = false
		interaction_body = null
		set_deferred("monitoring",true)
		return
	used = true
	body.collect(kind)
	collected.emit(kind)
	collected_with_id.emit(pickup_id,kind)
	set_collected_state(true)


func complete_collection(body: Node2D) -> bool:
	if used or not interaction_active or body != interaction_body:
		return false
	interaction_active = false
	interaction_body = null
	used = true
	body.collect(kind)
	collected.emit(kind)
	collected_with_id.emit(pickup_id,kind)
	set_collected_state(true)
	return true


func cancel_collection(body: Node2D) -> void:
	if not interaction_active or body != interaction_body:
		return
	interaction_active = false
	interaction_body = null
	set_deferred("monitoring",not used)


func set_collected_state(collected_state: bool) -> void:
	interaction_active = false
	interaction_body = null
	used = collected_state
	set_deferred("monitoring",not used)
	if kind == "orange_tree":
		$Visual.visible = true
		$Visual.modulate = Color(0.8,0.9,0.8) if used else Color.WHITE
		_update_orange_halo()
		queue_redraw()
	else:
		$Visual.visible = not used


func get_orange_halo_strength() -> float:
	return halo_strength if kind == "orange_tree" else 0.0


func _update_orange_halo() -> void:
	if kind != "orange_tree":
		halo_strength = 0.0
		return
	var pulse := 0.5+0.5*sin(halo_time*3.2)
	halo_strength = 0.018+0.012*pulse if used else 0.15+0.08*pulse


func _draw() -> void:
	if kind != "orange_tree" or halo_strength <= 0.0:
		return
	var pulse := 0.5+0.5*sin(halo_time*3.2)
	var radius := 28.0+pulse*7.0
	var halo_color := Color(1.0,0.67,0.16,halo_strength)
	draw_circle(Vector2(0.0,-12.0),radius,halo_color,false,1.5,true)
	draw_circle(Vector2(0.0,-12.0),radius*0.58,Color(1.0,0.84,0.35,halo_strength*0.45),false,1.0,true)
