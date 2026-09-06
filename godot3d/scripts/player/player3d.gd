## کنترلر سوم-شخص بازینو — همان حس Hollow-Knight در ۳ بعد.
## کایوت‌تایم + بافر پرش + دَش با مصونیت + کامبوی ۳ضربه‌ای + هیت‌استاپ.
class_name Player3D
extends CharacterBody3D

signal hp_changed(hp: int, hp_max: int)
signal lum_picked(amount: int)
signal attack_landed
signal combo_display(combo: int)
signal died

const RUN_SPEED := 5.6
const ACCEL := 34.0
const AIR_CONTROL := 0.6
const JUMP_VELOCITY := 9.2
const MAX_FALL := 20.0
const COYOTE_TIME := 0.14
const JUMP_BUFFER := 0.12
const DASH_SPEED := 16.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.9
const DASH_IFRAMES := 0.20
const ATTACK_TIME := 0.32
const ATTACK_CHAIN_GAP := 0.14
const HURT_IFRAMES := 0.8
const KNOCKBACK := Vector3(5.0, 4.0, 0.0)

var hp_max := 5
var hp := 5
var facing := Vector3.FORWARD          # جهت دید مدل (محل حمله)

var _coyote := 0.0
var _buffer := 0.0
var _dash_left := 0.0
var _dash_cd := 0.0
var _iframes := 0.0
var _attack_left := 0.0
var _chain_gap := 0.0
var _combo := 0
var _air := false
var _respawn := Vector3.ZERO

var cam_yaw := 0.0                     # از سمت CameraRig تنظیم می‌شود
var mesh_root: Node3D
var anim: AnimationPlayer


func _ready() -> void:
	add_to_group("player")
	_respawn = global_position
	collision_layer = 2
	collision_mask = 1 | 4 | 8
	_build_visual_fallback()
	try_upgrade_model()


func _build_visual_fallback() -> void:
	# مدل موقت تا وقتی پک‌های Quaternius در assets/external/ قرار بگیرند
	mesh_root = Node3D.new()
	mesh_root.name = "MeshRoot"
	add_child(mesh_root)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.32
	capsule.height = 1.3
	capsule.radial_segments = 16
	body.mesh = capsule
	body.position = Vector3(0, 0.65, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("8df7c9")
	mat.emission_enabled = true
	mat.emission = Color("44c98a")
	mat.emission_energy_multiplier = 0.6
	body.material_override = mat
	mesh_root.add_child(body)
	var col := CollisionShape3D.new()
	col.position = Vector3(0, 0.65, 0)
	var col_shape := CapsuleShape3D.new()
	col_shape.radius = 0.32
	col_shape.height = 1.3
	col.shape = col_shape
	add_child(col)


func node_ready_with_model(model: Node3D, anims: AnimationPlayer) -> void:
	"""هنگام دسترس‌بودن مدل واقعی پک، جایگزین fallback می‌شود."""
	anim = anims
	if mesh_root:
		for c in mesh_root.get_children():
			c.queue_free()
	mesh_root.add_child(model)


## در _ready فراخوانی شود: تلاش برای تعویض خودکار با پک‌های دانلودی
func try_upgrade_model() -> void:
	if not ModelBank.has("player"):
		return
	var pair := ModelBank.instantiate_animated("player")
	if pair[0] == null:
		return
	ModelBank.normalize_height(pair[0], 1.8)
	node_ready_with_model(pair[0], pair[1])


func _anim_tick() -> void:
	# انتخاب Run/Idle خودکار با مدل واقعی (با fallback بی‌صدا)
	if anim == null:
		return
	var spd := Vector2(velocity.x, velocity.z).length()
	if spd > 1.0:
		var run := ModelBank.pick_anim(anim, "run")
		if run == "":
			run = ModelBank.pick_anim(anim, "walk")
		if run != "" and anim.current_animation != run:
			anim.play(run)
	else:
		var idle := ModelBank.pick_anim(anim, "idle")
		if idle != "" and anim.current_animation != idle \
				and not str(anim.current_animation).to_lower().contains("attack"):
			anim.play(idle)


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_apply_gravity(delta)
	var raw := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move := Vector3(raw.x, 0.0, raw.y).rotated(Vector3.UP, cam_yaw)
	_move(move, delta)
	_jump()
	_dash(move)
	_attack()
	move_and_slide()
	_anim_tick()
	_update_facing(move, delta)


func _tick_timers(delta: float) -> void:
	_coyote = maxf(0.0, _coyote - delta)
	_buffer = maxf(0.0, _buffer - delta)
	_dash_left = maxf(0.0, _dash_left - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_iframes = maxf(0.0, _iframes - delta)
	_attack_left = maxf(0.0, _attack_left - delta)
	_chain_gap = maxf(0.0, _chain_gap - delta)
	if is_on_floor():
		if _air:
			Sfx.play("land", -5.0)
			if mesh_root:
				mesh_root.scale = Vector3(1.18, 0.72, 1.18)
				var tw := create_tween()
				tw.tween_property(mesh_root, "scale", Vector3.ONE, 0.18)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_air = false
		_coyote = COYOTE_TIME
	else:
		_air = true


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = maxf(velocity.y - 24.0 * delta, -MAX_FALL)


func _move(move: Vector3, delta: float) -> void:
	if _dash_left > 0.0:
		return
	var want_xz := move * RUN_SPEED
	var rate := ACCEL * (AIR_CONTROL if not is_on_floor() else 1.0)
	velocity.x = move_toward(velocity.x, want_xz.x, rate * delta)
	velocity.z = move_toward(velocity.z, want_xz.z, rate * delta)


func _jump() -> void:
	if Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
		Sfx.play("jump", -2.0)
		_try_anim("Jump")
	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= 0.5


func _dash(move: Vector3) -> void:
	if _dash_left > 0.0:
		velocity.x = facing.x * DASH_SPEED
		velocity.z = facing.z * DASH_SPEED
		return
	if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		var dir := move
		if dir.length_squared() < 0.01:
			dir = facing
		facing = dir.normalized()
		_dash_left = DASH_TIME
		_dash_cd = DASH_COOLDOWN
		_iframes = maxf(_iframes, DASH_IFRAMES)
		Sfx.play("dash", -2.0)
		Fx.cam_fov_kick(get_tree(), 9.0)
		_dust()


func _attack() -> void:
	if _attack_left > 0.0 or _chain_gap > 0.0:
		return
	if Input.is_action_just_pressed("attack"):
		_combo = (_combo % 3) + 1
		combo_display.emit(_combo)
		_attack_left = ATTACK_TIME
		_chain_gap = ATTACK_TIME + ATTACK_CHAIN_GAP
		Sfx.play("attack", -3.0, 0.95 + _combo * 0.08)
		_try_anim("Attack%d" % _combo)
		_strike_area()
		attack_landed.emit()
		Telemetry.track("attack_swing", "", {"combo": _combo, "dim": 3})


func _strike_area() -> void:
	# چک ناحیهٔ حمله: کرهٔ جلوی بازیکن
	for body in get_tree().get_nodes_in_group("damageable"):
		if body == self:
			continue
		if not (body is Node3D):
			continue
		var off: Vector3 = body.global_position - global_position
		off.y = 0.0
		if off.length() <= 2.2 and facing.angle_to(off.normalized()) < 1.2:
			body.take_damage(1, global_position + facing)
			Fx.burst(self, body.global_position + Vector3(0, 1.2, 0), "ffffff", 12, false)
			Fx.hitstop(get_tree(), 55)


func _update_facing(move: Vector3, delta: float) -> void:
	if move.length_squared() > 0.002:
		facing = lerp(facing, move.normalized(), clampf(delta * 14.0, 0.0, 1.0))
	if mesh_root:
		var target := atan2(facing.x, facing.z)
		mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target,
			clampf(delta * 12.0, 0.0, 1.0))


func _try_anim(name: String) -> void:
	if anim == null:
		return
	if anim.has_animation(name):
		anim.play(name)
		return
	# نام‌های متفاوت پک‌ها: substring case-insensitive (مثلاً Attack3 → 1H_Melee_Attack…)
	var key := name
	if name.begins_with("Attack"):
		key = "attack"
	var alt := ModelBank.pick_anim(anim, key)
	if alt != "":
		anim.play(alt)


func _dust() -> void:
	# ذرات گرد ساده – حین جلوت گرافیک
	var dust := GPUParticles3D.new()
	dust.amount = 8
	dust.lifetime = 0.35
	dust.one_shot = true
	dust.emitting = true
	var mat := ParticleProcessMaterial.new()
	mat.direction = -facing
	mat.spread = 35.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 2.5
	mat.scale_min = 0.06
	mat.scale_max = 0.14
	dust.process_material = mat
	get_parent().add_child(dust)
	dust.global_position = global_position + Vector3(0, 0.2, 0)


func take_damage(amount: int, from_pos: Vector3) -> void:
	if _iframes > 0.0 or hp <= 0:
		return
	hp -= amount
	_iframes = HURT_IFRAMES
	Sfx.play("hurt", -3.0)
	Fx.cam_shake(get_tree(), 0.4)
	var away := (global_position - from_pos)
	away.y = 0.0
	if away.length_squared() < 0.001:
		away = -facing
	away = away.normalized()
	velocity.x = away.x * KNOCKBACK.x
	velocity.z = away.z * KNOCKBACK.x
	velocity.y = KNOCKBACK.y
	hp_changed.emit(hp, hp_max)
	if hp <= 0:
		_die()
	Telemetry.track("death", "", {"hp": hp})


func collect_lum(n: int) -> void:
	Sfx.play("lum", -4.0)
	SaveData.add_lum(n)
	lum_picked.emit(n)


func knockback_simple(force: float = 4.0) -> void:
	velocity.x = -facing.x * force
	velocity.z = -facing.z * force


func _die() -> void:
	hp = hp_max
	hp_changed.emit(hp, hp_max)
	global_position = _respawn
	velocity = Vector3.ZERO
	died.emit()
	Telemetry.track("respawn", "", {"dim": 3})
