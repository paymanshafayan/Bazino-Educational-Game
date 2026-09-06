## Boss3D — پورت وفادار Eski Hesapçı به سه‌بعد (سیستم عمومی همهٔ ۷ باس).
## سپر پازلی: معادله + ۴ سکوی رون؛ جواب درست = شکست سپر و ۴٫۵ ثانیه آسیب‌پذیری،
## غلط/تأخیر = موج شوک. ضربهٔ تن‌به‌تن فقط بی‌سپر اثر دارد.
class_name Boss3D
extends CharacterBody3D

signal boss_defeated
signal hp_changed(hp: int, hp_max: int)

const MAX_HP := 24
const WALK_SPEED := 2.1
const GRAV := 24.0
const VULN_TIME := 4.5
const STAND_TIME := 0.55
const PHASE_TIME := 14.0
const CONTACT_DMG := 1
const PAD_RADIUS := 1.05

var name_key := "boss_eski"
var phases: Array = []
var hp := MAX_HP
var boss_name := "??"

var _phase := 0
var _shielded := true
var _vuln_left := 0.0
var _phase_left := 0.0
var _stand_progress := 0.0
var _candidate: Area3D = null
var _phase_retries := 0
var _panels: Array[Area3D] = []
var _eq_label: Label3D
var _body_mesh: MeshInstance3D
var _shield_mesh: MeshInstance3D
var _player: Player3D
var _alive := true
var _touch_cd := 0.0
var _veh_theme := Color("b8432f")


static func create(cfg_phases: Array, cfg: Dictionary = {}) -> Boss3D:
	var b := Boss3D.new()
	b.phases = cfg_phases
	var nk := str(cfg.get("name_key", str(cfg.get("boss_id", "boss_eski"))))
	if nk == "eski_hesapci":
		nk = "boss_eski"
	if not nk.begins_with("boss_"):
		nk = "boss_" + nk
	b.name_key = nk
	var tint := str(cfg.get("color", ""))
	if tint != "":
		b._veh_theme = Color(tint)
	return b


func _ready() -> void:
	add_to_group("damageable")
	boss_name = tr(name_key)
	if boss_name == name_key:
		boss_name = name_key.trim_prefix("boss_")
	_build_body()
	_player = get_tree().get_first_node_in_group("player")
	_start_phase(0)
	if _player and _player.has_signal("died"):
		pass


func _build_body() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 1.1
	cap.height = 3.4
	col.shape = cap
	col.position = Vector3(0, 1.9, 0)
	add_child(col)
	_body_mesh = MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = 1.1
	m.height = 3.4
	_body_mesh.mesh = m
	_body_mesh.position = Vector3(0, 1.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _veh_theme
	mat.roughness = 0.85
	_body_mesh.material_override = mat
	add_child(_body_mesh)
	# سر سنگی (ماشین‌حساب کهن)
	var head := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.5, 0.9, 0.9)
	head.mesh = box
	head.position = Vector3(0, 3.9, 0)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color("3a3f52")
	hmat.emission_enabled = true
	hmat.emission = Color("ff9f5a")
	hmat.emission_energy_multiplier = 0.7
	head.material_override = hmat
	add_child(head)
	# سپر درخشان
	_shield_mesh = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 2.2
	sph.height = 4.4
	_shield_mesh.mesh = sph
	_shield_mesh.position = Vector3(0, 2.0, 0)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.5, 0.8, 1.0, 0.18)
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.emission_enabled = true
	smat.emission = Color("59d6ff")
	smat.emission_energy_multiplier = 0.8
	_shield_mesh.material_override = smat
	add_child(_shield_mesh)
	# منطقهٔ برخورد (آسیب تماسی)
	var touch := Area3D.new()
	touch.collision_layer = 4
	touch.collision_mask = 2
	var tcol := CollisionShape3D.new()
	var tsph := SphereShape3D.new()
	tsph.radius = 1.5
	tcol.shape = tsph
	tcol.position = Vector3(0, 1.8, 0)
	touch.add_child(tcol)
	add_child(touch)
	touch.body_entered.connect(_on_touch)
	# تابلو معادله
	_eq_label = Label3D.new()
	_eq_label.font_size = 110
	_eq_label.modulate = Color("ffd166")
	_eq_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_eq_label.position = Vector3(0, 5.6, 0)
	add_child(_eq_label)
	var light := OmniLight3D.new()
	light.light_color = Color("ff9f5a")
	light.light_energy = 2.0
	light.omni_range = 10.0
	light.position = Vector3(0, 4.0, 0)
	add_child(light)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_touch_cd = maxf(_touch_cd - delta, 0.0)
	if not is_on_floor():
		velocity.y -= GRAV * delta
	else:
		velocity.y = 0.0
	if _shielded:
		_walk_toward_player()
		_track_phase(delta)
	else:
		_vuln_left -= delta
		velocity.x = lerpf(velocity.x, 0.0, 8.0 * delta)
		velocity.z = lerpf(velocity.z, 0.0, 8.0 * delta)
		if _vuln_left <= 0.0:
			_shield_on()
	move_and_slide()


func _walk_toward_player() -> void:
	if _player == null:
		return
	var to: Vector3 = _player.global_position - global_position
	to.y = 0.0
	if to.length() > 0.6:
		var dir := to.normalized()
		velocity.x = dir.x * WALK_SPEED
		velocity.z = dir.z * WALK_SPEED
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.08)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _track_phase(delta: float) -> void:
	_phase_left -= delta
	if _phase_left <= 0.0:
		_shockwave()
		_reset_stand(null)
		_start_phase(_phase)  # همان فاز دوباره
		return
	# پیشرفت ایستادن
	var cur: Area3D = null
	for pad in _panels:
		for body in pad.get_overlapping_bodies():
			if body is Player3D:
				cur = pad
	if cur != _candidate:
		_candidate = cur
		_stand_progress = 0.0
	if cur:
		_stand_progress += delta
		if _stand_progress >= STAND_TIME:
			if cur.get_meta("ok", false):
				_break_shield()
			else:
				_phase_retries += 1
				Sfx.play("gate_bad", -3.0)
				if _player:
					_player.knockback_simple(6.0)
				Telemetry.track("boss_attempt", _phase_topic(),
					{"dim": 3, "correct": false, "phase": _phase, "retries": _phase_retries})
				_shuffle_panels()
			_reset_stand(null)


func _reset_stand(p: Area3D) -> void:
	_candidate = p
	_stand_progress = 0.0


func _start_phase(i: int) -> void:
	if phases.is_empty():
		# باس بدون دادهٔ فاز: فقط hp با شکست سپر دوره‌ای
		_shielded = false
		_shield_mesh.visible = false
		_vuln_left = 86400.0
		_eq_label.text = "⚔"
		return
	_phase = i % maxi(phases.size(), 1)
	_phase_retries = 0
	_phase_left = PHASE_TIME
	var def: Dictionary = phases[_phase]
	_eq_label.text = str(def.get("equation", "= ?"))
	_spawn_panels(def.get("panels", []))
	Sfx.play("boss_roar", -6.0, 0.9)


func _spawn_panels(defs: Array) -> void:
	_clear_panels()
	var n := defs.size()
	if n == 0:
		return
	for i in n:
		var pad := Area3D.new()
		pad.collision_layer = 8
		pad.collision_mask = 2
		var col := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = PAD_RADIUS
		cyl.height = 0.4
		col.shape = cyl
		col.position = Vector3(0, 0.2, 0)
		pad.add_child(col)
		var stone := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = PAD_RADIUS
		disc.bottom_radius = PAD_RADIUS * 1.08
		disc.height = 0.3
		stone.mesh = disc
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("3a3040")
		mat.emission_enabled = true
		mat.emission = Color("ff9f5a")
		mat.emission_energy_multiplier = 0.5
		stone.material_override = mat
		pad.add_child(stone)
		var num := Label3D.new()
		num.text = str(defs[i].get("v", "?"))
		num.font_size = 100
		num.modulate = Color("ffd166")
		num.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		num.position = Vector3(0, 1.0, 0)
		pad.add_child(num)
		pad.set_meta("ok", defs[i].get("ok", false))
		var ang := i * TAU / n + PI / n
		pad.position = global_position + Vector3(cos(ang) * 6.2, 0, sin(ang) * 6.2)
		get_parent().add_child(pad)
		_panels.append(pad)


func _clear_panels() -> void:
	for p in _panels:
		if is_instance_valid(p):
			p.queue_free()
	_panels.clear()
	_reset_stand(null)


func _shuffle_panels() -> void:
	var xs: Array = []
	for p in _panels:
		xs.append(p.global_position)
	xs.shuffle()
	for i in _panels.size():
		var tw := create_tween()
		tw.tween_property(_panels[i], "global_position", xs[i], 0.35)


func _break_shield() -> void:
	_shielded = false
	_vuln_left = VULN_TIME
	_eq_label.text = "!!!"
	_shield_mesh.visible = false
	_clear_panels()
	Sfx.play("phase_break", -2.0)
	Fx.burst(self, global_position + Vector3(0, 3.0, 0), "59d6ff", 36)
	Fx.cam_shake(get_tree(), 0.55)
	Fx.hitstop(get_tree(), 110)
	Telemetry.track("boss_phase_break", _phase_topic(),
		{"dim": 3, "phase": _phase, "retries": _phase_retries, "time_s": PHASE_TIME - _phase_left})
	if _player:
		_player.knockback_simple(2.0)


func _shield_on() -> void:
	_shielded = true
	_shield_mesh.visible = true
	_start_phase(_phase + 1)


func _shockwave() -> void:
	Sfx.play("boss_roar", -4.0, 0.8)
	Telemetry.track("boss_attempt", _phase_topic(), {"dim": 3, "timeout": true, "phase": _phase})
	if _player and global_position.distance_to(_player.global_position) < 9.0:
		_player.knockback_simple(9.0)
		_player.take_damage(1, global_position)


func _on_touch(body: Node3D) -> void:
	if not _alive or _touch_cd > 0.0:
		return
	if body is Player3D:
		_touch_cd = 1.0
		body.take_damage(CONTACT_DMG, global_position)


## از طرف ضربهٔ بازیکن (گروه damageable)
func take_damage(amount: int, from: Vector3) -> void:
	if not _alive:
		return
	if _shielded:
		Sfx.play("gate_bad", -8.0, 1.4)  # پلینگ سپر
		return
	hp -= amount
	hp_changed.emit(hp, MAX_HP)
	Sfx.play("hurt", -3.0)
	_flash()
	if hp <= 0:
		_win()


func _flash() -> void:
	var mat: StandardMaterial3D = _body_mesh.material_override
	mat.emission_enabled = true
	mat.emission = Color(1, 0.3, 0.2)
	mat.emission_energy_multiplier = 1.6
	var tw := create_tween()
	tw.tween_property(mat, "emission_energy_multiplier", 0.0, 0.3)


func _phase_topic() -> String:
	return "%s.phase%d" % [name_key, _phase]


func _win() -> void:
	_alive = false
	_clear_panels()
	hp_changed.emit(0, MAX_HP)
	Sfx.play("victory", -2.0)
	Telemetry.track("boss_defeated", _phase_topic(), {"dim": 3, "boss": name_key})
	if _player:
		_player.collect_lum(40)
	Fx.burst(get_parent(), global_position + Vector3(0, 2.5, 0), "ffd166", 48)
	Fx.cam_shake(get_tree(), 0.6)
	boss_defeated.emit()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position:y", position.y - 3.0, 1.6)
	tw.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 1.6)
	tw.chain().tween_callback(queue_free)
