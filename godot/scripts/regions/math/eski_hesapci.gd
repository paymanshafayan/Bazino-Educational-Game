class_name EskiHesapci
extends CharacterBody2D
## 🐉 باس ریاضی: «حسابگر کهنه» (GDD §۵.۱ منطقه ۱).
## سپرش با مقدار درست x می‌شکند — معما=باس (قانون ۳). ۳ فاز با شوک‌ویو مجازاتی.

signal boss_defeated
signal hp_changed(hp: int, hp_max: int)

const MAX_HP := 24
const WALK_SPEED := 70.0
const GRAV := 2150.0
const VULN_TIME := 4.5
const STAND_TIME := 0.55

var phases: Array = []
var hp := MAX_HP

# پیکربندی ناحیه‌ای — باسِ کُنشه‌ای عمومی برای هر ۷ منطقه (نام ظاهری=کلید i18n روم)
var boss_name_key := "boss_eski"
var topic_prefix := "math.g8.guz"
var topic_suffixes := ["ozdeslik", "uslu", "karekoklu"]
var body_color := Color("8df7c9")

var _phase := 0
var _shielded := true
var _vuln_left := 0.0
var _panels: Array = []
var _stand_progress := 0.0
var _candidate: Area2D
var _phase_t0 := 0
var _phase_retries := 0
var _body_poly: Polygon2D
var _shield_poly: Polygon2D
var _eq_label: Label


static func create(cfg_phases: Array, cfg: Dictionary = {}) -> EskiHesapci:
	var b := EskiHesapci.new()
	b.add_to_group("enemy")
	b.phases = cfg_phases
	b.boss_name_key = cfg.get("name_key", b.boss_name_key)
	b.topic_prefix = cfg.get("topic_prefix", b.topic_prefix)
	b.topic_suffixes = cfg.get("topic_suffixes", b.topic_suffixes)
	if cfg.has("color"):
		b.body_color = Color(cfg["color"])
	return b


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var sh := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(72, 96)
	sh.shape = rect
	add_child(sh)
	_body_poly = Polygon2D.new()
	_body_poly.polygon = PackedVector2Array([
		Vector2(-36, -48), Vector2(36, -48), Vector2(30, 48), Vector2(-30, 48)])
	_body_poly.color = body_color
	add_child(_body_poly)
	var eye := Polygon2D.new()
	eye.polygon = PackedVector2Array([
		Vector2(-14, -22), Vector2(14, -22), Vector2(14, -8), Vector2(-14, -8)])
	eye.color = Color("07332a")
	add_child(eye)
	_shield_poly = Polygon2D.new()
	_shield_poly.polygon = PackedVector2Array([
		Vector2(0, -70), Vector2(60, -35), Vector2(60, 35),
		Vector2(0, 70), Vector2(-60, 35), Vector2(-60, -35)])
	_shield_poly.color = Color(0.35, 0.75, 1.0, 0.28)
	add_child(_shield_poly)
	_eq_label = Label.new()
	_eq_label.add_theme_font_size_override("font_size", 34)
	_eq_label.add_theme_color_override("font_color", Color("ffd166"))
	_eq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_eq_label.position = Vector2(-220, -170)
	_eq_label.custom_minimum_size = Vector2(440, 50)
	add_child(_eq_label)
	hp_changed.emit(hp, MAX_HP)
	_start_phase(0)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAV * delta, 900.0)
	if _vuln_left > 0.0:
		_vuln_left -= delta
		_body_poly.color = Color("ffb347")
		if _vuln_left <= 0.0:
			_shielded = true
			_shield_poly.visible = true
			_body_poly.color = body_color
	else:
		_walk_toward_player()
	move_and_slide()
	_track_stand(delta)


func _walk_toward_player() -> void:
	var pl := _player()
	if not pl:
		velocity.x = 0.0
		return
	var dx: float = pl.global_position.x - global_position.x
	velocity.x = WALK_SPEED * signf(dx)
	if absf(pl.global_position.distance_to(global_position)) < 90.0:
		pl.take_damage(1, global_position)


func _track_stand(delta: float) -> void:
	if not _shielded:
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
			_stand_progress = 0.0
			_candidate = null
			if found.get_meta("ok", false):
				_break_shield()
			else:
				_shockwave()


func _start_phase(i: int) -> void:
	_phase = i
	_phase_t0 = Time.get_ticks_msec()
	_phase_retries = 0
	if i == 0:
		Sfx.play("boss_roar", -1.0)
		Sfx.play_music("boss")
	var ph: Dictionary = phases[i]
	_eq_label.text = ph.get("equation", "")
	for p in _panels:
		p.queue_free()
	_panels.clear()
	var defs: Array = ph.get("panels", [])
	for j in defs.size():
		var p := Area2D.new()
		p.set_meta("ok", defs[j].get("ok", false))
		p.position = global_position + Vector2(-(defs.size() - 1) * 85.0 + j * 170.0, 0)
		var sh := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(120, 16)
		sh.shape = rect
		p.add_child(sh)
		var lay := Polygon2D.new()
		lay.polygon = PackedVector2Array([
			Vector2(-60, -8), Vector2(60, -8), Vector2(60, 8), Vector2(-60, 8)])
		lay.color = Color(0.35, 0.3, 0.55)
		p.add_child(lay)
		var lb := Label.new()
		lb.text = defs[j].get("v", "?")
		lb.add_theme_font_size_override("font_size", 26)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.position = Vector2(-100, -46)
		lb.custom_minimum_size = Vector2(200, 36)
		p.add_child(lb)
		get_parent().add_child.call_deferred(p)
		_panels.append(p)


func _break_shield() -> void:
	_shielded = false
	_vuln_left = VULN_TIME
	_shield_poly.visible = false
	Sfx.play("phase_break", -2.0)
	Telemetry.track("boss_phase", topic_prefix + "." + _phase_topic(), {
		"phase": _phase, "solved": true,
		"time_ms": Time.get_ticks_msec() - _phase_t0,
		"retries": _phase_retries, "tool_correct": true})


func _shockwave() -> void:
	_phase_retries += 1
	var pl := _player()
	if pl:
		pl.knockback_simple(380.0)
		if pl.global_position.distance_to(global_position) < 260.0:
			pl.take_damage(1, global_position)
	Telemetry.track("boss_phase", topic_prefix + "." + _phase_topic(), {
		"phase": _phase, "solved": false, "retries": _phase_retries})
	var tw := create_tween()
	tw.tween_property(_shield_poly, "scale", Vector2(1.6, 1.6), 0.12)
	tw.tween_property(_shield_poly, "scale", Vector2.ONE, 0.2)


func _phase_topic() -> String:
	if _phase < topic_suffixes.size():
		return topic_suffixes[_phase]
	return topic_suffixes[topic_suffixes.size() - 1]


func take_damage(amount: int, _from: Vector2) -> void:
	if _shielded:
		var tw := create_tween()
		tw.tween_property(_shield_poly, "modulate", Color(2, 2, 2, 0.5), 0.06)
		tw.tween_property(_shield_poly, "modulate", Color.WHITE, 0.15)
		return
	hp -= amount
	hp_changed.emit(hp, MAX_HP)
	var tw := create_tween()
	tw.tween_property(_body_poly, "modulate", Color(2.5, 1.2, 1.2), 0.06)
	tw.tween_property(_body_poly, "modulate", Color.WHITE, 0.2)
	if hp <= 0:
		_win()
	elif hp <= MAX_HP / 2 and _phase < 1:
		_start_phase(_phase + 1)


func _win() -> void:
	Sfx.play("victory", -1.0)
	Sfx.play_music("ambient")
	SaveData.add_lum(60)
	SaveData.set_region_cleared(topic_prefix.get_slice(".", 0), 1)
	Telemetry.track("boss_defeated", topic_prefix + "." + _phase_topic(),
		{"phases": _phase + 1})
	boss_defeated.emit()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(0.1, 2.2), 0.5)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tw.finished.connect(queue_free)


func _player() -> Player:
	var arr := get_tree().get_nodes_in_group("player")
	return arr[0] if arr.size() > 0 else null
