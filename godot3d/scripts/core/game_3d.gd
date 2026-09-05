## ریشهٔ بازی سه‌بعدی: ورودی‌ها، صف عنوان، ساخت محتوای مرحله از داده، HUD، پیشرفت.
class_name Game3D
extends Node3D

const REGION := "math"
const SEASON := 1

var _island: Island3D
var _player: Player3D
var _cam: CameraRig
var _hud: Hud3D
var _pending := 0          # اتاق‌های ناتمام: دروازه + دشمن + گنج
var _cleared := false
var _stage_title := ""


func _ready() -> void:
	_setup_input()
	_title()


func _setup_input() -> void:
	_add("move_left", [KEY_A, KEY_LEFT])
	_add("move_right", [KEY_D, KEY_RIGHT])
	_add("move_forward", [KEY_W, KEY_UP])
	_add("move_back", [KEY_S, KEY_DOWN])
	_add("jump", [KEY_SPACE])
	_add("dash", [KEY_SHIFT, KEY_K])
	_add("attack", [KEY_J, KEY_X])
	_add("interact", [KEY_E, KEY_F])


func _add(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.15)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)


func _title() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Title"
	add_child(layer)
	var veil := ColorRect.new()
	veil.color = Color(0.03, 0.04, 0.09, 0.92)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(veil)
	var title := Label.new()
	title.text = "★  BAZİNO 3D  ★"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("7ecaff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(290, 150)
	title.size = Vector2(700, 80)
	layer.add_child(title)
	var sub := Label.new()
	sub.text = "%s  ·  %s · %s" % [StageLoader.region_title(REGION), tr("season_1"), tr("grade_8")]
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(340, 250)
	sub.size = Vector2(600, 40)
	layer.add_child(sub)
	var btn := Button.new()
	btn.text = "▶  " + tr("ui_play")
	btn.custom_minimum_size = Vector2(200, 56)
	btn.position = Vector2(540, 350)
	btn.pressed.connect(func():
		Sfx.play("click", -5.0)
		layer.queue_free()
		_start_game())
	layer.add_child(btn)


func _start_game() -> void:
	_island = Island3D.new()
	add_child(_island)
	_island.build("8df7c9", "16203a")
	_player = Player3D.new()
	add_child(_player)
	_player.position = Vector3(0, 0.5, 14)
	_cam = CameraRig.new()
	add_child(_cam)
	_cam.bind(_player)
	_hud = Hud3D.new()
	add_child(_hud)
	_hud.setup(_player)
	Sfx.play_music("ambient")
	_build_stage(REGION, SEASON, 1)
	_hud.show_banner("%s — %s" % [StageLoader.region_title(REGION), _stage_title])


func _build_stage(region: String, season: int, index_no: int) -> void:
	var stage := StageLoader.get_stage(region, season, index_no)
	if stage.is_empty():
		_hud.show_banner("⚠ stage not found")
		return
	_stage_title = tr(str(stage.get("title_key", "region_math")))
	var rooms: Array = stage.get("rooms", [])
	var z := -10.0
	for i in rooms.size():
		var room: Dictionary = rooms[i]
		match str(room.get("type", "")):
			"obstacle":
				_spawn_gate(room, Vector3(0, 0, z))
			"battle":
				_spawn_battle(room, Vector3(0, 0, z))
			"treasure":
				_spawn_treasure(room, Vector3(0, 0, z))
		z -= 16.0


func _room_done() -> void:
	_pending -= 1
	SaveData.save_now()
	if _pending <= 0 and not _cleared:
		_cleared = true
		SaveData.set_region_cleared(REGION, SEASON)
		Sfx.play("victory", -4.0)
		_hud.show_banner("🏆 " + tr("region_cleared"), 3.5)


func _spawn_gate(room: Dictionary, pos: Vector3) -> void:
	var gate := RuneGate.create(room.get("gate", {}))
	add_child(gate)
	gate.position = pos
	_pending += 1
	gate.solved.connect(func():
		_hud.show_banner("✔", 0.9)
		_room_done())


func _spawn_battle(room: Dictionary, pos: Vector3) -> void:
	var n := int(room.get("enemies", 3))
	var colors := ["59d6ff", "ff9f5a", "b78dff"]
	for i in n:
		var w := Wisp3D.create(colors[i % colors.size()])
		add_child(w)
		w.position = pos + Vector3((i - n * 0.5 + 0.5) * 4.0, 1.4, -2.0)
		_pending += 1
		w.tree_exited.connect(func(): _room_done())


func _spawn_treasure(room: Dictionary, pos: Vector3) -> void:
	var t := Treasure3D.create(str(room.get("tool_id", "")), str(room.get("topic_id", "")))
	add_child(t)
	t.position = pos
	_pending += 1
	t.collected.connect(func(tool_id):
		_hud.show_banner("✨ " + tr("toast_formula"), 2.4)
		_room_done())
