extends Node
## SaveData (autoload) — پیشرفت محلی بازیکن در user://bazino_save.json

signal tool_added(tool_id: String)
signal lum_changed(amount: int)

const SAVE_PATH := "user://bazino_save.json"

var data := {
	"lang": "tr",
	"grade": 8,
	"lum": 0,
	"hp_max": 5,
	"tools": [],
	"regions_cleared": {},
	"venue_mode": false,
	"venue_name": "",
	"buff": {"energy_boost": 0, "extra_life": 0, "honor_skin": 0}
}


func _ready() -> void:
	load_from_disk()
	TranslationServer.set_locale(data.lang)


func add_tool(tool_id: String) -> void:
	if not data.tools.has(tool_id):
		data.tools.append(tool_id)
		tool_added.emit(tool_id)
		save_now()


func has_tool_for(topic_id: String) -> bool:
	var f := FileAccess.open("res://data/formulas.json", FileAccess.READ)
	if not f:
		return false
	var tools: Array = JSON.parse_string(f.get_as_text()).get("tools", [])
	for t in tools:
		if t.topic_id == topic_id and data.tools.has(t.id):
			return true
	return false


func add_lum(n: int) -> void:
	data.lum = int(data.lum) + n
	lum_changed.emit(data.lum)


func set_region_cleared(region: String, season: int) -> void:
	data.regions_cleared["%s_s%d" % [region, season]] = true
	save_now()


func is_region_cleared(region: String, season: int) -> bool:
	return data.regions_cleared.get("%s_s%d" % [region, season], false)


func apply_buff(buff: String, amount: int) -> void:
	data.buff[buff] = int(data.buff.get(buff, 0)) + amount
	save_now()


func save_now() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var saved = JSON.parse_string(f.get_as_text())
	if saved is Dictionary:
		for k in saved.keys():
			data[k] = saved[k]
