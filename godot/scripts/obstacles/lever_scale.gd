class_name LeverScale
extends Node2D
## اهرم/کفهٔ ترازو فیزیکی (Fizik Kalesi) — فیزیک واقعی موتور: تعادل با قرار دادن جعبه‌ها
## روی کفه‌ها تا زاویهٔ هدف. تله‌متری: obstacle_solved (topic_id فیزیک).

signal solved(gate: LeverScale)

const HOLD_ANGLE := 0.18     # رادیان — حداقل فاصلهٔ تعادل از صفر
const HOLD_TIME := 0.8

var config: Dictionary = {}
var retries := 0

var _pivot: StaticBody2D
var _plank: RigidBody2D
var _hold := 0.0
var _resolved := false
var _t0_ms := 0
var _plank_poly: Polygon2D
var _crates: Array = []


static func create(cfg: Dictionary) -> LeverScale:
	var l := LeverScale.new()
	l.config = cfg
	return l


func _ready() -> void:
	_t0_ms = Time.get_ticks_msec()
	_pivot = StaticBody2D.new()
	_pivot.collision_layer = 1
	var ps := CollisionShape2D.new()
	var tri := ConvexPolygonShape2D.new()
	tri.points = PackedVector2Array([Vector2(-14, 0), Vector2(14, 0), Vector2(0, -16)])
	ps.shape = tri
	_pivot.add_child(ps)
	add_child(_pivot)

	_plank = RigidBody2D.new()
	_plank.collision_layer = 1
	_plank.mass = 2.0
	_plank.center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	_plank.center_of_mass = Vector2(0, 0)
	var ms := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(520, 14)
	ms.shape = rect
	_plank.add_child(ms)
	_plank_poly = Polygon2D.new()
	_plank_poly.polygon = PackedVector2Array([
		Vector2(-260, -7), Vector2(260, -7), Vector2(260, 7), Vector2(-260, 7)])
	_plank_poly.color = Color("5a7dd6")
	_plank.add_child(_plank_poly)
	add_child(_plank)

	var joint := PinJoint2D.new()
	joint.node_a = _pivot.get_path()
	joint.node_b = _plank.get_path()
	add_child(joint)

	var need: int = config.get("crates", 3)
	for i in need:
		_spawn_crate(Vector2(-(need - 1) * 60.0 + i * 120.0, -160.0))
	_label(_tr_hint(), Vector2(0, -260))


func _tr_hint() -> String:
	return config.get("challenge", "Dengeyi kur! (crates → pan)")


func _spawn_crate(pos: Vector2) -> void:
	var c := RigidBody2D.new()
	c.mass = 1.0
	c.collision_layer = 1
	var sh := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 26)
	sh.shape = rect
	c.add_child(sh)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-13, -13), Vector2(13, -13), Vector2(13, 13), Vector2(-13, 13)])
	poly.color = Color("d6a75d")
	c.add_child(poly)
	c.position = pos
	add_child(c)
	_crates.append(c)


func _physics_process(delta: float) -> void:
	if _resolved:
		return
	var angle := absf(wrapf(_plank.rotation, -PI, PI))
	var near_level := angle < HOLD_ANGLE
	var enough_crates := _crates_on_plank() >= int(config.get("need", 2))
	if near_level and enough_crates:
		_hold += delta
		_plank_poly.color = Color("9dff70")
		if _hold >= HOLD_TIME:
			_resolve()
	else:
		_hold = 0.0
		_plank_poly.color = Color("5a7dd6")


func _crates_on_plank() -> int:
	var n := 0
	for c in _crates:
		if is_instance_valid(c) and absf(c.global_position.y - _plank.global_position.y) < 60.0 \
				and absf(c.global_position.x - _plank.global_position.x) < 280.0:
			n += 1
	return n


func _resolve() -> void:
	_resolved = true
	Telemetry.track("obstacle_solved", config.get("topic_id", "physics.g8.guz.basit-makineler"), {
		"solved": true, "time_ms": Time.get_ticks_msec() - _t0_ms,
		"retries": retries, "tool_correct": false})
	SaveData.add_lum(6)
	solved.emit(self)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.4, 0.8)


func _label(text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color("7ecaff"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = pos + Vector2(-250, -20)
	l.custom_minimum_size = Vector2(500, 40)
	add_child(l)
