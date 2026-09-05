class_name MathGate
extends Node2D
## دروازهٔ عددی — قلب «آموزش پنهان» ریاضی (GDD §۶/D7):
## پاسخ با ایستادن روی سکوی مقدار درست (نه پنجرهٔ سؤال!). تله‌متری: سرعت/تلاش/ابزار.

signal solved(gate: MathGate)

const STAND_TIME := 0.55
const SHUFFLE_PENALTY_LUM := 1

var config: Dictionary = {}
var retries := 0

var _t0_ms := 0
var _resolved := false
var _wall_body: StaticBody2D
var _wall_poly: Polygon2D
var _panels: Array = []
var _stand_progress := 0.0
var _candidate: Area2D
var _timer_left := 0.0
var _timer_label: Label


static func create(cfg: Dictionary) -> MathGate:
	var g := MathGate.new()
	g.config = cfg
	return g


func _ready() -> void:
	add_to_group("gate")
	_build_wall()
	_build_panels()
	_t0_ms = Time.get_ticks_msec()
	_timer_left = float(config.get("time_limit", 10))
	_timer_label = _make_label(str(ceili(_timer_left)), Vector2(0, -260), 42,
		Color("ffd166"))
	add_child(_timer_label)


func _build_wall() -> void:
	_wall_body = StaticBody2D.new()
	var sh := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 240)
	sh.shape = rect
	_wall_body.add_child(sh)
	add_child(_wall_body)
	_wall_poly = Polygon2D.new()
	_wall_poly.polygon = PackedVector2Array([
		Vector2(-13, -120), Vector2(13, -120), Vector2(13, 120), Vector2(-13, 120)])
	_wall_poly.color = Color(0.16, 0.18, 0.3)
	add_child(_wall_poly)
	var ch := _make_label(config.get("challenge", "= ?"), Vector2(0, -200), 34,
		Color("7ecaff"))
	add_child(ch)
	var hint := _make_label(tr("gate_hint"), Vector2(0, -230), 20, Color(1, 1, 1, 0.55))
	hint.visible = _timer_left < 99999.0
	add_child(hint)


func _build_panels() -> void:
	var defs: Array = config.get("panels", [])
	var n := defs.size()
	for i in n:
		var p := Area2D.new()
		p.set_meta("ok", defs[i].get("ok", false))
		p.set_meta("v", defs[i].get("v", "?"))
		p.position = Vector2(-(n - 1) * 70.0 + i * 140.0, 0)
		var sh := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(110, 14)
		sh.shape = rect
		p.add_child(sh)
		var lay := Polygon2D.new()
		lay.polygon = PackedVector2Array([
			Vector2(-55, -7), Vector2(55, -7), Vector2(55, 7), Vector2(-55, 7)])
		lay.color = Color(0.22, 0.26, 0.42)
		p.add_child(lay)
		var lb := _make_label(defs[i].get("v", "?"), Vector2(0, -34), 26, Color.WHITE)
		p.add_child(lb)
		add_child(p)
		_panels.append(p)


func _physics_process(delta: float) -> void:
	if _resolved:
		return
	_timer_left -= delta
	if _timer_left > 0.0:
		_timer_label.text = str(ceili(_timer_left))
	else:
		_timeout_shuffle()
		return
	var found: Area2D
	for p: Area2D in _panels:
		for b in p.get_overlapping_bodies():
			if b is Player:
				found = p
	if found != _candidate:
		_candidate = found
		_stand_progress = 0.0
	if _candidate:
		_stand_progress += delta
		if _stand_progress >= STAND_TIME:
			_resolve(_candidate.get_meta("ok", false))


func _resolve(ok: bool) -> void:
	_stand_progress = 0.0
	_candidate = null
	if ok:
		_resolved = true
		var ms := Time.get_ticks_msec() - _t0_ms
		Telemetry.track("obstacle_solved", config.get("topic_id", ""), {
			"solved": true, "time_ms": ms, "retries": retries,
			"tool_correct": SaveData.has_tool_for(config.get("topic_id", ""))})
		SaveData.add_lum(5)
		_open()
	else:
		retries += 1
		Telemetry.track("obstacle_attempt", config.get("topic_id", ""), {
			"solved": false, "retries": retries})
		var pl := _player()
		if pl:
			pl.knockback_simple(260.0)
		_timer_left = float(config.get("time_limit", 10)) * 0.7


func _timeout_shuffle() -> void:
	# پایان زمان: سکوها برمی‌خورند (نه تنبیه خشک — صنعت بازی)
	retries += 1
	SaveData.add_lum(-SHUFFLE_PENALTY_LUM)
	_timer_left = float(config.get("time_limit", 10))
	var xs: Array = []
	for p in _panels:
		xs.append(p.position.x)
	xs.shuffle()
	for i in _panels.size():
		var tw := _panels[i].create_tween()
		tw.tween_property(_panels[i], "position:x", xs[i], 0.3)
	Telemetry.track("obstacle_attempt", config.get("topic_id", ""),
		{"solved": false, "retries": retries, "timeout": true})


func _open() -> void:
	_wall_body.set_deferred("collision_layer", 0)
	_wall_body.set_deferred("collision_mask", 0)
	var shp: CollisionShape2D = _wall_body.get_child(0)
	shp.set_deferred("disabled", true)
	_timer_label.visible = false
	var tw := create_tween()
	tw.tween_property(_wall_poly, "color:a", 0.0, 0.45)
	tw.tween_property(_wall_poly, "position:y", -160.0, 0.45)
	solved.emit(self)


func _player() -> Player:
	var arr := get_tree().get_nodes_in_group("player")
	return arr[0] if arr.size() > 0 else null


func _make_label(text: String, pos: Vector2, size: int, color: Color) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", color)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.position = pos + Vector2(-160, -20)
	lb.custom_minimum_size = Vector2(320, 40)
	return lb
