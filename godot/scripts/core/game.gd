extends Node2D
## Game (ریشهٔ main.tscn) — نقشهٔ کلید زمان‌اجرا + جریان: منو → مرحله (تک‌نفره/کو-اوپ).
## مناطق: math/physics/english + weekly (Venue) + tournament (فینال فصل).

const STAGE_FILES := {
	"math": "res://data/stages_math_s1.json",
	"physics": "res://data/stages_physics_s1.json",
	"english": "res://data/stages_english_s1.json",
	"biology": "res://data/stages_biology_s1.json",
	"chemistry": "res://data/stages_chemistry_s1.json",
	"ict": "res://data/stages_ict_s1.json",
	"logic": "res://data/stages_logic_s1.json",
	"weekly": "res://data/stages_weekly.json",
	"tournament": "res://data/tournament.json",
}

var _menu: Menus
var _hud: Hud
var _stage: StageBuilder
var _coop: CoopSession
var _region := "math"
var _season := 1


func _ready() -> void:
	_setup_input_map()
	TranslationServer.set_locale(SaveData.data.lang)
	_show_menu()
	Api.ping()


func _setup_input_map() -> void:
	_add("move_left", [KEY_A, KEY_LEFT])
	_add("move_right", [KEY_D, KEY_RIGHT])
	_add("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add("dash", [KEY_SHIFT, KEY_K])
	_add("attack", [KEY_J, KEY_X])
	_add("interact", [KEY_E, KEY_F])
	_add("tool_1", [KEY_1])
	_add("tool_2", [KEY_2])
	_add("tool_3", [KEY_3])
	_add("map", [KEY_M])


func _add(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)


func _show_menu() -> void:
	_menu = Menus.create()
	add_child(_menu)
	_menu.start_stage.connect(_on_start_stage)


func _on_start_stage(region: String, index_no: int) -> void:
	# خواسته‌های منو را پیش از از بین بردنش نگه می‌داریم
	var want_coop := _menu.coop
	var want_host := _menu.coop_host
	var coop_ip := _menu.coop_ip
	_season = _menu.season

	_menu.queue_free()
	_menu = null
	_region = region
	Telemetry.track("stage_start", "", {"region": region, "index": index_no,
		"grade": SaveData.data.grade, "coop": want_coop})

	_hud = Hud.create()
	add_child(_hud)
	Api.reward_finished.connect(_on_reward)

	var stage_data := _load_stage_data(region, index_no)
	_stage = StageBuilder.new()
	_stage.hud = _hud
	add_child(_stage)
	_stage.build(stage_data)
	_hud.attach_player(_stage.player)
	_stage.stage_cleared.connect(_on_stage_cleared)

	if want_coop:
		_start_coop(want_host, coop_ip)

	if Api.token != "" and Api.child_id > 0 and \
			not ["weekly", "tournament"].has(region):
		Api.fetch_stage(region, 1, index_no)


func _start_coop(as_host: bool, ip: String) -> void:
	_coop = CoopSession.new()
	add_child(_coop)
	var err: Error
	if as_host:
		err = _coop.host()
	else:
		err = _coop.join(ip if ip != "" else "127.0.0.1")
	if err != OK:
		if _hud:
			_hud.toast("✗ co-op hatası")
		return
	_coop.attach_local_player(_stage.player)
	_coop.spawn_ghost(_stage)
	if _hud:
		_hud.toast(tr("coop_ok"))


func _on_stage_cleared() -> void:
	if _region == "tournament" and Api.token != "" and Api.child_id > 0:
		Api.claim_grand_reward()
	await get_tree().create_timer(2.4).timeout
	_back_to_menu()


func _on_reward(ok: bool, data: Dictionary) -> void:
	if ok and _hud and data.has("code"):
		_hud.toast(tr("grand_claimed") + " " + str(data.code))


func _back_to_menu() -> void:
	if _coop:
		_coop.queue_free()
		_coop = null
	if _stage:
		_stage.queue_free()
		_stage = null
	if _hud:
		_hud.queue_free()
		_hud = null
	_show_menu()


func _load_stage_data(region: String, index_no: int) -> Dictionary:
	var path: String = STAGE_FILES.get(region, STAGE_FILES["math"])
	if _season == 2 and not ["weekly", "tournament", "ict", "logic"].has(region):
		path = path.replace("_s1.json", "_s2.json")
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		# سقوط به فصل ۱ اگر دادهٔ فصل ۲ نبود (ict/logic هنوز فقط Güz)
		path = STAGE_FILES.get(region, STAGE_FILES["math"])
		f = FileAccess.open(path, FileAccess.READ)
		if not f:
			return {"region": region, "rooms": []}
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	for st in data.get("stages", []):
		if int(st.get("index_no", 0)) == index_no:
			return st
	return data.get("stages", [])[0]
