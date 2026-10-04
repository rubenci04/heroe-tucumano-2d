extends RefCounted
## Prototype only. Uniform actor scale keeps collision, hurtboxes and local attacks together.
const CFG = preload("res://scripts/prototype/feel_config.gd")

static func visible_height(sprite: AnimatedSprite2D) -> float:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	return CollisionFactory.opaque_bounds(texture).size.y * sprite.scale.y

static func remember(actor: Node2D) -> void:
	actor.set_meta("original_visible_height", visible_height(actor.visual))
	actor.visual.set_meta("legacy_visual_scale", actor.visual.scale.y)

static func apply(actor: Node2D, character: String) -> void:
	if character == "ciruja":
		return # Do not change player scale, collision, reach or launch points.
	var sprite: AnimatedSprite2D = actor.visual
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	var bounds := CollisionFactory.opaque_bounds(texture)
	var original_height := float(actor.get_meta("original_visible_height"))
	var factor := CFG.target_height(character) / original_height
	actor.scale = Vector2.ONE * factor
	sprite.scale = Vector2.ONE * (original_height / bounds.size.y)
	sprite.set_meta("batch_visual_scale", sprite.scale.y)
	actor.set_meta("prototype_character", character)
	# Local body geometry uses the new opaque silhouette, then inherits uniform actor scale.
	var body: CollisionShape2D = actor.get_node_or_null("CollisionShape2D")
	if body != null and body.shape is RectangleShape2D:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(maxf(6.0, bounds.size.x * sprite.scale.x * 0.65), original_height * 0.9)
		body.shape = shape
		body.position = Vector2(0.0, -shape.size.y * 0.5)
		actor.hurtbox.copy_shape_from(body)
		var contact: CollisionShape2D = actor.get_node_or_null("Contact/CollisionShape2D")
		if contact != null:
			contact.shape = shape.duplicate()
			contact.position = body.position
	# Distances are world-space; local hitbox definitions already inherit actor scale.
	if actor.get("definition") != null:
		actor.definition = actor.definition.duplicate(true)
		actor.definition.attack_range *= factor
		actor.definition.preferred_distance *= factor
	elif actor.get("chain_range") != null:
		actor.chain_range *= factor

static func apply_npc(sprite: AnimatedSprite2D, character: String) -> void:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	sprite.scale = Vector2.ONE * (CFG.target_height(character) / CollisionFactory.opaque_bounds(texture).size.y)
