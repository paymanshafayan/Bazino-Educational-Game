## Fx — ابزار جوس مشترک: انفجار ذرات کوتاه، توقف ضربه (hitstop)، لرزش دوربین.
## همهٔ توابع استاتیک‌اند؛ بدون نیاز به autoload جدید.
class_name Fx
extends RefCounted


## انفجار یک‌بارمصرف ذرات رنگی در نقطه (برخورد ضربه/کشتن/حل دروازه/لمس لوم)
static func burst(parent: Node, at: Vector3, color: String = "8df7c9",
		count: int = 22, spread_up: bool = true) -> void:
	if not (parent is Node3D):
		return
	var p := GPUParticles3D.new()
	p.amount = count
	p.lifetime = 0.55
	p.one_shot = true
	p.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1 if spread_up else 0, 0)
	pm.spread = 75.0
	pm.initial_velocity_min = 3.5
	pm.initial_velocity_max = 8.5
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.05
	pm.scale_max = 0.14
	pm.color = Color(color)
	p.process_material = pm
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	p.draw_pass_1 = mesh
	parent.add_child(p)
	p.global_position = at
	# خودتخریبی بعد از پایان انفجار
	var t: SceneTree = parent.get_tree()
	if t == null:
		return
	t.create_timer(0.9).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free())


## توقف-ضربهٔ سینمایی کوتاه (روی ضربهٔ موفق/هرت باس) — میلی‌ثانیه
static func hitstop(tree: SceneTree, ms: int = 70) -> void:
	if tree == null:
		return
	tree.paused = false  # اگر منوی مکث باز بود خراب نشود
	Engine.time_scale = 0.05
	tree.create_timer(ms / 1000.0, true, false, true).timeout.connect(func():
		Engine.time_scale = 1.0)


## لرزش دوربین در هر نود درخت
static func cam_shake(tree: SceneTree, power: float = 0.35) -> void:
	if tree == null:
		return
	for c in tree.get_nodes_in_group("cam_rig"):
		if c.has_method("shake"):
			c.shake(power)


## لگد میدان دید (دش/دوی سریع)
static func cam_fov_kick(tree: SceneTree, amount: float = 10.0) -> void:
	if tree == null:
		return
	for c in tree.get_nodes_in_group("cam_rig"):
		if c.has_method("fov_kick"):
			c.fov_kick(amount)
