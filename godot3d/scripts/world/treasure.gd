## Treasure3D — گنج فرمول: کریستال بزرگ؛ با نزدیک‌شدن، «توان» به کوله می‌افتد + لوم.
class_name Treasure3D
extends Node3D

signal collected(tool_id: String)

var tool_id: String = ""
var topic_id: String = ""
var _taken := false
var _gem: MeshInstance3D


static func create(p_tool_id: String, p_topic_id: String = "") -> Treasure3D:
	var t := Treasure3D.new()
	t.tool_id = p_tool_id
	t.topic_id = p_topic_id
	return t


func _ready() -> void:
	var zone := Area3D.new()
	zone.collision_layer = 8
	zone.collision_mask = 2
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.2
	col.shape = sph
	col.position = Vector3(0, 1.0, 0)
	zone.add_child(col)
	add_child(zone)
	zone.body_entered.connect(_on_near)
	# کریستال دوپیرامید درخشان
	_gem = MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ffd166")
	mat.emission_enabled = true
	mat.emission = Color("ffb347")
	mat.emission_energy_multiplier = 2.2
	_gem.material_override = mat
	var top := PrismMesh.new()
	top.size = Vector3(0.9, 1.0, 0.9)
	var m_top := MeshInstance3D.new()
	m_top.mesh = top
	m_top.material_override = mat
	m_top.position = Vector3(0, 1.5, 0)
	add_child(m_top)
	_gem = m_top
	var m_bot := MeshInstance3D.new()
	m_bot.mesh = top
	m_bot.material_override = mat
	m_bot.rotation.x = PI
	m_bot.position = Vector3(0, 0.5, 0)
	add_child(m_bot)
	# نور
	var light := OmniLight3D.new()
	light.light_color = Color("ffd166")
	light.light_energy = 1.8
	light.omni_range = 6.0
	light.position = Vector3(0, 1.4, 0)
	add_child(light)
	# پرواز ملایم
	var tw := create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(m_top, "position:y", 1.9, 1.6)
	tw.tween_property(m_top, "position:y", 1.5, 1.6)
	m_top.rotation.y = 0.001
	var spin := create_tween().set_loops()
	spin.tween_property(m_top, "rotation:y", TAU, 4.0).as_relative()
	var spin2 := create_tween().set_loops()
	spin2.tween_property(m_bot, "rotation:y", -TAU, 4.0).as_relative()


func _on_near(body: Node3D) -> void:
	if _taken or not (body is Player3D):
		return
	_taken = true
	collected.emit(tool_id)
	Sfx.play("victory", -6.0)
	if tool_id != "":
		SaveData.add_tool(tool_id)
	(Telemetry.track("treasure_collected", topic_id, {"tool_id": tool_id, "dim": 3}))
	body.collect_lum(15)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", position.y + 6.0, 1.2)
	tw.tween_property(self, "scale", Vector3.ZERO, 1.2)
	tw.chain().tween_callback(queue_free)
