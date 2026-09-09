extends SceneTree
const GAME_SESSION = preload("res://scripts/core/game_session.gd")
const CHARACTER_DEFINITION = preload("res://scripts/data/character_definition.gd")
const HEALTH_COMPONENT_SCENE = preload("res://scenes/components/health_component.tscn")
const ATTACK_DEFINITION = preload("res://scripts/data/attack_definition.gd")
const PROJECTILE_DEFINITION = preload("res://scripts/data/projectile_definition.gd")
const ENEMY_DEFINITION = preload("res://scripts/data/enemy_definition.gd")
const COMBO_COMPONENT = preload("res://scripts/components/combo_component.gd")
const TUCUMANAZO_COUNTER_COMPONENT = preload("res://scripts/components/special_meter_component.gd")
const HITBOX_SCENE = preload("res://scenes/components/hitbox.tscn")
const HURTBOX_SCENE = preload("res://scenes/components/hurtbox.tscn")
const PROJECTILE_SCENE = preload("res://scenes/actors/projectile.tscn")
const VEHICLE_SCENE = preload("res://scenes/actors/vehicle.tscn")
const GENERIC_PLATFORM_SCENE = preload("res://scenes/actors/generic_platform.tscn")
const PICKUP_SCENE = preload("res://scenes/actors/pickup.tscn")
const DIALOGUE_SEQUENCE = preload("res://scripts/data/dialogue_sequence.gd")

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame
	await process_frame

func run_tests() -> void:
	var game_session = root.get_node("GameSession")
	var audio_manager = root.get_node("AudioManager")
	var music_bus_index := AudioServer.get_bus_index(&"Music")
	var sfx_bus_index := AudioServer.get_bus_index(&"SFX")
	check(AudioServer.get_bus_index(&"Master")==0 and music_bus_index>=0 and sfx_bus_index>=0,"Master, Music and SFX buses load from the default layout")
	check(AudioServer.get_bus_send(music_bus_index)==&"Master" and AudioServer.get_bus_send(sfx_bus_index)==&"Master","Music and SFX buses route independently to Master")
	check(audio_manager.music_player.bus==&"Music" and audio_manager.voices.all(func(voice: AudioStreamPlayer): return voice.bus==&"SFX"),"Music and effects use their dedicated buses")
	audio_manager.set_music_volume(0.5)
	audio_manager.set_sfx_volume(0.25)
	check(absf(db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))-0.5)<0.001 and absf(db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))-0.25)<0.001,"Music and SFX volumes can be controlled independently")
	audio_manager.set_music_volume(1.0)
	audio_manager.set_sfx_volume(1.0)
	check(not audio_manager.request_music(&"missing_track",0.0) and audio_manager.current_music_state==&"missing_track" and audio_manager.music_player.stream==null,"A missing music track leaves a valid silent state without errors")
	var silent_music: AudioStream = audio_manager.streams["salto"]
	check(audio_manager.register_music(audio_manager.MUSIC_INTRO,silent_music) and audio_manager.register_music(audio_manager.MUSIC_GAMEPLAY,silent_music) and audio_manager.register_music(audio_manager.MUSIC_MINIBOSS,silent_music) and audio_manager.register_music(audio_manager.MUSIC_RESULT,silent_music),"The four vertical-slice music states accept future audio streams")
	audio_manager.reset_for_restart()
	check(audio_manager.request_music(audio_manager.MUSIC_INTRO,0.0) and audio_manager.music_player.stream==silent_music,"AudioManager can start a registered music track")
	var music_changes_before_duplicate: int = audio_manager.music_change_count
	check(audio_manager.request_music(audio_manager.MUSIC_INTRO,0.0) and audio_manager.music_change_count==music_changes_before_duplicate and audio_manager.get_children().filter(func(child: Node): return child is AudioStreamPlayer).size()==9,"Requesting the same loop does not create another player or transition")
	audio_manager.set_gameplay_paused(true)
	check(audio_manager.sfx_paused and not audio_manager.music_player.stream_paused,"Pause blocks SFX while music follows the continue-playing policy")
	audio_manager.set_gameplay_paused(false)
	audio_manager.reset_for_restart()
	var health_probe = HEALTH_COMPONENT_SCENE.instantiate()
	root.add_child(health_probe)
	health_probe.configure(5,5,0.2)
	var depleted_events := [0]
	health_probe.depleted.connect(func(): depleted_events[0] += 1)
	check(health_probe.take_damage(2,"test") and health_probe.current_health==3,"HealthComponent accepts damage through its shared contract")
	check(not health_probe.take_damage(2,"test") and health_probe.current_health==3,"HealthComponent blocks duplicate damage during invulnerability")
	health_probe.set_invulnerability(0.0)
	check(health_probe.take_damage(99,"test") and health_probe.current_health==0,"HealthComponent clamps depleted health to zero")
	check(not health_probe.take_damage(1,"test") and depleted_events[0]==1,"HealthComponent emits depletion only once")
	health_probe.set_current_health(99)
	check(health_probe.current_health==5 and not health_probe.is_depleted(),"HealthComponent clamps restored health to its maximum")
	health_probe.queue_free()
	var invalid_attack := ATTACK_DEFINITION.new()
	check(not invalid_attack.is_valid() and not invalid_attack.get_validation_errors().is_empty(),"Incomplete AttackDefinition reports validation errors")
	var headbutt_definition = load("res://data/attacks/cabezazo.tres")
	check(headbutt_definition != null and headbutt_definition.is_valid(),"Cabezazo has a valid AttackDefinition resource")
	check(headbutt_definition.damage==5 and is_equal_approx(headbutt_definition.get_total_duration(),0.25),"Cabezazo preserves its damage and total action time")
	var invalid_projectile := PROJECTILE_DEFINITION.new()
	check(not invalid_projectile.is_valid() and not invalid_projectile.get_validation_errors().is_empty(),"Incomplete ProjectileDefinition reports validation errors")
	var projectile_expectations := {
		&"orange": [1,560.0,&"player"],
		&"stone": [3,700.0,&"player"],
		&"bottle": [1,162.0,&"enemy"],
		&"coffee": [1,360.0,&"enemy"],
		&"bullet": [1,114.0,&"enemy"],
		&"drone_bolt": [1,320.0,&"enemy"]
	}
	for projectile_id: StringName in projectile_expectations:
		var projectile_definition = load("res://data/projectiles/%s.tres" % projectile_id)
		var expected: Array = projectile_expectations[projectile_id]
		check(projectile_definition != null and projectile_definition.is_valid(),"ProjectileDefinition is valid: "+projectile_id)
		check(projectile_definition.damage==expected[0] and projectile_definition.speed==expected[1] and projectile_definition.default_team==expected[2],"Projectile balance comes from data: "+projectile_id)
	var bullet_definition = load("res://data/projectiles/bullet.tres")
	var bottle_definition = load("res://data/projectiles/bottle.tres")
	check(bullet_definition.speed==114.0 and bottle_definition.speed==162.0 and bullet_definition.lifetime==3.94 and bottle_definition.lifetime==3.94,"Enemy projectiles receive the second 20 percent slowdown while retaining their prior useful travel distance")
	var invalid_enemy_definition := ENEMY_DEFINITION.new()
	check(not invalid_enemy_definition.is_valid() and not invalid_enemy_definition.get_validation_errors().is_empty(),"Incomplete EnemyDefinition reports validation errors")
	var grandote_definition = load("res://data/enemies/grandote.tres")
	var agente_definition = load("res://data/enemies/agente.tres")
	var drone_definition = load("res://data/enemies/drone.tres")
	check(grandote_definition != null and grandote_definition.is_valid() and grandote_definition.enemy_id==&"grandote","Vertical-slice melee EnemyDefinition is valid and has stable identity")
	check(agente_definition != null and agente_definition.is_valid() and agente_definition.enemy_id==&"agente","Vertical-slice ranged EnemyDefinition is valid and has stable identity")
	check(drone_definition != null and drone_definition.is_valid() and drone_definition.enemy_id==&"drone" and drone_definition.max_health==3,"Drone has a valid reusable EnemyDefinition with three health")
	var drone_frames: SpriteFrames = load("res://assets/animations/drone.tres")
	var drone_texture_paths := ["res://assets/drone_1.png","res://assets/drone_2.png","res://assets/drone_3.png"]
	check(drone_frames.get_frame_texture(&"idle",0).resource_path==drone_texture_paths[0] and drone_frames.get_frame_texture(&"aim",0).resource_path==drone_texture_paths[1] and drone_frames.get_frame_texture(&"fire",0).resource_path==drone_texture_paths[2],"Drone maps drone_1, drone_2 and drone_3 to idle, aim and fire")
	var drone_textures: Array[Texture2D] = [load(drone_texture_paths[0]),load(drone_texture_paths[1]),load(drone_texture_paths[2])]
	check(drone_textures.all(func(texture: Texture2D): return texture.get_width()==150 and texture.get_height()==150),"The three drone source PNGs retain their exact 150x150 dimensions")
	check(grandote_definition.attack_mode==ENEMY_DEFINITION.AttackMode.MELEE and grandote_definition.melee_attack is ATTACK_DEFINITION,"Grandote legacy basic uses AttackDefinition for melee")
	check(agente_definition.attack_mode==ENEMY_DEFINITION.AttackMode.PROJECTILE and agente_definition.projectile_definition is PROJECTILE_DEFINITION and agente_definition.projectile_definition.projectile_id==&"bullet","Agente uses ProjectileDefinition for ranged attacks")
	check(grandote_definition.max_health==10 and grandote_definition.move_speed==100.0 and grandote_definition.attack_range==100.0 and grandote_definition.reward_points==300,"Melee health, speed, range and reward come from data")
	check(agente_definition.max_health==5 and agente_definition.move_speed==75.0 and agente_definition.attack_range==650.0 and agente_definition.attack_cooldown==2.6,"Ranged health, speed, range and cooldown come from data")
	check(load("res://data/enemies/hipster.tres").is_valid() and load("res://data/enemies/boss.tres").is_valid(),"Current level enemy ids retain valid compatibility definitions")
	var enemy_source := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd")
	check("if archetype" not in enemy_source and "match archetype" not in enemy_source and '"health":' not in enemy_source,"Enemy controller has no behavior or statistics branches by archetype name")
	var projectile_source := FileAccess.get_file_as_string("res://scripts/actors/projectile.gd")
	check("SpriteFrames.new" not in projectile_source and "CollisionFactory" not in projectile_source,"Projectile instances do not build visual resources or analyze image pixels")
	var combo_probe := COMBO_COMPONENT.new()
	combo_probe.combo_window_seconds = 1.0
	combo_probe.milestone_interval = 2
	combo_probe.set_physics_process(false)
	root.add_child(combo_probe)
	var combo_breaks := [0]
	var combo_milestones := [0]
	var valid_hit_events := [0]
	combo_probe.combo_broken.connect(func(_previous: int): combo_breaks[0] += 1)
	combo_probe.combo_milestone.connect(func(_count: int): combo_milestones[0] += 1)
	combo_probe.valid_hit_registered.connect(func(_combo: int,_total: int): valid_hit_events[0] += 1)
	check(combo_probe.register_hit(&"probe_a") and combo_probe.current_combo==1,"ComboComponent accepts a unique valid impact")
	check(not combo_probe.register_hit(&"probe_a") and combo_probe.current_combo==1,"ComboComponent rejects a duplicate impact identifier")
	check(combo_probe.register_hit(&"probe_b") and combo_probe.current_combo==2 and combo_milestones[0]==1,"ComboComponent emits configured milestones")
	check(combo_probe.total_valid_hits==2 and valid_hit_events[0]==2,"ComboComponent exposes clean valid-hit progress for future systems")
	combo_probe._physics_process(1.01)
	check(combo_probe.current_combo==0 and combo_breaks[0]==1,"ComboComponent breaks combo when its configurable window expires")
	combo_probe.reset()
	check(combo_probe.current_combo==0 and combo_probe.total_valid_hits==0,"ComboComponent reset clears run state")
	combo_probe.queue_free()
	var tucumanazo_definition = load("res://data/attacks/tucumanazo.tres")
	check(tucumanazo_definition != null and tucumanazo_definition.is_valid(),"Tucumanazo has a valid configurable definition")
	check(tucumanazo_definition.starting_uses==5 and tucumanazo_definition.damage==5 and tucumanazo_definition.radius==150.0 and tucumanazo_definition.hit_stop_time_scale==0.08,"Tucumanazo starting stock, damage, radius and hit-stop come from data")
	var miniboss_charge = load("res://data/attacks/miniboss_charge.tres")
	var miniboss_punch = load("res://data/attacks/miniboss_punch.tres")
	var miniboss_slam = load("res://data/attacks/miniboss_ground_slam.tres")
	check(miniboss_charge.is_valid() and miniboss_punch.is_valid() and miniboss_slam.is_valid(),"El Grandote has three valid data-driven AttackDefinitions")
	check(miniboss_slam.recovery_duration>miniboss_punch.recovery_duration and miniboss_slam.shape_kind==ATTACK_DEFINITION.ShapeKind.CIRCLE,"Ground slam has the larger recovery and area shape")
	var palermitano_chain = load("res://data/attacks/palermitano_chain.tres")
	var palermitano_scene: PackedScene = load("res://scenes/actors/palermitano_boss.tscn")
	var palermitano_frames: SpriteFrames = load("res://assets/animations/boss.tres")
	check(palermitano_chain.is_valid() and palermitano_chain.damage==2 and palermitano_chain.attack_id==&"palermitano_chain","Palermitano chain has a valid two-damage AttackDefinition")
	check(palermitano_scene != null and palermitano_frames.has_animation(&"boss_cofee") and palermitano_frames.has_animation(&"boss_punch") and palermitano_frames.has_animation(&"boss_joke"),"Palermitano reuses the legacy boss art for coffee, chain and summon telegraphs")
	var special_probe := TUCUMANAZO_COUNTER_COMPONENT.new()
	root.add_child(special_probe)
	special_probe.configure(tucumanazo_definition.starting_uses,tucumanazo_definition.starting_uses)
	check(special_probe.current_uses==5 and special_probe.max_uses==5,"Tucumanazo counter starts with five uses")
	check(special_probe.consume_one() and special_probe.current_uses==4,"Tucumanazo counter consumes exactly one use")
	special_probe.set_uses(0)
	check(not special_probe.consume_one() and special_probe.current_uses==0,"Tucumanazo counter rejects use at zero")
	special_probe.queue_free()
	var attack := ATTACK_DEFINITION.new()
	attack.attack_id = &"contract_probe"
	attack.damage = 2
	attack.active_duration = 0.2
	attack.reach = Vector2(40,24)
	attack.offset = Vector2(20,-12)
	var attacker_owner := Node2D.new()
	var target_owner := Node2D.new()
	var target_health = HEALTH_COMPONENT_SCENE.instantiate()
	var target_hurtbox = HURTBOX_SCENE.instantiate()
	var attack_hitbox = HITBOX_SCENE.instantiate()
	attacker_owner.add_child(attack_hitbox)
	target_owner.add_child(target_health)
	target_owner.add_child(target_hurtbox)
	root.add_child(attacker_owner)
	root.add_child(target_owner)
	target_health.configure(5,5,0.0)
	target_hurtbox.configure(target_owner,target_health,&"enemy",0,GameConfig.ENEMY_LAYER)
	check(attack_hitbox.configure(attacker_owner,&"player",0,attack,1,GameConfig.ENEMY_LAYER),"Hitbox accepts a valid AttackDefinition")
	check(attack_hitbox.collision_shape.position==Vector2(20,-12) and attack_hitbox.collision_shape.shape.size==Vector2(40,24),"AttackDefinition configures physical reach and direction")
	check(not attack_hitbox.try_hit(target_hurtbox) and target_health.current_health==5,"Inactive Hitbox cannot apply damage")
	check(attack_hitbox.activate() and attack_hitbox.try_hit(target_hurtbox) and target_health.current_health==3,"Enemy Hitbox/Hurtbox contract delegates damage to HealthComponent")
	check(not attack_hitbox.try_hit(target_hurtbox) and target_health.current_health==3,"One Hitbox activation cannot damage the same Hurtbox twice")
	attack_hitbox.deactivate()
	target_hurtbox.combat_owner = attacker_owner
	attack_hitbox.activate()
	check(not attack_hitbox.try_hit(target_hurtbox) and target_health.current_health==3,"An attacker cannot damage itself")
	target_hurtbox.combat_owner = target_owner
	target_hurtbox.team = &"player"
	attack_hitbox.activate()
	check(not attack_hitbox.try_hit(target_hurtbox) and target_health.current_health==3,"Allied Hitbox and Hurtbox reject friendly damage")
	target_hurtbox.team = &"enemy"
	target_hurtbox.lane_index = 1
	attack_hitbox.activate()
	check(not attack_hitbox.try_hit(target_hurtbox) and target_health.current_health==3,"Hitbox and Hurtbox on different lanes do not interact")
	target_hurtbox.lane_index = 0
	attack_hitbox.activate()
	check(attack_hitbox.try_hit(target_hurtbox) and target_health.current_health==1,"A new valid activation can damage the target again")
	attacker_owner.queue_free()
	target_owner.queue_free()
	var san_martin = load("res://data/characters/san_martin.tres")
	var atletico = load("res://data/characters/atletico.tres")
	check(san_martin != null and san_martin.is_runtime_ready(),"San Martin CharacterDefinition is runtime ready")
	check(san_martin.character_id==&"san_martin" and san_martin.display_name=="Hincha de San Martín de Tucumán","San Martin definition has stable identity")
	check(san_martin.sprite_frames==GameConfig.PLAYER_FRAMES,"San Martin reuses current SpriteFrames")
	check(san_martin.walk_speed==GameConfig.WALK_SPEED and san_martin.gravity==GameConfig.GRAVITY and san_martin.jump_speed==GameConfig.JUMP_SPEED and san_martin.lane_duration==GameConfig.LANE_DURATION,"San Martin preserves movement values")
	check(san_martin.max_health==3 and san_martin.starting_lives==3,"San Martin preserves health and lives")
	check(san_martin.get_animation_names().size()==8,"San Martin exposes all required player animations")
	check(atletico != null and not atletico.selectable and not atletico.is_runtime_ready(),"Atletico remains a non-selectable pending definition")
	check(atletico.walk_speed==san_martin.walk_speed and atletico.jump_speed==san_martin.jump_speed and atletico.max_health==san_martin.max_health,"Atletico reserves identical base values")
	var invalid_definition := CHARACTER_DEFINITION.new()
	check(not invalid_definition.is_runtime_ready() and not invalid_definition.get_validation_errors().is_empty(),"Incomplete CharacterDefinition reports validation errors")
	var invalid_dialogue := DIALOGUE_SEQUENCE.new()
	check(not invalid_dialogue.is_valid() and not invalid_dialogue.get_validation_errors().is_empty(),"Incomplete DialogueSequence reports validation errors")
	var technical_dialogue = load("res://data/dialogues/technical_test.tres")
	check(technical_dialogue != null and technical_dialogue.is_valid() and technical_dialogue.sequence_id==&"technical_test","Technical dialogue is valid and has stable identity")
	check(technical_dialogue.entries.size()==2 and technical_dialogue.entries[0].speaker!=technical_dialogue.entries[1].speaker,"Dialogue data supports multiple speakers")
	check(String(technical_dialogue.entries[1].text)=="Segunda línea, desde datos editables.","Dialogue text is editable in a data resource")
	var intro_dialogue = load("res://data/dialogues/intro_famailla_san_martin.tres")
	check(intro_dialogue != null and intro_dialogue.is_valid() and intro_dialogue.entries.size()==6,"Famailla intro dialogue is valid, short and editable from data")
	check(intro_dialogue.entries.any(func(entry: Dictionary): return entry.speaker=="Campeona de la Empanada" and "receta" in String(entry.text)),"The Campeona speaks and defends her traditional recipe")
	var palermitano_lines: Array = intro_dialogue.entries.filter(func(entry: Dictionary): return entry.speaker=="Empresario palermitano")
	check(palermitano_lines.size()==2 and palermitano_lines.all(func(entry: Dictionary): return "ura" not in String(entry.text).to_lower()),"Palermitano dialogue keeps its distinct voice without Tucuman idioms")
	var demo_ending = load("res://data/dialogues/demo_ending.tres")
	check(demo_ending != null and demo_ending.is_valid() and demo_ending.sequence_id==&"demo_ending_acheral","Demo ending is a valid short data-driven dialogue")
	var ending_palermitano_lines: Array = demo_ending.entries.filter(func(entry: Dictionary): return String(entry.speaker).begins_with("Empresario palermitano"))
	check(demo_ending.entries.size()==4 and demo_ending.entries.any(func(entry: Dictionary): return "Acheral" in String(entry.text)) and ending_palermitano_lines.all(func(entry: Dictionary): return "ura" not in String(entry.text).to_lower()),"Ending points to Acheral while preserving the Palermitano voice")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset_manifest.json"))
	check(manifest.images.size() == 100,"100 original images")
	for item: Dictionary in manifest.images:
		check(load(item.path) is Texture2D,"Texture imported: "+item.filename)
	var animation_count: int = 0
	for actor: String in ["player","hipster","agente","grandote","boss"]:
		var resource: SpriteFrames = load("res://assets/animations/"+actor+".tres")
		check(resource != null,"Animation resource: "+actor)
		animation_count += resource.get_animation_names().size()
		for animation: StringName in resource.get_animation_names():
			check(resource.get_frame_count(animation)>0,"Nonempty animation: "+animation)
	check(animation_count == 31,"Existing animation definitions plus the isolated three-frame Grandote ground slam")
	var library: SpriteFrames = load("res://assets/animations/asset_library.tres")
	check(library.get_animation_names().size()==100,"AnimatedSprite2D poses for all 100 images")
	for effect: String in root.get_node("AudioManager").EFFECTS:
		check(load("res://audio/"+effect+".wav") is AudioStreamWAV,"WAV: "+effect)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(4)
	var route = scene.get_node("Route38")
	route.set_physics_process(false)
	var player = route.get_node("Player")
	var hud = scene.get_node("Interface/HUD")
	var character_select = scene.get_node("Interface/CharacterSelect")
	var dialogue = scene.get_node("Interface/DialogueBox")
	var intro = scene.get_node("IntroFamailla")
	var traffic_director = route.get_node("TrafficDirector")
	var environment = route.get_node("Environment")
	var distant_background = environment.get_node("DistantBackground")
	var road_back = environment.get_node("RoadLayers/BackLane")
	var road_front = environment.get_node("RoadLayers/FrontLane")
	var environment_sprites: Array[Node] = environment.find_children("*","Sprite2D",true,false)
	check(environment is Node2D and environment.scene_file_path=="res://scenes/levels/route_38_environment.tscn","Route loads its reusable editor-composed environment scene")
	check(distant_background is Parallax2D and distant_background.scroll_scale==Vector2(0.05,1.0),"Distant mountains preserve their coherent slow horizontal parallax")
	check(distant_background.repeat_size==Vector2(1800,0) and distant_background.repeat_times>=2 and distant_background.get_node("MountainsB").flip_h,"Distant background alternates mirrored tiles to avoid visible edge gaps")
	check(road_back is Parallax2D and road_front is Parallax2D and road_back.scroll_scale==Vector2.ONE and road_front.scroll_scale==Vector2.ONE,"Both road planes remain anchored to gameplay coordinates")
	check(road_back.repeat_size==Vector2(700,0) and road_front.repeat_size==Vector2(700,0) and road_back.repeat_times>=2 and road_front.repeat_times>=2,"Road planes use declarative continuous repetition")
	check(environment.get_node("TownPanorama/Localities").texture.get_width()>=GameConfig.WORLD_WIDTH,"Locality panorama covers the complete route while remaining aligned to world space")
	check(environment_sprites.size()==19 and environment_sprites.all(func(sprite: Node): return sprite.get("texture") is Texture2D),"All 19 current environmental sprites have valid imported legacy textures")
	check(environment_sprites.all(func(sprite: Node): return sprite.get_script()==null) and environment.find_children("*","CollisionObject2D",true,false).is_empty(),"Static decoration has no per-prop scripts or gameplay collisions")
	check(environment.get_node("FamaillaLandmarks/EntranceSign").position.is_equal_approx(Vector2(271,291)) and environment.get_node_or_null("FamaillaLandmarks/RoadsideShrine")==null and is_equal_approx(environment.get_node("FamaillaLandmarks/CocaKiosk").position.x,1453.0001),"Current Famailla landmarks retain their intentional route composition")
	var route_stone_positions: Array = route.get_node("Objects").get_children().filter(func(item: Node): return item.get("kind")=="stone_pile").map(func(item: Node): return item.position.x)
	route_stone_positions.sort()
	check(route_stone_positions==[1250.0,4450.0] and absf(route_stone_positions[0]-environment.get_node("FamaillaLandmarks/CocaKiosk").position.x)>200.0,"Stone piles are independent pickups with clear space from the Coca kiosk")
	check(environment.get_node("RouteProps").get_child_count()==7 and environment.get_node("LightPosts").get_child_count()==3 and environment.get_node("LightPosts/LightPost06").position.is_equal_approx(Vector2(3800,271.475)) and environment.get_node("LightPosts/LightPost09").position.is_equal_approx(Vector2(5750,271.475)),"Current route props remain editable scene nodes with intentional spaced composition")
	var route_environment_source := FileAccess.get_file_as_string("res://scripts/core/route_38.gd")
	check("add_image" not in route_environment_source and "add_prop" not in route_environment_source and "Sprite2D.new" not in route_environment_source,"Route gameplay code no longer constructs static decoration procedurally")
	check(player is CharacterBody2D,"Player uses CharacterBody2D")
	check(player.character_definition==san_martin,"Player loads the San Martin definition")
	check(player.visual.sprite_frames==san_martin.sprite_frames and player.visual.scale==Vector2(0.42,0.42),"Player applies definition visuals without changing appearance")
	check(player.walk_speed==230.0 and player.gravity==1300.0 and player.jump_speed==580.0 and player.lane_duration==0.2,"Player applies existing movement values from data")
	check(player.health==3 and player.max_health==3 and player.lives==3,"Player applies existing health values from data")
	check(player.health_component.get_script().resource_path=="res://scripts/components/health_component.gd","Player uses the shared HealthComponent contract")
	check(player.hurtbox.combat_owner==player and player.hurtbox.health_component==player.health_component and player.hurtbox.team==&"player","Player exposes a Hurtbox connected to its HealthComponent")
	check(player.hurtbox.collision_shape.shape.size==player.get_node("CollisionShape2D").shape.size,"Player Hurtbox preserves the generated collision dimensions")
	check(hud._combo_component==player.combo_component and not hud.combo.visible,"HUD binds to the player's empty combo through signals")
	check(hud._special_counter==player.tucumanazo_counter and player.tucumanazo_counter.current_uses==5 and hud.special_status.text=="TUCUMANAZO x5" and not hud.has_node("SpecialBar"),"HUD binds to the five-use Tucumanazo counter without a charge bar")
	check(hud._health_component==player.health_component and hud._game_session==game_session and hud._player_status_source==player,"HUD binds health, session progress and player presentation through signals")
	var main_source := FileAccess.get_file_as_string("res://scripts/core/main.gd")
	var hud_source := FileAccess.get_file_as_string("res://scripts/core/hud.gd")
	check("hud.update_status" not in main_source and "func update_status" not in hud_source,"HUD no longer polls the complete Player state every frame")
	player.health_component.set_current_health(2)
	check(hud.life_bar.value==2 and hud.life_bar.max_value==player.max_health,"Health signal updates HUD immediately")
	player.health_component.restore_full(true)
	game_session.set_progress(123,4)
	check("PUNTOS 000123" in hud.status.text and "MONEDAS 004" in hud.status.text,"GameSession progress signal updates score and coins")
	game_session.set_progress(0,0)
	player.stones = 7
	player.oranges_unlocked = true
	player._emit_hud_status()
	check("NARANJAS ∞" in hud.location.text and "CASCOTES 7" in hud.location.text,"Player presentation event updates inventory HUD without frame polling")
	player.stones = 0
	player.oranges_unlocked = false
	player._emit_hud_status()
	hud.bind_game_session(game_session)
	hud.bind_game_session(game_session)
	check(game_session.progress_changed.is_connected(hud._on_progress_changed) and game_session.checkpoint_changed.is_connected(hud._on_checkpoint_changed),"Rebinding HUD keeps one valid signal contract across restart-style setup")
	var active_definition = player.character_definition
	check(not player.apply_character_definition(invalid_definition),"Player rejects an incomplete definition")
	check(player.character_definition==active_definition and not player.last_definition_error.is_empty(),"Rejected definition preserves the active character and explains the failure")
	check(scene.current_state==GAME_SESSION.DemoState.CHARACTER_SELECT and character_select.visible,"Main starts at CHARACTER_SELECT")
	var required_gamepad_actions: Array[StringName] = [
		&"move_left",&"move_right",&"lane_up",&"lane_down",&"jump",&"throw_orange",&"throw_stone",
		&"tucumanazo",&"pause",&"restart",&"select_previous",&"select_next",
		&"select_confirm",&"select_cancel",&"dialogue_advance",&"dialogue_skip"
	]
	check(required_gamepad_actions.all(func(action: StringName): return InputMap.action_get_events(action).any(func(event: InputEvent): return event is InputEventJoypadButton or event is InputEventJoypadMotion)),"Keyboard gameplay and every vertical-slice flow have semantic gamepad bindings")
	check(not InputMap.has_action(&"headbutt") and not player.has_method("start_headbutt") and not player.has_node("HeadbuttHitbox"),"Cabezazo has no independent runtime input, method or Hitbox")
	check(InputMap.action_get_events(&"move_left").any(func(event: InputEvent): return event is InputEventJoypadMotion and event.axis==JOY_AXIS_LEFT_X and event.axis_value<0.0) and InputMap.action_get_events(&"lane_down").any(func(event: InputEvent): return event is InputEventJoypadMotion and event.axis==JOY_AXIS_LEFT_Y and event.axis_value>0.0),"Left stick supports horizontal movement and lane changes")
	check(traffic_director.get_active_vehicle_count()==0 and traffic_director.enabled,"TrafficDirector initializes empty and ready for gameplay")
	check(game_session.demo_state==GAME_SESSION.DemoState.CHARACTER_SELECT,"GameSession tracks character selection state")
	check(not player.controls_enabled,"Character selection disables player controls")
	check(character_select.get_selected_definition().character_id==&"san_martin","San Martin is selected by default")
	var select_next_event := InputEventAction.new()
	select_next_event.action = &"select_next"
	select_next_event.pressed = true
	character_select._unhandled_input(select_next_event)
	check(character_select.get_selected_definition().character_id==&"atletico","Semantic navigation action moves selection to Atletico")
	check(not character_select.confirm_selected(),"Locked Atletico cannot be confirmed")
	var cancel_event := InputEventAction.new()
	cancel_event.action = &"select_cancel"
	cancel_event.pressed = true
	character_select._unhandled_input(cancel_event)
	check(character_select.get_selected_definition().character_id==&"san_martin","Cancel restores the safe default selection")
	check(character_select.confirm_selected(),"San Martin can be confirmed")
	check(scene.current_state==GAME_SESSION.DemoState.INTRO and intro.active and not player.controls_enabled,"Character selection transitions to INTRO and blocks player control")
	check(audio_manager.current_music_state==audio_manager.MUSIC_INTRO,"INTRO requests its music state")
	check(game_session.selected_character==&"san_martin" and player.character_definition.character_id==&"san_martin","Selection is saved and applied to Player")
	check(dialogue.active and dialogue.visible and dialogue.active_sequence.sequence_id==&"intro_famailla_san_martin","Intro begins its data-driven dialogue")
	check(intro.get_node("FadeLayer").visible,"Intro enables its fade layer only while the cinematic is active")
	check(not player.visual.visible and intro.protagonist_proxy.visible and intro.champion.visible and intro.palermitano.visible,"Intro presents protagonist, Campeona and Palermitano with provisional legacy visuals")
	var intro_initial_player_state: Dictionary = player.get_respawn_state().duplicate(true)
	var intro_initial_health: int = player.health
	var intro_initial_position: Vector2 = player.position
	var intro_completion_events: Array[bool] = []
	intro.completed.connect(func(skipped: bool): intro_completion_events.append(skipped))
	intro.animation_player.advance(0.6)
	intro._process(0.0)
	check(scene.camera.position.x < 400.0 and not scene.camera.position_smoothing_enabled,"Intro AnimationPlayer moves the camera away from gameplay framing")
	var intro_animation_position: float = intro.animation_player.current_animation_position
	scene.pause_game()
	check(scene.current_state==GAME_SESSION.DemoState.PAUSED and intro.active and dialogue.active,"Pause preserves the active intro and dialogue")
	check(is_equal_approx(intro.animation_player.current_animation_position,intro_animation_position),"Pause leaves the cinematic animation at its current position")
	scene.resume_game()
	check(scene.current_state==GAME_SESSION.DemoState.INTRO and intro.active and not player.controls_enabled,"Resume returns to INTRO without restoring combat control")
	var intro_encounter_director = route.encounter_director
	var intro_live_enemy_count := 0
	for encounter_id: StringName in intro_encounter_director.get_registered_encounter_ids():
		intro_live_enemy_count += intro_encounter_director.get_active_enemy_count(encounter_id)
	check(intro_live_enemy_count==0 and intro_encounter_director.get_completed_encounter_ids().is_empty(),"Encounters remain dormant throughout INTRO")
	var intro_traffic_delay: float = traffic_director.spawn_remaining
	route._physics_process(10.0)
	check(traffic_director.get_active_vehicle_count()==0 and is_equal_approx(traffic_director.spawn_remaining,intro_traffic_delay),"INTRO does not advance or spawn route traffic")
	while dialogue.active:
		dialogue.advance()
	check(scene.current_state==GAME_SESSION.DemoState.GAMEPLAY and player.controls_enabled and not intro.active,"Completing the intro enters GAMEPLAY and restores control once")
	check(audio_manager.current_music_state==audio_manager.MUSIC_GAMEPLAY,"Completing INTRO transitions to gameplay music")
	check(player.visual.visible and scene.camera.position==Vector2(400,225) and scene.camera.position_smoothing_enabled,"Completed intro restores player visibility and exact gameplay camera state")
	check(player.position==intro_initial_position and player.health==intro_initial_health and player.get_respawn_state()==intro_initial_player_state,"Playing the intro does not alter initial player state")
	var played_state: Dictionary = _capture_intro_result(scene)
	check(scene.begin_intro(),"The intro can be started again without duplicate actors or signals")
	var has_keyboard_intro_skip := false
	var has_gamepad_intro_skip := false
	for input_event in InputMap.action_get_events("dialogue_skip"):
		has_keyboard_intro_skip = has_keyboard_intro_skip or input_event is InputEventKey
		has_gamepad_intro_skip = has_gamepad_intro_skip or input_event is InputEventJoypadButton
	check(has_keyboard_intro_skip and has_gamepad_intro_skip,"Intro skip uses one clear semantic action for keyboard and gamepad")
	var intro_skip_event := InputEventAction.new()
	intro_skip_event.action = &"dialogue_skip"
	intro_skip_event.pressed = true
	dialogue._unhandled_input(intro_skip_event)
	check(not intro.active,"The complete intro can be skipped through its dialogue input contract")
	check(scene.current_state==GAME_SESSION.DemoState.GAMEPLAY and player.controls_enabled and _capture_intro_result(scene)==played_state,"Playing and skipping produce exactly the same gameplay state")
	check(intro_completion_events==[false,true],"Each intro path emits exactly one completion with its skip result")
	check(not dialogue.active and not dialogue.visible and not intro.get_node("FadeLayer").visible,"Intro cleanup leaves dialogue and its fade overlay inactive and hidden")
	var dialogue_started := [0]
	var dialogue_finished := [0]
	var dialogue_skipped := [false]
	dialogue.sequence_started.connect(func(_id: StringName): dialogue_started[0] += 1)
	dialogue.sequence_finished.connect(func(_id: StringName,skipped: bool): dialogue_finished[0] += 1; dialogue_skipped[0] = skipped)
	check(scene.start_dialogue(technical_dialogue),"A dialogue sequence can still start through Main's event-facing entry point")
	check(dialogue.active and dialogue.visible and not player.controls_enabled,"Dialogue blocks player control while active")
	check(dialogue.speaker_label.text=="Operador" and dialogue.text_label.text=="Primera línea de validación técnica.","Dialogue displays speaker and text from data")
	var has_keyboard_dialogue := false
	var has_gamepad_dialogue := false
	for input_event in InputMap.action_get_events("dialogue_advance"):
		has_keyboard_dialogue = has_keyboard_dialogue or input_event is InputEventKey
		has_gamepad_dialogue = has_gamepad_dialogue or input_event is InputEventJoypadButton
	check(has_keyboard_dialogue and has_gamepad_dialogue,"Dialogue advance uses the same semantic action for keyboard and gamepad")
	var dialogue_advance_event := InputEventAction.new()
	dialogue_advance_event.action = &"dialogue_advance"
	dialogue_advance_event.pressed = true
	dialogue._unhandled_input(dialogue_advance_event)
	check(dialogue.line_index==1 and dialogue.speaker_label.text=="Supervisora","Dialogue advances across multiple speakers")
	scene.pause_game()
	dialogue._unhandled_input(dialogue_advance_event)
	check(dialogue.active and dialogue.line_index==1 and not player.controls_enabled,"Pause preserves dialogue without advancing it")
	check(audio_manager.current_music_state==audio_manager.MUSIC_GAMEPLAY and audio_manager.sfx_paused and not audio_manager.music_player.stream_paused,"Pause preserves one music stream and blocks SFX playback")
	scene.resume_game()
	check(dialogue.active and not player.controls_enabled,"Resume preserves the active dialogue control lock")
	dialogue._unhandled_input(dialogue_advance_event)
	check(not dialogue.active and not dialogue.visible and player.controls_enabled,"Normal dialogue completion restores player control")
	check(dialogue_started[0]==1 and dialogue_finished[0]==1 and not dialogue_skipped[0],"Normal dialogue emits start and completion once")
	check(not dialogue.advance() and dialogue_finished[0]==1,"Inactive dialogue cannot emit duplicate completion")
	check(scene.start_dialogue(technical_dialogue) and dialogue.skip(),"Skippable dialogue can be omitted safely")
	check(not dialogue.active and player.controls_enabled and dialogue_finished[0]==2 and dialogue_skipped[0],"Skipping restores controls and emits one skipped completion")
	check(scene.start_dialogue(technical_dialogue),"Dialogue can start again after a safe skip")
	scene.change_state(GAME_SESSION.DemoState.INTRO)
	check(not dialogue.active and not player.controls_enabled,"Changing flow state cancels active dialogue without unlocking non-gameplay control")
	scene.change_state(GAME_SESSION.DemoState.GAMEPLAY)
	check(player.controls_enabled,"Returning to gameplay restores control after flow cancellation")
	var traffic_warning_count := [0]
	traffic_director.vehicle_warning.connect(func(_lane: int,_direction: int): traffic_warning_count[0] += 1)
	check(traffic_director.spawn_now(1000.0)==null,"Traffic remains inactive outside its configured route section")
	var traffic_player_position: Vector2 = player.position
	var traffic_player_lane: int = player.lane_index
	player.position = Vector2(2500,GameConfig.LANES[0])
	player.lane_index = 0
	player.hurtbox.lane_index = 0
	var first_vehicle = traffic_director.spawn_now(player.position.x)
	var second_vehicle = traffic_director.spawn_now(player.position.x)
	check(first_vehicle != null and first_vehicle is AnimatableBody2D and first_vehicle.asset_id==&"auto1" and first_vehicle.lane_index==0 and first_vehicle.direction==-1 and is_equal_approx(first_vehicle.image_scale,0.84) and first_vehicle.base_speed==160.0 and first_vehicle.current_speed==160.0 and first_vehicle.impact_hitbox.attack_definition.reach.is_equal_approx(Vector2(128.1168,47.4096)),"Traffic spawns an interactive compact auto with its reduced base speed and lane-specific body")
	check(second_vehicle != null and second_vehicle.asset_id==&"auto2" and second_vehicle.lane_index==1 and second_vehicle.direction==1 and is_equal_approx(second_vehicle.image_scale,1.10) and second_vehicle.base_speed==180.0,"Traffic supports the faster calibrated yellow auto and opposite lane flow")
	check(absf(first_vehicle.position.x-player.position.x)>=traffic_director.camera_half_width+traffic_director.offscreen_margin and absf(second_vehicle.position.x-player.position.x)>=traffic_director.camera_half_width+traffic_director.offscreen_margin,"Vehicles spawn outside the camera and player safety area")
	var compact_auto_reach: float = first_vehicle.impact_hitbox.attack_definition.reach.x
	var first_roof_shape := first_vehicle.roof_collision.shape as RectangleShape2D
	var first_impact_shape := first_vehicle.impact_hitbox.collision_shape.shape as RectangleShape2D
	var first_impact_top: float = first_vehicle.impact_hitbox.collision_shape.position.y-first_impact_shape.size.y*0.5
	var first_roof_bottom: float = first_vehicle.roof_collision.position.y+first_roof_shape.size.y*0.5
	check(first_vehicle.collision_layer==(1<<first_vehicle.lane_index) and first_roof_shape.size.is_equal_approx(Vector2(124.32,8.0)) and first_vehicle.roof_collision.one_way_collision,"Mobile auto exposes only its scale-derived one-way roof on the matching lane")
	check(first_impact_top>first_roof_bottom and first_vehicle.projectile_target.collision_layer==GameConfig.ENEMY_LAYER,"Safe roof is vertically separated from the lower traffic damage and projectile target region")
	check(traffic_warning_count[0]==2,"Each vehicle emits one warning before entering the visible route")
	check(traffic_director.get_active_vehicle_count()==traffic_director.max_simultaneous and traffic_director.spawn_now(player.position.x)==null,"TrafficDirector enforces its simultaneous vehicle budget")
	player.health_component.restore_full(true)
	var health_before_traffic: int = player.health
	check(first_vehicle.impact_hitbox.try_hit(player.hurtbox) and player.health==health_before_traffic-1,"Vehicle damage reaches Player through Hitbox, Hurtbox and HealthComponent")
	check(not first_vehicle.impact_hitbox.try_hit(player.hurtbox) and not second_vehicle.impact_hitbox.try_hit(player.hurtbox),"A vehicle cannot duplicate one impact and a different lane cannot hit Player")
	var slowdown_orange = PROJECTILE_SCENE.instantiate()
	slowdown_orange.kind = &"orange"
	slowdown_orange.team = &"player"
	slowdown_orange.lane_index = first_vehicle.lane_index
	route.get_node("Projectiles").add_child(slowdown_orange)
	slowdown_orange.set_physics_process(false)
	slowdown_orange._resolve_collision(first_vehicle.projectile_target)
	var speed_after_first_hit: float = first_vehicle.current_speed
	slowdown_orange._resolve_collision(first_vehicle.projectile_target)
	check(slowdown_orange.spent and is_equal_approx(speed_after_first_hit,first_vehicle.base_speed*0.8) and first_vehicle.current_speed==speed_after_first_hit,"One Naranjazo is consumed once and reduces vehicle speed to 80 percent")
	for slowdown_kind: StringName in [&"stone",&"orange",&"stone"]:
		var slowdown_projectile = PROJECTILE_SCENE.instantiate()
		slowdown_projectile.kind = slowdown_kind
		slowdown_projectile.team = &"player"
		slowdown_projectile.lane_index = first_vehicle.lane_index
		route.get_node("Projectiles").add_child(slowdown_projectile)
		slowdown_projectile.set_physics_process(false)
		slowdown_projectile._resolve_collision(first_vehicle.projectile_target)
		check(slowdown_projectile.spent,"Valid vehicle slowdown projectile is consumed: "+String(slowdown_kind))
	check(is_equal_approx(first_vehicle.get_speed_ratio(),0.55) and first_vehicle.current_speed>0.0,"Repeated hits accumulate only to the configurable 55 percent speed floor")
	var wrong_lane_projectile = PROJECTILE_SCENE.instantiate()
	wrong_lane_projectile.kind = &"orange"
	wrong_lane_projectile.team = &"player"
	wrong_lane_projectile.lane_index = 1-first_vehicle.lane_index
	route.get_node("Projectiles").add_child(wrong_lane_projectile)
	wrong_lane_projectile.set_physics_process(false)
	wrong_lane_projectile._resolve_collision(first_vehicle.projectile_target)
	check(not wrong_lane_projectile.spent and is_equal_approx(first_vehicle.get_speed_ratio(),0.55),"Opposite-lane projectile cannot affect or be consumed by a vehicle")
	wrong_lane_projectile.queue_free()
	first_vehicle._update_slowdown(1.5)
	var minimum_vehicle_speed: float = first_vehicle.current_speed
	first_vehicle._update_slowdown(1.0)
	var recovering_vehicle_speed: float = first_vehicle.current_speed
	first_vehicle._update_slowdown(1.0)
	check(is_equal_approx(minimum_vehicle_speed,first_vehicle.base_speed*0.55) and recovering_vehicle_speed>minimum_vehicle_speed and is_equal_approx(first_vehicle.current_speed,first_vehicle.base_speed),"Vehicle waits 1.5 seconds then progressively recovers from minimum to base speed within two seconds")
	first_vehicle._update_hit_feedback(first_vehicle.impact_flash_duration)
	check(first_vehicle.visual.modulate==Color.WHITE,"Projectile slowdown flash clears without leaving stale modulation")
	var distant_player_x: float = first_vehicle.position.x-traffic_director.camera_half_width-traffic_director.despawn_margin-1.0
	traffic_director.update_traffic(0.0,distant_player_x)
	check(traffic_director.get_active_vehicle_count()==1,"Traffic despawns vehicles after they leave the camera margin")
	var third_vehicle = traffic_director.spawn_now(player.position.x)
	check(third_vehicle != null and third_vehicle.asset_id==&"auto3" and third_vehicle.lane_index==0 and is_equal_approx(third_vehicle.image_scale,0.95) and third_vehicle.base_speed==160.0,"Traffic sequence adds compatible auto3 as an interactive compact variant")
	traffic_director.reset_runtime_state(true)
	await frames(2)
	traffic_director.sequence_index = 3
	var truck_vehicle = traffic_director.spawn_now(player.position.x)
	check(truck_vehicle != null and truck_vehicle.asset_id==&"camion_limones" and is_equal_approx(truck_vehicle.image_scale,1.25) and truck_vehicle.base_speed==125.0 and truck_vehicle.impact_hitbox.attack_definition.reach.is_equal_approx(Vector2(194.75,74.8)) and truck_vehicle.roof_collision.shape.size.is_equal_approx(Vector2(190.0,8.0)) and truck_vehicle.impact_hitbox.attack_definition.reach.x>compact_auto_reach,"Interactive lemon truck is larger and slower than compact traffic")
	traffic_director.reset_runtime_state(true)
	await frames(2)
	traffic_director.sequence_index = 4
	var exprebus_vehicle = traffic_director.spawn_now(player.position.x)
	check(exprebus_vehicle != null and exprebus_vehicle.asset_id==&"exprebus" and is_equal_approx(exprebus_vehicle.image_scale,1.15) and exprebus_vehicle.base_speed==130.0 and exprebus_vehicle.roof_collision.shape.size.is_equal_approx(Vector2(182.16,8.0)) and exprebus_vehicle.impact_hitbox.attack_definition.reach.x>compact_auto_reach,"Exprebus uses the shared interactive roof, slowdown and traffic damage contract")
	traffic_director.reset_runtime_state(true)
	await frames(2)
	traffic_director.sequence_index = 5
	var tesa_vehicle = traffic_director.spawn_now(player.position.x)
	check(tesa_vehicle != null and tesa_vehicle.asset_id==&"tesa" and is_equal_approx(tesa_vehicle.image_scale,1.30) and tesa_vehicle.base_speed==130.0 and tesa_vehicle.roof_collision.shape.size.is_equal_approx(Vector2(208.0,8.0)) and tesa_vehicle.impact_hitbox.attack_definition.reach.x>compact_auto_reach,"Tesa uses the shared interactive roof, slowdown and traffic damage contract")
	var traffic_bus_assets: Array = traffic_director.VEHICLE_CONFIGS.filter(func(config: Dictionary): return String(config.asset).contains("bus") or config.asset==&"tesa").map(func(config: Dictionary): return config.asset)
	check(traffic_bus_assets==[&"exprebus",&"tesa"] and not traffic_bus_assets.has(&"bus1"),"Ruta 38 traffic preserves only Exprebus and Tesa bus assets")
	traffic_director.reset_runtime_state(true)
	await frames(2)
	check(traffic_director.get_active_vehicle_count()==0 and traffic_director.sequence_index==0 and is_equal_approx(traffic_director.spawn_remaining,traffic_director.initial_spawn_delay),"Traffic reset is empty and deterministic")
	var mobile_roof_vehicle = VEHICLE_SCENE.instantiate()
	mobile_roof_vehicle.configure(&"auto1",0.84,0,1,160.0)
	mobile_roof_vehicle.position = Vector2(2350.0,GameConfig.LANES[0])
	mobile_roof_vehicle.active = false
	route.get_node("Vehicles").add_child(mobile_roof_vehicle)
	await frames(2)
	player.lane_index = 0
	player.hurtbox.lane_index = 0
	player.collision_mask = 1 << 0
	player.hurtbox.set_receiving_enabled(false)
	player.position = Vector2(mobile_roof_vehicle.position.x,mobile_roof_vehicle.get_roof_world_y()+32.0)
	player.velocity = Vector2(0.0,-500.0)
	await frames(8)
	check(player.position.y<mobile_roof_vehicle.get_roof_world_y()-4.0,"Player passes upward through the mobile one-way roof")
	player.hurtbox.set_receiving_enabled(true)
	player.health_component.restore_full(true)
	player.position = Vector2(mobile_roof_vehicle.position.x,mobile_roof_vehicle.get_roof_world_y()-65.0)
	player.velocity = Vector2.ZERO
	var roof_health_before: int = player.health
	await frames(50)
	check(player.is_on_floor() and absf(player.position.y-mobile_roof_vehicle.get_roof_world_y())<2.0 and player.health==roof_health_before,"Player lands on the mobile one-way roof without receiving traffic damage")
	var roof_relative_x: float = player.position.x-mobile_roof_vehicle.position.x
	mobile_roof_vehicle.active = true
	await frames(12)
	check(absf((player.position.x-mobile_roof_vehicle.position.x)-roof_relative_x)<2.0 and player.get_platform_velocity().x>0.0,"AnimatableBody2D roof carries Player with horizontal vehicle motion")
	player.health_component.restore_full(true)
	player.health_component.set_invulnerability(0.0)
	var side_contact_health: int = player.health
	player.position = Vector2(mobile_roof_vehicle.position.x+mobile_roof_vehicle.impact_hitbox.attack_definition.reach.x*0.4,GameConfig.LANES[0])
	player.velocity = Vector2.ZERO
	await frames(3)
	check(player.health==side_contact_health-1,"Lower lateral contact still applies exactly one traffic damage outside the safe roof")
	mobile_roof_vehicle.request_despawn()
	mobile_roof_vehicle.queue_free()
	await frames(2)
	traffic_director.sequence_index = 0
	var reset_vehicle = traffic_director.spawn_now(2500.0)
	check(reset_vehicle != null and reset_vehicle.current_speed==reset_vehicle.base_speed and reset_vehicle.get_speed_ratio()==1.0,"Fresh traffic after reset has no stale slowdown state")
	traffic_director.reset_runtime_state(true)
	await frames(2)
	player.position = traffic_player_position
	player.lane_index = traffic_player_lane
	player.hurtbox.lane_index = traffic_player_lane
	player.collision_mask = 1 << traffic_player_lane
	player.health_component.restore_full(true)
	var has_keyboard_selection := false
	var has_gamepad_selection := false
	for input_event in InputMap.action_get_events("select_next"):
		has_keyboard_selection = has_keyboard_selection or input_event is InputEventKey
		has_gamepad_selection = has_gamepad_selection or input_event is InputEventJoypadButton
	check(has_keyboard_selection,"Keyboard maps the semantic selection navigation action")
	check(has_gamepad_selection,"Gamepad maps the same semantic selection navigation action")
	var has_keyboard_tucumanazo := false
	var has_gamepad_tucumanazo := false
	for input_event in InputMap.action_get_events("tucumanazo"):
		has_keyboard_tucumanazo = has_keyboard_tucumanazo or input_event is InputEventKey
		has_gamepad_tucumanazo = has_gamepad_tucumanazo or input_event is InputEventJoypadButton
	check(has_keyboard_tucumanazo and has_gamepad_tucumanazo,"Tucumanazo uses one semantic action for keyboard and gamepad")
	var controls_before_special_gate: bool = player.controls_enabled
	player.controls_enabled = false
	check(not player.start_tucumanazo() and player.tucumanazo_counter.current_uses==5,"Tucumanazo cannot activate while controls are disabled or consume stock")
	player.controls_enabled = controls_before_special_gate
	game_session.set_selected_character(&"invalid_character")
	check(game_session.resolve_character_definition(game_session.selected_character).character_id==&"san_martin","Invalid selected identifier resolves to San Martin fallback")
	game_session.set_selected_character(&"san_martin")
	var encounter_director = route.encounter_director
	var lane_readability = route.get_node("LaneReadability")
	check(lane_readability != null and lane_readability.has_method("_draw") and lane_readability.z_index==1,"Route includes a presentation-only lane readability overlay behind gameplay actors")
	var registered_encounters: Array[StringName] = encounter_director.get_registered_encounter_ids()
	check(registered_encounters.size()==8 and registered_encounters[0]==&"route_wave_01" and registered_encounters.has(&"route_drone_01") and registered_encounters.has(&"route_drone_02") and registered_encounters.has(&"route_drone_03") and registered_encounters[-1]==&"route_wave_06" and not encounter_director.has_encounter(&"route_miniboss_grandote"),"Route registers its three-step Drone progression alongside the ground encounters")
	var encounter_source := FileAccess.get_file_as_string("res://scripts/core/route_38.gd")
	check("data.waves" not in encounter_source and "activated_waves" not in encounter_source,"Route delegates wave activation state to EncounterDirector")
	var started_encounters: Array[StringName] = []
	var completed_encounters: Array[StringName] = []
	encounter_director.encounter_started.connect(func(encounter_id: StringName): started_encounters.append(encounter_id))
	encounter_director.encounter_completed.connect(func(encounter_id: StringName): completed_encounters.append(encounter_id))
	encounter_director.update_activation(899.0)
	check(not encounter_director.is_encounter_activated(&"route_wave_01"),"Encounter remains dormant before its activation condition")
	encounter_director.update_activation(900.0)
	var first_encounter_enemies: Array[Node] = encounter_director.get_active_enemies(&"route_wave_01")
	for encounter_enemy in first_encounter_enemies:
		encounter_enemy.set_physics_process(false)
	check(started_encounters==[&"route_wave_01"] and first_encounter_enemies.size()==2,"Encounter activates once and creates its configured enemies")
	encounter_director.update_activation(900.0)
	check(not encounter_director.activate_encounter(&"route_wave_01",900.0) and encounter_director.get_active_enemy_count(&"route_wave_01")==2 and started_encounters.size()==1,"An active encounter cannot be activated or spawned twice")
	check(first_encounter_enemies[0].lane_index==0 and first_encounter_enemies[1].lane_index==1 and first_encounter_enemies.all(func(active_enemy): return active_enemy.archetype=="hipster"),"Encounter applies configured spawn types and lanes")
	check(encounter_director.activate_encounter(&"route_wave_04",4700.0),"An independent encounter can activate while another remains active")
	var mixed_encounter_enemies: Array[Node] = encounter_director.get_active_enemies(&"route_wave_04")
	for encounter_enemy in mixed_encounter_enemies:
		encounter_enemy.set_physics_process(false)
	var mixed_types: Array[String] = []
	for encounter_enemy in mixed_encounter_enemies:
		mixed_types.append(encounter_enemy.archetype)
	mixed_types.sort()
	check(mixed_types==["agente","grandote"] and mixed_encounter_enemies[0].lane_index!=mixed_encounter_enemies[1].lane_index,"Mixed encounter creates data-driven melee and ranged enemies on configured lanes")
	var encounter_score_before: int = player.score
	first_encounter_enemies[0].take_damage(999,&"player")
	first_encounter_enemies[0].take_damage(999,&"player")
	check(encounter_director.get_active_enemy_count(&"route_wave_01")==1 and player.score==encounter_score_before+75,"Defeating one tracked enemy updates the live count and awards its reward once")
	check(encounter_director.get_active_enemy_count(&"route_wave_04")==2 and not encounter_director.is_encounter_completed(&"route_wave_04"),"Independent encounter counts do not interfere")
	first_encounter_enemies[1].queue_free()
	await frames(2)
	check(encounter_director.is_encounter_completed(&"route_wave_01") and encounter_director.get_active_enemy_count(&"route_wave_01")==0,"Encounter completes when no configured enemies remain")
	check(completed_encounters.count(&"route_wave_01")==1 and encounter_director.get_active_enemies(&"route_wave_01").is_empty(),"Completion emits once and releases eliminated enemy references")
	for encounter_enemy in mixed_encounter_enemies:
		encounter_enemy.take_damage(999,&"player")
	check(encounter_director.is_encounter_completed(&"route_wave_04") and completed_encounters.count(&"route_wave_04")==1,"Mixed encounter completes once after both enemy roles are defeated")
	check(encounter_director.get_completed_encounter_ids()==[&"route_wave_01",&"route_wave_04"],"Stable completed encounter ids are available for future checkpoint restoration")
	var first_mixed_signature: Array[String] = []
	for encounter_enemy in mixed_encounter_enemies:
		first_mixed_signature.append("%s:%d" % [encounter_enemy.archetype,encounter_enemy.lane_index])
	first_mixed_signature.sort()
	encounter_director.reset_runtime_state(true)
	await frames(2)
	check(encounter_director.get_completed_encounter_ids().is_empty() and not encounter_director.is_encounter_activated(&"route_wave_01"),"Encounter runtime state resets deterministically without checkpoint persistence")
	check(encounter_director.activate_encounter(&"route_wave_04",4700.0),"Reset encounter can be activated again in a new runtime state")
	var reset_mixed_enemies: Array[Node] = encounter_director.get_active_enemies(&"route_wave_04")
	var reset_mixed_signature: Array[String] = []
	for encounter_enemy in reset_mixed_enemies:
		encounter_enemy.set_physics_process(false)
		reset_mixed_signature.append("%s:%d" % [encounter_enemy.archetype,encounter_enemy.lane_index])
	reset_mixed_signature.sort()
	check(reset_mixed_signature==first_mixed_signature and reset_mixed_enemies.size()==2,"Reset recreates the same encounter composition")
	encounter_director.reset_runtime_state(true)
	await frames(2)
	check(encounter_director.activate_encounter(&"route_drone_01",4100.0),"First Drone encounter activates independently before the Grandote zone")
	var drone_enemies: Array[Node] = encounter_director.get_active_enemies(&"route_drone_01")
	var drone = drone_enemies[0]
	drone.set_physics_process(false)
	var drone_lane_shadow = drone.get_node("LaneShadow")
	await frames(1)
	check(drone_enemies.size()==1 and drone is Node2D and not drone is CharacterBody2D and not drone.uses_gravity and drone.position.y==GameConfig.LANES[0]-drone.flight_height and is_equal_approx(drone_lane_shadow.ground_y,GameConfig.LANES[drone.lane_index]),"Drone remains a single aerial Node2D with a presentation-only ground anchor on its assigned lane")
	var drone_entry_x: float = drone.position.x
	drone._process_entry(0.1)
	check(drone.ai_state==drone.AIState.ENTRY and drone.position.x<drone_entry_x and is_equal_approx(drone.flight_anchor_y,GameConfig.LANES[0]-drone.flight_height),"Drone enters horizontally while retaining its configured aerial height")
	drone.position.x = player.position.x+drone.definition.preferred_distance
	drone._process_entry(0.01)
	check(drone.ai_state==drone.AIState.IDLE and drone.visual.animation==&"idle","Drone finishes entry in its reusable idle state")
	var initial_reticle_radius: float = drone.aim_reticle.current_radius
	check(drone._begin_aim() and drone.ai_state==drone.AIState.AIM and drone.visual.animation==&"aim" and drone.aim_reticle.active,"Drone aim state exposes a visible world-space red reticle")
	var player_before_drone_lock: Vector2 = player.position
	drone._process_aim(0.69)
	check(drone.aim_reticle.active and drone.aim_reticle.current_radius>initial_reticle_radius and drone.aim_reticle.charge_progress>=0.69 and not drone.aim_target_locked,"Drone reticle follows Player and grows during the first 0.69 seconds of telegraph")
	player.position += Vector2(96.0,0.0)
	drone._process_aim(0.01)
	var drone_locked_target: Vector2 = drone.locked_target_position
	check(drone.aim_target_locked and drone_locked_target.is_equal_approx(player.position+Vector2(0.0,-35.0)) and drone.aim_reticle.global_position.is_equal_approx(drone_locked_target),"Drone locks its reticle at exactly 0.70 seconds")
	player.position += Vector2(96.0,0.0)
	drone._process_aim(0.29)
	check(drone.ai_state==drone.AIState.AIM and drone.aim_reticle.global_position.is_equal_approx(drone_locked_target),"Drone retains the locked target for the final 0.30-second escape window")
	player.position = player_before_drone_lock
	var drone_projectile_count_before: int = route.get_node("Projectiles").get_child_count()
	drone._process_aim(0.01)
	var drone_bolt = route.get_node("Projectiles").get_child(-1)
	drone_bolt.set_physics_process(false)
	check(drone.ai_state==drone.AIState.FIRE and drone.visual.animation==&"fire" and not drone.aim_reticle.active and drone.shots_emitted==1 and route.get_node("Projectiles").get_child_count()==drone_projectile_count_before+1,"Drone fires once at full charge and immediately clears its reticle")
	check(drone_bolt.kind==&"drone_bolt" and drone_bolt.damage==1 and drone_bolt.speed==320.0 and drone_bolt.definition.lifetime==3.0,"Drone red bolt uses its one-damage ProjectileDefinition values")
	var locked_bolt_direction: Vector2 = drone_bolt.travel_direction
	var locked_bolt_rotation: float = drone_bolt.visual.rotation
	var bolt_start: Vector2 = drone_bolt.position
	var player_position_before_drone_shot: Vector2 = player.position
	player.position += Vector2(120.0,0.0)
	drone_bolt._physics_process(0.05)
	player.position = player_position_before_drone_shot
	var bolt_displacement: Vector2 = drone_bolt.position-bolt_start
	check(absf(bolt_displacement.normalized().cross(locked_bolt_direction))<0.0001 and drone_bolt.travel_direction.is_equal_approx(locked_bolt_direction),"Drone bolt travels straight toward the locked position and is not homing")
	check(is_equal_approx(bolt_displacement.length(),drone_bolt.speed*0.05) and is_equal_approx(drone_bolt.visual.rotation,locked_bolt_rotation),"Drone bolt preserves speed and stable one-time visual orientation")
	drone._process_fire(drone.definition.projectile_release_duration)
	check(drone.ai_state==drone.AIState.COOLDOWN and is_equal_approx(drone.cooldown_remaining,2.0),"Drone enters its two-second cooldown after the fire pose")
	drone._process_cooldown(drone.definition.attack_cooldown)
	check(drone.ai_state==drone.AIState.IDLE,"Drone returns from cooldown to idle")
	var vertical_shot = PROJECTILE_SCENE.instantiate()
	vertical_shot.kind = &"orange"
	vertical_shot.team = &"player"
	vertical_shot.lane_index = drone.lane_index
	vertical_shot.travel_direction = Vector2.UP
	root.add_child(vertical_shot)
	var diagonal_shot = PROJECTILE_SCENE.instantiate()
	diagonal_shot.kind = &"orange"
	diagonal_shot.team = &"player"
	diagonal_shot.lane_index = drone.lane_index
	diagonal_shot.travel_direction = Vector2(1,-1)
	root.add_child(diagonal_shot)
	check(vertical_shot._try_hurtbox(drone.hurtbox) and drone.health==2,"Drone Hurtbox receives a vertical Naranjazo on its assigned lane")
	drone.health_component.set_invulnerability(0.0)
	check(diagonal_shot._try_hurtbox(drone.hurtbox) and drone.health==1,"Drone Hurtbox receives a diagonal Naranjazo through the shared projectile contract")
	var drone_shots_before_death: int = drone.shots_emitted
	check(drone._begin_aim() and drone.aim_reticle.active,"Drone can begin another telegraph after cooldown")
	drone.health_component.set_invulnerability(0.0)
	drone.take_damage(99,&"player")
	check(drone.ai_state==drone.AIState.DEAD and not drone.active and not drone.aim_reticle.active and drone.shots_emitted==drone_shots_before_death,"Drone death clears pending aim feedback without emitting a delayed projectile")
	check(encounter_director.is_encounter_completed(&"route_drone_01") and encounter_director.get_active_enemy_count(&"route_drone_01")==0,"EncounterDirector counts the first Drone defeat as a normal encounter completion")
	drone_bolt.queue_free()
	vertical_shot.queue_free()
	diagonal_shot.queue_free()
	encounter_director.reset_runtime_state(true)
	await frames(2)
	check(encounter_director.activate_encounter(&"route_drone_02",5400.0),"Second Drone encounter activates after the first wave is completed")
	var second_drone_enemies: Array[Node] = encounter_director.get_active_enemies(&"route_drone_02")
	check(second_drone_enemies.size()==2 and second_drone_enemies.all(func(enemy: Node): return enemy.get("archetype")=="drone") and second_drone_enemies[0].lane_index!=second_drone_enemies[1].lane_index,"Second Drone encounter creates exactly two aerial enemies on separate lanes")
	for second_drone in second_drone_enemies:
		second_drone.set_physics_process(false)
		second_drone.take_damage(999,&"player")
	check(encounter_director.is_encounter_completed(&"route_drone_02") and encounter_director.get_active_enemies(&"route_drone_02").is_empty(),"Completing the two-Drone wave leaves no tracked aerial actors")
	check(encounter_director.activate_encounter(&"route_drone_03",6100.0),"Third Drone encounter activates after the completed two-Drone wave")
	var mixed_drone_enemies: Array[Node] = encounter_director.get_active_enemies(&"route_drone_03")
	var mixed_drone_types: Array[String] = []
	for mixed_drone_enemy in mixed_drone_enemies:
		mixed_drone_enemy.set_physics_process(false)
		mixed_drone_types.append(mixed_drone_enemy.archetype)
	mixed_drone_types.sort()
	check(mixed_drone_enemies.size()==2 and mixed_drone_types==["agente","drone"],"Third Drone encounter creates exactly one Drone and one Agente")
	for mixed_drone_enemy in mixed_drone_enemies:
		mixed_drone_enemy.take_damage(999,&"player")
	check(encounter_director.is_encounter_completed(&"route_drone_03") and encounter_director.get_active_enemies(&"route_drone_03").is_empty(),"Mixed Drone encounter completes cleanly without orphaned actors")
	encounter_director.reset_runtime_state(true)
	await frames(2)
	var grandote_frames: SpriteFrames = load("res://assets/animations/grandote.tres")
	var slam_textures := ["res://assets/grandote_golpe_suelo1.png","res://assets/grandote_golpe_suelo2.png","res://assets/grandote_golpe_suelo3.png"]
	check(grandote_frames.has_animation(&"grandote_ground_slam") and grandote_frames.get_frame_count(&"grandote_ground_slam")==3,"Grandote ground slam has exactly three frames")
	check(range(3).all(func(frame: int): return grandote_frames.get_frame_texture(&"grandote_ground_slam",frame).resource_path==slam_textures[frame]),"Ground slam loads golpe_suelo1, golpe_suelo2 and golpe_suelo3 in order")
	var elite = route.spawn_enemy("grandote",player.position.x+240.0,player.lane_index)
	elite.set_physics_process(false)
	await frames(2)
	check(elite.is_in_group("elite_enemy") and not elite.is_in_group("miniboss") and elite.health==10 and elite.definition.reward_points==300,"El Grandote spawns as a normal tracked elite with normal health and reward")
	check(not hud.boss_bar.visible and not hud.boss_name.visible and traffic_director.enabled and scene.camera_follow_min_x==400.0,"Spawning El Grandote does not activate boss HUD, arena lock or traffic suppression")
	var waves_before: int = route.get_node("Projectiles").get_child_count()
	check(elite._begin_ground_slam() and elite.ai_state==elite.AIState.TELEGRAPH and elite.visual.frame==0 and elite.visual.position.is_equal_approx(elite.definition.visual_offset+Vector2(0,2)),"Medium-range ground slam begins with a grounded frame 1 and a 0.24 s telegraph")
	check(not elite._begin_ground_slam() and elite.ground_waves_emitted==0,"No second attack can begin during the ground-slam telegraph")
	elite._advance_attack_state(elite.GRANDOTE_SLAM_DEFINITION.startup_duration+0.01)
	check(elite.ai_state==elite.AIState.ATTACK and elite.visual.frame==1 and elite.visual.position.is_equal_approx(elite.definition.visual_offset+Vector2(0,8)) and elite.ground_waves_emitted==0,"Ground-slam frame 2 uses its grounded visual offset and does not emit early")
	elite._advance_attack_state(elite.GRANDOTE_SLAM_DEFINITION.active_duration+0.01)
	var spawned_waves: Array[Node] = route.get_node("Projectiles").get_children().filter(func(child: Node): return child is GrandoteGroundWave)
	var wave: GrandoteGroundWave = spawned_waves[0]
	wave.set_physics_process(false)
	check(elite.ai_state==elite.AIState.RECOVERY and elite.visual.frame==2 and elite.visual.position.is_equal_approx(elite.definition.visual_offset+Vector2(0,28)) and elite.ground_waves_emitted==1 and route.get_node("Projectiles").get_child_count()==waves_before+1,"Wave emits once exactly when the grounded visible impact frame 3 appears")
	check(wave.attack_definition.damage==1 and wave.speed==300.0 and wave.lifetime==1.4 and wave.max_distance==420.0,"Ground wave uses its explicit damage, speed, lifetime and distance limits")
	var wave_start: Vector2 = wave.position
	wave._physics_process(0.1)
	check(is_equal_approx(absf(wave.position.x-wave_start.x),30.0) and wave.position.y==wave_start.y and wave.lane_index==elite.lane_index,"Ground wave travels straight and remains locked to Grandote's lane")
	var player_position_before_wave: Vector2 = player.position
	player.position.y = GameConfig.LANES[player.lane_index]-60.0
	check(not wave.can_hit_body(player),"A jump higher than the wave clearance avoids the ground attack")
	player.position.y = GameConfig.LANES[player.lane_index]
	check(wave.can_hit_body(player),"A grounded player in the same lane is a valid wave target")
	wave.lane_index = 1-player.lane_index
	check(not wave.can_hit_body(player),"Ground wave cannot hit across lanes")
	wave.queue_free()
	player.position = player_position_before_wave
	elite._advance_attack_state(elite.GRANDOTE_SLAM_DEFINITION.recovery_duration+0.01)
	check(elite.ai_state==elite.AIState.CHASE and elite.visual.position.is_equal_approx(elite.definition.visual_offset) and not elite._begin_ground_slam(),"Ground-slam recovery restores the normal visual anchor while its 2.20 s cooldown prevents spam")
	elite.ground_slam_cooldown = 0.0
	elite.attack_cooldown = 0.0
	elite._begin_attack()
	check(elite.ai_state==elite.AIState.TELEGRAPH and elite.active_attack_kind==elite.AttackKind.PRIMARY and not elite.melee_hitbox.active,"Close punch retains a brief telegraph with an inactive Hitbox")
	elite._advance_attack_state(elite.definition.telegraph_duration+0.01)
	check(elite.ai_state==elite.AIState.ATTACK and elite.melee_hitbox.active,"Close punch activates its Hitbox only in the impact window")
	elite._advance_attack_state(elite.definition.get_active_duration()+0.01)
	check(elite.ai_state==elite.AIState.RECOVERY and not elite.melee_hitbox.active,"Close punch deactivates its Hitbox for clear recovery")
	elite.queue_free()
	await frames(2)
	check(encounter_director.activate_encounter(&"route_wave_06",7000.0),"EncounterDirector activates the normal heavy-enemy wave after the Drone progression")
	var elite_wave_enemies: Array[Node] = encounter_director.get_active_enemies(&"route_wave_06")
	var elite_reward_start: int = player.score
	for heavy_enemy in elite_wave_enemies:
		heavy_enemy.set_physics_process(false)
		heavy_enemy.take_damage(999,&"player")
	check(elite_wave_enemies.size()==2 and encounter_director.is_encounter_completed(&"route_wave_06") and player.score==elite_reward_start+600,"EncounterDirector counts Grandotes as normal enemies and completes their wave once")
	check(not scene.demo_closing and scene.current_state==GAME_SESSION.DemoState.GAMEPLAY and not hud.boss_bar.visible,"Grandote defeat does not trigger RESULT, ending dialogue or boss HUD")
	check(traffic_director.enabled and scene.camera_follow_min_x==400.0 and scene.camera_follow_max_x==GameConfig.WORLD_WIDTH-400.0,"Grandote defeat leaves traffic and normal camera framing intact")
	encounter_director.reset_runtime_state(true)
	await frames(2)
	player.score = encounter_score_before
	player.status_changed.emit()
	var checkpoint = route.get_node("Checkpoint")
	check(checkpoint.checkpoint_id==&"route_midpoint" and checkpoint.global_position+checkpoint.respawn_offset==Vector2(3600,370),"Route has one movable checkpoint with a stable id and provisional respawn position")
	check(encounter_director.activate_encounter(&"route_wave_01",900.0),"Pre-checkpoint encounter activates for restoration validation")
	var checkpoint_completed_enemies: Array[Node] = encounter_director.get_active_enemies(&"route_wave_01")
	for checkpoint_enemy in checkpoint_completed_enemies:
		checkpoint_enemy.set_physics_process(false)
		checkpoint_enemy.take_damage(999,&"player")
	check(encounter_director.is_encounter_completed(&"route_wave_01"),"Encounter can complete before checkpoint activation")
	var pre_checkpoint_pickup = route.add_pickup("empanada","empanada",7900,0,0.14,-1.0,&"checkpoint_pickup_before")
	pre_checkpoint_pickup._on_body_entered(player)
	check(pre_checkpoint_pickup.used and route.get_collected_pickup_ids().has(&"checkpoint_pickup_before"),"Collected pickup has a stable id before checkpoint")
	var checkpoint_score: int = player.score
	var checkpoint_coins: int = player.coins
	player.tucumanazo_counter.set_uses(3)
	check(checkpoint.activate_for(player) and not checkpoint.activate_for(player),"Checkpoint activates exactly once")
	check(game_session.active_checkpoint==&"route_midpoint" and game_session.respawn_position==Vector2(3600,370),"GameSession stores checkpoint id and respawn position")
	check(game_session.checkpoint_completed_encounters==[&"route_wave_01"] and game_session.checkpoint_collected_pickups.has(&"checkpoint_pickup_before") and game_session.checkpoint_player_state.tucumanazos==3,"GameSession snapshots encounters, pickups and the non-default Tucumanazo count")
	check(hud.notice.text=="CHECKPOINT","Checkpoint activation provides minimal HUD feedback")
	check(encounter_director.activate_encounter(&"route_wave_04",4700.0),"Post-checkpoint active encounter starts for deterministic respawn validation")
	var interrupted_encounter_enemies: Array[Node] = encounter_director.get_active_enemies(&"route_wave_04")
	var interrupted_signature: Array[String] = []
	for checkpoint_enemy in interrupted_encounter_enemies:
		checkpoint_enemy.set_physics_process(false)
		interrupted_signature.append("%s:%d" % [checkpoint_enemy.archetype,checkpoint_enemy.lane_index])
	interrupted_signature.sort()
	interrupted_encounter_enemies[0].take_damage(999,&"player")
	var post_checkpoint_pickup = route.add_pickup("empanada","empanada",7950,0,0.14,-1.0,&"checkpoint_pickup_after")
	post_checkpoint_pickup._on_body_entered(player)
	check(traffic_director.spawn_now(4700.0)!=null and traffic_director.get_active_vehicle_count()==1,"Post-checkpoint traffic can be active before respawn")
	player.combo_component.register_hit(&"checkpoint_combo")
	player.shot_cooldown = 0.0
	check(player.start_tucumanazo() and player.tucumanazo_counter.current_uses==2,"Player consumes one Tucumanazo after the checkpoint before respawn")
	player.position = Vector2(5000,415)
	player.lane_index = 1
	player.hurtbox.lane_index = 1
	player.collision_mask = 1 << 1
	player.invulnerability = 0.0
	player.health = 1
	var lives_before_respawn: int = player.lives
	var local_state_before_respawn: Dictionary = player.get_respawn_state()
	var local_score_before_respawn: int = player.score
	var local_coins_before_respawn: int = player.coins
	var traffic_before_respawn: Array[Node] = traffic_director.get_active_vehicles()
	var remaining_encounter_enemies: Array[Node] = encounter_director.get_active_enemies(&"route_wave_04")
	player.take_damage(1,"enemy")
	check(player.lives==lives_before_respawn-1 and player.health==player.max_health and player.state!=player.State.DEATH,"Local respawn consumes exactly one life and restores health")
	check(player.position==Vector2(4840,415) and player.lane_index==1 and player.velocity==Vector2.ZERO and 5000.0-player.position.x==160.0,"Local respawn uses the first safe point 160 px behind death and preserves the safe lane")
	check(player.combo_component.current_combo==0 and player.tucumanazo_counter.current_uses==int(local_state_before_respawn.tucumanazos) and not player.special_active and not player.tucumanazo_hitbox.active,"Local respawn clears temporary combat state without rolling back consumed Tucumanazos")
	check(player.character_definition.character_id==game_session.selected_character,"Respawn preserves selected character")
	check(traffic_director.get_active_vehicle_count()==traffic_before_respawn.size() and traffic_before_respawn.all(func(vehicle: Node): return is_instance_valid(vehicle) and vehicle.is_inside_tree()),"Local respawn preserves active traffic without duplicating or resetting its sequence")
	check(player.score==local_score_before_respawn and player.coins==local_coins_before_respawn and player.stones==int(local_state_before_respawn.stones) and player.oranges_unlocked==bool(local_state_before_respawn.oranges_unlocked) and game_session.score==local_score_before_respawn and game_session.coins==local_coins_before_respawn,"Local respawn preserves current score, coins, ammo and infinite oranges")
	check(encounter_director.is_encounter_completed(&"route_wave_01") and not encounter_director.activate_encounter(&"route_wave_01",900.0),"Encounter completed before checkpoint cannot duplicate after respawn")
	check(encounter_director.is_encounter_activated(&"route_wave_04") and encounter_director.get_active_enemy_count(&"route_wave_04")==remaining_encounter_enemies.size() and remaining_encounter_enemies.all(func(enemy: Node): return is_instance_valid(enemy) and enemy.is_inside_tree()),"Local respawn preserves the interrupted encounter and its living enemies without duplication")
	check(pre_checkpoint_pickup.used and post_checkpoint_pickup.used and not pre_checkpoint_pickup.get_node("Visual").visible and not post_checkpoint_pickup.get_node("Visual").visible,"Local respawn keeps every already collected pickup consumed")
	check(player.invulnerability>=1.24 and player.invulnerability<=scene.LOCAL_RESPAWN_INVULNERABILITY,"Local respawn grants the configured 1.25-second movable safety window")
	var health_after_respawn: int = player.health
	player.take_damage(1,"enemy")
	check(player.health==health_after_respawn,"Player invulnerability prevents immediate duplicate damage")
	var vehicle_safety_probe: Node = traffic_before_respawn[0]
	var vehicle_probe_position: Vector2 = vehicle_safety_probe.position
	var vehicle_probe_lane: int = vehicle_safety_probe.lane_index
	vehicle_safety_probe.position = Vector2(4840,GameConfig.LANES[1])
	vehicle_safety_probe.lane_index = 1
	var vehicle_safe_respawn: Dictionary = route.find_local_respawn(Vector2(5000,415),1)
	check(bool(vehicle_safe_respawn.found) and (int(vehicle_safe_respawn.lane_index)!=1 or absf(float(vehicle_safe_respawn.position.x)-vehicle_safety_probe.position.x)>route.LOCAL_RESPAWN_VEHICLE_CLEARANCE) and is_equal_approx(float(vehicle_safe_respawn.position.y),GameConfig.LANES[int(vehicle_safe_respawn.lane_index)]),"Local search avoids vehicle impact/roof space and always chooses fixed lane ground")
	vehicle_safety_probe.position = vehicle_probe_position
	vehicle_safety_probe.lane_index = vehicle_probe_lane
	var local_probe: Dictionary = route.find_local_respawn(Vector2(5000,415),1)
	var hostile_probe = PROJECTILE_SCENE.instantiate()
	hostile_probe.kind = &"bullet"
	hostile_probe.team = &"enemy"
	hostile_probe.lane_index = int(local_probe.lane_index)
	hostile_probe.position = local_probe.position
	route.get_node("Projectiles").add_child(hostile_probe)
	hostile_probe.set_physics_process(false)
	var aim_probe = route.spawn_drone(float(local_probe.position.x)+260.0,int(local_probe.lane_index))
	aim_probe.set_physics_process(false)
	aim_probe.ai_state = aim_probe.AIState.AIM
	aim_probe.locked_target_position = local_probe.position
	aim_probe.aim_reticle.show_target(local_probe.position)
	var cleanup_result: Dictionary = route.prepare_local_respawn_safety(local_probe.position,int(local_probe.lane_index))
	check(cleanup_result.removed_projectiles==1 and cleanup_result.cancelled_drone_aims==1 and aim_probe.ai_state==aim_probe.AIState.COOLDOWN and not aim_probe.aim_reticle.active,"Local safety clears only nearby hostile shots and cancels a Drone aim locked onto the respawn point")
	await frames(2)
	for blocker_lane in range(GameConfig.LANES.size()):
		for blocker_x in [5840.0,5880.0,5800.0,5780.0]:
			var blocker = route.spawn_enemy("agente",blocker_x,blocker_lane)
			blocker.set_physics_process(false)
	player.position = Vector2(6000,GameConfig.LANES[1])
	player.lane_index = 1
	player.hurtbox.lane_index = 1
	player.collision_mask = 1 << 1
	player.invulnerability = 0.0
	player.health = 1
	var lives_before_fallback: int = player.lives
	player.take_damage(1,"enemy")
	check(player.lives==lives_before_fallback-1 and player.position==game_session.respawn_position and player.lane_index==0,"Checkpoint remains the fallback when every local candidate in both lanes is unsafe")
	check(player.score==checkpoint_score and player.coins==checkpoint_coins and player.tucumanazo_counter.current_uses==3 and pre_checkpoint_pickup.used and not post_checkpoint_pickup.used,"Checkpoint fallback retains the previous snapshot restoration contract")
	check(encounter_director.is_encounter_completed(&"route_wave_01") and not encounter_director.is_encounter_activated(&"route_wave_04") and traffic_director.get_active_vehicle_count()==0,"Checkpoint fallback resets interrupted encounters and traffic without duplicates")
	player.tucumanazo_counter.reset_full()
	var empty_checkpoint_ids: Array[StringName] = []
	route.restore_checkpoint_state(empty_checkpoint_ids,empty_checkpoint_ids)
	await frames(2)
	player.respawn_at(Vector2(80,370),{"score":0,"coins":0,"stones":0,"oranges_unlocked":false,"heat":0.0})
	player.lives = san_martin.starting_lives
	player.health = player.max_health
	player.invulnerability = 0.0
	player.hit_time = 0.0
	scene.change_state(GAME_SESSION.DemoState.CHARACTER_SELECT)
	check(scene.current_state==GAME_SESSION.DemoState.CHARACTER_SELECT and not player.controls_enabled,"CHARACTER_SELECT disables player control")
	scene.change_state(GAME_SESSION.DemoState.INTRO)
	check(not paused and not player.controls_enabled,"INTRO disables control without pausing the scene")
	scene.pause_game()
	scene.resume_game()
	check(scene.current_state==GAME_SESSION.DemoState.INTRO and not player.controls_enabled,"Resume restores the state active before pause")
	scene.change_state(GAME_SESSION.DemoState.GAMEPLAY)
	scene.pause_game()
	check(paused and scene.current_state==GAME_SESSION.DemoState.PAUSED,"Pause enters PAUSED flow state")
	check(not player.controls_enabled,"Pause disables player controls")
	scene.resume_game()
	check(not paused and scene.current_state==GAME_SESSION.DemoState.GAMEPLAY,"Resume restores previous flow state")
	check(player.controls_enabled,"Resume restores player controls")
	check(player.get_node("CollisionShape2D").shape is RectangleShape2D,"Player collision generated")
	check(player.is_on_floor(),"Player stands on physical ground")
	player.position = Vector2(180,GameConfig.LANES[0])
	player.velocity = Vector2.ZERO
	player.health = player.max_health
	player.invulnerability = 0.0
	player.hit_time = 0.0
	var health_before_hit_response: int = player.health
	var lives_before_hit_response: int = player.lives
	var x_before_hit_response: float = player.position.x
	var lane_before_hit_response: int = player.lane_index
	player.take_damage(1,"enemy")
	player._physics_process(0.1)
	check(player.health==health_before_hit_response-1 and player.lives==lives_before_hit_response and is_equal_approx(player.position.x,x_before_hit_response) and player.lane_index==lane_before_hit_response and is_zero_approx(player.velocity.x) and player.hit_time>0.0,"Normal damage preserves Player X and lane without knockback while retaining health loss and hit feedback")
	var health_after_first_hit: int = player.health
	player.take_damage(1,"enemy")
	check(player.health==health_after_first_hit and player.health_component.is_invulnerable(),"Damage invulnerability still blocks an immediate duplicate hit")
	player.health_component.restore_full(true)
	player.hit_time = 0.0
	player.invulnerability = 100.0
	var initial_x: float = player.position.x
	Input.action_press("move_right")
	await frames(60)
	Input.action_release("move_right")
	check(absf(player.position.x-initial_x-230.0)<8.0,"230 px/s movement through fixed physics")
	check(player.coins==1 and player.score==25,"Empanada collision updates coins and score")
	check(game_session.coins==1 and game_session.score==25,"GameSession mirrors current progress")
	player.position = Vector2(520,370)
	player.velocity = Vector2.ZERO
	var route_orange_tree = route.get_node("Objects").get_children().filter(func(item: Node): return item.get("pickup_id")==&"orange_tree_520_0")[0]
	route_orange_tree._on_body_entered(player)
	await frames(32)
	check(player.oranges_unlocked and not player.collection_active,"Tree collision unlocks oranges after completing its collection animation")
	var enemy = route.spawn_enemy("hipster",640,0)
	await frames(2)
	check(enemy.health_component.get_script()==player.health_component.get_script() and enemy.max_health==3,"Enemy uses the same HealthComponent with archetype health")
	check(enemy.definition==load("res://data/enemies/hipster.tres") and enemy.health==enemy.definition.max_health and enemy.visual.sprite_frames==enemy.definition.sprite_frames,"Enemy instance applies health and visuals from EnemyDefinition")
	check(enemy.hurtbox.combat_owner==enemy and enemy.hurtbox.health_component==enemy.health_component and enemy.hurtbox.team==&"enemy","Enemy exposes the same Hurtbox contract")
	player.throw_projectile("orange")
	var orange_projectile = route.get_node("Projectiles").get_child(-1)
	check(orange_projectile.definition.projectile_id==&"orange" and orange_projectile.damage==1 and orange_projectile.speed==560.0 and orange_projectile.travel_direction.is_equal_approx(Vector2.RIGHT),"Naranjazo instance reads ProjectileDefinition and receives Player's aimed direction")
	check(player.resolve_shot_direction(Vector2.LEFT,false,1).is_equal_approx(Vector2.LEFT) and player.resolve_shot_direction(Vector2.RIGHT,false,-1).is_equal_approx(Vector2.RIGHT),"Ground aiming supports left and right")
	check(player.resolve_shot_direction(Vector2.UP,false,1).is_equal_approx(Vector2.UP),"Ground aiming supports straight up")
	check(player.resolve_shot_direction(Vector2(-1,-1),false,1).is_equal_approx(Vector2(-1,-1).normalized()) and player.resolve_shot_direction(Vector2(1,-1),false,-1).is_equal_approx(Vector2(1,-1).normalized()),"Ground aiming supports both upper diagonals")
	check(player.resolve_shot_direction(Vector2(-1,1),true,1).is_equal_approx(Vector2(-1,1).normalized()) and player.resolve_shot_direction(Vector2(1,1),false,-1).is_equal_approx(Vector2(1,1).normalized()),"Both air and ground aiming support lower diagonals")
	check(player.resolve_shot_direction(Vector2.DOWN,true,-1).is_equal_approx(Vector2.DOWN) and player.resolve_shot_direction(Vector2.DOWN,false,-1).is_equal_approx(Vector2.DOWN),"Straight down is available both in air and while grounded")
	var shooting_probe = load("res://scenes/actors/player.tscn").instantiate()
	root.add_child(shooting_probe)
	shooting_probe.set_physics_process(false)
	shooting_probe.position = Vector2(2500.0,GameConfig.LANES[0])
	var aimed_shots: Array[Array] = []
	shooting_probe.shot_requested.connect(func(origin: Vector2,lane: int,direction: Vector2,kind: String,shot_team: String): aimed_shots.append([origin,lane,direction,kind,shot_team]))
	shooting_probe.stones = 2
	shooting_probe.throw_projectile("stone",Vector2(-1,-1))
	check(shooting_probe.stones==1 and aimed_shots.size()==1 and aimed_shots[0][2].is_equal_approx(Vector2(-1,-1).normalized()) and aimed_shots[0][3]=="stone","Aimed Cascotazo consumes exactly one stone and emits its normalized direction")
	shooting_probe.oranges_unlocked = true
	shooting_probe.shot_cooldown = 0.0
	shooting_probe.throw_projectile("orange",Vector2.UP)
	shooting_probe.shot_cooldown = 0.0
	shooting_probe.throw_projectile("orange",Vector2.RIGHT)
	shooting_probe.shot_cooldown = 0.0
	shooting_probe.throw_projectile("orange",Vector2.DOWN)
	check(aimed_shots.size()==4 and shooting_probe.oranges_unlocked,"Aimed Naranjazos remain unlimited after oranges are unlocked")
	check(aimed_shots[3][2].is_equal_approx(Vector2.DOWN) and is_equal_approx(aimed_shots[3][0].y,GameConfig.LANES[0]-18.0),"Grounded downward fire uses a valid downward vector and starts safely above the lane floor")
	shooting_probe.queue_free()
	var left_bullet = PROJECTILE_SCENE.instantiate()
	left_bullet.kind = &"bullet"
	left_bullet.team = &"enemy"
	left_bullet.lane_index = 0
	left_bullet.direction = -1
	left_bullet.position = Vector2(4000,370)
	route.get_node("Projectiles").add_child(left_bullet)
	left_bullet.set_physics_process(false)
	var left_bullet_rotation: float = left_bullet.visual.rotation
	left_bullet._physics_process(0.1)
	check(is_zero_approx(left_bullet_rotation) and is_equal_approx(left_bullet.visual.rotation,left_bullet_rotation) and is_equal_approx(left_bullet.position.x,3988.6),"Left-moving agent bullet keeps a stable forward visual while using its slower straight speed")
	var right_bullet = PROJECTILE_SCENE.instantiate()
	right_bullet.kind = &"bullet"
	right_bullet.team = &"enemy"
	right_bullet.lane_index = 0
	right_bullet.direction = 1
	right_bullet.position = Vector2(4000,370)
	route.get_node("Projectiles").add_child(right_bullet)
	right_bullet.set_physics_process(false)
	var right_bullet_rotation: float = right_bullet.visual.rotation
	right_bullet._physics_process(0.1)
	check(is_equal_approx(right_bullet_rotation,PI) and is_equal_approx(right_bullet.visual.rotation,right_bullet_rotation) and is_equal_approx(right_bullet.position.x,4011.4),"Right-moving agent bullet is oriented once and never spins during slower straight travel")
	var bottle_probe = PROJECTILE_SCENE.instantiate()
	bottle_probe.kind = &"bottle"
	bottle_probe.team = &"enemy"
	bottle_probe.lane_index = 0
	bottle_probe.position = Vector2(4000,370)
	route.get_node("Projectiles").add_child(bottle_probe)
	bottle_probe.set_physics_process(false)
	bottle_probe._physics_process(0.1)
	check(is_equal_approx(bottle_probe.position.x,4016.2) and is_equal_approx(bottle_probe.speed,162.0) and is_equal_approx(bottle_probe.remaining_life,3.84),"Hipster bottle keeps its distinct slower speed, straight trajectory and restored travel distance")
	var aimed_stone = PROJECTILE_SCENE.instantiate()
	aimed_stone.kind = &"stone"
	aimed_stone.team = &"player"
	aimed_stone.lane_index = 1
	aimed_stone.travel_direction = Vector2(1,-1)
	aimed_stone.position = Vector2(4000,120)
	route.get_node("Projectiles").add_child(aimed_stone)
	aimed_stone.set_physics_process(false)
	var aimed_start: Vector2 = aimed_stone.position
	var aimed_rotation: float = aimed_stone.visual.rotation
	var aimed_direction: Vector2 = aimed_stone.travel_direction
	aimed_stone._physics_process(0.02)
	var aimed_displacement: Vector2 = aimed_stone.position-aimed_start
	check(is_equal_approx(aimed_displacement.length(),aimed_stone.speed*0.02),"Diagonal projectile preserves the ProjectileDefinition speed magnitude")
	check(absf(aimed_displacement.normalized().cross(aimed_direction))<0.0001 and aimed_stone.travel_direction.is_equal_approx(aimed_direction),"Aimed projectile follows a straight trajectory and never changes direction")
	check(is_equal_approx(aimed_rotation,aimed_direction.angle()) and is_equal_approx(aimed_stone.visual.rotation,aimed_rotation),"Player projectile visual is oriented once and remains stable")
	check(aimed_stone.lane_index==1 and aimed_stone.collision_mask==(GameConfig.ENEMY_LAYER | (1 << 1)),"Multidirectional projectile preserves its assigned lane collision mask")
	aimed_stone.queue_free()
	left_bullet.queue_free()
	right_bullet.queue_free()
	bottle_probe.queue_free()
	var second_orange = PROJECTILE_SCENE.instantiate()
	second_orange.kind = &"orange"
	second_orange.team = &"player"
	second_orange.set_physics_process(false)
	route.get_node("Projectiles").add_child(second_orange)
	check(second_orange.visual.sprite_frames==orange_projectile.visual.sprite_frames,"Naranjazo instances reuse preconfigured SpriteFrames")
	second_orange.queue_free()
	await frames(22)
	check(enemy.health==2,"Orange hits enemy via real collision")
	check(player.combo_component.current_combo==1 and hud.combo.visible and hud.combo.text=="COMBO x1","Valid Naranjazo increments combo and updates HUD")
	check(player.tucumanazo_counter.current_uses==5 and hud.special_status.text=="TUCUMANAZO x5","Valid Naranjazo and combo do not recharge or alter Tucumanazo stock")
	var score_before_enemy_defeat: int = player.score
	var enemy_depleted_events := [0]
	enemy.health_component.depleted.connect(func(): enemy_depleted_events[0] += 1)
	enemy.take_damage(20,"player")
	enemy.take_damage(20,"player")
	check(enemy_depleted_events[0]==1 and player.score==score_before_enemy_defeat+75,"Enemy depletion awards its reward exactly once")
	await frames(20)
	check(not is_instance_valid(enemy),"Defeated enemy keeps its existing removal behavior")
	var melee_phase_probe = route.spawn_enemy("grandote",player.position.x+300.0,player.lane_index)
	melee_phase_probe.set_physics_process(false)
	await frames(2)
	melee_phase_probe.contact.set_deferred("monitoring",false)
	melee_phase_probe._begin_attack()
	check(melee_phase_probe.ai_state==melee_phase_probe.AIState.TELEGRAPH and not melee_phase_probe.melee_hitbox.active,"Melee enters telegraph before its active attack")
	melee_phase_probe._advance_attack_state(melee_phase_probe.definition.telegraph_duration)
	check(melee_phase_probe.ai_state==melee_phase_probe.AIState.ATTACK and melee_phase_probe.melee_hitbox.active,"Melee telegraph advances to an active Hitbox attack")
	var health_before_lane_probe: int = player.health
	var combo_before_lane_probe: int = player.combo_component.current_combo
	melee_phase_probe.melee_hitbox.lane_index = 1-player.lane_index
	check(not melee_phase_probe.melee_hitbox.try_hit(player.hurtbox) and player.health==health_before_lane_probe,"Enemy melee Hitbox rejects a player on another lane")
	melee_phase_probe.melee_hitbox.lane_index = player.lane_index
	player.invulnerability = 0.0
	check(melee_phase_probe.melee_hitbox.try_hit(player.hurtbox) and player.health==health_before_lane_probe-1,"Enemy melee Hitbox damages the player on the same lane through Hurtbox")
	check(not melee_phase_probe.melee_hitbox.try_hit(player.hurtbox) and player.health==health_before_lane_probe-1,"Enemy melee attack cannot duplicate a hit during one activation")
	melee_phase_probe._advance_attack_state(melee_phase_probe.definition.get_active_duration())
	check(melee_phase_probe.ai_state==melee_phase_probe.AIState.RECOVERY and not melee_phase_probe.melee_hitbox.active,"Melee active window advances to recovery and disables its Hitbox")
	melee_phase_probe._advance_attack_state(melee_phase_probe.definition.recovery_duration)
	check(melee_phase_probe.ai_state==melee_phase_probe.AIState.CHASE,"Melee recovery returns to chase")
	player.health = player.max_health
	player.invulnerability = 100.0
	player.combo_component.current_combo = combo_before_lane_probe
	player.combo_component.remaining_window = player.combo_component.combo_window_seconds
	player.combo_component.combo_changed.emit(combo_before_lane_probe)
	melee_phase_probe.queue_free()
	await frames(2)
	var ranged_phase_probe = route.spawn_enemy("agente",player.position.x+300.0,player.lane_index)
	ranged_phase_probe.set_physics_process(false)
	await frames(2)
	ranged_phase_probe.contact.set_deferred("monitoring",false)
	var ranged_shots: Array = []
	ranged_phase_probe.shot_requested.connect(func(_origin: Vector2,lane: int,_direction: int,kind: String,shot_team: String): ranged_shots.append([lane,kind,shot_team]))
	ranged_phase_probe._begin_attack()
	check(ranged_phase_probe.ai_state==ranged_phase_probe.AIState.TELEGRAPH,"Ranged enemy telegraphs before firing")
	ranged_phase_probe._advance_attack_state(ranged_phase_probe.definition.telegraph_duration)
	check(ranged_phase_probe.ai_state==ranged_phase_probe.AIState.ATTACK and ranged_shots.size()==1 and ranged_shots[0]==[player.lane_index,"bullet","enemy"],"Ranged attack emits its data-defined projectile with faction and lane")
	ranged_phase_probe._advance_attack_state(ranged_phase_probe.definition.get_active_duration())
	ranged_phase_probe._advance_attack_state(ranged_phase_probe.definition.recovery_duration)
	check(ranged_phase_probe.ai_state==ranged_phase_probe.AIState.CHASE and ranged_shots.size()==1,"Ranged attack recovers without firing duplicate projectiles")
	ranged_phase_probe.queue_free()
	await frames(2)
	check(load("res://data/attacks/cabezazo.tres") != null and player.visual.sprite_frames.has_animation(&"Headbutt"),"Legacy Cabezazo data and Headbutt art remain available as non-runtime references")
	check(player.tucumanazo_counter.current_uses==5 and hud.special_status.text=="TUCUMANAZO x5","Player begins gameplay with five Tucumanazos and an explicit HUD counter")
	var uses_before_combo: int = player.tucumanazo_counter.current_uses
	check(player.combo_component.register_hit(&"counter_independence") and player.tucumanazo_counter.current_uses==uses_before_combo,"Combo hits no longer charge Tucumanazo")
	player.combo_component.reset()
	var special_enemy_right = route.spawn_enemy("grandote",player.position.x+80.0,player.lane_index)
	var special_enemy_left = route.spawn_enemy("grandote",player.position.x-80.0,player.lane_index)
	var special_enemy_other_lane = route.spawn_enemy("grandote",player.position.x,1-player.lane_index)
	for special_enemy in [special_enemy_right,special_enemy_left,special_enemy_other_lane]:
		special_enemy.set_physics_process(false)
	await frames(2)
	var health_before_special: int = player.health
	player.shot_cooldown = 0.0
	var wave_activations_before: int = player.tucumanazo_wave_visual.activation_count
	check(player.start_tucumanazo() and player.special_active and player.special_phase==player.SpecialPhase.STARTUP,"Available stock activates Tucumanazo startup")
	check(player.tucumanazo_counter.current_uses==4 and hud.special_status.text=="TUCUMANAZO x4" and "¡VAMO' URA!" in hud.notice.text,"A valid Tucumanazo consumes exactly one use and updates HUD")
	check(player.visual.animation==player.character_definition.headbutt_animation and player.visual.animation==&"Headbutt","Tucumanazo reuses the existing Headbutt animation")
	check(not player.start_tucumanazo() and player.tucumanazo_counter.current_uses==4,"Overlapping activation cannot consume a second use")
	await frames(10)
	check(player.tucumanazo_wave_visual.activation_count==wave_activations_before+1 and player.tucumanazo_wave_visual.active,"The radial wave visual is generated once with the active phase")
	check(special_enemy_right.health==5 and special_enemy_left.health==5,"Tucumanazo damages each valid nearby enemy once")
	check(special_enemy_other_lane.health==10 and player.health==health_before_special,"Tucumanazo rejects another lane and its owning player")
	check(player.tucumanazo_counter.current_uses==4 and player.combo_component.current_combo==0,"Tucumanazo impacts do not refill stock or combo")
	check(player._special_hit_stop_used and scene.shake_remaining>0.0,"Tucumanazo triggers hit-stop and screen shake on impact")
	await create_timer(0.12,true,false,true).timeout
	await frames(50)
	check(not player.special_active and player.special_phase==player.SpecialPhase.READY and not player.tucumanazo_hitbox.active and is_equal_approx(Engine.time_scale,1.0),"Tucumanazo ends cleanly and restores normal time")
	check(special_enemy_right.health==5 and special_enemy_left.health==5,"Tucumanazo does not duplicate impacts during one activation")
	for special_enemy in [special_enemy_right,special_enemy_left,special_enemy_other_lane]:
		special_enemy.queue_free()
	await frames(2)
	player.shot_cooldown = 0.0
	check(player.start_tucumanazo() and player.tucumanazo_counter.current_uses==3 and hud.special_status.text=="TUCUMANAZO x3","Second Tucumanazo consumes one use for pause validation")
	await frames(3)
	var special_phase_before_pause: int = player.special_phase
	var special_time_before_pause: float = player.special_phase_remaining
	scene.pause_game()
	await create_timer(0.15,true,false,true).timeout
	check(player.special_active and player.special_phase==special_phase_before_pause and is_equal_approx(player.special_phase_remaining,special_time_before_pause) and player.tucumanazo_counter.current_uses==3,"Pause freezes Tucumanazo timing without duplicating consumption")
	scene.resume_game()
	await frames(45)
	check(not player.special_active and not player.tucumanazo_hitbox.active,"Tucumanazo resumes and finishes after pause")
	player.shot_cooldown = 0.0
	player.invulnerability = 0.0
	player.hit_time = 0.0
	check(player.start_tucumanazo() and player.tucumanazo_counter.current_uses==2 and hud.special_status.text=="TUCUMANAZO x2","Third Tucumanazo consumes one use before damage cancellation")
	player.take_damage(1,"enemy")
	check(not player.special_active and not player.tucumanazo_hitbox.active and not player.tucumanazo_wave_visual.active and player.tucumanazo_counter.current_uses==2,"Damage cancels active Tucumanazo without refunding or consuming twice")
	player.health = player.max_health
	player.invulnerability = 0.0
	player.hit_time = 0.0
	player.tucumanazo_counter.set_uses(1)
	check(hud.special_status.text=="TUCUMANAZO x1","HUD represents the penultimate Tucumanazo explicitly")
	player.shot_cooldown = 0.0
	check(player.start_tucumanazo() and player.tucumanazo_counter.current_uses==0 and hud.special_status.text=="TUCUMANAZO x0","Last available Tucumanazo consumes the counter to zero")
	player.cancel_tucumanazo()
	player.shot_cooldown = 0.0
	check(not player.start_tucumanazo() and player.tucumanazo_counter.current_uses==0,"Tucumanazo cannot activate or consume below zero")
	var sweep_enemy = route.spawn_enemy("grandote",player.position.x+120.0,player.lane_index)
	sweep_enemy.set_physics_process(false)
	await frames(2)
	var swept_stone = PROJECTILE_SCENE.instantiate()
	swept_stone.kind = &"stone"
	swept_stone.team = &"player"
	swept_stone.position = player.position+Vector2(24.0,-42.0)
	route.get_node("Projectiles").add_child(swept_stone)
	swept_stone.set_physics_process(false)
	await frames(1)
	swept_stone._physics_process(0.25)
	check(sweep_enemy.health==7 and swept_stone.spent,"Fast Cascotazo sweep reaches Hurtbox without tunneling")
	var friendly_projectile = PROJECTILE_SCENE.instantiate()
	friendly_projectile.kind = &"bottle"
	friendly_projectile.team = &"enemy"
	route.get_node("Projectiles").add_child(friendly_projectile)
	friendly_projectile.set_physics_process(false)
	check(not friendly_projectile._try_hurtbox(sweep_enemy.hurtbox) and sweep_enemy.health==7 and not friendly_projectile.spent,"Enemy projectile ignores an allied Hurtbox")
	friendly_projectile.queue_free()
	sweep_enemy.queue_free()
	await frames(2)
	var other = route.spawn_enemy("agente",640,1)
	await frames(2)
	check(other.max_health==5,"Different enemy health values remain configured")
	var other_health: int = other.health
	scene._spawn_projectile(Vector2(580,375),0,1,"stone","player")
	await frames(18)
	check(other.health==other_health and player.combo_component.current_combo==0 and player.tucumanazo_counter.current_uses==0,"Projectile on another lane adds no damage, combo or Tucumanazo stock")
	for body in get_nodes_in_group("enemies"):
		body.queue_free()
	await frames(2)
	player.position = Vector2(1000,370)
	player.velocity = Vector2.ZERO
	await frames(3)
	player.begin_lane_change(1)
	await frames(1)
	check(lane_readability.feedback_remaining>0.0 and is_equal_approx(lane_readability.feedback_position.y,GameConfig.LANES[1]),"Lane change triggers a brief diegetic destination-plane feedback without changing Player state")
	await frames(18)
	check(player.lane_index==1 and absf(player.position.y-415.0)<1.0,"Lane transition reaches physical lower floor")
	await frames(4)
	check(is_zero_approx(lane_readability.feedback_remaining),"Lane-change visual feedback expires after its short presentation window")
	check(player.is_on_floor(),"Lower lane supported without viewport clamp")
	player.begin_lane_change(0)
	await frames(18)
	Input.action_press("jump")
	await frames(8)
	Input.action_release("jump")
	check(player.get_height()>30.0,"Jump raises physical player")
	await frames(60)
	check(player.is_on_floor() and player.get_height()<1.0,"Jump returns to lane")
	player.position = Vector2(1900,200)
	player.velocity = Vector2.ZERO
	await frames(50)
	check(player.is_on_floor() and player.get_height()>30.0,"Player lands on generated vehicle roof")
	var platform = get_nodes_in_group("platforms")[0]
	check(platform.get_node("CollisionShape2D").one_way_collision,"Vehicle has one-way roof shape")
	var route_platforms: Array[Node] = get_nodes_in_group("platforms")
	var auto_platform: Node = route_platforms.filter(func(item: Node): return item.get("asset")=="auto1")[0]
	var lemon_platform: Node = route_platforms.filter(func(item: Node): return item.get("asset")=="camion_limones")[0]
	check(is_equal_approx(auto_platform.image_scale,0.84) and auto_platform.get_node("CollisionShape2D").shape.size.is_equal_approx(Vector2(124.32,8.0)) and auto_platform.get_node("CollisionShape2D").one_way_collision,"Auto1 platform uses the reduced scale and its recalculated one-way roof collider")
	check(is_equal_approx(lemon_platform.image_scale,1.25) and lemon_platform.get_node("CollisionShape2D").shape.size.is_equal_approx(Vector2(190.0,8.0)) and lemon_platform.get_node("CollisionShape2D").one_way_collision,"Lemon truck platform uses the larger scale and its recalculated one-way roof collider")
	var generic_platforms: Array[Node] = get_nodes_in_group("generic_platforms")
	check(generic_platforms.size()==2 and generic_platforms.all(func(item: Node): return item is StaticBody2D and item.roof_collision.one_way_collision and item.roof_collision.shape.size.y==8.0),"Route adds exactly two generic StaticBody2D platforms with roof-only one-way collision")
	var kiosk_platform: Node = generic_platforms.filter(func(item: Node): return item.name=="KioskPlatformPOC")[0]
	var bus_stop_platform: Node = generic_platforms.filter(func(item: Node): return item.name=="BusStopPlatformPOC")[0]
	check(kiosk_platform.platform_texture.resource_path=="res://assets/kiosco_coca.png" and is_equal_approx(kiosk_platform.image_scale,0.72) and kiosk_platform.roof_width==112.0 and kiosk_platform.roof_vertical_offset==-95.0,"Kiosk POC exposes its arbitrary texture, scale, useful width and roof offset")
	check(bus_stop_platform.platform_texture.resource_path=="res://assets/parada_colectivo.png" and is_equal_approx(bus_stop_platform.image_scale,0.62) and bus_stop_platform.roof_width==94.0 and bus_stop_platform.roof_vertical_offset==-108.0,"Bus-stop POC exposes an independent texture and calibrated roof parameters")
	for generic_platform in [kiosk_platform,bus_stop_platform]:
		player.lane_index = generic_platform.lane_index
		player.hurtbox.lane_index = generic_platform.lane_index
		player.collision_mask = 1 << generic_platform.lane_index
		player.position = Vector2(generic_platform.position.x,generic_platform.get_roof_world_y()-70.0)
		player.velocity = Vector2.ZERO
		await frames(55)
		check(player.is_on_floor() and absf(player.position.y-generic_platform.get_roof_world_y())<2.0,"Player lands and remains on generic roof: "+generic_platform.name)
	var pass_through_roof_y: float = kiosk_platform.get_roof_world_y()
	player.position = Vector2(kiosk_platform.position.x,pass_through_roof_y+34.0)
	player.velocity = Vector2(0.0,-500.0)
	await frames(8)
	check(player.position.y<pass_through_roof_y-4.0,"Player passes through a generic platform from below")
	player.lane_index = 1
	player.hurtbox.lane_index = 1
	player.collision_mask = 1 << 1
	player.position = Vector2(kiosk_platform.position.x,200.0)
	player.velocity = Vector2.ZERO
	await frames(60)
	check(player.is_on_floor() and absf(player.position.y-GameConfig.LANES[1])<2.0,"Opposite lane falls to its own ground and is not blocked by the generic roof")
	player.position = Vector2(kiosk_platform.position.x,GameConfig.LANES[1])
	player.velocity = Vector2.ZERO
	player.begin_lane_change(0)
	await frames(18)
	check(player.lane_index==0 and absf(player.position.y-GameConfig.LANES[0])<1.0,"Lane change beside a generic structure remains functional")
	var roof_projectile = PROJECTILE_SCENE.instantiate()
	roof_projectile.kind = &"orange"
	roof_projectile.team = &"player"
	roof_projectile.lane_index = kiosk_platform.lane_index
	roof_projectile.travel_direction = Vector2.DOWN
	roof_projectile.position = Vector2(kiosk_platform.position.x,kiosk_platform.get_roof_world_y()-60.0)
	route.get_node("Projectiles").add_child(roof_projectile)
	roof_projectile.set_physics_process(false)
	roof_projectile._physics_process(0.2)
	check(roof_projectile.spent,"Naranjazo impacts the visible roof surface in the matching lane")
	var other_lane_projectile = PROJECTILE_SCENE.instantiate()
	other_lane_projectile.kind = &"stone"
	other_lane_projectile.team = &"player"
	other_lane_projectile.lane_index = 1
	other_lane_projectile.travel_direction = Vector2.DOWN
	other_lane_projectile.position = Vector2(kiosk_platform.position.x,kiosk_platform.get_roof_world_y()-60.0)
	route.get_node("Projectiles").add_child(other_lane_projectile)
	other_lane_projectile.set_physics_process(false)
	other_lane_projectile._physics_process(0.2)
	check(not other_lane_projectile.spent,"Projectile from the opposite lane ignores the generic roof")
	other_lane_projectile.queue_free()
	for kind: String in ["orange","stone","bottle","coffee","bullet"]:
		scene._spawn_projectile(Vector2(2200,250),0,1,kind,"player")
		var projectile = route.get_node("Projectiles").get_child(-1)
		check(projectile is Area2D and projectile.has_node("CollisionShape2D"),"Projectile shape: "+kind)
	await frames(240)
	check(route.get_node("Projectiles").get_child_count()==0,"All expired projectiles removed after their preserved useful travel lifetime")
	player.position = Vector2(2500,370)
	player.velocity = Vector2.ZERO
	player.stones = 0
	player.oranges_unlocked = false
	var orange_pickup = route.add_pickup("orange_tree","arbol_naranjas",2500,0,0.85,370.0,&"animated_orange_test")
	check(not player.oranges_unlocked and not orange_pickup.used and orange_pickup.get_orange_halo_strength()>0.15,"Orange reward is absent before pickup interaction starts and its interactive tree has a visible halo")
	orange_pickup._on_body_entered(player)
	orange_pickup._on_body_entered(player)
	check(player.collection_active and player.state==player.State.COLLECT and player.visual.animation==player.character_definition.idle_animation and is_equal_approx(player.visual.scale.x,player.character_visual_scale),"Orange pickup uses the normal-scale Idle presentation during its temporary collection state")
	check(not player.oranges_unlocked and orange_pickup.interaction_active and not orange_pickup.used,"Orange remains reserved but unrewarded at interaction start")
	var collection_start_x: float = player.position.x
	var collection_start_lane: int = player.lane_index
	var projectiles_before_collection: int = route.get_node("Projectiles").get_child_count()
	Input.action_press("move_right")
	Input.action_press("jump")
	await frames(3)
	Input.action_release("move_right")
	Input.action_release("jump")
	player.begin_lane_change(1)
	player.throw_projectile("orange")
	player.tucumanazo_counter.set_uses(1)
	check(not player.start_tucumanazo() and player.tucumanazo_counter.current_uses==1 and is_equal_approx(player.position.x,collection_start_x) and player.lane_index==collection_start_lane and not player.changing_lane and route.get_node("Projectiles").get_child_count()==projectiles_before_collection,"Collection blocks movement, jump, Tucumanazo consumption and projectiles")
	await frames(19)
	check(not player.oranges_unlocked and not orange_pickup.used,"Orange is not granted before the explicit fifth-frame reward point")
	var collection_time_before_pause: float = player.collection_remaining
	scene.pause_game()
	await create_timer(0.1,true,false,true).timeout
	check(player.collection_active and is_equal_approx(player.collection_remaining,collection_time_before_pause) and not player.oranges_unlocked,"Pause freezes collection without granting or corrupting it")
	scene.resume_game()
	await frames(5)
	check(player.oranges_unlocked and orange_pickup.used and orange_pickup.get_node("Visual").visible and orange_pickup.get_node("Visual").modulate!=Color.WHITE and orange_pickup.get_orange_halo_strength()<0.04,"Orange is granted once at 0.4 seconds and its tree keeps the existing collected treatment while fading its halo")
	var collected_ids_after_orange: int = route.get_collected_pickup_ids().count(&"animated_orange_test")
	orange_pickup._on_body_entered(player)
	check(player.oranges_unlocked and route.get_collected_pickup_ids().count(&"animated_orange_test")==collected_ids_after_orange,"Persistent contact cannot grant the orange pickup twice")
	await frames(7)
	check(not player.collection_active and player.state==player.State.IDLE and player.controls_enabled and player.visual.animation==player.character_definition.idle_animation and is_equal_approx(player.visual.scale.x,player.character_visual_scale),"Player returns cleanly to Idle with controls and normal visual scale after orange collection")
	var stone_pickup = route.add_pickup("stone_pile","montaña_cascote",2500,0,0.65,370.0,&"animated_stone_test")
	stone_pickup._on_body_entered(player)
	check(player.collection_active and player.visual.animation==player.character_definition.idle_animation and player.stones==0 and is_equal_approx(player.visual.scale.x,player.character_visual_scale),"Stone pile uses the normal-scale Idle presentation without immediate ammo")
	await frames(23)
	check(player.stones==0 and not stone_pickup.used,"Stone reward waits until the fifth-frame reward point")
	await frames(2)
	check(player.stones==20 and stone_pickup.used and not stone_pickup.get_node("Visual").visible,"Stone pile grants exactly 20 once and becomes dormant and invisible")
	stone_pickup._on_body_entered(player)
	check(player.stones==20,"Persistent contact cannot duplicate stone ammo")
	await frames(7)
	check(not player.collection_active and player.controls_enabled and is_equal_approx(player.visual.scale.x,player.character_visual_scale),"Player recovers controls and normal visual scale after stone collection")
	var interrupted_pickup = route.add_pickup("stone_pile","montaña_cascote",2550,0,0.65,370.0,&"interrupted_stone_test")
	interrupted_pickup._on_body_entered(player)
	player.invulnerability = 0.0
	player.health = player.max_health
	player.take_damage(1,"enemy")
	check(not player.collection_active and not interrupted_pickup.used and player.stones==20,"Damage before the reward point cancels collection without losing or duplicating its reward")
	interrupted_pickup.queue_free()
	paused = true
	check(not route.can_process(),"Physics world pauses")
	check(scene.get_node("Interface/AssetGallery").can_process(),"Gallery stays interactive during pause")
	paused = false
	var gallery = scene.get_node("Interface/AssetGallery")
	for index in range(100):
		gallery.show_image(index)
	for index in range(5):
		gallery.show_actor(index)
	check(gallery.preview.texture!=null,"All gallery resources browse correctly")
	check(route.current_location(0)=="Famaillá" and route.current_location(7000)=="Río Seco","Route begins in Famailla and ends in Rio Seco")
	var route_achilatas: Array[Node] = route.get_node("Objects").get_children().filter(func(item: Node): return item.get("kind")=="achilata")
	check(route_achilatas.size()==6 and route_achilatas.all(func(item: Node): return is_equal_approx(item.image_scale,0.18) and item.get_node("Visual").scale==Vector2(0.18,0.18)),"Achilata uses the reduced 0.18 runtime scale without changing its pickup count")
	player.set_physics_process(false)
	for rate: int in [30,60,120]:
		player.position = Vector2(3400,370)
		player.heat = 0.0
		for step in range(rate):
			player._physics_process(1.0/float(rate))
		check(absf(player.heat-2.1)<0.001,"Heat is time-based at "+str(rate)+" FPS")
	player.heat = 39.0
	player._emit_hud_status()
	check(not hud.heat_sun.visible and not hud.heat_shimmer.visible and not hud.heat_alert.visible,"Heat feedback remains hidden below 40")
	player.heat = 40.0
	player._emit_hud_status()
	var heat_sun_scale_40: float = hud.heat_sun.scale.x
	var heat_sun_alpha_40: float = hud.heat_sun.modulate.a
	check(hud.heat_sun.visible and hud.heat_sun.material is ShaderMaterial and not hud.heat_shimmer.visible and not hud.heat_alert.visible,"A small background-masked sun appears at the 40 heat threshold")
	player.heat = 60.0
	player._emit_hud_status()
	var heat_sun_scale_60: float = hud.heat_sun.scale.x
	var heat_shimmer_alpha_60: float = hud.heat_shimmer.modulate.a
	check(hud.heat_sun.visible and hud.heat_shimmer.visible and heat_sun_scale_60>heat_sun_scale_40 and hud.heat_sun.modulate.a>heat_sun_alpha_40,"Sun size and intensity progress and subtle shimmer appears at 60 heat")
	player.heat = 75.0
	player._emit_hud_status()
	check(hud.heat_alert.visible and hud.heat_alert.text=="¡TE ESTÁS INSOLANDO!","Red heat warning appears at 75")
	player.heat = 90.0
	player._emit_hud_status()
	check(hud.heat_sun.scale.x>heat_sun_scale_60 and hud.heat_shimmer.modulate.a>heat_shimmer_alpha_60 and hud.heat_alert.modulate.a>0.9,"Sun, warning and shimmer intensify at 90 heat")
	player.heat = 74.0
	player._emit_hud_status()
	check(not hud.heat_alert.visible and hud.heat_sun.visible and hud.heat_shimmer.visible,"Heat warning disappears again below 75 without hiding lower-tier feedback")
	player.heat = 90.0
	player._emit_hud_status()
	scene.pause_game()
	check(hud.heat_sun.visible and hud.heat_alert.visible and not hud.heat_shimmer.visible,"Pause freezes stable heat indicators and hides moving shimmer")
	scene.resume_game()
	check(hud.heat_shimmer.visible,"Resume restores shimmer for the current heat value")
	player.heat = 80.0
	var health_before_achilata: int = player.health
	player.collect("achilata")
	check(player.heat==30.0 and player.health==health_before_achilata and not hud.heat_sun.visible and not hud.heat_shimmer.visible and not hud.heat_alert.visible,"Achilata cools exactly 50 and immediately clears heat feedback without changing healing rules")
	player.position = Vector2(3400,370)
	player.controls_enabled = true
	player.health = player.max_health
	player.invulnerability = 0.0
	player.heat = 100.0
	player.heat_damage_time = 1.99
	player._emit_hud_status()
	var health_before_heat_damage: int = player.health
	player._physics_process(0.02)
	check(player.heat==100.0 and player.health==health_before_heat_damage-1,"Maximum heat preserves the existing one-damage interval behavior")
	var respawn_heat_state: Dictionary = player.get_respawn_state()
	respawn_heat_state["heat"] = 35.0
	player.respawn_at(Vector2(3400,370),respawn_heat_state)
	check(player.heat==35.0 and not hud.heat_sun.visible and not hud.heat_shimmer.visible and not hud.heat_alert.visible,"Respawn restores heat and leaves no stale visual feedback")
	player.set_physics_process(true)

	var boss_data: Dictionary = route.data.boss
	var coffee_definition = load("res://data/projectiles/coffee.tres")
	check(is_equal_approx(float(boss_data.trigger_x),7425.0) and is_equal_approx(float(boss_data.x),7600.0),"Palermitano final encounter uses the approved trigger and spawn positions")
	check(coffee_definition.damage==1 and coffee_definition.speed==360.0 and coffee_definition.rotation_speed_degrees==0.0,"Boss coffee keeps one damage and stable non-spinning projectile presentation")
	check(not scene.demo_closing and scene.current_state==GAME_SESSION.DemoState.GAMEPLAY and not scene.get_node("Interface/HUD/Results").visible,"Boss data inspection does not alter the active gameplay flow")
	game_session.selected_character = &"san_martin"
	game_session.set_checkpoint(&"temporary_test_checkpoint")
	scene.restart_game()
	await frames(4)
	var restarted_scene = current_scene
	check(restarted_scene != scene and restarted_scene.current_state==GAME_SESSION.DemoState.CHARACTER_SELECT,"Restart returns to character selection")
	check(game_session.selected_character==&"san_martin","Restart preserves selected character")
	check(game_session.score==0 and game_session.coins==0 and game_session.active_checkpoint==&"" and game_session.respawn_position==Vector2(80,370),"Restart clears checkpoint progress and creates a new start baseline")
	var restarted_select = restarted_scene.get_node("Interface/CharacterSelect")
	check(restarted_scene.get_node("Route38/EncounterDirector").get_completed_encounter_ids().is_empty(),"Full restart creates a clean deterministic EncounterDirector state")
	check(restarted_scene.get_node("Route38/Environment").find_children("*","Sprite2D",true,false).size()==19,"Full restart recreates exactly one current environmental composition without duplicated decoration")
	check(restarted_scene.get_node("Route38/TrafficDirector").get_active_vehicle_count()==0,"Full restart creates no stale traffic instances")
	check(audio_manager.current_music_state==audio_manager.MUSIC_SILENT and audio_manager.music_player.stream==null and audio_manager.voices.all(func(voice: AudioStreamPlayer): return voice.stream==null),"Full restart leaves music and SFX playback clean")
	check(restarted_select.get_selected_definition().character_id==&"san_martin" and restarted_select.confirm_selected(),"Restarted selection keeps the previous character as default")
	check(restarted_scene.current_state==GAME_SESSION.DemoState.INTRO and restarted_scene.get_node("IntroFamailla").active,"Restarted selection starts a fresh intro")
	restarted_scene.restart_game()
	await frames(4)
	var intro_restart_scene = current_scene
	check(intro_restart_scene != restarted_scene and intro_restart_scene.current_state==GAME_SESSION.DemoState.CHARACTER_SELECT,"Restart during INTRO returns to clean character selection")
	check(not intro_restart_scene.get_node("IntroFamailla").active and not intro_restart_scene.get_node("Interface/DialogueBox").active,"Restart removes active cinematic and dialogue state")
	var intro_restart_select = intro_restart_scene.get_node("Interface/CharacterSelect")
	check(intro_restart_select.confirm_selected() and intro_restart_scene.get_node("IntroFamailla").skip(),"A clean restart can select, skip and enter gameplay")
	check(intro_restart_scene.get_node("Route38/Player").controls_enabled,"Skipped restarted intro accepts player control")
	check(intro_restart_scene.get_node("Route38/Player/ComboComponent").current_combo==0 and not intro_restart_scene.get_node("Interface/HUD/Combo").visible,"Restart creates a clean combo and HUD")
	check(intro_restart_scene.get_node("Route38/Player/TucumanazoCounterComponent").current_uses==5 and intro_restart_scene.get_node("Interface/HUD/SpecialStatus").text=="TUCUMANAZO x5" and not intro_restart_scene.get_node("Interface/HUD").has_node("SpecialBar"),"Restart creates a fresh five-use Tucumanazo counter without a bar")
	check(not intro_restart_scene.get_node("Interface/DialogueBox").active and not intro_restart_scene.get_node("Interface/DialogueBox").visible,"Restart and skip leave a clean inactive dialogue state")
	intro_restart_scene.queue_free()
	await frames(2)
	var elite_flow_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(elite_flow_scene)
	current_scene = elite_flow_scene
	await frames(4)
	check(elite_flow_scene.get_node("Interface/CharacterSelect").confirm_selected() and elite_flow_scene.get_node("IntroFamailla").skip(),"Elite-flow fixture enters gameplay through the normal selection and intro path")
	var elite_flow_route = elite_flow_scene.get_node("Route38")
	var elite_flow_player = elite_flow_route.get_node("Player")
	var elite_flow_dialogue = elite_flow_scene.get_node("Interface/DialogueBox")
	var elite_flow_hud = elite_flow_scene.get_node("Interface/HUD")
	var elite_flow_encounters = elite_flow_route.get_node("EncounterDirector")
	var elite_flow_traffic = elite_flow_route.get_node("TrafficDirector")
	elite_flow_route.set_physics_process(false)
	var closing_started := [0]
	var closing_finished := [0]
	elite_flow_scene.demo_closing_started.connect(func(): closing_started[0] += 1)
	elite_flow_scene.demo_closing_finished.connect(func(): closing_finished[0] += 1)
	check(elite_flow_encounters.activate_encounter(&"route_wave_06",7000.0),"Reusable Grandote encounter can start in a fresh run")
	var reusable_grandotes: Array[Node] = elite_flow_encounters.get_active_enemies(&"route_wave_06")
	var elite_flow_reward_start: int = elite_flow_player.score
	for reusable_grandote in reusable_grandotes:
		reusable_grandote.set_physics_process(false)
		reusable_grandote.take_damage(999,&"player")
	await frames(3)
	check(reusable_grandotes.size()==2 and elite_flow_encounters.is_encounter_completed(&"route_wave_06") and elite_flow_player.score==elite_flow_reward_start+600,"Reusable Grandotes grant only normal rewards and complete their wave")
	check(closing_started[0]==0 and closing_finished[0]==0 and not elite_flow_scene.demo_closing and not elite_flow_route.demo_closing,"Grandote defeat never starts the old demo-closing contract")
	check(elite_flow_scene.current_state==GAME_SESSION.DemoState.GAMEPLAY and not paused and not elite_flow_hud.get_node("Results").visible,"Grandote defeat leaves the session in GAMEPLAY without RESULT")
	check(not elite_flow_dialogue.active and not elite_flow_hud.boss_bar.visible and not elite_flow_hud.boss_name.visible,"Grandote defeat starts no ending dialogue or boss HUD")
	check(elite_flow_route.is_physics_processing()==false and elite_flow_traffic.enabled and elite_flow_player.controls_enabled and elite_flow_player.hurtbox.receiving_enabled,"Grandote completion leaves traffic and player systems enabled")
	elite_flow_scene.restart_game()
	await frames(4)
	var elite_restarted_scene = current_scene
	check(elite_restarted_scene != elite_flow_scene and elite_restarted_scene.current_state==GAME_SESSION.DemoState.CHARACTER_SELECT,"Restart after an elite wave returns to clean character selection")
	check(game_session.score==0 and game_session.coins==0 and game_session.active_checkpoint==&"" and game_session.checkpoint_completed_encounters.is_empty(),"Restart after an elite wave clears session and encounter progress")
	check(elite_restarted_scene.get_node("Route38/EncounterDirector").get_completed_encounter_ids().is_empty() and elite_restarted_scene.get_node("Route38/Enemies").get_children().filter(func(enemy: Node): return enemy.is_in_group("miniboss")).is_empty(),"Restart leaves no completed encounter or miniboss actor")
	check(elite_restarted_scene.get_node("Interface/CharacterSelect").confirm_selected() and elite_restarted_scene.get_node("IntroFamailla").skip() and elite_restarted_scene.current_state==GAME_SESSION.DemoState.GAMEPLAY,"The demo can begin again after a normal elite encounter")
	var boss_flow_route = elite_restarted_scene.get_node("Route38")
	var boss_flow_player = boss_flow_route.get_node("Player")
	var boss_flow_encounters = boss_flow_route.get_node("EncounterDirector")
	var boss_flow_hud = elite_restarted_scene.get_node("Interface/HUD")
	var boss_flow_dialogue = elite_restarted_scene.get_node("Interface/DialogueBox")
	var boss_flow_traffic = boss_flow_route.get_node("TrafficDirector")
	var boss_closing_started := [0]
	var boss_closing_finished := [0]
	elite_restarted_scene.demo_closing_started.connect(func(): boss_closing_started[0] += 1)
	elite_restarted_scene.demo_closing_finished.connect(func(): boss_closing_finished[0] += 1)
	boss_flow_route.set_physics_process(false)
	boss_flow_player.position = Vector2(7425.0,GameConfig.LANES[0])
	boss_flow_player.lane_index = 0
	boss_flow_route._physics_process(0.0)
	check(not is_instance_valid(boss_flow_route.boss),"Final boss waits for the last normal encounter to be completed")
	var all_encounters: Array[StringName] = boss_flow_encounters.get_registered_encounter_ids()
	boss_flow_encounters.restore_completed_encounters(all_encounters)
	boss_flow_route._physics_process(0.0)
	var palermitano = boss_flow_route.boss
	check(is_instance_valid(palermitano) and palermitano is PalermitanoBoss and palermitano.position.x==7600.0 and palermitano.health==90,"Final zone spawns one specialized 90-health Palermitano at x=7600")
	check(palermitano.coffee_telegraph==0.30 and palermitano.coffee_shot_interval==0.16 and palermitano.coffee_recovery==0.55 and palermitano.coffee_cooldown==1.80 and palermitano.summon_cooldown==5.0 and palermitano.chain_cooldown==1.35,"Palermitano pattern timings and cooldowns remain explicit and configurable")
	check(boss_flow_route.boss_active and boss_flow_hud.boss_bar.visible and boss_flow_hud.boss_name.text=="EL PALERMITANO" and not boss_flow_traffic.enabled,"Boss activation enables its arena, named HUD and traffic lock")
	check(elite_restarted_scene.camera_follow_min_x==7400.0 and elite_restarted_scene.camera_follow_max_x==7550.0,"Final arena constrains camera progression only during the boss encounter")
	palermitano.set_physics_process(false)
	palermitano.boss_state = palermitano.BossState.DECIDE
	boss_flow_player.lane_index = palermitano.lane_index
	boss_flow_player.hurtbox.lane_index = palermitano.lane_index
	boss_flow_player.position = Vector2(7200.0,GameConfig.LANES[palermitano.lane_index])
	var coffee_directions: Array[Vector2] = []
	palermitano.aimed_shot_requested.connect(func(_origin: Vector2,_lane: int,direction: Vector2,_kind: String,_team: String): coffee_directions.append(direction))
	check(palermitano.begin_pattern(palermitano.Pattern.TRIPLE_COFFEE),"Palermitano can begin triple coffee at range")
	palermitano._process_telegraph(palermitano.coffee_telegraph)
	palermitano._process_attack(palermitano.coffee_shot_interval)
	palermitano._process_attack(palermitano.coffee_shot_interval)
	check(palermitano.coffee_projectiles_emitted==3 and coffee_directions.size()==3 and boss_flow_route.get_node("Projectiles").get_child_count()==3,"Triple coffee emits exactly three separated projectiles once")
	check(coffee_directions.all(func(direction: Vector2): return is_equal_approx(direction.length(),1.0)) and coffee_directions[0]!=coffee_directions[1] and coffee_directions[1]!=coffee_directions[2],"Triple coffee uses normalized vector trajectories with a small readable spread")
	var coffee_projectile = boss_flow_route.get_node("Projectiles").get_child(0)
	var coffee_travel_direction: Vector2 = coffee_projectile.travel_direction
	var coffee_visual_rotation: float = coffee_projectile.visual.rotation
	coffee_projectile._physics_process(0.02)
	check(coffee_projectile.travel_direction==coffee_travel_direction and coffee_projectile.visual.rotation==coffee_visual_rotation,"Coffee is non-homing and keeps one stable orientation during straight travel")
	palermitano.boss_state = palermitano.BossState.DECIDE
	palermitano._summon_cooldown_remaining = 0.0
	boss_flow_player.position = Vector2(7350.0,GameConfig.LANES[palermitano.lane_index])
	check(palermitano.begin_pattern(palermitano.Pattern.SUMMON_AGENTS),"Palermitano can begin its summon pattern at medium range")
	palermitano._process_telegraph(palermitano.summon_telegraph)
	var summon_count_after_first: int = palermitano.get_live_summon_count()
	palermitano._emit_summons_once()
	check(summon_count_after_first==2 and palermitano.get_live_summon_count()==2 and palermitano.summon_requests_emitted==1 and palermitano._summon_cooldown_remaining==5.0,"Summon creates at most two normal Agentes, starts cooldown and cannot emit twice in one activation")
	palermitano.boss_state = palermitano.BossState.DECIDE
	palermitano._summon_cooldown_remaining = 0.0
	check(not palermitano.begin_pattern(palermitano.Pattern.SUMMON_AGENTS),"Palermitano cannot summon while two summoned Agentes remain alive")
	var boss_health_before_respawn: int = palermitano.health
	var boss_summons_before_respawn: Array[Node] = []
	for summon_reference: WeakRef in palermitano._summons:
		var boss_summon: Node = summon_reference.get_ref()
		if is_instance_valid(boss_summon):
			boss_summons_before_respawn.append(boss_summon)
	var boss_lives_before_respawn: int = boss_flow_player.lives
	boss_flow_player.position = Vector2(7350.0,GameConfig.LANES[palermitano.lane_index])
	boss_flow_player.lane_index = palermitano.lane_index
	boss_flow_player.hurtbox.lane_index = palermitano.lane_index
	boss_flow_player.collision_mask = 1 << palermitano.lane_index
	boss_flow_player.invulnerability = 0.0
	boss_flow_player.health = 1
	boss_flow_player.take_damage(1,"enemy")
	check(boss_flow_player.lives==boss_lives_before_respawn-1 and boss_flow_player.position.x>=boss_flow_route.BOSS_ARENA_BOUNDS.x+boss_flow_route.LOCAL_RESPAWN_ARENA_PADDING and boss_flow_player.position.x<=boss_flow_route.BOSS_ARENA_BOUNDS.y-boss_flow_route.LOCAL_RESPAWN_ARENA_PADDING,"Boss death respawns locally inside the arena with one life consumed")
	check(boss_flow_route.boss==palermitano and palermitano.health==boss_health_before_respawn and boss_flow_route.boss_active and boss_flow_hud.boss_bar.visible,"Boss local respawn preserves the same Palermitano instance, HP, arena and HUD")
	check(palermitano.get_live_summon_count()==boss_summons_before_respawn.size(),"Boss local respawn preserves the summon count without duplication (%d -> %d)" % [boss_summons_before_respawn.size(),palermitano.get_live_summon_count()])
	check(boss_summons_before_respawn.all(func(summon: Node): return is_instance_valid(summon) and summon.is_inside_tree()),"Boss local respawn preserves every existing summon instance")
	palermitano.boss_state = palermitano.BossState.DECIDE
	palermitano._chain_cooldown_remaining = 0.0
	boss_flow_player.position = Vector2(palermitano.position.x-100.0,GameConfig.LANES[palermitano.lane_index])
	check(palermitano.begin_pattern(palermitano.Pattern.CHAIN),"Chain can begin only at short range on the same lane")
	check(not palermitano.chain_hitbox.active,"Chain hitbox stays inactive during its telegraph")
	palermitano._process_telegraph(palermitano.chain_definition.startup_duration)
	check(palermitano.chain_hitbox.active and palermitano.chain_hitbox.damage==2 and palermitano.chain_activations==1,"Chain hitbox activates once during its two-damage impact window")
	palermitano._process_attack(palermitano.chain_definition.active_duration)
	check(not palermitano.chain_hitbox.active and palermitano.boss_state==palermitano.BossState.RECOVERY,"Chain hitbox closes before its punishable recovery")
	palermitano.boss_state = palermitano.BossState.DECIDE
	palermitano._chain_cooldown_remaining = 0.0
	palermitano.last_pattern = palermitano.Pattern.CHAIN
	check(palermitano.choose_pattern()!=palermitano.Pattern.CHAIN,"Pattern selection prevents consecutive chain loops at point-blank range")
	palermitano.last_pattern = palermitano.Pattern.NONE
	boss_flow_player.position.x = palermitano.position.x-300.0
	check(not palermitano.begin_pattern(palermitano.Pattern.CHAIN),"Chain is rejected outside its configured short range")
	var final_score_before: int = boss_flow_player.score
	palermitano.health_component.set_invulnerability(0.0)
	palermitano.take_damage(999,&"player")
	palermitano.take_damage(999,&"player")
	await frames(3)
	check(boss_flow_player.score==final_score_before+1500 and boss_closing_started[0]==1 and elite_restarted_scene.demo_closing,"Palermitano defeat awards its reward and starts demo closing exactly once")
	check(not boss_flow_hud.boss_bar.visible and not boss_flow_hud.boss_name.visible and not boss_flow_route.boss_active,"Boss defeat clears HUD and arena state without depending on Grandote")
	check(boss_flow_dialogue.active and boss_flow_route.get_node("Enemies").get_child_count()==0 and boss_flow_route.get_node("Projectiles").get_child_count()==0,"Boss closing removes remaining summons and projectiles without waiting for them")
	while boss_flow_dialogue.active:
		boss_flow_dialogue.advance()
	await frames(2)
	check(elite_restarted_scene.current_state==GAME_SESSION.DemoState.RESULT and boss_closing_finished[0]==1 and boss_flow_hud.get_node("Results").visible,"Palermitano ending reaches RESULT exactly once")
	elite_restarted_scene.restart_game()
	await frames(4)
	var boss_restarted_scene = current_scene
	check(boss_restarted_scene.current_state==GAME_SESSION.DemoState.CHARACTER_SELECT and boss_restarted_scene.get_node("Route38/Enemies").get_child_count()==0 and boss_restarted_scene.get_node("Route38/Projectiles").get_child_count()==0,"Restart after Palermitano leaves no boss, summon or projectile nodes")
	boss_restarted_scene.queue_free()
	await frames(2)
	var special_death_player = load("res://scenes/actors/player.tscn").instantiate()
	root.add_child(special_death_player)
	await frames(2)
	special_death_player.controls_enabled = true
	special_death_player.position = Vector2(80,370)
	special_death_player.health = 1
	special_death_player.lives = 1
	special_death_player.shot_cooldown = 0.0
	check(special_death_player.start_tucumanazo(),"Tucumanazo can start before lethal damage validation")
	special_death_player.take_damage(1,"enemy")
	check(special_death_player.state==special_death_player.State.DEATH and not special_death_player.special_active and not special_death_player.tucumanazo_hitbox.active and special_death_player.tucumanazo_counter.current_uses==4,"Death cancels Tucumanazo without duplicating or refunding its consumption")
	special_death_player.queue_free()
	await frames(2)
	var collection_death_player = load("res://scenes/actors/player.tscn").instantiate()
	root.add_child(collection_death_player)
	var collection_death_pickup = PICKUP_SCENE.instantiate()
	collection_death_pickup.kind = "stone_pile"
	collection_death_pickup.asset = "montaña_cascote"
	collection_death_pickup.lane_index = 0
	root.add_child(collection_death_pickup)
	await frames(2)
	collection_death_player.controls_enabled = true
	collection_death_player.position = Vector2(80,370)
	collection_death_player.health = 1
	collection_death_player.lives = 1
	collection_death_pickup._on_body_entered(collection_death_player)
	check(collection_death_player.collection_active and collection_death_player.stones==0,"Lethal-damage probe begins collection before its reward point")
	collection_death_player.take_damage(1,"enemy")
	check(collection_death_player.state==collection_death_player.State.DEATH and not collection_death_player.collection_active and not collection_death_pickup.used and collection_death_player.stones==0,"Death cancels an unrewarded collection without leaving a blocked state or granting ammo")
	collection_death_player.queue_free()
	collection_death_pickup.queue_free()
	await frames(2)
	var death_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(death_scene)
	current_scene = death_scene
	await frames(3)
	death_scene.get_node("Interface/CharacterSelect").confirm_selected()
	death_scene.get_node("IntroFamailla").skip()
	var dying_player = death_scene.get_node("Route38/Player")
	dying_player.combo_component.register_hit(&"death_reset_test")
	dying_player.health = 1
	dying_player.lives = 1
	dying_player.shot_cooldown = 0.0
	check(dying_player.start_tucumanazo() and dying_player.tucumanazo_counter.current_uses==4,"Final-life player can consume one Tucumanazo before lethal damage")
	dying_player.take_damage(1,"enemy")
	check(dying_player.state==dying_player.State.DEATH and dying_player.visual.animation==&"Death" and not dying_player.special_active and not dying_player.tucumanazo_hitbox.active and dying_player.tucumanazo_counter.current_uses==4 and dying_player.combo_component.current_combo==0,"Death cancels Tucumanazo, preserves spent stock, clears combo and uses the death pose")
	await frames(40)
	check(death_scene.finished and paused,"Game over pauses completed death sequence")
	paused = false
	await create_timer(0.4).timeout
	root.get_node("AudioManager").clear_music_registry()
	root.get_node("AudioManager").stop_all()
	await create_timer(0.3).timeout
	death_scene.queue_free()
	await frames(3)
	var result: Dictionary = {"passed":failures.is_empty(),"checks":checks,"errors":failures,"engine":Engine.get_version_info().string}
	var output := FileAccess.open("res://validation/godot_test_results.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  ")+"\n")
	output.close()
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)


func _capture_intro_result(scene: Node) -> Dictionary:
	var result_player = scene.get_node("Route38/Player")
	var result_session = root.get_node("GameSession")
	var result_encounters = scene.get_node("Route38/EncounterDirector")
	var live_enemy_count := 0
	for encounter_id: StringName in result_encounters.get_registered_encounter_ids():
		live_enemy_count += result_encounters.get_active_enemy_count(encounter_id)
	return {
		"position": result_player.position,
		"health": result_player.health,
		"lives": result_player.lives,
		"score": result_player.score,
		"coins": result_player.coins,
		"stones": result_player.stones,
		"oranges_unlocked": result_player.oranges_unlocked,
		"checkpoint": result_session.active_checkpoint,
		"completed_encounters": result_encounters.get_completed_encounter_ids(),
		"live_enemies": live_enemy_count,
		"combo": result_player.combo_component.current_combo,
		"special": result_player.tucumanazo_counter.current_uses,
		"camera_position": scene.camera.position,
		"camera_smoothing": scene.camera.position_smoothing_enabled,
		"flow_state": scene.current_state
	}
