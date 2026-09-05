class_name FormulaScroll
extends Area2D
## گنجینهٔ «دفترچهٔ فرمول» — توان جدید → کارت بصری (بدون درس‌نامه؛ GDD §۴).

signal tool_pickup(tool_id: String)

var tool_id := ""
var topic_id := ""
var _taken := false


static func create(tid: String, topic: String) -> FormulaScroll:
	var s := FormulaScroll.new()
	s.tool_id = tid
	s.topic_id = topic
	return s


func _ready() -> void:
	monitoring = true
	collision_layer = 0
	collision_mask = 1
	var sh := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, 44)
	sh.shape = rect
	add_child(sh)
	var glow := Polygon2D.new()
	glow.name = "Glow"
	glow.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(16, -6), Vector2(10, 18),
		Vector2(-10, 18), Vector2(-16, -6)])
	glow.color = Color(1.0, 0.85, 0.35, 0.9)
	add_child(glow)
	body_entered.connect(_on_body)


func _process(_d: float) -> void:
	if _taken:
		return
	var g := get_node("Glow") as Polygon2D
	g.position.y = sin(Time.get_ticks_msec() / 350.0) * 4.0
	g.rotation = sin(Time.get_ticks_msec() / 700.0) * 0.15


func _on_body(body: Node2D) -> void:
	if _taken or not (body is Player):
		return
	_taken = true
	SaveData.add_tool(tool_id)
	SaveData.add_lum(10)
	Telemetry.track("tool_acquired", topic_id, {"tool_id": tool_id})
	tool_pickup.emit(tool_id)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.2)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tw.finished.connect(queue_free)
