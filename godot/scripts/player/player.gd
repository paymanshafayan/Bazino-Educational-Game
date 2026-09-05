class_name Player
extends CharacterBody2D
## بازیکن — «Movement Feel First» (GDD §۳.۱): شتاب لذت‌بخش، کایوت/بافر، دَش i-frame، کامبوی نور.

signal hp_changed(hp: int, hp_max: int)
signal died
signal lum_picked(amount: int)
signal attack_landed

# ── پارامترهای حس حرکت (تون‌شده برای سبک HK) ─────────────
const RUN_SPEED := 240.0
const ACCEL := 1900.0
const FRICTION := 1700.0
const AIR_CONTROL := 0.82
const GRAVITY := 2150.0
const JUMP_VELOCITY := -560.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.12
const DASH_SPEED := 640.0
const DASH_TIME := 0.16
const DASH_IFRAMES := 0.28
const DASH_COOLDOWN := 0.45
const HURT_IFRAMES := 0.8
const MAX_FALL := 900.0
const ATTACK_TIME := 0.19
const ATTACK_CHAIN_GAP := 0.28
const ATTACK_DAMAGE := 2
const KNOCKBACK := Vector2(260, -140)

@export var is_boss_room := false

var hp: int
var hp_max: int
var facing := 1
var _coyote := 0.0
var _buffer := 0.0
var _dash_left := 0.0
var _dash_cd := 0.0
var _air := false
var _iframes := 0.0
var _attack_left := 0.0
var _combo := 0
var _chain_gap := 0.0
var _respawn := Vector2.ZERO
var frozen := false

@onready var visual: Node2D = $Visual
@onready var blade: Area2D = $Blade


static func create() -> Player:
	var p := Player.new()
	p.name = "Player"
	var body := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(22, 34)
	body.shape = shape
	p.add_child(body)

	var vis := Node2D.new()
	vis.name = "Visual"
	var sil := Polygon2D.new()
	sil.name = "Body"
	sil.polygon = PackedVector2Array([
		Vector2(-11, -17), Vector2(11, -17), Vector2(11, 17), Vector2(-11, 17)])
	sil.color = Color("f5f4ff")
	var eye := Polygon2D.new()
	eye.name = "Eye"
	eye.polygon = PackedVector2Array([
		Vector2(2, -8), Vector2(8, -8), Vector2(8, -1), Vector2(2, -1)])
	eye.color = Color("57d6ff")
	vis.add_child(sil)
	vis.add_child(eye)
	p.add_child(vis)

	var bl := Area2D.new()
	bl.name = "Blade"
	bl.set_script(preload("res://scripts/combat/blade.gd"))
	var bls := CollisionShape2D.new()
	var blrect := RectangleShape2D.new()
	blrect.size = Vector2(44, 26)
	bls.shape = blrect
	bls.position = Vector2(30, 0)
	bl.add_child(bls)
	p.add_child(bl)
	return p


func _ready() -> void:
	hp_max = int(SaveData.data.hp_max) + int(SaveData.data.buff.get("extra_life", 0))
	hp = hp_max
	blade.setup(self, ATTACK_DAMAGE)


func _physics_process(delta: float) -> void:
	if frozen:
		return
	_tick_timers(delta)
	_apply_gravity(delta)
	var dir := Input.get_axis("move_left", "move_right")
	_move(dir, delta)
	_jump()
	_dash(dir, delta)
	_attack(delta)
	move_and_slide()
	_update_visual(dir, delta)


func _tick_timers(delta: float) -> void:
	_coyote = maxf(0.0, _coyote - delta)
	_buffer = maxf(0.0, _buffer - delta)
	_dash_left = maxf(0.0, _dash_left - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_iframes = maxf(0.0, _iframes - delta)
	_attack_left = maxf(0.0, _attack_left - delta)
	_chain_gap = maxf(0.0, _chain_gap - delta)
	if is_on_floor():
		_coyote = COYOTE_TIME


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)


func _move(dir: float, delta: float) -> void:
	if _dash_left > 0.0 or _attack_left > 0.0:
		return
	var want := dir * RUN_SPEED
	var rate := ACCEL if dir != 0.0 else FRICTION
	if not is_on_floor():
		rate *= AIR_CONTROL
	velocity.x = move_toward(velocity.x, want, rate * delta)
	if dir != 0.0:
		facing = signi(dir)


func _jump() -> void:
	if Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
		_squash(Vector2(0.82, 1.18))
		Sfx.play("jump", -2.0)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5  # پرش کوتاه با ول‌دادن زود کلید


func _dash(dir: float, delta: float) -> void:
	if _dash_left > 0.0:
		velocity = Vector2(DASH_SPEED * facing, 0.0)
		visual.modulate.a = 0.55 + 0.2 * sin(Time.get_ticks_msec() / 25.0)
		return
	if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0:
		_dash_left = DASH_TIME
		_dash_cd = DASH_COOLDOWN
		_iframes = maxf(_iframes, DASH_IFRAMES)
		_squash(Vector2(1.25, 0.75))
		Sfx.play("dash", -2.0)


func _attack(delta: float) -> void:
	if _attack_left > 0.0:
		return
	if _chain_gap > 0.0:
		return
	if Input.is_action_just_pressed("attack"):
		_combo = (_combo % 3) + 1
		_attack_left = ATTACK_TIME
		_chain_gap = ATTACK_TIME + ATTACK_CHAIN_GAP
		velocity.x = facing * (RUN_SPEED * (0.55 if _combo == 3 else 0.3))
		Sfx.play("attack", -3.0, 0.95 + _combo * 0.08)
		blade.strike(facing, ATTACK_TIME, _combo == 3)
		attack_landed.emit()
		Telemetry.track("attack_swing", "", {"combo": _combo})


func take_damage(amount: int, from_pos: Vector2) -> void:
	if _iframes > 0.0 or hp <= 0:
		return
	hp -= amount
	_iframes = HURT_IFRAMES
	Sfx.play("hurt", -3.0)
	velocity = Vector2(signi(global_position.x - from_pos.x) * KNOCKBACK.x, KNOCKBACK.y)
	hp_changed.emit(hp, hp_max)
	var tw := create_tween()
	tw.tween_property(visual, "modulate", Color(1.0, 0.25, 0.25), 0.05)
	tw.tween_property(visual, "modulate", Color.WHITE, 0.22)
	if hp <= 0:
		_die()
	Telemetry.track("death", "", {"hp": hp})


func heal(n: int) -> void:
	hp = mini(hp_max, hp + n)
	hp_changed.emit(hp, hp_max)


func knockback_simple(force: float = 320.0) -> void:
	velocity = Vector2(-facing * force, -force * 0.6)


func collect_lum(n: int) -> void:
	Sfx.play("lum", -4.0)
	SaveData.add_lum(n)
	lum_picked.emit(n)


func _die() -> void:
	hp = hp_max
	hp_changed.emit(hp, hp_max)
	global_position = _respawn
	velocity = Vector2.ZERO
	visual.modulate = Color.WHITE
	died.emit()
	Telemetry.track("respawn", "", {})


func set_respawn(point: Vector2) -> void:
	_respawn = point


func _squash(target: Vector2) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual, "scale", target, 0.06)
	tw.tween_property(visual, "scale", Vector2.ONE, 0.12)


func _update_visual(dir: float, _delta: float) -> void:
	if _dash_left <= 0.0 and is_on_floor():
		visual.modulate.a = 1.0
		if dir != 0.0:
			visual.position.y = abs(sin(Time.get_ticks_msec() / 90.0)) * -2.0
		else:
			visual.position.y = 0.0
	if _dash_left <= 0.0:
		visual.modulate.a = 1.0
	visual.scale.x = abs(visual.scale.x) * facing


func _on_arena_body_entered(body: Node2D) -> void:
	# توسط stage_builder برای هنگام سقوط در چاله صدا زده می‌شود
	if body == self:
		take_damage(1, global_position + Vector2(0, 100))
		global_position = _respawn
