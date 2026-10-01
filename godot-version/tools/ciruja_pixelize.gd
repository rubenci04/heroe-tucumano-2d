extends SceneTree
## Experimento aislado: genera Ciruja pixelada (base + 2 variantes) en assets/prototype/ciruja_pixel/.
## Uso: Godot_console --headless --path godot-version --script res://tools/ciruja_pixelize.gd
## No modifica ningún asset original; solo lee player.tres y los PNG que referencia.

const FRAMES_PATH := "res://assets/animations/player.tres"
const OUT_DIR := "res://assets/prototype/ciruja_pixel"
const TARGET_H := 64.0
const REF_H := 198.0          # alto opaco del idle original (para escala única en todos los frames)
const CANVAS := Vector2i(80, 72)
const ANCHOR := Vector2i(40, 68)   # punto de apoyo común (pie) en todos los frames
const PALETTE_SIZE := 15           # + 1 color de contorno = 16
const OUTLINE := Color(0.10, 0.07, 0.12)
const FOOT_ROWS := 8


func _init() -> void:
	var sf: SpriteFrames = load(FRAMES_PATH)
	var files := {}   # basename -> ruta original
	for anim in sf.get_animation_names():
		for i in sf.get_frame_count(anim):
			var tex := sf.get_frame_texture(anim, i)
			if tex != null and tex.resource_path != "":
				files[tex.resource_path.get_file()] = tex.resource_path
	var scaled := {}  # basename -> {img, ground, h}
	var samples: Array[Color] = []
	var k := TARGET_H / REF_H
	for name in files:
		var img := Image.new()
		img.load(ProjectSettings.globalize_path(files[name]))
		img.convert(Image.FORMAT_RGBA8)
		var info := _shrink(img, k)
		scaled[name] = info
		for p in info.pixels:
			samples.append(p)
	var palette := _median_cut(samples, PALETTE_SIZE)
	var variants := {
		"base": palette,
		"var_a_saturada": _tint(palette, 1.55, 1.08, 0.0),
		"var_b_apagada": _tint(palette, 0.5, 0.92, 0.12),
	}
	var report := PackedStringArray()
	report.append("frame | alto_px | ancho_px | pie_y | colores")
	var idle_h := 0
	for v in variants:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR + "/" + v))
	for name in scaled:
		var info: Dictionary = scaled[name]
		var idx_img := _quantize(info.img, palette)
		for v in variants:
			var out := _recolor(idx_img, variants[v])
			out.save_png(ProjectSettings.globalize_path("%s/%s/%s" % [OUT_DIR, v, name]))
		var b := _bounds(idx_img)
		if name == "ciruja_idle.png":
			idle_h = b.size.y
		report.append("%s | %d | %d | %d | %d" % [name, b.size.y, b.size.x, b.end.y - 1, _count_colors(idx_img)])
	var f := FileAccess.open(OUT_DIR + "/report.txt", FileAccess.WRITE)
	f.store_string("idle_h=%d\n%s\n" % [idle_h, "\n".join(report)])
	f.close()
	print("OK frames=%d" % scaled.size())
	quit()


## Reduce a k, umbral de alfa (sin suavizado) y reubica el pie en ANCHOR.
func _shrink(src: Image, k: float) -> Dictionary:
	var w := src.get_width()
	var h := src.get_height()
	var gy := -1
	for y in range(h - 1, -1, -1):
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				gy = y
				break
		if gy >= 0:
			break
	var sx := 0.0
	var n := 0
	for y in range(maxi(gy - FOOT_ROWS, 0), gy + 1):
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				sx += x
				n += 1
	var gx := sx / maxf(n, 1)
	var nw := maxi(int(round(w * k)), 1)
	var nh := maxi(int(round(h * k)), 1)
	var small := src.duplicate() as Image
	small.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
	var dest := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	var ox := ANCHOR.x - int(round(gx * k))
	var low := 0
	for y in range(nh - 1, -1, -1):
		var hit := false
		for x in nw:
			if small.get_pixel(x, y).a > 0.5:
				hit = true
				break
		if hit:
			low = y
			break
	var oy := (ANCHOR.y - 1) - low   # la fila más baja cae siempre en y=67 (contorno en 68)
	var pixels: Array[Color] = []
	for y in nh:
		for x in nw:
			var c := small.get_pixel(x, y)
			var dx := x + ox
			var dy := y + oy
			if c.a > 0.5 and dx >= 0 and dy >= 0 and dx < CANVAS.x and dy < CANVAS.y:
				c.a = 1.0
				dest.set_pixel(dx, dy, c)
				pixels.append(c)
	return {"img": dest, "pixels": pixels}


func _median_cut(samples: Array[Color], count: int) -> Array[Color]:
	var buckets: Array = [samples]
	while buckets.size() < count:
		var bi := 0
		var best := -1
		for i in buckets.size():
			if buckets[i].size() > best:
				best = buckets[i].size()
				bi = i
		var bucket: Array = buckets[bi]
		if bucket.size() < 2:
			break
		var lo := Vector3(1, 1, 1)
		var hi := Vector3.ZERO
		for c: Color in bucket:
			lo = Vector3(minf(lo.x, c.r), minf(lo.y, c.g), minf(lo.z, c.b))
			hi = Vector3(maxf(hi.x, c.r), maxf(hi.y, c.g), maxf(hi.z, c.b))
		var span := hi - lo
		var axis := 0 if span.x >= span.y and span.x >= span.z else (1 if span.y >= span.z else 2)
		bucket.sort_custom(func(a: Color, b: Color) -> bool: return a[axis] < b[axis])
		var mid := bucket.size() / 2
		buckets[bi] = bucket.slice(0, mid)
		buckets.append(bucket.slice(mid))
	var pal: Array[Color] = []
	for bucket in buckets:
		var r := 0.0
		var g := 0.0
		var b := 0.0
		for c: Color in bucket:
			r += c.r
			g += c.g
			b += c.b
		var n := float(bucket.size())
		pal.append(Color(r / n, g / n, b / n))
	pal.append(OUTLINE)   # índice final = contorno
	return pal


func _nearest(c: Color, palette: Array[Color]) -> int:
	var best := 0
	var bd := 1e9
	for i in palette.size() - 1:   # el contorno no se elige por cercanía
		var p := palette[i]
		var d := (p.r - c.r) * (p.r - c.r) * 0.3 + (p.g - c.g) * (p.g - c.g) * 0.59 + (p.b - c.b) * (p.b - c.b) * 0.11
		if d < bd:
			bd = d
			best = i
	return best


## Devuelve imagen con índice de paleta en el canal R (A=255 si opaco) + contorno de 1 px.
func _quantize(src: Image, palette: Array[Color]) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var idx := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var outline := palette.size() - 1
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a > 0.5:
				idx.set_pixel(x, y, Color8(_nearest(c, palette), 0, 0, 255))
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				continue
			var touch := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.5:
					touch = true
					break
			if touch:
				idx.set_pixel(x, y, Color8(outline, 0, 0, 255))
	return idx


func _recolor(idx: Image, palette: Array[Color]) -> Image:
	var out := Image.create(idx.get_width(), idx.get_height(), false, Image.FORMAT_RGBA8)
	for y in idx.get_height():
		for x in idx.get_width():
			var c := idx.get_pixel(x, y)
			if c.a > 0.5:
				out.set_pixel(x, y, palette[int(round(c.r * 255.0))])
	return out


func _tint(palette: Array[Color], sat: float, val: float, desat_mix: float) -> Array[Color]:
	var res: Array[Color] = []
	for i in palette.size():
		var c := palette[i]
		if i == palette.size() - 1:
			res.append(Color(c.r * 0.9, c.g * 0.8, c.b * 1.1) if sat > 1.0 else Color(0.16, 0.14, 0.15))
			continue
		var grey := c.get_luminance()
		var r := Color(grey, grey, grey).lerp(c, sat)
		r = Color(clampf(r.r * val, 0, 1), clampf(r.g * val, 0, 1), clampf(r.b * val, 0, 1))
		if desat_mix > 0.0:
			r = r.lerp(Color(0.55, 0.5, 0.45), desat_mix)
		res.append(r)
	return res


func _bounds(idx: Image) -> Rect2i:
	var r := idx.get_used_rect()
	return r


func _count_colors(idx: Image) -> int:
	var seen := {}
	for y in idx.get_height():
		for x in idx.get_width():
			var c := idx.get_pixel(x, y)
			if c.a > 0.5:
				seen[int(round(c.r * 255.0))] = true
	return seen.size()
