## ModelBank — موتور اتصال خودکار پک‌های Quaternius (CC0) داخل assets/external.
## با هر نامپوشه‌ای سازگار است: بازگشتی همهٔ فایل‌های glb/gltf/fbx را اسکن می‌کند و
## بر اساس کلیدواژه مدل مناسب پیدا می‌کند. اگر پکی نبود، بی‌صدا رد می‌شود (fallback کد).
class_name ModelBank
extends RefCounted

static var _files: PackedStringArray = []
static var _scanned := false
static var _role_cache: Dictionary = {}   # role -> مسیر مدل


## نقش → فهرست کلیدواژه‌های نام فایل، به‌ترتیب اولویت (پین‌شده با پک‌های واقعی کاربر)
const ROLES := {
	"player": ["knight_male", "knight", "adventurer", "rogue", "barbarian", "paladin",
		"mage", "hero", "ninja_male"],
	"wisp": ["ghost", "hywirl", "spirit", "bat", "skull", "wisp", "imp", "eye"],
	"golem": ["goleling_evolved", "goleling", "yeti", "golem", "ogre", "troll", "cyclops"],
	"spitter": ["mushroomking", "squidle", "glub", "cactoro", "slime", "mushroom",
		"tentacle", "spider", "plant"],
	"boss": ["dragon_evolved", "dragon", "demon", "kraken", "gorilla", "boss"],
	"tree": ["birchtree_1", "birchtree", "tree", "palm", "pine", "trunk"],
	"rock": ["rock_1", "rock", "stone", "boulder", "cliff"],
	"bush": ["bush_flowers", "bush", "grass", "flower", "crystal", "gem", "shroom"],
}


static func _scan() -> void:
	if _scanned:
		return
	_scanned = true
	_walk("res://assets/external/")


static func _walk(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if d.current_is_dir():
			if not name.begins_with("."):
				_walk(dir_path.path_join(name))
		else:
			var low := name.to_lower()
			for ext in [".glb", ".gltf", ".fbx", ".obj", ".blend", ".scn", ".tscn"]:
				if low.ends_with(ext):
					_files.append(dir_path.path_join(name))
					break
		name = d.get_next()


## آیا می‌خواهیم پکی از این نقش موجود است؟
static func has(role: String) -> bool:
	return role_path(role) != ""


static func role_path(role: String) -> String:
	_scan()
	if _role_cache.has(role):
		return str(_role_cache[role])
	# اولویت ۱: فرمت (glb/gltf بهترین ایمپورت در Godot) — سپس کلیدواژه — سپس فایل
	var kws: Array = ROLES.get(role, [])
	var buckets: Array[Array] = [[], [], []]
	for f in _files:
		var low := f.to_lower()
		if low.ends_with(".glb") or low.ends_with(".gltf"):
			buckets[0].append(f)
		elif low.ends_with(".fbx"):
			buckets[1].append(f)
		else:
			buckets[2].append(f)
	var best := ""
	for bucket in buckets:
		for kw in kws:
			for f in bucket:
				if f.get_file().to_lower().contains(str(kw).to_lower()):
					best = f
					break
			if best != "":
				break
		if best != "":
			break
	_role_cache[role] = best
	return best


## نمونهٔ ساخته‌شده از مدل نقش (بدون انیمیشن) — برای آبجکت‌های ایستا
static func instantiate_static(role: String) -> Node3D:
	var path := role_path(role)
	if path == "":
		return null
	var res = load(path)
	if res == null:
		_role_cache[role] = ""
		return null
	var inst: Node = null
	if res is PackedScene:
		inst = (res as PackedScene).instantiate()
	elif res is Mesh:
		inst = MeshInstance3D.new()
		(inst as MeshInstance3D).mesh = res
	if inst is Node3D:
		return inst
	return null


## نمونه + جستجوی AnimationPlayer (برای بازیکن/دشمنان/باس)
## خروجی: [model: Node3D, anims: AnimationPlayer؟]
static func instantiate_animated(role: String) -> Array:
	var model := instantiate_static(role)
	if model == null:
		return [null, null]
	var anims := _find_anim_player(model)
	return [model, anims]


static func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var got := _find_anim_player(c)
		if got:
			return got
	return null


## اندازه‌گیر real-world: مدل را به ارتفاع هدف نرمال می‌کند (Quaternius ~ 0.5–4 واحد متفاوت)
static func normalize_height(node: Node3D, target_h: float) -> void:
	var aabb := _model_aabb(node)
	if aabb.size.y <= 0.001:
		return
	var s := target_h / aabb.size.y
	node.scale = Vector3.ONE * s


static func _model_aabb(node: Node) -> AABB:
	var out := AABB()
	out.size = Vector3.ZERO
	_merge_aabb(node, out, true)
	return out


static func _merge_aabb(node: Node, acc: AABB, first: bool) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var a := mi.get_aabb()
		# تقریبی به فضای ریشه — برای نرمال‌سازی مقیاس کافی است
		var p0 := acc.position
		var p1 := acc.position + acc.size
		var q0 := a.position
		var q1 := a.position + a.size
		if first or acc.size == Vector3.ZERO:
			acc.position = a.position
			acc.size = a.size
		else:
			var mn := Vector3(minf(p0.x, q0.x), minf(p0.y, q0.y), minf(p0.z, q0.z))
			var mx := Vector3(maxf(p1.x, q1.x), maxf(p1.y, q1.y), maxf(p1.z, q1.z))
			acc.position = mn
			acc.size = mx - mn
	if node is Node3D:
		for c in (node as Node).get_children():
			_merge_aabb(c, acc, false)


## پنهان‌کردن همهٔ MeshInstance3D فرزندان (برای تعویض placeholder با مدل واقعی)
static func hide_child_meshes(root: Node) -> void:
	for c in root.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visible = false
		hide_child_meshes(c)


## پخش خودکار اولین انیمیشن حرکتی (walk/run/idle یا هر انیمیشن موجود)
static func autoplay_movement(anims: AnimationPlayer) -> void:
	if anims == null:
		return
	for key in ["walk", "run", "idle", "fly", "hover"]:
		var a := pick_anim(anims, key)
		if a != "":
			anims.play(a)
			return
	var all := anims.get_animation_list()
	if all.size() > 0:
		anims.play(str(all[0]))


## انتخاب نام انیمیشن مناسب از فهرست نام‌ها (case-insensitive، substring)
static func pick_anim(anims: AnimationPlayer, want: String) -> String:
	if anims == null:
		return ""
	var w := want.to_lower()
	for lib_name in anims.get_animation_library_list():
		var lib := anims.get_animation_library(lib_name)
		for a in lib.get_animation_list():
			if str(a).to_lower().contains(w):
				return (lib_name + "/" if lib_name != "" else "") + str(a)
	for an in anims.get_animation_list():
		if str(an).to_lower().contains(w):
			return str(an)
	return ""
