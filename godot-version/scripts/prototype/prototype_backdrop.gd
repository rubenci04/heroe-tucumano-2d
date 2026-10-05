extends Node2D
## Fondo por capas de la arena prototipo. Cielo repetido sin espejar (módulos que se funden entre sí)
## y panorama lejano; cada capa se desplaza a su propia fracción del avance de Ciruja.

const CFG = preload("res://scripts/prototype/feel_config.gd")
const SKY_TEXTURE = preload("res://assets/fondo_cerros.png")
const PANORAMA_TEXTURE = preload("res://assets/fondo_completo.png")
const SEAMLESS = preload("res://shaders/seamless_tile.gdshader")

var player: Node2D
var origin_x := 0.0          # X del jugador al arrancar (referencia del desplazamiento)
var view_left := 200.0       # borde izquierdo visible
var view_center := 400.0
var sky_tiles: Array[Sprite2D] = []
var panorama: Sprite2D
var sky_step := 0.0


func setup(player_node: Node2D, left: float, center: float) -> void:
	player = player_node
	origin_x = player.global_position.x
	view_left = left
	view_center = center
	_build_sky()
	_build_panorama()
	_build_floor()


func _build_sky() -> void:
	var material := ShaderMaterial.new()
	material.shader = SEAMLESS
	material.set_shader_parameter("overlap", CFG.BACKDROP_SKY_OVERLAP)
	sky_step = CFG.BACKDROP_SKY_TILE_PX * CFG.BACKDROP_SKY_SCALE
	var top := CFG.BACKDROP_SKY_BOTTOM_Y - SKY_TEXTURE.get_height() * CFG.BACKDROP_SKY_SCALE
	for index in 2:
		var tile := Sprite2D.new()
		tile.name = "SkyTile%d" % index
		tile.texture = SKY_TEXTURE
		tile.material = material
		tile.region_enabled = true
		tile.region_rect = Rect2(0.0, 0.0, CFG.BACKDROP_SKY_TILE_PX, SKY_TEXTURE.get_height())
		tile.centered = false
		tile.scale = Vector2.ONE * CFG.BACKDROP_SKY_SCALE
		tile.position = Vector2(view_left + index * sky_step, top)
		tile.z_index = -9
		add_child(tile)
		sky_tiles.append(tile)


func _build_panorama() -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = PANORAMA_TEXTURE
	atlas.region = CFG.BACKDROP_PANORAMA_REGION
	panorama = Sprite2D.new()
	panorama.name = "Panorama"
	panorama.texture = atlas
	panorama.centered = false
	panorama.scale = Vector2.ONE * CFG.BACKDROP_PANORAMA_SCALE
	panorama.position = Vector2(view_center - atlas.region.size.x * CFG.BACKDROP_PANORAMA_SCALE * 0.5, CFG.BACKDROP_PANORAMA_BOTTOM_Y - atlas.region.size.y * CFG.BACKDROP_PANORAMA_SCALE)
	panorama.z_index = -7
	add_child(panorama)


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var travelled := player.global_position.x - origin_x
	var shift := fposmod(travelled * CFG.BACKDROP_SCROLL_SKY, sky_step)
	for index in sky_tiles.size():
		sky_tiles[index].position.x = view_left - shift + index * sky_step
	panorama.position.x = view_center - panorama.texture.get_width() * panorama.scale.x * 0.5 - travelled * CFG.BACKDROP_SCROLL_PANORAMA


## Suelo opaco y continuo: reemplaza la tira de 5 px visible; el panorama queda como fondo, no como piso.
func _build_floor() -> void:
	var old := get_parent().get_node_or_null("FloorVisual")
	if old != null:
		old.visible = false
	var width := 2000.0
	var left := view_center - width * 0.5
	var bands := [
		[CFG.FLOOR_TOP_Y, CFG.FLOOR_BOTTOM_Y - CFG.FLOOR_TOP_Y, CFG.FLOOR_COLOR],
		[CFG.FLOOR_TOP_Y, CFG.FLOOR_CURB_HEIGHT, CFG.FLOOR_CURB_COLOR],
		[CFG.FLOOR_TOP_Y + CFG.FLOOR_CURB_HEIGHT, CFG.FLOOR_SHADE_HEIGHT, CFG.FLOOR_SHADE_COLOR],
	]
	for index in bands.size():
		var band := ColorRect.new()
		band.name = "FloorBand%d" % index
		band.position = Vector2(left, bands[index][0])
		band.size = Vector2(width, bands[index][1])
		band.color = bands[index][2]
		band.z_index = -6
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(band)
