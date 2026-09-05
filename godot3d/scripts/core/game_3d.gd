## ریشهٔ بازی سه‌بعدی: ورودی‌ها، صف عنوان، ساخت جزیرهٔ تست، HUD، موسیقی.
class_name Game3D
extends Node3D

var _island: Island3D
var _player: Player3D
var _cam: CameraRig
var _hud: CanvasLayer


func _ready() -> void:
	_setup_input()
	_title()
	Sfx.play_music("ambient")


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
	title.position = Vector2(340, 180)
	layer.add_child(title)
	var sub := Label.new()
	sub.text = tr("menu_choose") if tr("menu_choose") != "menu_choose" else "کلیک روی شروع"
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(440, 280)
	layer.add_child(sub)
	var btn := Button.new()
	btn.text = "▶  " + tr("menu_start") if tr("menu_start") != "menu_start" else "▶  شروع"
	btn.position = Vector2(560, 360)
	btn.custom_minimum_size = Vector2(160, 52)
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
	_make_hud()
	# — محتوای نمایشی چپتر A/B: دروازه + ۳ دشمن —
	var gate := RuneGate.create({
		"topic_id": "math.g7.guz.tamsayilar",
		"challenge": "2x + 6 = 14 → x = ?",
		"panels": [
			{"v": "4", "ok": true}, {"v": "10", "ok": false},
			{"v": "−4", "ok": false}, {"v": "8", "ok": false},
		]})
	add_child(gate)
	gate.position = Vector3(0, 0, -12)
	for i in 3:
		var w := Wisp3D.create("59d6ff")
		add_child(w)
		w.position = Vector3(9 - i * 9.0, 1.4, -2 - i * 5.0)


func _make_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)
	var hearts := Label.new()
	hearts.name = "Hearts"
	hearts.add_theme_font_size_override("font_size", 30)
	hearts.position = Vector2(26, 18)
	_hud.add_child(hearts)
	_update_hearts()
	_player.hp_changed.connect(func(_h, _m): _update_hearts())
	var lum := Label.new()
	lum.name = "Lum"
	lum.add_theme_font_size_override("font_size", 24)
	lum.add_theme_color_override("font_color", Color("ffd166"))
	lum.position = Vector2(26, 60)
	_hud.add_child(lum)
	SaveData.lum_changed.connect(func(n): lum.text = "✦ %d" % n)
	lum.text = "✦ %d" % int(SaveData.data.lum)


func _update_hearts() -> void:
	var hearts: Label = _hud.get_node("Hearts")
	var full := ""
	for i in _player.hp:
		full += "♥"
	var empty := ""
	for j in (_player.hp_max - _player.hp):
		empty += "♡"
	hearts.text = full + empty
	hearts.remove_theme_color_override("font_color")
	hearts.add_theme_color_override("font_color", Color("ff5d5d"))
