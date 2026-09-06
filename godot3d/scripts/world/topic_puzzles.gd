## TopicPuzzles — موتور تولید پازلِ سمت کلاینت.
## اتاق‌های تطبیقی سرور فقط topic_id دارند؛ این‌جا از روی موضوع معما/صفحه می‌سازیم
## (همان نقشی که در 2D فایل‌های stages_*.json از قبل پر شده‌بودند — این‌جا زنده تولید می‌شود).
class_name TopicPuzzles
extends RefCounted


## نقشهٔ ثابت: topic_id → [پرسش، [جواب‌ها..ok..]] — محتوای پایه ۸ Güz
static func _fixed() -> Dictionary:
	return {
		"math.g7.guz.cebir-giris":
			["2x + 6 = 14 → x = ?", 4, [10, -4, 8]],
		"math.g8.guz.karekoklu":
			["√81 = ?", 9, [8, 18, 40.5]],
		"math.g8.guz.carpanlar":
			["EBOB(12, 18) = ?", 6, [3, 36, 2]],
		"math.g8.guz.uslu-sayilar":
			["2⁵ / 2³ = ?", 4, [2, 8, 6]],
		"math.g8.guz.ozdeslik":
			["(a+3)² = a² + ka + 9 → k = ?", 6, [3, 9, 16]],
		"math.g7.guz.tamsayilar":
			["(−3) × (+4) − (−2) = ?", -10, [10, -14, 14]],
		"physics.g8.guz.basit-makinalar":
			["اهرم: ۶ نیوتن در ۲m ↔ ۳ نیوتن در ___ m", 4, [1, 3, 6]],
		"physics.g8.guz.basinc":
			["F = 20 N، A = 5 m² → P = ? Pa", 4, [100, 25, 0.25]],
		"biology.g8.guz.hucresel-bolunme":
			["Mitoz: 46 kromozomlu hücreden kaç yavru hücre?", 2, [4, 1, 3]],
		"chemistry.g8.guz.periyodik-tablo":
			["Soy gazlar periyodik tabloda kaçıncı grup?", 18, [1, 17, 8]],
	}


static func _det_seed(text: String) -> int:
	var h := 5381
	for i in text.length():
		h = (h * 33 + text.unicode_at(i)) & 0x7fffffff
	return h


## ساخت پیکربندی کامل دروازه برای RuneGate از روی موضوع
static func make_gate(topic_id: String, ref_time_ms: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = _det_seed(topic_id)
	if _fixed().has(topic_id):
		var f: Array = _fixed()[topic_id]
		var panels := [{"v": str(f[1]), "ok": true}]
		for w in f[2]:
			panels.append({"v": str(w), "ok": false})
		return {"topic_id": topic_id, "challenge": f[0], "panels": panels,
			"time_limit": _time_from_ref(ref_time_ms)}
	# مولد عمومی بر اساس بخش کشویی موضوع (ریاضی/فیزیک/سایر)
	var kind := topic_id.get_slice(".", 0)
	if kind == "physics":
		var m := rng.randi_range(2, 9)
		return {"topic_id": topic_id, "challenge": "v = s/t → s=%d، t=2 → v = ?" % (2 * m),
			"panels": _mk_panels(m, [m * 2, m + 2, m - 1]), "time_limit": _time_from_ref(ref_time_ms)}
	if topic_id.begins_with("math"):
		var a := rng.randi_range(3, 9)
		var b := rng.randi_range(3, 9)
		return {"topic_id": topic_id, "challenge": "%d × %d = ?" % [a, b],
			"panels": _mk_panels(a * b, [a * b + a, a * b - b, a * b + 1]),
			"time_limit": _time_from_ref(ref_time_ms)}
	if topic_id.begins_with("ict"):
		return {"topic_id": topic_id, "challenge": "1 KB = ? B",
			"panels": _mk_panels(1024, [1000, 512, 2048]), "time_limit": _time_from_ref(ref_time_ms)}
	# پیش‌فرض: جمع
	var c := rng.randi_range(12, 89)
	var d := rng.randi_range(12, 89)
	return {"topic_id": topic_id, "challenge": "%d + %d = ?" % [c, d],
		"panels": _mk_panels(c + d, [c + d + 10, c + d - 10, c + d + 1]),
		"time_limit": _time_from_ref(ref_time_ms)}


static func _mk_panels(ok_val, wrongs: Array) -> Array:
	var panels := [{"v": str(ok_val), "ok": true}]
	for w in wrongs:
		panels.append({"v": str(w), "ok": false})
	return panels


static func _time_from_ref(ref_time_ms: int) -> float:
	# سرور ref_time_ms می‌دهد؛ ما آن را زمان دروازه می‌کنیم (حداقل ۶s، x3 برای کودک)
	if ref_time_ms <= 0:
		return 0.0
	return clampf(ref_time_ms / 1000.0 * 3.0, 6.0, 45.0)


## formulas.json: topic → tool_id (برای اتاق گنجِ سمت سرور که tool_id ندارد)
static func tool_for(topic_id: String) -> String:
	var f := FileAccess.open("res://data/formulas.json", FileAccess.READ)
	if not f:
		return ""
	for t in (JSON.parse_string(f.get_as_text()) as Dictionary).get("tools", []):
		if str(t.get("topic_id", "")) == topic_id:
			return str(t.get("id", ""))
	return ""
