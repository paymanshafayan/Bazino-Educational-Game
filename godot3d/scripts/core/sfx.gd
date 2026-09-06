## سامانهٔ صدای بازینو — autoload.
## همهٔ صداها با ابزار tools/synth_audio.py سنتز شده‌اند و در assets/audio/ هستند.
extends Node

const SFX := {
	"jump": "res://assets/audio/jump.wav",
	"land": "res://assets/audio/land.wav",
	"dash": "res://assets/audio/dash.wav",
	"attack": "res://assets/audio/attack.wav",
	"hurt": "res://assets/audio/hurt.wav",
	"gate_ok": "res://assets/audio/gate_ok.wav",
	"gate_bad": "res://assets/audio/gate_bad.wav",
	"boss_roar": "res://assets/audio/boss_roar.wav",
	"lum": "res://assets/audio/lum.wav",
	"scroll": "res://assets/audio/scroll.wav",
	"phase_break": "res://assets/audio/phase_break.wav",
	"click": "res://assets/audio/click.wav",
	"victory": "res://assets/audio/victory.wav",
}
const MUSIC := {
	"ambient": "res://assets/audio/ambient_cave.wav",
	"boss": "res://assets/audio/boss_theme.wav",
}

const POOL_SIZE := 8

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _cursor := 0
var music: AudioStreamPlayer
var music_name := ""
var enabled := true


func _ready() -> void:
	for key: String in SFX:
		_streams[key] = load(SFX[key])
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	music = AudioStreamPlayer.new()
	music.volume_db = -10.0
	add_child(music)


func play(name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not enabled:
		return
	var stream: AudioStream = _streams.get(name)
	if stream == null:
		return
	var p: AudioStreamPlayer = _pool[_cursor]
	_cursor = (_cursor + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func play_music(name: String) -> void:
	if music_name == name:
		return
	music_name = name
	var path: String = MUSIC.get(name, "")
	if path.is_empty():
		music.stop()
		return
	var stream: AudioStreamWAV = load(path)
	if stream == null:
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.stream = stream
	# کراس‌فید آرام: از حجم پایین شروع می‌کنیم
	music.volume_db = -24.0
	music.play()
	var tw := create_tween()
	tw.tween_property(music, "volume_db", -10.0, 1.2)
