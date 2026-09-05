class_name StageBuilder
extends Node2D
## StageBuilder — اتاق‌های مرحله را از StageConfig سرور یا JSON آفلاین می‌سازد.

signal stage_cleared

const ROOM_W := 1500.0
const GROUND_Y := 520.0
const GROUND_H := 160.0
const WallDir := 1

var hud: CanvasLayer
var player: Player
var camera: GameCamera

var _total_w := 4000.0
var _region := "math"


func build(stage_data: Dictionary) -> void:
	var rooms: Array = stage_data.get("rooms", [])
	_region = str(stage_data.get("region", "math")).strip_edges()
	_total_w = (rooms.size() + 2) * ROOM_W
	_make_background()
	_make_ground()
	_spawn_setup()
	_build_rooms(rooms)
	_make_bounds()


func _make_background() -> void:
	var back := Node2D.new()
	back.name = "Background"
	back.z_index = -10
	add_child(back)
	var bg_path := "res://assets/bg/%s.png" % _region
	if ResourceLoader.exists(bg_path):
		# صف نمایشی نقاشانه + پارالاکس دور/نزدیک برای حس عمق
		var base := Polygon2D.new()
		base.color = Color("0b0e1a")
		base.polygon = PackedVector2Array([
			Vector2(-400, -400), Vector2(_total_w + 800, -400),
			Vector2(_total_w + 800, GROUND_Y), Vector2(-400, GROUND_Y)])
		back.add_child(base)
		var tex: Texture2D = load(bg_path)
		var pb := ParallaxBackground.new()
		back.add_child(pb)
		var far := ParallaxLayer.new()
		far.motion_scale = Vector2(0.2, 0.45)
		far.motion_mirroring = Vector2(tex.get_width() * 2.0, 0)
		pb.add_child(far)
		for k in 3:
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.centered = false
			sp.scale = Vector2(2.0, 2.0)
			sp.position = Vector2(k * tex.get_width() * 2.0, -140)
			sp.modulate = Color(0.9, 0.92, 1.05)
			far.add_child(sp)
		var near := ParallaxLayer.new()
		near.motion_scale = Vector2(0.5, 0.75)
		near.motion_mirroring = Vector2(tex.get_width() * 3.0, 0)
		pb.add_child(near)
		for m in 3:
			var sp2 := Sprite2D.new()
			sp2.texture = tex
			sp2.centered = false
			sp2.scale = Vector2(3.0, 3.0)
			sp2.position = Vector2(m * tex.get_width() * 3.0, -80)
			sp2.modulate = Color(0.30, 0.34, 0.5, 0.45)
			near.add_child(sp2)
		return
	var sky := Polygon2D.new()
	sky.color = Color("0b0e1a")
	sky.polygon = PackedVector2Array([
		Vector2(-400, -400), Vector2(_total_w + 800, -400),
		Vector2(_total_w + 800, GROUND_Y), Vector2(-400, GROUND_Y)])
	back.add_child(sky)
	for i in 3:  # کوه‌های سیلوئت با پارالاکسِ سبکِ دستی
		var ridge := Polygon2D.new()
		ridge.color = Color(0.09 + i * 0.025, 0.10 + i * 0.02, 0.16 + i * 0.03)
		var pts := PackedVector2Array()
		var base := GROUND_Y - 30.0 - i * 50.0
		pts.append(Vector2(-400, base))
		var x := -400.0
		while x < _total_w + 800:
			pts.append(Vector2(x, base - 90.0 - randf() * 150.0 - i * 40.0))
			x += 260.0 + randf() * 200.0
		pts.append(Vector2(_total_w + 800, base))
		ridge.polygon = pts
		ridge.z_index = -5 - i
		back.add_child(ridge)
	var stars := Node2D.new()
	for j in 48:
		var s := Polygon2D.new()
		s.polygon = PackedVector2Array([
			Vector2(0, -2), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0)])
		s.color = Color(1, 1, 1, 0.35 + randf() * 0.45)
		s.position = Vector2(randf() * _total_w, randf() * 340 - 380)
		stars.add_child(s)
	back.add_child(stars)


func _make_ground() -> void:
	var g := StaticBody2D.new()
	g.name = "Ground"
	g.collision_layer = 1
	var sh := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(_total_w, GROUND_H)
	sh.shape = rect
	g.add_child(sh)
	g.position = Vector2(_total_w / 2.0, GROUND_Y + GROUND_H / 2.0)
	add_child(g)
	var top := Polygon2D.new()
	top.color = Color("131a2e")
	top.polygon = PackedVector2Array([
		Vector2(0, GROUND_Y), Vector2(_total_w, GROUND_Y),
		Vector2(_total_w, GROUND_Y + GROUND_H), Vector2(0, GROUND_Y + GROUND_H)])
	add_child(top)
	# سکوهای متفرقهٔ معمایی
	for i in 8:
		_add_platform(Vector2(500 + randf() * (_total_w - 900), GROUND_Y - 110 - randf() * 120),
			90.0 + randf() * 90.0)


func _add_platform(pos: Vector2, w: float) -> void:
	var pb := StaticBody2D.new()
	pb.collision_layer = 1
	var sh := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 12)
	sh.shape = rect
	sh.one_way_collision = true
	pb.add_child(sh)
	pb.position = pos
	add_child(pb)
	var lay := Polygon2D.new()
	lay.polygon = PackedVector2Array([
		Vector2(-w / 2, -6), Vector2(w / 2, -6), Vector2(w / 2, 6), Vector2(-w / 2, 6)])
	lay.color = Color("223055")
	pb.add_child(lay)


func _spawn_setup() -> void:
	player = Player.create()
	player.global_position = Vector2(160, GROUND_Y - 40)
	player.add_to_group("player")
	player.set_respawn(player.global_position)
	add_child(player)
	camera = GameCamera.create(player)
	add_child(camera)
	camera.limit_right = int(_total_w)
	var start_shrine := Shrine.create()
	start_shrine.global_position = Vector2(90, GROUND_Y - 25)
	add_child(start_shrine)


func _build_rooms(rooms: Array) -> void:
	for i in rooms.size():
		var room: Dictionary = rooms[i]
		var cx := ROOM_W * (i + 1.5)
		match room.get("type", ""):
			"obstacle":
				var gate := MathGate.create(room.get("gate", {}))
				gate.global_position = Vector2(cx, GROUND_Y)
				gate.solved.connect(_on_gate_solved)
				add_child(gate)
			"lever":
				var lv := LeverScale.create(room.get("lever", {}))
				lv.global_position = Vector2(cx, GROUND_Y - 60)
				lv.solved.connect(_on_gate_solved_lever)
				add_child(lv)
			"circuit":
				var cg := CircuitGate.create(room.get("circuit", {}))
				cg.global_position = Vector2(cx, GROUND_Y)
				cg.solved.connect(_on_gate_solved_circuit)
				add_child(cg)
			"battle":
				for e in room.get("enemies", 3):
					var wisp := Enemy.create(room.get("enemy_theme", "number_wisp"))
					wisp.global_position = Vector2(cx - 260 + e * 170, GROUND_Y - 40)
					add_child(wisp)
			"treasure":
				var scroll := FormulaScroll.create(
					room.get("tool_id", ""), room.get("topic_id", ""))
				scroll.global_position = Vector2(cx, GROUND_Y - 40)
				scroll.tool_pickup.connect(_on_tool)
				add_child(scroll)
			"boss":
				_spawn_boss(room, cx)


func _spawn_boss(room: Dictionary, cx: float) -> void:
	var boss := EskiHesapci.create(
		room.get("phases", []), room.get("boss_cfg", {}))
	boss.global_position = Vector2(cx + 300, GROUND_Y - 50)
	boss.boss_defeated.connect(_on_boss_down)
	add_child(boss)
	if hud and hud.has_method("attach_boss"):
		hud.attach_boss(boss)
	# برچسب راهنمای مکانیک باس
	lbl(tr("boss_shield"), Vector2(cx - 200, GROUND_Y - 240), 24, Color("ffd166"))


func _on_gate_solved(gate: MathGate) -> void:
	var tw := gate.create_tween()
	tw.tween_property(gate, "modulate:a", 0.35, 0.6)


func _on_gate_solved_lever(_g: LeverScale) -> void:
	pass


func _on_gate_solved_circuit(_g: CircuitGate) -> void:
	pass


func _on_tool(tool_id: String) -> void:
	if hud and hud.has_method("toast"):
		hud.toast(tr("toast_formula") + "  ✦ " + tr(_tool_key(tool_id)))


func _tool_key(tool_id: String) -> String:
	return "tool_" + tool_id


func _on_boss_down() -> void:
	if hud and hud.has_method("victory"):
		hud.victory(tr("victory"))
	stage_cleared.emit()


func _make_bounds() -> void:
	for x in [-60.0, _total_w + 60.0]:
		var w := StaticBody2D.new()
		var sh := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(40, 2000)
		sh.shape = rect
		w.add_child(sh)
		w.position = Vector2(x, GROUND_Y - 500)
		add_child(w)


func lbl(text: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = pos
	l.custom_minimum_size = Vector2(600, 40)
	add_child(l)
	return l
