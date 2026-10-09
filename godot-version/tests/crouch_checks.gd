extends SceneTree
## Agacharse: ↓ en el piso → agacharse → agachado (bucle) → soltar → levantarse → idle; hurtbox al 60 %,
## velocidad ≤ 25 %, saltar cancela, se puede lanzar agachado y un disparo a altura de cabeza solo golpea parado.

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func expect(condition: bool,message: String,context: Dictionary = {}) -> void:
	checks += 1
	if condition:
		return
	var diagnostic := "%s | %s" % [message,JSON.stringify(context)]
	failures.append(diagnostic)
	push_error(diagnostic)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

## Proyectil enemigo horizontal a `height` px sobre los pies del jugador; devuelve si le hizo daño.
func shoot_at_height(route: Node, scene: Node, player: CharacterBody2D, height: float) -> bool:
	player.health_component.set_invulnerability(0.0)
	var before: int = player.health
	var projectile = load("res://scenes/actors/projectile.tscn").instantiate()
	projectile.position = Vector2(player.position.x+140.0,player.position.y-height)
	projectile.direction = -1
	projectile.travel_direction = Vector2.LEFT
	projectile.kind = &"agent_orb"
	projectile.team = &"enemy"
	route.get_node("Projectiles").add_child(projectile)
	for i in 60:
		await physics_frame
		if is_instance_valid(projectile) and projectile.spent:
			break
	var hit: bool = player.health < before
	if is_instance_valid(projectile):
		projectile.queue_free()
	player.health = before
	await physics_frame
	return hit

func run() -> void:
	root.size = Vector2i(800,450)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("Interface/CharacterSelect").confirm_selected()
	scene.get_node("IntroFamailla").skip()
	await process_frame
	var CFG = load("res://scripts/prototype/feel_config.gd")
	var route = scene.get_node("Route38")
	var player: CharacterBody2D = route.player
	route.encounter_director._rest_remaining = 1000000.0
	player.position.x = 2000.0
	player.oranges_unlocked = true
	player.stones = 20
	await frames(10)
	var standing_height: float = (player.hurtbox.collision_shape.shape as RectangleShape2D).size.y
	expect(CFG.CROUCH_SPEED_MULT <= 0.25,"Velocidad agachado parametrizada ≤ 25 %",{})
	# Parado: un disparo a altura de cabeza golpea.
	var head := standing_height*0.85
	expect(await shoot_at_height(route,scene,player,head),"Parado, el disparo a altura de cabeza golpea",{"head":head})
	player.hit_time = 0.0
	player.velocity = Vector2.ZERO
	await frames(30)
	player.position.x = 2000.0
	# Agacharse.
	Input.action_press("aim_down")
	await frames(2)
	expect(player.crouch_phase == player.CrouchPhase.DOWN and player.visual.animation == &"agacharse","↓ en el piso inicia agacharse",{"phase":player.crouch_phase,"anim":player.visual.animation})
	await frames(20)
	expect(player.crouch_phase == player.CrouchPhase.HELD and player.visual.animation == &"agachado","Luego queda agachado en bucle",{"phase":player.crouch_phase})
	var crouched_height: float = (player.hurtbox.collision_shape.shape as RectangleShape2D).size.y
	expect(absf(crouched_height/standing_height-CFG.CROUCH_HURTBOX_RATIO) < 0.01,"Hurtbox al 60 % de la altura",{"ratio":crouched_height/standing_height})
	expect(absf(player.hurtbox.collision_shape.position.y+crouched_height*0.5) < 0.01,"Los pies de la hurtbox quedan fijos",{})
	expect(not await shoot_at_height(route,scene,player,head),"Agachado, el disparo a altura de cabeza NO golpea",{"head":head})
	expect(await shoot_at_height(route,scene,player,crouched_height*0.4),"Agachado, un disparo bajo sí golpea",{})
	player.hit_time = 0.0
	await frames(30)
	expect(player.crouching,"Sigue agachado tras recibir un golpe",{"phase":player.crouch_phase})
	# Mover mientras está agachado.
	Input.action_press("move_right")
	var x0 := player.position.x
	await frames(15)
	expect(absf(player.position.x-x0) <= 15.0*player.walk_speed*CFG.CROUCH_SPEED_MULT/60.0+0.5 and player.crouching,"Agachado casi no se desplaza",{"dx":player.position.x-x0})
	Input.action_release("move_right")
	# Lanzar agachado: se mantiene agachado y el proyectil sale bajo.
	var container: Node = route.get_node("Projectiles")
	for child in container.get_children():
		child.queue_free()
	await physics_frame
	player.shot_cooldown = 0.0
	player.throw_projectile("orange")
	await frames(6)
	expect(player.crouching and player.visual.animation == &"agachado","Lanza agachado sin salir de la pose",{"anim":player.visual.animation})
	var shot = container.get_child(0) if container.get_child_count() > 0 else null
	expect(shot != null and shot.position.y > player.position.y-35.0,"El proyectil agachado sale más bajo",{"y":shot.position.y-player.position.y if shot else null})
	# Ya no apunta abajo en el piso.
	expect(player.get_shot_direction().y == 0.0,"↓ en el piso no apunta abajo",{"dir":player.get_shot_direction()})
	# Soltar: levantarse → idle.
	Input.action_release("aim_down")
	await frames(2)
	expect(player.crouch_phase == player.CrouchPhase.UP and player.visual.animation == &"levantarse","Soltar ↓ inicia levantarse",{"phase":player.crouch_phase})
	await frames(25)
	expect(player.crouch_phase == player.CrouchPhase.NONE and player.visual.animation == player.character_definition.idle_animation,"Termina en idle",{"anim":player.visual.animation})
	expect(absf((player.hurtbox.collision_shape.shape as RectangleShape2D).size.y-standing_height) < 0.01,"La hurtbox vuelve a su altura",{})
	# Saltar cancela el agachado.
	Input.action_press("aim_down")
	await frames(30)
	expect(player.crouching,"Se agacha de nuevo",{})
	Input.action_press("jump")
	await frames(3)
	expect(player.crouch_phase == player.CrouchPhase.NONE and not player.is_on_floor(),"Saltar cancela el agachado",{"phase":player.crouch_phase})
	Input.action_release("jump")
	Input.action_release("aim_down")
	scene.queue_free()
	await process_frame
	print("CROUCH_CHECKS %d/%d" % [checks-failures.size(),checks])
	quit(0 if failures.is_empty() else 1)
