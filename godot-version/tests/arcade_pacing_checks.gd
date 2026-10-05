extends RefCounted

static func run(tree: SceneTree,scene: Node) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var route = scene.get_node("Route38")
	var director = route.encounter_director
	route.set_physics_process(false)
	director.reset_runtime_state(true)
	director.camera_center_x = NAN
	director.activate_encounter(&"route_wave_03",3500.0)
	var actors: Array = director.get_active_enemies(&"route_wave_03")
	for actor in actors:
		actor.set_physics_process(false)
	results.append({"ok":director.request_attack(actors[0]),"message":"First minor obtains attack token"})
	results.append({"ok":not director.request_attack(actors[1]),"message":"Grant spacing prevents same-frame synchronized attacks"})
	director.advance_spawns(0.23)
	results.append({"ok":not director.request_attack(actors[1]),"message":"Second minor waits even after grant spacing"})
	director.advance_spawns(0.23)
	results.append({"ok":not director.request_attack(actors[2]) and director.get_attack_token_count()==1,"message":"Early pool keeps exactly one attacker"})
	actors[2]._advance_ranged_lifecycle(actors[2].definition.entry_duration,-300.0)
	actors[2]._advance_ranged_lifecycle(actors[2]._state_remaining,-300.0)
	actors[2]._begin_attack()
	results.append({"ok":actors[2].ai_state==actors[2].AIState.REACT,"message":"Ready minor waits in reaction when another actor holds the token"})
	actors[0].take_damage(999,&"player")
	results.append({"ok":director.get_attack_token_count()==0 and director.request_attack(actors[2]),"message":"Death immediately releases token to waiting attacker"})
	actors[2].ai_state = actors[2].AIState.RECOVERY
	actors[2]._state_remaining = 0.0
	actors[2]._advance_attack_state(0.1)
	results.append({"ok":director.get_attack_token_count()==0,"message":"Recovery releases minor token"})
	director.advance_spawns(0.23)
	director.request_attack(actors[2])
	actors[2].queue_free()
	await tree.process_frame
	results.append({"ok":director.get_attack_token_count()==0,"message":"Tree exit releases token"})
	director.reset_runtime_state(true)
	director.activate_encounter(&"route_wave_06",6800.0)
	actors = director.get_active_enemies(&"route_wave_06")
	for actor in actors:
		actor.set_physics_process(false)
	for index in range(1,3):
		director.advance_spawns(0.23)
		results.append({"ok":director.request_attack(actors[index])==(index==1),"message":"Dense encounter grants only first ranged token, request %d" % index})
	results.append({"ok":director.get_attack_token_count()==1,"message":"Dense encounters also keep the ranged cap at one"})
	results.append({"ok":not director.request_attack(actors[3]),"message":"Dense encounter refuses a third ranged holder"})
	director.reset_runtime_state(true)
	results.append({"ok":director.get_attack_token_count()==0,"message":"Restart clears all attack tokens"})
	director.activate_encounter(&"route_wave_03",3500.0,true)
	director.activate_encounter(&"route_wave_01",900.0)
	director.advance_spawns(0.46,3500.0)
	director.advance_spawns(0.45,3500.0)
	director.advance_spawns(1.5,3500.0)
	results.append({"ok":director.get_active_enemy_count(&"route_wave_03")==1 and director._pending.size()==5,"message":"Population cap seven keeps excess entries pending"})
	director.reset_runtime_state(true)
	director.activate_encounter(&"route_drone_02",6100.0)
	actors = director.get_active_enemies(&"route_drone_02")
	for actor in actors:
		actor.set_physics_process(false)
	var first_drone_granted: bool = director.request_attack(actors[0])
	director.advance_spawns(0.8)
	var second_drone_blocked: bool = not director.request_attack(actors[1])
	director.release_attack(actors[0])
	director.advance_spawns(0.76)
	var second_drone_granted: bool = director.request_attack(actors[1])
	results.append({"ok":first_drone_granted and second_drone_blocked and second_drone_granted and director.get_drone_attack_token_count()==1,"message":"Five-Drone wave grants one aerial token with a 0.75-second handoff"})
	director.reset_runtime_state(true)
	director.activate_encounter(&"route_wave_03",3500.0,true)
	director.advance_spawns(0.46,3500.0)
	results.append({"ok":director.get_active_enemy_count(&"route_wave_03")==2,"message":"First sub-wave contains two entries"})
	director.advance_spawns(0.43,3500.0)
	results.append({"ok":director.get_active_enemy_count(&"route_wave_03")==2,"message":"Third entry waits until its 0.90-second absolute timestamp"})
	director.advance_spawns(0.02,3500.0)
	results.append({"ok":director.get_active_enemy_count(&"route_wave_03")==3,"message":"Third reinforcement follows the second by 0.45 seconds"})
	director.reset_runtime_state(true)
	director.update_safety(7700.0,7600.0,800.0)
	director.activate_encounter(&"route_wave_01",7700.0,true)
	director.advance_spawns(0.44,7700.0)
	results.append({"ok":director.get_active_enemy_count(&"route_wave_01")==1,"message":"Micro-wave respects 0.45-second entry spacing"})
	director.advance_spawns(0.02,7800.0)
	actors = director.get_active_enemies(&"route_wave_01")
	for actor in actors:
		actor.set_physics_process(false)
	results.append({"ok":actors.size()==2 and actors[1].position.x>=8280.0,"message":"Fast Player cannot be overlapped by clamped delayed spawn"})
	results.append({"ok":not director.activate_encounter(&"route_wave_01"),"message":"Encounter cannot duplicate"})
	actors[0].position.x = 6800.0
	director.update_safety(7800.0,7600.0,800.0)
	results.append({"ok":actors[0].is_queued_for_deletion() and not actors[1].is_queued_for_deletion(),"message":"Leash retires only actors far behind, never in front"})
	director.advance_spawns(2.3,7800.0)
	for remaining_actor in director.get_active_enemies(&"route_wave_01"):
		remaining_actor.take_damage(999,&"player")
	await tree.process_frame
	results.append({"ok":director.is_resting(),"message":"Completion creates breathing pause"})
	director.update_activation(7800.0)
	results.append({"ok":not director.is_encounter_activated(&"route_wave_02"),"message":"Rest blocks next encounter even if Player rushed ahead"})
	director.reset_runtime_state(true)
	var protected_rewards: Array[Node] = route.get_node("Objects").get_children().filter(func(item: Node): return item.has_meta("reward_after"))
	results.append({"ok":protected_rewards.size()==1 and protected_rewards.all(func(item: Node): return not item.visible),"message":"The remaining protected sandwich starts hidden"})
	var completed_for_reward: Array[StringName] = [&"route_drone_02"]
	director.restore_completed_encounters(completed_for_reward)
	route._refresh_protected_rewards()
	var drone_reward: Node = protected_rewards.filter(func(item: Node): return int(item.position.x)==6200)[0]
	results.append({"ok":drone_reward.visible and protected_rewards.filter(func(item: Node): return item.visible).size()==1,"message":"Only the reward for a completed heavy encounter appears"})
	var nearby_threat = route.spawn_enemy("hipster",6350.0,0)
	nearby_threat.set_physics_process(false)
	route._refresh_protected_rewards()
	results.append({"ok":not drone_reward.visible,"message":"Protected reward hides while a nearby threat remains"})
	nearby_threat.queue_free()
	await tree.process_frame
	route._refresh_protected_rewards()
	results.append({"ok":drone_reward.visible and protected_rewards.size()==1,"message":"Safe reward returns without duplicate instances"})
	var collected_reward_ids: Array[StringName] = [drone_reward.pickup_id]
	route.restore_checkpoint_state(completed_for_reward,collected_reward_ids)
	results.append({"ok":drone_reward.used and not drone_reward.visible,"message":"Collected protected reward stays consumed after checkpoint restore"})
	var no_completed: Array[StringName] = []
	var no_collected: Array[StringName] = []
	route.restore_checkpoint_state(no_completed,no_collected)
	results.append({"ok":not drone_reward.used and not drone_reward.visible,"message":"Fresh restart restores reward once but keeps it gated"})
	director.camera_center_x = NAN
	await tree.process_frame
	return results
