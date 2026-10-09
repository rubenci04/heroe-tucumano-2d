extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	root.size = Vector2i(800,450)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	var route = scene.get_node("Route38")
	route.set_physics_process(false)
	var panorama: Parallax2D = route.get_node("Environment/MainPanorama")
	var segments: Array[Sprite2D] = [panorama.get_node("FondoA"),panorama.get_node("FondoB"),panorama.get_node("FondoC")]
	var expected_regions := [Rect2(0,0,2667,1024),Rect2(2667,0,2666,1024),Rect2(5333,0,2667,1024)]
	for index in range(segments.size()):
		var atlas := segments[index].texture as AtlasTexture
		check(atlas != null and atlas.atlas.resource_path=="res://assets/fondo_completo.png" and atlas.region==expected_regions[index],"Panorama region %d uses the expected non-destructive third" % index)
		check(segments[index].scale==Vector2(0.84,0.84) and is_equal_approx(segments[index].position.y,-232.76),"Panorama region %d keeps uniform scale and baseline" % index)
	check(is_equal_approx(segments[0].position.x+expected_regions[0].size.x*0.84,segments[1].position.x) and is_equal_approx(segments[1].position.x+expected_regions[1].size.x*0.84,segments[2].position.x),"Panorama regions meet at exact scaled boundaries")
	# Vertical 1.0 (antes 0.0): el fondo queda fijo al mundo cuando la cámara se acerca y baja (ROUTE_CAMERA_ZOOM); con zoom 1.0 el encuadre es idéntico.
	check(panorama.scroll_scale==Vector2(0.66,1.0) and panorama.repeat_size==Vector2.ZERO,"Panorama keeps coherent parallax without repetition")
	var stationary: Array[Node] = get_nodes_in_group("stationary_vehicles")
	check(stationary.size()==9 and stationary.all(func(vehicle): return is_equal_approx(vehicle.get_ground_anchor_world_y(),GameConfig.GROUND_Y)),"All stationary vehicle wheel anchors touch the gameplay surface")
	check(stationary.all(func(vehicle): return vehicle.get_node("CollisionShape2D").one_way_collision),"All stationary roofs remain one-way after grounding")
	var stop = route.get_node("Terrain/RoadsideBusStop")
	var stop_bounds := CollisionFactory.opaque_bounds(stop.platform_texture)
	var expected_stop_visual_y: float = (stop.platform_texture.get_height()*0.5-stop_bounds.end.y)*stop.image_scale
	check(stop.position==Vector2(2700,preload("res://scripts/prototype/feel_config.gd").backdrop_ground_y(2700)) and is_equal_approx(stop.visual.position.y,expected_stop_visual_y),"Bus stop uses its opaque base on the configured roadside ground")
	var traffic = route.traffic_director
	traffic.enabled = true
	var exprebus = traffic.spawn_set_piece(&"grounding_exprebus",&"exprebus",3200,-1,240,false)
	var tesa = traffic.spawn_set_piece(&"grounding_tesa",&"tesa",3650,-1,225,false)
	check(exprebus.get_ground_anchor_world_y()==GameConfig.GROUND_Y and tesa.get_ground_anchor_world_y()==GameConfig.GROUND_Y,"Expresbus and Tesa wheel anchors remain on the gameplay surface")
	check(exprebus.roof_collision.one_way_collision and tesa.roof_collision.one_way_collision,"Moving bus roofs remain one-way after anchor verification")
	var result := {"passed":failures.is_empty(),"checks":checks,"errors":failures,"regions":[[0,0,2667,1024],[2667,0,2666,1024],[5333,0,2667,1024]],"scale":0.84,"parallax":[0.66,0.0],"positions":[[0.0,-232.76],[2240.28,-232.76],[4479.72,-232.76]],"stationary_ground_y":GameConfig.GROUND_Y,"bus_stop_ground_y":stop.get_ground_anchor_world_y()}
	var output := FileAccess.open("res://validation/background_grounding_checks.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	root.get_node("AudioManager").stop_all()
	await create_timer(0.3).timeout
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
