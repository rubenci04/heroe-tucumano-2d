extends Node2D
## Isolated visual audit tool. It reads current runtime resources but never writes them.

const PLAYER_OPAQUE_HEIGHT := 197.0*0.42
const GROUND_Y := 315.0
const PAGE_SIZE := 4
const CATEGORY_NAMES: Array[StringName] = [&"Characters",&"Enemies",&"Vehicles",&"Props"]
const COLOR_GROUND := Color(1.0,0.62,0.12,0.95)
const COLOR_BOUNDS := Color(0.25,0.82,1.0,0.95)
const COLOR_COLLIDER := Color(0.95,0.30,0.35,0.95)
const COLOR_PIVOT := Color(0.95,0.30,0.95,1.0)
const COLOR_SOCKET := Color(0.35,1.0,0.45,1.0)

var category_index := 0
var page := 0
var overlays_visible := true
var entries: Dictionary
var overlay_nodes: Array[CanvasItem] = []
var item_labels: Array[Label] = []

@onready var display: Node2D = $Display
@onready var guides: Node2D = $Guides
@onready var ui: CanvasLayer = $UI
@onready var header: Label = $UI/Header


func _ready() -> void:
	entries = _build_catalog()
	_build_static_guides()
	_show_page()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1,KEY_2,KEY_3,KEY_4:
			category_index = int(event.keycode-KEY_1)
			page = 0
			_show_page()
		KEY_LEFT:
			page = maxi(0,page-1)
			_show_page()
		KEY_RIGHT:
			var count: int = (entries[CATEGORY_NAMES[category_index]] as Array).size()
			page = mini(maxi(0,int(ceil(float(count)/PAGE_SIZE))-1),page+1)
			_show_page()
		KEY_H:
			overlays_visible = not overlays_visible
			for node in overlay_nodes:
				node.visible = overlays_visible


func _build_static_guides() -> void:
	_add_line(guides,PackedVector2Array([Vector2(0,GROUND_Y),Vector2(800,GROUND_Y)]),COLOR_GROUND,2.0,false)
	_add_line(guides,PackedVector2Array([Vector2(32,GROUND_Y),Vector2(32,GROUND_Y-PLAYER_OPAQUE_HEIGHT)]),Color(0.25,0.95,0.88),2.0,false)
	_add_line(guides,PackedVector2Array([Vector2(26,GROUND_Y-PLAYER_OPAQUE_HEIGHT),Vector2(38,GROUND_Y-PLAYER_OPAQUE_HEIGHT)]),Color(0.25,0.95,0.88),2.0,false)


func _show_page() -> void:
	for child in display.get_children():
		child.queue_free()
	for node in overlay_nodes:
		if is_instance_valid(node) and node.get_parent()!=guides:
			node.queue_free()
	overlay_nodes = overlay_nodes.filter(func(node): return is_instance_valid(node) and node.get_parent()==guides)
	for label in item_labels:
		label.queue_free()
	item_labels.clear()
	var category: StringName = CATEGORY_NAMES[category_index]
	var category_entries: Array = entries[category]
	var page_count := maxi(1,int(ceil(float(category_entries.size())/PAGE_SIZE)))
	page = clampi(page,0,page_count-1)
	header.text = "VISUAL LAB · %s · página %d/%d · escala runtime sin correcciones" % [category,page+1,page_count]
	var start := page*PAGE_SIZE
	for slot in range(PAGE_SIZE):
		var index := start+slot
		if index >= category_entries.size():
			break
		_spawn_entry(category_entries[index],105.0+slot*185.0)


func _spawn_entry(entry: Dictionary,x: float) -> void:
	var holder := Node2D.new()
	holder.name = String(entry.name).validate_node_name()
	holder.position = Vector2(x,GROUND_Y+float(entry.get("anchor_y",0.0)))
	display.add_child(holder)
	var sprite: Node2D
	var texture: Texture2D
	if entry.has("frames"):
		var animated := AnimatedSprite2D.new()
		animated.sprite_frames = load(entry.frames)
		animated.animation = entry.animation
		animated.frame = int(entry.get("frame",0))
		animated.pause()
		animated.offset = entry.get("frame_offset",Vector2.ZERO)
		texture = animated.sprite_frames.get_frame_texture(animated.animation,animated.frame)
		sprite = animated
	else:
		var static_sprite := Sprite2D.new()
		texture = load(entry.texture)
		static_sprite.texture = texture
		sprite = static_sprite
	if texture == null:
		return
	var scale_value := float(entry.scale)
	sprite.scale = Vector2.ONE*scale_value
	var bounds := CollisionFactory.opaque_bounds(texture)
	var visual_offset: Vector2 = entry.get("visual_offset",Vector2.ZERO)
	if entry.get("grounded",false):
		visual_offset.y = (texture.get_height()*0.5-bounds.end.y)*scale_value
	sprite.position = visual_offset
	holder.add_child(sprite)
	var sprite_offset: Vector2 = sprite.offset if sprite is AnimatedSprite2D else Vector2.ZERO
	var rect := Rect2(
		visual_offset+(bounds.position-texture.get_size()*0.5+sprite_offset)*scale_value,
		bounds.size*scale_value
	)
	_add_rect(holder,rect,COLOR_BOUNDS)
	_add_cross(holder,Vector2.ZERO,COLOR_GROUND,5.0)
	_add_cross(holder,visual_offset,COLOR_PIVOT,5.0)
	if entry.has("collision_ratio"):
		var collider_size := Vector2(bounds.size.x*scale_value*float(entry.collision_ratio),bounds.size.y*scale_value*0.9)
		_add_rect(holder,Rect2(Vector2(-collider_size.x*0.5,-collider_size.y),collider_size),COLOR_COLLIDER)
	elif entry.has("collision_size"):
		var collider_size: Vector2 = entry.collision_size
		_add_rect(holder,Rect2(Vector2(-collider_size.x*0.5,-collider_size.y),collider_size),COLOR_COLLIDER)
	if entry.get("roof",false):
		var roof_y := -bounds.size.y*scale_value
		_add_line(holder,PackedVector2Array([Vector2(-rect.size.x*0.4,roof_y),Vector2(rect.size.x*0.4,roof_y)]),Color(0.65,0.45,1.0),2.0)
	for socket: Vector2 in entry.get("sockets",[]):
		_add_cross(holder,socket,COLOR_SOCKET,4.0)
	var ratio := bounds.size.y*scale_value/PLAYER_OPAQUE_HEIGHT
	var target: Vector2 = entry.get("target",Vector2(-1,-1))
	var status := "sin rango"
	if target.x >= 0.0:
		status = "OK" if ratio>=target.x and ratio<=target.y else ("BAJO" if ratio<target.x else "ALTO")
	var label := Label.new()
	label.position = Vector2(x-82.0,338.0)
	label.size = Vector2(164.0,88.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",10)
	label.add_theme_color_override("font_color",Color(0.94,0.95,0.97))
	label.text = "%s\n%s · scale %.2f\n%.1f px · ratio %.2f · %s" % [entry.name,texture.resource_path.get_file(),scale_value,bounds.size.y*scale_value,ratio,status]
	ui.add_child(label)
	item_labels.append(label)


func _add_rect(parent: Node,rect: Rect2,color: Color) -> void:
	_add_line(parent,PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y),rect.position]),color,1.0)


func _add_cross(parent: Node,point: Vector2,color: Color,radius: float) -> void:
	_add_line(parent,PackedVector2Array([point-Vector2(radius,0),point+Vector2(radius,0)]),color,1.5)
	_add_line(parent,PackedVector2Array([point-Vector2(0,radius),point+Vector2(0,radius)]),color,1.5)


func _add_line(parent: Node,points: PackedVector2Array,color: Color,width: float,track: bool = true) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.default_color = color
	line.width = width
	line.antialiased = false
	parent.add_child(line)
	if track:
		overlay_nodes.append(line)
	return line


func _actor(name: String,frames: String,animation: StringName,scale_value: float,visual_offset: Vector2,frame_offset: Vector2,target: Vector2,collision_ratio: float,sockets: Array[Vector2] = [],anchor_y: float = 0.0) -> Dictionary:
	return {"name":name,"frames":frames,"animation":animation,"scale":scale_value,"visual_offset":visual_offset,"frame_offset":frame_offset,"target":target,"collision_ratio":collision_ratio,"sockets":sockets,"anchor_y":anchor_y}


func _grounded(name: String,texture: String,scale_value: float,target: Vector2 = Vector2(-1,-1),roof: bool = false) -> Dictionary:
	return {"name":name,"texture":texture,"scale":scale_value,"grounded":true,"target":target,"roof":roof}


func _build_catalog() -> Dictionary:
	var no_target := Vector2(-1,-1)
	return {
		&"Characters":[
			_actor("Ciruja","res://assets/animations/player.tres",&"Idle",0.42,Vector2(0,-42),Vector2(-5.5,0),Vector2(1,1),0.65,[Vector2(32,-42),Vector2(0,-74),Vector2(26,-68),Vector2(26,-24)])
		],
		&"Enemies":[
			_actor("Hipster scooter","res://assets/animations/hipster.tres",&"hipster_run",0.34,Vector2(0,-47.94),Vector2(-1.5,3),Vector2(0.95,1.05),0.65,[Vector2(24,-42)]),
			_actor("Agente","res://assets/animations/agente.tres",&"agente_run",0.36,Vector2(0,-50.4),Vector2(-3,13),Vector2(1.05,1.10),0.65,[Vector2(22,-58)]),
			_actor("Grandote","res://assets/animations/grandote.tres",&"grandote_run",0.44,Vector2(0,-63.36),Vector2(-1.5,8),Vector2(1.15,1.22),0.65),
			_actor("Drone","res://assets/animations/drone.tres",&"idle",0.55,Vector2.ZERO,Vector2.ZERO,no_target,0.72,[],-145.0),
			_actor("Palermitano","res://assets/animations/boss.tres",&"boss_run",0.42,Vector2(0,-60.9),Vector2(6.5,19),Vector2(1.15,1.25),0.65,[Vector2(-34,-62)]),
			_actor("Grandote miniboss","res://assets/animations/grandote.tres",&"grandote_run",0.48,Vector2(0,-69.12),Vector2(-1.5,8),Vector2(1.15,1.22),0.65)
		],
		&"Vehicles":[
			_grounded("Auto 1","res://assets/auto1.png",0.90,Vector2(0.70,0.82),true),
			_grounded("Auto 2","res://assets/auto2.png",0.90,Vector2(0.70,0.82),true),
			_grounded("Auto 3","res://assets/auto3.png",0.95,Vector2(0.70,0.82),true),
			_grounded("Camioneta 1","res://assets/camioneta1.png",0.82,Vector2(0.70,0.82),true),
			_grounded("Camioneta 2","res://assets/camioneta2.png",0.72,Vector2(0.70,0.82),true),
			_grounded("Camioneta 3","res://assets/camioneta3.png",0.70,Vector2(0.70,0.82),true),
			_grounded("Camioneta 4","res://assets/camioneta4.png",0.78,Vector2(0.70,0.82),true),
			_grounded("Camión limones","res://assets/camion_limones.png",0.80,Vector2(1.10,1.25),true),
			_grounded("Expresbus","res://assets/exprebus.png",1.20,Vector2(1.25,1.40),true),
			_grounded("Tesa","res://assets/tesa.png",1.10,Vector2(1.25,1.40),true),
			_actor("Moto + Hipster","res://assets/animations/hipster.tres",&"hipster_run",0.34,Vector2(0,-47.94),Vector2(-1.5,3),Vector2(0.65,0.75),0.65)
		],
		&"Props":[
			_grounded("Árbol naranjas","res://assets/arbol_naranjas.png",0.85),
			_grounded("Parada activa","res://assets/parada_colectivo2.png",0.50,no_target,true),
			_grounded("Cascotes","res://assets/montaña_cascote.png",0.32),
			_grounded("Empanada","res://assets/empanada.png",0.14,Vector2(0.80,0.90)),
			_grounded("Sánguche","res://assets/sanguche.png",0.25,Vector2(0.80,0.90)),
			_grounded("Cartel Famaillá","res://assets/cartel_famailla.png",0.80),
			_grounded("Poste luz","res://assets/poste_luz.png",0.75),
			_grounded("Semáforo","res://assets/semaforo1.png",0.70),
			_grounded("Cañaveral","res://assets/cañas_solas.png",0.45),
			_grounded("Casa 1 (referencia)","res://assets/casa1.png",1.0),
			_grounded("Kiosco (referencia)","res://assets/kiosco_coca2.png",1.0),
			_grounded("Pilar (referencia)","res://assets/pilar_cableado.png",1.0)
		]
	}
