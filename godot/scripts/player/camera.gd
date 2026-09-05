class_name GameCamera
extends Camera2D
## دوربین با هموارسازی + نگاه‌پیشِ حرکتی (حس HK).

var target: Player
var lookahead := 0.0


static func create(t: Player) -> GameCamera:
	var c := GameCamera.new()
	c.target = t
	c.position_smoothing_enabled = true
	c.position_smoothing_speed = 6.0
	c.zoom = Vector2(1.0, 1.0)
	return c


func _process(delta: float) -> void:
	if not target:
		return
	var want: float = clampf(target.velocity.x * 0.45, -110.0, 110.0)
	lookahead = lerpf(lookahead, want, delta * 2.5)
	position.x = target.global_position.x + lookahead
	position.y = target.global_position.y - 20.0
