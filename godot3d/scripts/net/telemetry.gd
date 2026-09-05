extends Node
## Telemetry (autoload) — صف آفلاین رویدادهای گیم‌پلی ← همگام‌سازی با «موتور تسلط» سرور
## قرارداد دقیق با فاز ۲: obstacle_solved{solved,time_ms,retries,tool_correct} و غیره.

const QUEUE_PATH := "user://telemetry_queue.json"
const FLUSH_SEC := 20.0

var _queue: Array = []
var _timer: Timer


func _ready() -> void:
	_load_queue()
	_timer = Timer.new()
	_timer.wait_time = FLUSH_SEC
	_timer.autostart = true
	_timer.timeout.connect(_flush)
	add_child(_timer)
	Api.sync_finished.connect(_on_sync)


func track(type: String, topic_id: String = "", payload: Dictionary = {}) -> void:
	_queue.append({
		"type": type,
		"topic_id": topic_id if topic_id != "" else null,
		"payload": payload,
		"client_ts": Time.get_datetime_string_from_system(true)
	})


func _flush() -> void:
	if _queue.is_empty():
		return
	if Api.token == "" or Api.child_id <= 0:
		return
	var batch := _queue.duplicate()
	var ok: bool = await Api.send_telemetry(batch)


func _on_sync(ok: bool) -> void:
	if ok:
		_queue.clear()
		_save_queue()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_queue()


func _save_queue() -> void:
	var f := FileAccess.open(QUEUE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_queue))


func _load_queue() -> void:
	if not FileAccess.file_exists(QUEUE_PATH):
		return
	var f := FileAccess.open(QUEUE_PATH, FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data is Array:
			_queue = data
