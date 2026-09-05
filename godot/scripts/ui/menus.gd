class_name Menus
extends Control
## منوی خوش‌آمد: زبان (TR/EN/FA) ← پایه ۶–۱۲ ← ورود/مهمان ← منطقه/مرحله + کد سالن
## + مرحلهٔ هفتگی (Venue) + فینال فصل (Tournament) + کو-اوپ LAN.

signal start_stage(region: String, index_no: int)

var region := "math"
var weekly := 0            # 0 = نه هفتگی؛ 1..4 = W1..W4
var coop := false
var coop_ip := ""
var coop_host := false
var season := 1

var _grade: OptionButton
var _email: LineEdit
var _pass: LineEdit
var _status: Label
var _venue_code: LineEdit
var _stage_pick: OptionButton
var _region_lbl: Label


static func create() -> Menus:
	var m := Menus.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	return m


func _ready() -> void:
	Sfx.play_music("ambient")
	_build()


func _build() -> void:
	# صف نمایهٔ عنوان نقاشانه
	var tpath := "res://assets/bg/title.png"
	var tex: Texture2D = load(tpath)
	if tex:
		var bg := TextureRect.new()
		bg.texture = tex
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.modulate = Color(0.85, 0.87, 1.0)
		add_child(bg)
		var veil := ColorRect.new()
		veil.color = Color(0.02, 0.03, 0.07, 0.5)
		veil.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(veil)
		move_child(bg, 0)
		move_child(veil, 1)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.custom_minimum_size = Vector2(520, 0)
	col.position = Vector2(380, 40)
	col.add_theme_constant_override("separation", 8)
	add_child(col)

	col.add_child(_title("★  BAZİNO  ★", 56, Color("7ecaff")))

	var langs := HBoxContainer.new()
	langs.alignment = BoxContainer.ALIGNMENT_CENTER
	for cfg in [["tr", "Türkçe"], ["en", "English"], ["fa", "فارسی"]]:
		var b := Button.new()
		b.text = cfg[1]
		b.pressed.connect(_on_lang.bind(cfg[0]))
		langs.add_child(b)
	col.add_child(langs)

	_grade = OptionButton.new()
	for g in range(6, 13):
		_grade.add_item(str(g) + ". Sınıf", g)
		_grade.set_item_disabled(_grade.item_count - 1, g > 8)
	_grade.selected = 2
	col.add_child(_grade)

	col.add_child(_sep(tr("ui_login") + " / " + tr("ui_offline")))
	_email = LineEdit.new()
	_email.placeholder_text = "e-posta"
	col.add_child(_email)
	_pass = LineEdit.new()
	_pass.placeholder_text = "şifre"
	_pass.secret = true
	col.add_child(_pass)
	var auth := HBoxContainer.new()
	var lb := Button.new()
	lb.text = tr("ui_login")
	lb.pressed.connect(_on_login)
	auth.add_child(lb)
	var gb := Button.new()
	gb.text = tr("ui_offline")
	gb.pressed.connect(_on_guest)
	auth.add_child(gb)
	col.add_child(auth)

	col.add_child(_sep("⚑ " + tr("venue_code_hint")))
	var venue_row := HBoxContainer.new()
	_venue_code = LineEdit.new()
	_venue_code.max_length = 6
	venue_row.add_child(_venue_code)
	var vb := Button.new()
	vb.text = "⚑"
	vb.pressed.connect(_on_venue)
	venue_row.add_child(vb)
	col.add_child(venue_row)

	col.add_child(_sep("🗺️ Bölge"))
	_region_lbl = _title("Matematik Vadisi", 22, Color("8df7c9"))
	col.add_child(_region_lbl)
	var regs := HBoxContainer.new()
	for cfg in [["math", "🧮"], ["physics", "⚡"], ["english", "🗣️"],
			["biology", "🌿"]]:
		var b := Button.new()
		b.text = cfg[1]
		b.pressed.connect(_on_region.bind(cfg[0]))
		regs.add_child(b)
	col.add_child(regs)
	var regs2 := HBoxContainer.new()
	for cfg in [["chemistry", "⚗️"], ["ict", "💻"], ["logic", "🧩"]]:
		var b := Button.new()
		b.text = cfg[1]
		b.pressed.connect(_on_region.bind(cfg[0]))
		regs2.add_child(b)
	var s2 := Button.new()
	s2.text = "① Güz"
	s2.toggle_mode = true
	s2.pressed.connect(func():
		season = 2 if season == 1 else 1
		s2.text = ("② Bahar" if season == 2 else "① Güz")
		_status.text = tr("season_1") if season == 1 else tr("season_2_teaser"))
	regs2.add_child(s2)
	col.add_child(regs2)

	_stage_pick = OptionButton.new()
	for i in [1, 2, 3]:
		_stage_pick.add_item(tr("stage_free") + " 1" if i == 1 else "Etap %d" % i, i)
	col.add_child(_stage_pick)
	var sb := Button.new()
	sb.text = "▶  " + tr("ui_play")
	sb.pressed.connect(_on_start)
	col.add_child(sb)
	var wb := Button.new()
	wb.text = tr("weekly_btn")
	wb.pressed.connect(_on_weekly)
	col.add_child(wb)
	var tb := Button.new()
	tb.text = tr("tour_btn")
	tb.pressed.connect(_on_tournament)
	col.add_child(tb)

	col.add_child(_sep(tr("coop_host")))
	var coop_row := HBoxContainer.new()
	var ip := LineEdit.new()
	ip.placeholder_text = "192.168…"
	ip.text_changed.connect(func(t): coop_ip = t)
	coop_row.add_child(ip)
	var hb := Button.new()
	hb.text = "Host"
	hb.pressed.connect(func():
		coop = true
		coop_host = true
		_status.text = tr("coop_ok"))
	coop_row.add_child(hb)
	var jb := Button.new()
	jb.text = tr("coop_join")
	jb.pressed.connect(func():
		coop = true
		coop_host = false
		_status.text = tr("coop_join") + "…")
	coop_row.add_child(jb)
	col.add_child(coop_row)

	_status = _title("", 18, Color(1, 1, 1, 0.8))
	col.add_child(_status)
	Api.login_finished.connect(_on_login_result)
	Api.venue_finished.connect(_on_venue_result)


func _on_lang(code: String) -> void:
	Sfx.play("click", -6.0)
	SaveData.data.lang = code
	SaveData.save_now()
	TranslationServer.set_locale(code)


func _on_region(r: String) -> void:
	Sfx.play("click", -6.0)
	region = r
	weekly = 0
	_region_lbl.text = tr("region_" + r)


func _on_start() -> void:
	Sfx.play("click", -6.0)
	SaveData.data.grade = _grade.get_selected_id()
	SaveData.save_now()
	start_stage.emit(region, maxi(1, _stage_pick.get_selected_id()))


func _on_weekly() -> void:
	Sfx.play("click", -6.0)
	if not SaveData.data.venue_mode:
		_status.text = tr("venue_locked")
		return
	weekly = SaveData.data.get("week_index", 1)
	start_stage.emit("weekly", int(weekly))


func _on_tournament() -> void:
	Sfx.play("click", -6.0)
	var cleared := SaveData.is_region_cleared("math", 1) \
		and SaveData.is_region_cleared("physics", 1) \
		and SaveData.is_region_cleared("english", 1)
	if not (SaveData.data.venue_mode and cleared):
		_status.text = tr("tour_locked")
		return
	start_stage.emit("tournament", 1)


func _on_login() -> void:
	Sfx.play("click", -6.0)
	_status.text = "…"
	Api.login(_email.text, _pass.text)


func _on_login_result(ok: bool, _d: Dictionary) -> void:
	_status.text = "✓" if ok else "✗"


func _on_guest() -> void:
	Sfx.play("click", -6.0)
	_status.text = tr("ui_offline") + " ✓"


func _on_venue() -> void:
	Sfx.play("click", -6.0)
	Api.join_venue(_venue_code.text.strip_edges())


func _on_venue_result(ok: bool, data: Dictionary) -> void:
	if ok:
		SaveData.data.venue_mode = true
		SaveData.data.venue_name = data.get("venue", "GamNet")
		SaveData.save_now()
		_status.text = "⚑ " + SaveData.data.venue_name
	else:
		_status.text = tr("venue_locked")


func _title(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _sep(text: String) -> Label:
	return _title("── " + text + " ──", 16, Color(1, 1, 1, 0.45))
