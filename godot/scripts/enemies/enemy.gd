class_name Enemy
extends CharacterBody2D
## Enemy — سیلوئت موضوعی پایه: گشت/دنبال‌کردن/ضربهٔ تماسی.

signal died(enemy: Enemy)

const SPEED := 90.0
const CHASE_SPEED := 150.0
const GRAV := 2150.0
const CONTACT_COOLDOWN := 0.9
const MAX_HP := 6

var hp := MAX_HP
var patrol_left := -160.0
var patrol_right := 160.0
var _dir := 1
var _home := Vector2.ZERO
var _cool := 0.0
var _visual: Polygon2D


static func create(theme: String) -> Enemy:
	var e := Enemy.new()
	e.add_to_group("enemy")
	e.collision_layer = 4   # شمشیر بازیکن (mask=4) همین را هدف می‌گیرد
	e.collision_mask = 1
	var body := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(26, 26)
	body.shape = shape
	e.add_child(body)
	var v := Polygon2D.new()
	v.polygon = PackedVector2Array([
		Vector2(0, -16), Vector2(15, 0), Vector2(0, 16), Vector2(-15, 0)])
	v.color = Color("ff5c7a") if theme != "root_crawler" else Color("9dff70")
	e.add_child(v)
	var eye := Polygon2D.new()
	eye.polygon = PackedVector2Array([
		Vector2(2, -6), Vector2(7, -6), Vector2(7, -1), Vector2(2, -1)])
	eye.color = Color.WHITE
	e.add_child(eye)
	e._visual = v
	return e


func _ready() -> void:
	_home = global_position


func _physics_process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAV * delta, 900.0)
	var pl := _player()
	if pl and global_position.distance_to(pl.global_position) < 220.0:
		_dir = signi(pl.global_position.x - global_position.x)
		velocity.x = _dir * CHASE_SPEED
	else:
		velocity.x = _dir * SPEED
		if _home.x + patrol_right < global_position.x:
			_dir = -1
		elif _home.x + patrol_left > global_position.x:
			_dir = 1
	move_and_slide()
	if _cool <= 0.0 and pl and global_position.distance_to(pl.global_position) < 34.0:
		pl.take_damage(1, global_position)
		_cool = CONTACT_COOLDOWN


func take_damage(amount: int, from_pos: Vector2) -> void:
	hp -= amount
	velocity = Vector2(signi(global_position.x - from_pos.x) * 240.0, -160.0)
	var tw := create_tween()
	tw.tween_property(_visual, "modulate", Color(2, 2, 2), 0.05)
	tw.tween_property(_visual, "modulate", Color.WHITE, 0.18)
	if hp <= 0:
		_die()


func _die() -> void:
	Sfx.play("land", -3.0, 0.7)
	died.emit(self)
	SaveData.add_lum(3)
	Telemetry.track("enemy_down", "", {"hp0": true})
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(self, "scale", Vector2(1.8, 0.1), 0.3)
	tw.finished.connect(queue_free)


func _player() -> Player:
	var arr := get_tree().get_nodes_in_group("player")
	return arr[0] if arr.size() > 0 else null
