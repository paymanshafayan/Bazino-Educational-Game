## تهاجمات جزیرهٔ پایه: سطح، آب، سنگ/کریستال، چراغ مهتاب — همهٔ کد-محور.
## این چیدمان در هر جزیرهٔ بعد با پک‌های assets/external جایگزین/تزئین می‌شود.
class_name Island3D
extends Node3D

const RADIUS := 34.0

var env_sky_top := Color("0b0e1a")
var accent := Color("8df7c9")
var length := 400.0   # راهرو: از z=+20 تا z=-length
var width := 42.0


func build(accent_hex: String = "8df7c9", ground_hex: String = "16203a",
		p_length: float = 400.0, p_width: float = 42.0) -> void:
	accent = Color(accent_hex)
	length = p_length
	width = p_width
	_make_environment()
	_make_ground(ground_hex)
	_make_scatter()
	_make_beacon()


func _make_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = env_sky_top
	env.fog_enabled = true
	env.fog_density = 0.045
	env.glow_enabled = true
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.9, -0.6, 0.0)
	sun.light_color = Color("bcd7ff")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 10, 0)
	fill.light_color = accent
	fill.light_energy = 1.4
	fill.omni_range = RADIUS * 2
	add_child(fill)


func _make_ground(ground_hex: String) -> void:
	# بستر راهرو: تختهٔ بلند از z=+20 تا z=-length (placeholder پیش از پک‌های محیط)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	add_child(body)
	var mid_z := 20.0 - (length + 20.0) * 0.5
	var col := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(width, 2.0, length + 20.0)
	col.shape = slab
	col.position = Vector3(0, -1.0, mid_z)
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 2.2, length + 20.0)
	mesh.mesh = bm
	mesh.position = Vector3(0, -1.1, mid_z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(ground_hex)
	mat.roughness = 0.95
	mesh.material_override = mat
	add_child(mesh)
	# لبه‌های درخشان دو طرف راهرو
	for side in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.35, 0.18, length + 20.0)
		rail.mesh = rm
		rail.position = Vector3(side * (width * 0.5 - 0.4), 0.09, mid_z)
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = accent.darkened(0.4)
		rmat.emission_enabled = true
		rmat.emission = accent
		rmat.emission_energy_multiplier = 1.1
		rail.material_override = rmat
		add_child(rail)


func _make_scatter() -> void:
	# سنگ‌ها و کریستال‌های درخشان پراکنده (placeholder تا ورود پک‌های محیط)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var count := int(length / 14.0)
	for i in count:
		var rock := MeshInstance3D.new()
		var cone := ConeMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = rng.randf_range(0.35, 0.8)
		cone.height = rng.randf_range(0.8, 2.2)
		rock.mesh = cone
		var side := 1.0 if rng.randf() > 0.5 else -1.0
		var x := side * rng.randf_range(width * 0.5 + 1.5, width * 0.5 + 6.0)
		var z := rng.randf_range(18.0, -length)
		rock.position = Vector3(x, cone.height * 0.5 - 0.15, z)
		rock.rotation.y = rng.randf_range(0.0, TAU)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("2a3557")
		rock.material_override = mat
		add_child(rock)
	var cry_count := int(count * 0.4)
	for j in cry_count:
		var cry := MeshInstance3D.new()
		var cone2 := ConeMesh.new()
		cone2.bottom_radius = rng.randf_range(0.16, 0.3)
		cone2.height = rng.randf_range(1.0, 2.4)
		cry.mesh = cone2
		var side2 := 1.0 if rng.randf() > 0.5 else -1.0
		cry.position = Vector3(
			side2 * rng.randf_range(width * 0.5 + 1.0, width * 0.5 + 5.0),
			cone2.height * 0.5, rng.randf_range(18.0, -length))
		var mat2 := StandardMaterial3D.new()
		mat2.albedo_color = accent.darkened(0.3)
		mat2.emission_enabled = true
		mat2.emission = accent
		mat2.emission_energy_multiplier = 1.6
		cry.material_override = mat2
		add_child(cry)


func _make_beacon() -> void:
	# «ستارهٔ LUM» شناور روشن در مرکز آسمان جزیره
	var star := MeshInstance3D.new()
	var s := ConeMesh.new()
	s.top_radius = 0.0
	s.bottom_radius = 0.5
	s.height = 1.4
	star.mesh = s
	star.position = Vector3(0, 11, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ffd166")
	mat.emission_enabled = true
	mat.emission = Color("ffd166")
	mat.emission_energy_multiplier = 3.0
	star.material_override = mat
	star.name = "Beacon"
	add_child(star)
	var tw := create_tween().set_loops()
	tw.tween_property(star, "position:y", 11.9, 2.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(star, "position:y", 11.0, 2.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
