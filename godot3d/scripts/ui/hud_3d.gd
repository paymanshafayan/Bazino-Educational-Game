## Hud3D — قلب‌ها، لوم، کمبو، بنر مرکزی، نوار باس، وینیت آسیب، منوی مکث+زبان زنده.
class_name Hud3D
extends CanvasLayer

var _player: Player3D
var _hearts: Label
var _lum: Label
var _combo: Label
var _combo_t := 0.0
var _banner: Label
var _boss_bar: ProgressBar
var _boss_name: Label
var _vignette: ColorRect
var _pause: Control
var _lang: OptionButton


func setup(player: Player3D) -> Hud3D:
	_player = player
	process_mode = Node.PROCESS_MODE_ALWAYS
	# قلب‌ها
	_hearts = Label.new()
	_hearts.add_theme_font_size_override("font_size", 30)
	_hearts.add_theme_color_override("font_color", Color("ff5d5d"))
	_hearts.position = Vector2(26, 18)
	add_child(_hearts)
	_update_hearts()
	player.hp_changed.connect(func(_h, _m):
		_update_hearts()
		_pulse_vignette())
	# لوم
	_lum = Label.new()
	_lum.add_theme_font_size_override("font_size", 24)
	_lum.add_theme_color_override("font_color", Color("ffd166"))
	_lum.position = Vector2(26, 60)
	add_child(_lum)
	SaveData.lum_changed.connect(func(n): _lum.text = "✦ %d" % n)
	_lum.text = "✦ %d" % int(SaveData.data.lum)
	# کمبو (بالا راست)
	_combo = Label.new()
	_combo.add_theme_font_size_override("font_size", 26)
	_combo.add_theme_color_override("font_color", Color("8df7c9"))
	_combo.position = Vector2(1080, 22)
	_combo.visible = false
	add_child(_combo)
	player.combo_display.connect(_on_combo)
	# بنر مرکزی
	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 44)
	_banner.add_theme_color_override("font_color", Color("7ecaff"))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.position = Vector2(0, 140)
	_banner.size = Vector2(1280, 60)
	_banner.modulate.a = 0.0
	add_child(_banner)
	# نوار باس (پنهان)
	_boss_bar = ProgressBar.new()
	_boss_bar.position = Vector2(330, 26)
	_boss_bar.size = Vector2(620, 22)
	_boss_bar.min_value = 0
	_boss_bar.max_value = 1
	_boss_bar.value = 1
	_boss_bar.visible = false
	add_child(_boss_bar)
	_boss_name = Label.new()
	_boss_name.add_theme_font_size_override("font_size", 20)
	_boss_name.position = Vector2(330, 2)
	_boss_name.size = Vector2(620, 22)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.visible = false
	add_child(_boss_name)
	# وینیت قرمز آسیب
	_vignette = ColorRect.new()
	_vignette.color = Color(1.0, 0.12, 0.18, 0.28)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.modulate.a = 0.0
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)
	_build_pause()
	return self


func _input(_ev: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and _player != null:
		_toggle_pause()


func _build_pause() -> void:
	_pause = PanelContainer.new()
	_pause.visible = false
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.07, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	dim.visible = false
	_pause.set_meta("dim", dim)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(300, 0)
	_pause.add_child(box)
	var title := Label.new()
	title.text = "⏸ " + tr("ui_pause")
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("7ecaff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var resume := Button.new()
	resume.text = "▶ " + tr("ui_resume")
	resume.pressed.connect(_toggle_pause)
	box.add_child(resume)
	var lang := OptionButton.new()
	lang.add_item("🇹🇷 Türkçe")
	lang.add_item("🇬🇧 English")
	lang.add_item("🇮🇷 فارسی")
	var cur := {"tr": 0, "en": 1, "fa": 2}.get(str(SaveData.data.lang), 0)
	lang.select(cur)
	lang.item_selected.connect(func(i):
		var code := ["tr", "en", "fa"][i]
		SaveData.data.lang = code
		TranslationServer.set_locale(code)
		SaveData.save_now()
		Sfx.play("click", -5.0)
		get_tree().reload_current_scene())
	box.add_child(lang)
	var restart := Button.new()
	restart.text = "↻ " + tr("ui_restart")
	restart.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	box.add_child(restart)
	add_child(_pause)
	_lang = lang


func _toggle_pause() -> void:
	var now := not _pause.visible
	get_tree().paused = now
	_pause.visible = now
	(_pause.get_meta("dim") as ColorRect).visible = now
	Sfx.play("click", -5.0)


func _on_combo(n: int) -> void:
	_combo_t = 2.0
	if n >= 2:
		_combo.text = "⚔ %s ×%d" % [tr("combo_hit"), n]
		_combo.visible = true
		var tw := create_tween()
		_combo.scale = Vector2(1.35, 1.35)
		tw.tween_property(_combo, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	if _combo.visible:
		_combo_t -= delta
		if _combo_t <= 0.0:
			_combo.visible = false


func show_banner(text: String, hold := 2.2) -> void:
	_banner.text = text
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.25)
	tw.tween_interval(hold)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4)


func set_boss(name: String, frac: float) -> void:
	_boss_name.text = name
	_boss_bar.value = clampf(frac, 0.0, 1.0)
	_boss_bar.visible = frac > 0.0
	_boss_name.visible = frac > 0.0


func _pulse_vignette() -> void:
	_vignette.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_vignette, "modulate:a", 0.0, 0.5)


func _update_hearts() -> void:
	var full := ""
	for i in _player.hp:
		full += "♥"
	var empty := ""
	for j in (_player.hp_max - _player.hp):
		empty += "♡"
	_hearts.text = full + empty
