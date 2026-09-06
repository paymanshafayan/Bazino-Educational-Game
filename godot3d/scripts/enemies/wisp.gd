## عرضی «روح عدد»: شناور، تعقیب کنندهٔ آرام، خودمرگ دو-ضربه.
class_name Wisp3D
extends CharacterBody3D

signal died

const SPEED := 1.9
const HOVER_H := 1.1
const CHASE_RANGE := 20.0

var hp := 2
var body_color: Color = Color("59d6ff")
var _t := 0.0
var _mesh: MeshInstance3D


static func create(theme_color: String = "59d6ff") -> Wisp3D:
	var w := Wisp3D.new()
	w.body_color = Color(theme_color)
	return w


func _ready() -> void:
	add_to_group("damageable")
	add_to_group("wisp")
	collision_layer = 4
	collision_mask = 1 | 2
	_mesh = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.42
	s.height = 0.84
	_mesh.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.emission_enabled = true
	mat.emission = body_color
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	_mesh.material_override = mat
	add_child(_mesh)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.0
	col.shape = cap
	col.position = Vector3(0, HOVER_H * 0.5, 0)
	add_child(col)
	_mesh.position = Vector3(0, HOVER_H * 0.5, 0)


func _physics_process(delta: float) -> void:
	_t += delta
	# شناوری نرم (بدون نیاز به فیزیک سنگین)
	var target := _player()
	if target and global_position.distance_to(target.global_position) < CHASE_RANGE:
		var to := target.global_position - global_position
		to.y = 0.0
		velocity.x = move_toward(velocity.x, to.normalized().x * SPEED, 1.5 * delta * 60)
		velocity.z = move_toward(velocity.z, to.normalized().z * SPEED, 1.5 * delta * 60)
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 60)
		velocity.z = move_toward(velocity.z, 0.0, delta * 60)
	velocity.y = -(velocity.y) * 0.9  # نگهداشت ارتفاع تقریبی
	velocity.y += (sin(_t * 2.2) * 0.4 - velocity.y) * 0.25
	move_and_slide()
	_mesh.position.y = HOVER_H * 0.5 + sin(_t * 2.6) * 0.15
	# تماسی با بازیکن = آسیب سبک
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var o := c.get_collider()
		if o is Player3D:
			o.take_damage(1, global_position)


func _player() -> Player3D:
	var arr := get_tree().get_nodes_in_group("player")
	if arr.size() > 0 and arr[0] is Player3D:
		return arr[0]
	return null


func take_damage(amount: int, from_pos: Vector3) -> void:
	hp -= amount
	Sfx.play("hurt", -6.0, 1.4)
	var tw := create_tween()
	tw.tween_property(_mesh, "scale", Vector3(1.3, 0.8, 1.3), 0.06)
	tw.tween_property(_mesh, "scale", Vector3.ONE, 0.12)
	var away := global_position - from_pos
	away.y = 0.0
	velocity += away.normalized() * 4.0
	if hp <= 0:
		_die()


func _die() -> void:
	Sfx.play("land", -3.0, 0.7)
	died.emit()
	SaveData.add_lum(3)
	Telemetry.track("enemy_down", "", {"dim": 3})
	Fx.burst(get_parent(), global_position, body_color.to_html(false), 20)
	var tw := create_tween()
	tw.tween_property(_mesh, "scale", Vector3(0.0, 1.8, 0.0), 0.35)
	tw.tween_callback(queue_free)
