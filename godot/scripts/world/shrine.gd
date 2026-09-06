class_name Shrine
extends Area2D
## شین — نقطهٔ استراحت/ذخیره (الگوی نیمکت HK): جان کامل + ریسپاون جدید.

static func create() -> Shrine:
	return Shrine.new()


func _ready() -> void:
	monitoring = true
	collision_layer = 0
	collision_mask = 1
	var sh := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 50)
	sh.shape = rect
	add_child(sh)
	var sil := Polygon2D.new()
	sil.polygon = PackedVector2Array([
		Vector2(-26, 25), Vector2(26, 25), Vector2(16, -10),
		Vector2(0, -25), Vector2(-16, -10)])
	sil.color = Color(0.35, 0.9, 0.75, 0.85)
	add_child(sil)
	body_entered.connect(_on_body)


func _on_body(body: Node2D) -> void:
	if body is Player:
		body.heal(99)
		body.set_respawn(body.global_position)
		SaveData.save_now()
		Telemetry.track("shrine_rest", "", {})
