## Spitter3D — تیرانداز شناور: ایستا/شناور، هر چند ثانیه تیر به سمت بازیکن.
class_name Spitter3D
extends CharacterBody3D

signal died

const HP_MAX := 2
const GRAV := 24.0
const HOVER_Y := 2.1
const SHOT_PERIOD := 2.4
const SHOT_SPEED := 11.0
const LUM_DROP := 8

var hp := HP_MAX
var _player: Player3D
var _theme := Color("c792ea")
var _alive := true
var _t := 0.0
var _shot_t := 0.0


static func create(theme_color: String = "c792ea") -> Spitter3D:
	var s := Spitter3D.new()
	s._theme = Color(theme_color)
	return s


func _ready() -> void:
	add_to_group("damageable")
	_build_visual()
	_player = get_tree().get_first_node_in_group("player")


func _build_visual() -> void:
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.6
	col.shape = sph
	col.position = Vector3(0, HOVER_Y, 0)
	add_child(col)
	var core := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.55
	m.height = 1.1
	core.mesh = m
	core.position = Vector3(0, HOVER_Y, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _theme.darkened(0.35)
	core.material_override = mat
	core.name = "Core"
	add_child(core)
	# دهانهٔ درخشان
	var muzzle := MeshInstance3D.new()
	var cone := ConeMesh.new()
	cone.bottom_radius = 0.22
	cone.height = 0.5
	cone.top_radius = 0.05
	muzzle.mesh = cone
	muzzle.position = Vector3(0, HOVER_Y - 0.1, -0.6)
	muzzle.rotation.x = -PI * 0.5
	var mm := StandardMaterial3D.new()
	mm.albedo_color = _theme
	mm.emission_enabled = true
	mm.emission = _theme
	mm.emission_energy_multiplier = 2.4
	muzzle.material_override = mm
	muzzle.name = "Muzzle"
	add_child(muzzle)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_t += delta
	if not is_on_floor():
		velocity.y -= GRAV * delta
	else:
		velocity.y = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()
	# موج شناور
	var core := get_node_or_null("Core") as MeshInstance3D
	if core:
		core.position.y = HOVER_Y + sin(_t * 2.2) * 0.18
	var muzzle := get_node_or_null("Muzzle") as MeshInstance3D
	if muzzle:
		muzzle.position.y = core.position.y - 0.1 if core else HOVER_Y - 0.1
	# رو به بازیکن + شلیک
	if _player and is_instance_valid(_player):
		var to: Vector3 = _player.global_position - global_position
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 0.1)
		_shot_t -= delta
		if _shot_t <= 0.0 and to.length() < 22.0:
			_shot_t = SHOT_PERIOD
			_fire(to)


func _fire(to: Vector3) -> void:
	var dir := (to + Vector3(0, 0.9, 0) - Vector3(0, HOVER_Y, 0)).normalized()
	Sfx.play("attack", -7.0, 1.3)
	var bolt := Area3D.new()
	bolt.collision_layer = 4
	bolt.collision_mask = 3   # بازیکن (2) + زمین (1)
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.22
	col.shape = sph
	bolt.add_child(col)
	var mesh := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.2
	m.height = 0.4
	mesh.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _theme
	mat.emission_enabled = true
	mat.emission = _theme
	mat.emission_energy_multiplier = 3.0
	mesh.material_override = mat
	bolt.add_child(mesh)
	get_parent().add_child(bolt)
	bolt.global_position = global_position + Vector3(0, HOVER_Y, 0) + dir * 0.8
	bolt.set_meta("dir", dir)
	bolt.set_meta("speed", SHOT_SPEED)
	bolt.set_meta("life", 4.0)
	bolt.body_entered.connect(_on_bolt_hit.bind(bolt))
	bolt.process_mode = Node.PROCESS_MODE_INHERIT
	bolt.set_process(true)
	_track_bolt(bolt)


func _track_bolt(bolt: Area3D) -> void:
	# حرکت دستی تیر (منطق ساده بدون RigidBody)
	if not is_instance_valid(get_tree()):
		return
	while is_instance_valid(bolt):
		await get_tree().process_frame
		if not is_instance_valid(bolt):
			return
		var dt := get_process_delta_time()
		var d: Vector3 = bolt.get_meta("dir")
		bolt.position += d * float(bolt.get_meta("speed")) * dt
		bolt.set_meta("life", float(bolt.get_meta("life")) - dt)
		if float(bolt.get_meta("life")) <= 0.0:
			bolt.queue_free()
			return


func _on_bolt_hit(body: Node3D, bolt: Area3D) -> void:
	if not is_instance_valid(bolt):
		return
	if body is Player3D:
		body.take_damage(1, bolt.global_position)
	Sfx.play("hurt", -9.0, 1.5)
	bolt.queue_free()


func take_damage(amount: int, _from_pos: Vector3) -> void:
	if not _alive:
		return
	hp -= amount
	Sfx.play("hurt", -5.0, 1.1)
	if hp <= 0:
		_die()


func _die() -> void:
	_alive = false
	died.emit()
	Sfx.play("gate_bad", -5.0, 0.8)
	if _player and is_instance_valid(_player):
		_player.collect_lum(LUM_DROP)
	Telemetry.track("enemy_defeated", "", {"type": "spitter", "dim": 3})
	Fx.burst(get_parent(), global_position + Vector3(0, 2.0, 0), _theme.to_html(false), 24)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position:y", position.y + 2.5, 0.5)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tw.chain().tween_callback(queue_free)
