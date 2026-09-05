## RuneGate 3D — دروازهٔ رون: نسخهٔ سه‌بعدی مکانیک امضای بازینو.
## همان قانون: با «ایستادن روی سکوی جواب درست» باز می‌شود — بدون پنجرهٔ سؤال.
class_name RuneGate
extends Node3D

signal solved

const WALL_W := 7.0
const WALL_H := 6.0
const PAD_RADIUS := 1.05
const PAD_SPREAD := 5.2
const SHUFFLE_PENALTY_LUM := 2

var config: Dictionary = {}
var _panels: Array[Area3D] = []
var _resolved := false
var _retries := 0
var _wall: StaticBody3D
var _riddle: Label3D


static func create(cfg: Dictionary) -> RuneGate:
	var g := RuneGate.new()
	g.config = cfg
	return g


func _ready() -> void:
	_build_wall()
	_build_riddle()
	_build_pads()


func _build_wall() -> void:
	_wall = StaticBody3D.new()
	_wall.collision_layer = 1
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(WALL_W, WALL_H, 0.5)
	col.shape = box
	col.position = Vector3(0, WALL_H * 0.5, 0)
	_wall.add_child(col)
	add_child(_wall)
	var stone := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(WALL_W, WALL_H, 0.5)
	stone.mesh = m
	stone.position = Vector3(0, WALL_H * 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("1c2542")
	mat.roughness = 0.9
	stone.material_override = mat
	add_child(stone)
	# ستون‌ها
	for side in [-1, 1]:
		var p := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.5
		cyl.bottom_radius = 0.6
		cyl.height = WALL_H + 1.2
		p.mesh = cyl
		p.position = Vector3(side * (WALL_W * 0.5 + 0.5), (WALL_H + 1.2) * 0.5 - 0.6, 0)
		add_child(p)


func _build_riddle() -> void:
	_riddle = Label3D.new()
	_riddle.text = str(config.get("challenge", "= ?"))
	_riddle.font_size = 120
	_riddle.modulate = Color("8df7c9")
	_riddle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_riddle.position = Vector3(0, WALL_H + 1.2, 0.3)
	add_child(_riddle)
	var hint := Label3D.new()
	hint.text = tr("gate_hint")
	hint.font_size = 60
	hint.modulate = Color(1, 1, 1, 0.55)
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.position = Vector3(0, WALL_H + 0.4, 0.3)
	add_child(hint)


func _build_pads() -> void:
	var defs: Array = config.get("panels", [])
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
		# صفحهٔ درخشان
		var stone := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = PAD_RADIUS
		disc.bottom_radius = PAD_RADIUS * 1.08
		disc.height = 0.3
		stone.mesh = disc
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("28304f")
		mat.emission_enabled = true
		mat.emission = Color("29304f")
		mat.emission_energy_multiplier = 0.5
		stone.material_override = mat
		pad.add_child(stone)
		# عدد رون
		var num := Label3D.new()
		num.text = str(defs[i].get("v", "?"))
		num.font_size = 110
		num.modulate = Color("8df7c9")
		num.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		num.position = Vector3(0, 1.0, 0)
		pad.add_child(num)
		pad.set_meta("ok", defs[i].get("ok", false))
		# قرارگیری: نیم‌دایره پشت دیوار سمت بازیکن
		var span := (n - 1) * PAD_SPREAD
		pad.position = Vector3(-span * 0.5 + i * PAD_SPREAD, 0.0, 3.4)
		add_child(pad)
		_panels.append(pad)
		pad.body_entered.connect(_on_stand.bind(pad))


func _on_stand(body: Node3D, pad: Area3D) -> void:
	if _resolved:
		return
	if not (body is Player3D):
		return
	# کمی صبر برای جلوگیری از عبور اتفاقی روی سکو
	await get_tree().create_timer(0.5).timeout
	if _resolved or not pad.overlaps_body(body):
		return
	if pad.get_meta("ok", false):
		solved.emit()
		Sfx.play("gate_ok", -2.0)
		Telemetry.track("obstacle_solved", config.get("topic_id", ""),
			{"time_ms": 0, "retries": _retries, "tool_correct": true, "dim": 3})
		_open(body)
	else:
		Sfx.play("gate_bad", -4.0)
		_retries += 1
		body.knockback_simple(3.0)
		Telemetry.track("obstacle_attempt", config.get("topic_id", ""),
			{"dim": 3, "solved": false, "retries": _retries})
		_shuffle()


func _shuffle() -> void:
	# ترتیب سکوها را می‌خورد (گیم‌پلی ترساندن بهانه افزایش خطای نمایش می‌دهد نه به نظرش)
	var xs: Array = []
	for p in _panels:
		xs.append(p.position.x)
	xs.shuffle()
	for i in _panels.size():
		var tw := create_tween()
		tw.tween_property(_panels[i], "position:x", xs[i], 0.35)


func _open(player: Player3D) -> void:
	_resolved = true
	_wall.set_deferred("collision_layer", 0)
	_wall.set_deferred("collision_mask", 0)
	var tw := create_tween()
	tw.tween_property(self, "position:y", -WALL_H - 2.0, 0.9)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _wall.visible = false)
	player.collect_lum(10)
