class_name Hud
extends CanvasLayer
## HUD — قلب‌ها، لوم، تراشه‌های توان، نوار باس، بنر پیروزی، نشان سالن (Venue).

var _hearts: Label
var _lum: Label
var _tools: HBoxContainer
var _toast_lbl: Label
var _boss_bar: ProgressBar
var _boss_name: Label
var _banner: Label


static func create() -> Hud:
	var h := Hud.new()
	return h


func _ready() -> void:
	layer = 10
	_build()
	SaveData.lum_changed.connect(_on_lum)
	SaveData.tool_added.connect(_on_tool)
	_on_lum(SaveData.data.lum)
	for t in SaveData.data.tools:
		_add_chip(t)
	if SaveData.data.venue_mode:
		_venue_badge()


func _build() -> void:
	_hearts = _mk(Vector2(30, 22), 40, Color("ff5c7a"))
	add_child(_hearts)
	_lum = _mk(Vector2(30, 74), 30, Color("ffd166"))
	add_child(_lum)
	_tools = HBoxContainer.new()
	_tools.position = Vector2(30, 118)
	_tools.add_theme_constant_override("separation", 8)
	add_child(_tools)
	_toast_lbl = _mk(Vector2(340, 150), 32, Color("7ecaff"))
	_toast_lbl.modulate.a = 0.0
	add_child(_toast_lbl)
	_boss_bar = ProgressBar.new()
	_boss_bar.position = Vector2(340, 24)
	_boss_bar.custom_minimum_size = Vector2(600, 26)
	_boss_bar.max_value = 1
	_boss_bar.visible = false
	add_child(_boss_bar)
	_boss_name = _mk(Vector2(340, 0), 24, Color("8df7c9"))
	_boss_name.visible = false
	add_child(_boss_name)
	_banner = _mk(Vector2(340, 300), 56, Color("9dff70"))
	_banner.visible = false
	add_child(_banner)


func attach_player(p: Player) -> void:
	p.hp_changed.connect(_on_hp)
	_on_hp(p.hp, p.hp_max)


func _on_hp(hp: int, _m: int) -> void:
	_hearts.text = ""
	for i in hp:
		_hearts.text += "♥ "
	_hearts.text += "♡ ".repeat(maxi(0, _m - hp))


func _on_lum(n: int) -> void:
	_lum.text = "◆ %s  %d" % [tr("hud_lum"), n]


func _on_tool(tool_id: String) -> void:
	_add_chip(tool_id)


func _attach_tool(_t) -> void:
	pass


func _add_chip(tool_id: String) -> void:
	var c := Label.new()
	c.text = " ✦ "
	c.add_theme_font_size_override("font_size", 26)
	c.add_theme_color_override("font_color", Color("ffb347"))
	c.tooltip_text = tr("tool_" + tool_id)
	_tools.add_child(c)


func toast(text: String) -> void:
	_toast_lbl.text = text
	_toast_lbl.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(_toast_lbl, "modulate:a", 0.0, 0.5)


func attach_boss(boss) -> void:
	_boss_name.text = tr(boss.boss_name_key if "boss_name_key" in boss else "boss_eski")
	_boss_name.visible = true
	_boss_bar.visible = true
	_boss_bar.max_value = boss.MAX_HP
	_boss_bar.value = boss.hp
	boss.hp_changed.connect(func(h, _m): _boss_bar.value = h)
	boss.boss_defeated.connect(func():
		_boss_bar.visible = false
		_boss_name.visible = false)


func victory(text: String) -> void:
	_banner.text = "★ " + text + " ★"
	_banner.visible = true
	_banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.4)


func _venue_badge() -> void:
	var b := _mk(Vector2(980, 22), 22, Color("9dff70"))
	b.text = "⚑ " + SaveData.data.venue_name
	add_child(b)


func _mk(pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.position = pos
	l.custom_minimum_size = Vector2(600, 60)
	return l
