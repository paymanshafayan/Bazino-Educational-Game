## RegionThemes — هویت بصری هر جزیره (رنگ لهجه/زمین/آسمان + ترکیب دشمنان).
## مقادیر از boss_cfg.color و حس درسی هر منطقه گرفته شده‌اند.
class_name RegionThemes
extends RefCounted


static func theme(region: String) -> Dictionary:
	return _themes().get(region, _themes()["math"])


static func _themes() -> Dictionary:
	return {
		"math":
		{"accent": "8df7c9", "ground": "16203a", "sky": "0b0e1a", "fog": 0.045,
			"wisp_colors": ["59d6ff", "8df7c9", "b78dff"], "crawl": false},
		"physics":
		{"accent": "7ecaff", "ground": "14213d", "sky": "071018", "fog": 0.038,
			"wisp_colors": ["7ecaff", "ffd166", "ffa94d"], "crawl": true},
		"biology":
		{"accent": "7ded8b", "ground": "14301f", "sky": "05140b", "fog": 0.05,
			"wisp_colors": ["7ded8b", "b5e048", "4dd0a5"], "crawl": true},
		"chemistry":
		{"accent": "c792ea", "ground": "241335", "sky": "12071d", "fog": 0.05,
			"wisp_colors": ["c792ea", "ff7edb", "89ddff"], "crawl": true},
		"english":
		{"accent": "ffb471", "ground": "2b1c12", "sky": "160c05", "fog": 0.04,
			"wisp_colors": ["ffb471", "ffe08a", "ff8fa3"], "crawl": false},
		"ict":
		{"accent": "00e5ff", "ground": "101a1f", "sky": "02090c", "fog": 0.042,
			"wisp_colors": ["00e5ff", "ff2e88", "b0ff57"], "crawl": true},
		"logic":
		{"accent": "ffd166", "ground": "201a0c", "sky": "0d0a03", "fog": 0.045,
			"wisp_colors": ["ffd166", "9dffb0", "ffa07a"], "crawl": true},
		"weekly":
		{"accent": "ff5d8f", "ground": "241020", "sky": "10040c", "fog": 0.05,
			"wisp_colors": ["ff5d8f", "ffd166", "7ecaff"], "crawl": true},
		"tournament":
		{"accent": "ffd700", "ground": "1c1206", "sky": "0a0601", "fog": 0.048,
			"wisp_colors": ["ffd700", "ff5d5d", "b78dff"], "crawl": true},
	}


## دشمن بر حسب theme اتاق نبرد (number_wisp/root_crawler) + عمق مرحله
static func enemy_kind(theme_key: String, stage_depth: int, slot: int) -> String:
	if theme_key == "root_crawler":
		if slot == 0 and stage_depth >= 2:
			return "spitter"
		return "golem" if slot % 2 == 1 else "wisp"
	# جزیره‌های هوایی: فقط wisp + یک تیرانداز در اعماق
	if slot == 0 and stage_depth >= 3:
		return "spitter"
	return "wisp"
