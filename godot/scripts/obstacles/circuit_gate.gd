class_name CircuitGate
extends Node2D
## دروازهٔ مدار/منطق (ICT + بخش الکتریکی فیزیک) — با هر تعامل، الگوی اتصال سه گره
## می‌چرخد؛ وقتی الگو با هدف برابر شد، دروازه باز می‌شود. تله‌متری استاندارد.

signal solved(gate: CircuitGate)

const NODE_SPACING := 150.0

var config: Dictionary = {}
var retries := 0

var _nodes: Array = []
var _target: Array = []
var _state: Array = []
var _resolved := false
var _t0_ms := 0
var _wall_body: StaticBody2D
var _wall_poly: Polygon2D


static func create(cfg: Dictionary) -> CircuitGate:
	var c := CircuitGate.new()
	c.config = cfg
	return c


func _ready() -> void:
	_t0_ms = Time.get_ticks_msec()
	_target = config.get("target", [1, 0, 1])
	_state = config.get("start", [0, 0, 0])
	_build_wall()
	_build_nodes()


func _build_wall() -> void:
	_wall_body = StaticBody2D.new()
	_wall_body.collision_layer = 1
	var sh := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 200)
	sh.shape = rect
	_wall_body.add_child(sh)
	add_child(_wall_body)
	_wall_poly = Polygon2D.new()
	_wall_poly.polygon = PackedVector2Array([
		Vector2(-12, -100), Vector2(12, -100), Vector2(12, 100), Vector2(-12, 100)])
	_wall_poly.color = Color(0.1, 0.35, 0.3)
	add_child(_wall_poly)


func _build_nodes() -> void:
	for i in _state.size():
		var a := Area2D.new()
		a.set_meta("i", i)
		a.input_pickable = true
		a.position = Vector2(-float(_state.size() - 1) / 2.0 * NODE_SPACING
			+ i * NODE_SPACING, -140.0)
		var sh := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 26.0
		sh.shape = c
		a.add_child(sh)
		var glow := Polygon2D.new()
		glow.name = "Glow"
		glow.polygon = PackedVector2Array([
			Vector2(0, -20), Vector2(19, -6), Vector2(12, 16),
			Vector2(-12, 16), Vector2(-19, -6)])
		a.add_child(glow)
		a.body_entered.connect(_on_node_touch.bind(a))
		add_child(a)
		_nodes.append(a)
	_refresh_glow()
	var l := Label.new()
	l.text = config.get("challenge", "Devreyi kur! [AND=1 OR=0]")
	l.add_theme_font_size_override("font_size", 24)
	l.position = Vector2(-300, -230)
	l.custom_minimum_size = Vector2(600, 40)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)


func _on_node_touch(body: Node2D, node: Area2D) -> void:
	if _resolved or not (body is Player):
		return
	# هر لمس مسیر گره را می‌چرخاند
	var i: int = node.get_meta("i")
	_state[i] = (_state[i] + 1) % 3
	retries += 1
	_refresh_glow()
	if _state == _target:
		_resolve()


func _refresh_glow() -> void:
	var cols := [Color("233049"), Color("57d6ff"), Color("ffd166")]
	for i in _nodes.size():
		var g: Polygon2D = _nodes[i].get_node("Glow")
		g.color = cols[_state[i] % cols.size()]


func _resolve() -> void:
	_resolved = true
	_wall_body.set_deferred("collision_layer", 0)
	var shp: CollisionShape2D = _wall_body.get_child(0)
	shp.set_deferred("disabled", true)
	Telemetry.track("obstacle_solved", config.get("topic_id", "ict.g8.guz.algoritma"), {
		"solved": true, "time_ms": Time.get_ticks_msec() - _t0_ms,
		"retries": retries, "tool_correct": false})
	SaveData.add_lum(6)
	var tw := create_tween()
	tw.tween_property(_wall_poly, "color:a", 0.0, 0.5)
	solved.emit(self)
