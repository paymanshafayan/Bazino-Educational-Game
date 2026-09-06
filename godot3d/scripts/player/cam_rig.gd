## دوربین سوم-شخص نرم: تعقیب روان + نگاهمه کوتاه + محافظت با استوانهٔ فنری.
class_name CameraRig
extends Node3D

var target: Player3D
var yaw := 0.0                    # چرخش افقی (منهای موس در نسخه‌ی بازی کیبوردی)
var pitch := -0.62                # کمی از پشت بالاتر نگاه می‌کند
var distance := 7.5
var fov := 68.0

var _spring: SpringArm3D
var _cam: Camera3D


var _shake := 0.0
var _fov_kick := 0.0


func _ready() -> void:
	add_to_group("cam_rig")
	_spring = SpringArm3D.new()
	_spring.spring_length = distance
	_spring.collision_mask = 1
	add_child(_spring)
	_cam = Camera3D.new()
	_cam.fov = fov
	_cam.near = 0.1
	_cam.far = 400.0
	_spring.add_child(_cam)
	_cam.current = true


## لرزش مسیر بازی (آسیب/شوک/شکست سپر) — مقدار ۰..۱
func shake(power: float = 0.35) -> void:
	_shake = maxf(_shake, clampf(power, 0.0, 1.0))


## لگد میدان دید برای دش/سرعت (مثبت = بیرون)
func fov_kick(amount: float = 10.0, back_time: float = 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(_cam, "fov", fov + amount, 0.08)
	tw.tween_property(_cam, "fov", fov, back_time).set_trans(Tween.TRANS_SINE)


func bind(player: Player3D) -> void:
	target = player
	global_position = target.global_position


func _process(delta: float) -> void:
	if not target:
		return
	# چرخش خودکار ملایم در جهت حرکت بازیکن (keyboard-only friendly)
	if target.velocity.length_squared() > 1.0:
		var want_yaw := atan2(target.velocity.x, target.velocity.z)
		yaw = lerp_angle(yaw, want_yaw, clampf(delta * 2.2, 0.0, 1.0))
	# لرزش فروکش‌گر شبه‌تصادفی
	if _shake > 0.001:
		_shake = lerpf(_shake, 0.0, clampf(delta * 6.0, 0.0, 1.0))
		var sz := _shake * 0.22
		rotation = Vector3(
			pitch + sin(Time.get_ticks_msec() * 0.09) * sz * 0.5,
			yaw + sin(Time.get_ticks_msec() * 0.13) * sz * 0.35,
			sin(Time.get_ticks_msec() * 0.11) * sz)
	else:
		rotation = Vector3(pitch, yaw, 0.0)
	target.cam_yaw = yaw + PI          # کنترلر نسبت به دوربین WASD می‌گیرد
	# تعقیب نرم موقعیت (همه جای دومروبین روی بازیکن با لِک کوتاه)
	var want_pos := target.global_position + Vector3(0, 2.0, 0)
	global_position = global_position.lerp(want_pos, clampf(delta * 7.0, 0.0, 1.0))
