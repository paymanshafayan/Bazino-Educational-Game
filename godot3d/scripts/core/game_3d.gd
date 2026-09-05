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


var _auth_status: Label


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
	title.position = Vector2(290, 110)
	title.size = Vector2(700, 80)
	layer.add_child(title)
	var sub := Label.new()
	sub.text = "%s  ·  %s · %s" % [StageLoader.region_title(REGION), tr("season_1"), tr("grade_8")]
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(340, 205)
	sub.size = Vector2(600, 40)
	layer.add_child(sub)
	# — ورود / مهمان (همان قرارداد Api دو‌بعدی) —
	var email := LineEdit.new()
	email.placeholder_text = "e-posta"
	email.position = Vector2(490, 270)
	email.size = Vector2(300, 36)
	layer.add_child(email)
	var passw := LineEdit.new()
	passw.placeholder_text = "şifre"
	passw.secret = true
	passw.position = Vector2(490, 316)
	passw.size = Vector2(300, 36)
	layer.add_child(passw)
	_auth_status = Label.new()
	_auth_status.position = Vector2(490, 398)
	_auth_status.size = Vector2(300, 30)
	_auth_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_auth_status.text = "…"
	layer.add_child(_auth_status)
	var lb := Button.new()
	lb.text = tr("ui_login")
	lb.position = Vector2(490, 360)
	lb.size = Vector2(145, 34)
	lb.pressed.connect(_on_login.bind(email, passw))
	layer.add_child(lb)
	var gb := Button.new()
	gb.text = tr("ui_offline")
	gb.position = Vector2(645, 360)
	gb.size = Vector2(145, 34)
	gb.pressed.connect(func(): _auth_status.text = tr("ui_offline") + " ✓"; Sfx.play("click", -6.0))
	layer.add_child(gb)
	Api.login_finished.connect(_on_login_result)
	_ping_status()
	var btn := Button.new()
	btn.text = "▶  " + tr("ui_play")
	btn.custom_minimum_size = Vector2(220, 60)
	btn.position = Vector2(530, 480)
	btn.pressed.connect(func():
		Sfx.play("click", -5.0)
		layer.queue_free()
		_start_game())
	layer.add_child(btn)


func _ping_status() -> void:
	var ok := await Api.ping()
	if _auth_status and is_instance_valid(_auth_status):
		_auth_status.text = ("🟢 %s" % (Api.base_url if Api.base_url != "" else "127.0.0.1")) if ok \
			else ("🔴 " + tr("ui_offline"))


func _on_login(email: LineEdit, passw: LineEdit) -> void:
	Sfx.play("click", -6.0)
	_auth_status.text = "…"
	Api.login(email.text, passw.text)


func _on_login_result(ok: bool, _d: Dictionary) -> void:
	_auth_status.text = "🟢 ✓" if ok else "🔴 ✗"


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
	await _build_stage(REGION, SEASON, 1)
	_hud.show_banner("%s — %s" % [StageLoader.region_title(REGION), _stage_title])


func _build_stage(region: String, season: int, index_no: int) -> void:
	# ابتدا سرور (انطباق تطبیقی/adaptive)، بعد بازگشت به فایل محلی
	var stage: Dictionary = {}
	if Api.child_id > 0:
		stage = await _fetch_stage_server(region, season, index_no)
	if stage.is_empty():
		stage = StageLoader.get_stage(region, season, index_no)
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


func _fetch_stage_server(region: String, season: int, index_no: int) -> Dictionary:
	# واکشی با سقف زمانی: اگر سرور جواب نداد خالی برگردان (بازگشت آفلاین)
	var done := false
	var got: Dictionary = {}
	var on_res := func(ok: bool, cfg: Dictionary):
		done = true
		if ok:
			var inner: Dictionary = cfg.get("stage", cfg)
			if inner.has("rooms"):
				got = inner
	if not Api.stage_finished.is_connected(on_res):
		Api.stage_finished.connect(on_res, CONNECT_ONE_SHOT)
	Api.fetch_stage(region, season, index_no)
	var waited := 0.0
	while not done and waited < 3.0:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	return got


func _room_done() -> void:
	_pending -= 1
	SaveData.save_now()
	if _pending <= 0 and not _cleared:
		_cleared = true
		SaveData.set_region_cleared(REGION, SEASON)
		Sfx.play("victory", -4.0)
		_hud.show_banner("🏆 " + tr("region_cleared"), 3.5)


func _spawn_gate(room: Dictionary, pos: Vector3) -> void:
	var cfg: Dictionary = room.get("gate", {})
	if cfg.is_empty() and room.has("topic_id"):
		# اتاق تطبیقی سرور: موضوع → پازل زنده (با پرچم reinjection یادگیری پنهان)
		cfg = TopicPuzzles.make_gate(
			str(room.get("topic_id", "")), int(room.get("ref_time_ms", 0)))
	var gate := RuneGate.create(cfg)
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
	var tool_id := str(room.get("tool_id", ""))
	var topic := str(room.get("topic_id", ""))
	if tool_id == "" and topic != "":
		tool_id = TopicPuzzles.tool_for(topic)
	var t := Treasure3D.create(tool_id, topic)
	add_child(t)
	t.position = pos
	_pending += 1
	t.collected.connect(func(tool_id):
		_hud.show_banner("✨ " + tr("toast_formula"), 2.4)
		_room_done())
