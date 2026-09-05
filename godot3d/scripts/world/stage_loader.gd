## StageLoader — خواندن دادهٔ مراحل مناطق از res://data/stages_{region}_s{n}.json
## (همان فایل‌های 2D؛ سرور/آنلاین در چپتر C می‌آید — فعلاً آفلاینِ قطعی)
class_name StageLoader
extends RefCounted


static func load_stages(region: String, season: int) -> Array:
	var path := "res://data/stages_%s_s%d.json" % [region, season]
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return []
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed.get("stages", [])
	return []


static func get_stage(region: String, season: int, index_no: int) -> Dictionary:
	for st in load_stages(region, season):
		if int(st.get("index_no", -1)) == index_no:
			return st
	return {}


static func regions() -> Array:
	return ["math", "physics", "biology", "chemistry", "english", "ict", "logic"]


static func region_title(region: String) -> String:
	return tr("region_%s" % region)
