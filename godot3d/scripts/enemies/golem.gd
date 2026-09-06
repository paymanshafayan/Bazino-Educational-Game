## Golem3D — «root crawler»: تانک زمینی کند، ضربهٔ تماسی سنگین، HP بالا.
class_name Golem3D
extends CharacterBody3D

signal died

const HP_MAX := 5
const SPEED := 1.9
const GRAV := 24.0
const LUM_DROP := 6
const CONTACT_DMG := 2

var hp := HP_MAX
var _player: Player3D
var _touch_cd := 0.0
var _theme := Color("7ded8b")
var _alive := true


static func create(theme_color: String = "7ded8b") -> Golem3D:
	var g := Golem3D.new()
	g._theme = Color(theme_color)
	return g


func _ready() -> void:
	add_to_group("damageable")
	_build_visual()
	_player = get_tree().get_first_node_in_group("player")


func _build_visual() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.9
	cap.height = 2.6
	col.shape = cap
	col.position = Vector3(0, 1.4, 0)
	add_child(col)
	# بدنهٔ سنگی
	var body := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = 0.9
	m.height = 2.6
	body.mesh = m
	body.position = Vector3(0, 1.4, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _theme.darkened(0.45)
	mat.roughness = 0.9
	body.material_override = mat
	add_child(body)
	# چشم‌های درخشان
	for side in [-0.32, 0.32]:
		var eye := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.09
		sph.height = 0.18
		eye.mesh = sph
		eye.position = Vector3(side, 1.9, -0.75)
		var emat := StandardMaterial3D.new()
		emat.albedo_color = _theme
		emat.emission_enabled = true
		emat.emission = _theme
		emat.emission_energy_multiplier = 3.0
		eye.material_override = emat
		add_child(eye)
	# شاخ‌های کریستالی پشت
	for i in 3:
		var spike := MeshInstance3D.new()
		var cone := ConeMesh.new()
		cone.bottom_radius = 0.14
		cone.height = 0.9
		spike.mesh = cone
		spike.position = Vector3((i - 1) * 0.3, 2.2 - abs(i - 1) * 0.25, 0.55)
		spike.rotation.x = 0.8
		var smat := StandardMaterial3D.new()
		smat.albedo_color = _theme
		smat.emission_enabled = true
		smat.emission = _theme
		smat.emission_energy_multiplier = 1.4
		spike.material_override = smat
		add_child(spike)
	var touch := Area3D.new()
	touch.collision_layer = 4
	touch.collision_mask = 2
	var tcol := CollisionShape3D.new()
	var tsph := SphereShape3D.new()
	tsph.radius = 1.25
	tcol.shape = tsph
	tcol.position = Vector3(0, 1.3, 0)
	touch.add_child(tcol)
	add_child(touch)
	touch.body_entered.connect(_on_touch)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_touch_cd = maxf(_touch_cd - delta, 0.0)
	if not is_on_floor():
		velocity.y -= GRAV * delta
	else:
		velocity.y = 0.0
	if _player and is_instance_valid(_player):
		var to: Vector3 = _player.global_position - global_position
		to.y = 0.0
		if to.length() > 1.0:
			var dir := to.normalized()
			velocity.x = dir.x * SPEED
			velocity.z = dir.z * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 0.06)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	move_and_slide()


func _on_touch(body: Node3D) -> void:
	if not _alive or _touch_cd > 0.0:
		return
	if body is Player3D:
		_touch_cd = 1.2
		body.take_damage(CONTACT_DMG, global_position)
		body.knockback_simple(6.0)


func take_damage(amount: int, from_pos: Vector3) -> void:
	if not _alive:
		return
	hp -= amount
	Sfx.play("hurt", -5.0, 0.75)
	var off: Vector3 = global_position - from_pos
	off.y = 0.0
	velocity += off.normalized() * 1.6  # سنگین است؛ خیلی نمی‌پرد
	if hp <= 0:
		_die()


func _die() -> void:
	_alive = false
	died.emit()
	Sfx.play("land", -2.0, 0.6)
	if _player and is_instance_valid(_player):
		_player.collect_lum(LUM_DROP)
	Telemetry.track("enemy_defeated", "", {"type": "golem", "dim": 3})
	Fx.burst(get_parent(), global_position + Vector3(0, 1.0, 0), _theme.to_html(false), 24)
	Fx.cam_shake(get_tree(), 0.15)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "rotation:x", -PI * 0.5, 0.4)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.55)
	tw.chain().tween_callback(queue_free)
