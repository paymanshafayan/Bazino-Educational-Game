extends Area2D
## Blade — ناحیهٔ ضربهٔ شمشیر نور بازیکن؛ فقط در لحظهٔ حمله فعال است.

const HIT_STOP := 0.045

var _owner_player: Node2D
var _damage := 2
var _heavy := false
var _visible_poly: Polygon2D


func setup(player: Node2D, damage: int) -> void:
	_owner_player = player
	_damage = damage
	monitoring = false
	collision_layer = 2
	collision_mask = 4
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)
	_visible_poly = Polygon2D.new()
	_visible_poly.polygon = PackedVector2Array([
		Vector2(8, -16), Vector2(56, -10), Vector2(64, 0),
		Vector2(56, 10), Vector2(8, 16)])
	_visible_poly.color = Color(0.55, 0.85, 1.0, 0.0)
	add_child(_visible_poly)


func strike(dir: int, duration: float, heavy: bool) -> void:
	_heavy = heavy
	scale.x = dir
	monitoring = true
	var tw := create_tween()
	_visible_poly.color.a = 0.85
	tw.tween_property(_visible_poly, "color:a", 0.0, maxf(duration, 0.05))
	await get_tree().create_timer(duration).timeout
	monitoring = false


func _on_body(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		_hit_stop()
		body.take_damage(_damage * (2 if _heavy else 1), _owner_player.global_position)
		if _owner_player.has_method("collect_lum"):
			pass


func _on_area(area: Area2D) -> void:
	var tgt := area.get_parent()
	if tgt and tgt.is_in_group("enemy") and tgt.has_method("take_damage"):
		_hit_stop()
		tgt.take_damage(_damage * (2 if _heavy else 1), _owner_player.global_position)


func _hit_stop() -> void:
	Engine.time_scale = 0.25
	get_tree().create_timer(HIT_STOP, false).timeout.connect(
		func(): Engine.time_scale = 1.0)
