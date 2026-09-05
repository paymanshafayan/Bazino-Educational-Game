extends Node
## Api (autoload) — اتصال کلاینت Godot به بک‌اند Bazino (فاز ۲)
## base_url: پیش‌فرض PC محلی؛ برای موبایل/سالن: متغیر محیطی BAZINO_API

signal login_finished(ok: bool, user: Dictionary)
signal player_info_finished(ok: bool, info: Dictionary)
signal stage_finished(ok: bool, config: Dictionary)
signal venue_finished(ok: bool, data: Dictionary)
signal reward_finished(ok: bool, data: Dictionary)
signal sync_finished(ok: bool)

var base_url := "http://127.0.0.1:8000"
var token := ""
var child_id := 0
var online := false


func _ready() -> void:
	var e := OS.get_environment("BAZINO_API")
	if e != "":
		base_url = e


func _request(method: int, path: String, payload: Dictionary = {}) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = 8.0
	add_child(req)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if token != "":
		headers.append("Authorization: Bearer %s" % token)
	var body := ""
	if method != HTTPClient.METHOD_GET:
		body = JSON.stringify(payload)
	var url := path if path.begins_with("http") else base_url + path
	var err := req.request(url, headers, method, body)
	if err != OK:
		req.queue_free()
		online = false
		return {"ok": false, "code": 0, "body": {}}
	var res: Array = await req.request_completed
	req.queue_free()
	var code: int = res[1]
	var raw: String = (res[3] as PackedByteArray).get_string_from_utf8()
	var data = JSON.parse_string(raw)
	online = code >= 200 and code < 300
	return {"ok": online, "code": code,
		"body": data if data is Dictionary else {"data": data}}


func _http_get(path: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, path)


func _post(path: String, payload: Dictionary) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, path, payload)


func ping() -> bool:
	var r: Dictionary = await _http_get("/health")
	return r.ok


func login(email: String, password: String) -> void:
	var r: Dictionary = await _post("/auth/login", {"email": email, "password": password})
	if r.ok and r.body.has("access_token"):
		token = r.body.access_token
		login_finished.emit(true, r.body)
		await fetch_player_info()
	else:
		login_finished.emit(false, r.body)


func fetch_player_info() -> void:
	var r: Dictionary = await _http_get("/auth/me/player")
	if r.ok:
		child_id = int(r.body.get("child_id", 0))
	player_info_finished.emit(r.ok, r.body)


func fetch_stage(region: String, season: int, index_no: int) -> void:
	var path := "/adaptive/stage/%d?region=%s&season=%d&index_no=%d" % [
		child_id, region, season, index_no]
	var r: Dictionary = await _http_get(path)
	stage_finished.emit(r.ok, r.body)


func send_telemetry(events: Array) -> bool:
	if child_id <= 0 or token == "":
		return false
	var req := HTTPRequest.new()
	req.timeout = 10.0
	add_child(req)
	var headers := PackedStringArray(["Content-Type: application/json",
		"Authorization: Bearer %s" % token])
	# توجه: endpoint بک‌انتد خودِ آرایهٔ رویدادها را می‌خواهد (نه شی‌ء بسته‌بندی‌شده)
	var err := req.request("%s/telemetry/events/%d" % [base_url, child_id],
		headers, HTTPClient.METHOD_POST, JSON.stringify(events))
	if err != OK:
		req.queue_free()
		sync_finished.emit(false)
		return false
	var res: Array = await req.request_completed
	req.queue_free()
	var ok := int(res[1]) == 200
	sync_finished.emit(ok)
	return ok


func join_venue(code: String) -> void:
	var r: Dictionary = await _post("/venue/join", {"code": code})
	venue_finished.emit(r.ok, r.body)


## قهرمان تورنمنت: کد جایزهٔ بزرگ فصل را می‌گیرد (در باجهٔ سالن تحویل می‌شود)
func claim_grand_reward() -> void:
	var cat: Dictionary = await _http_get("/rewards/catalog")
	if not cat.ok:
		reward_finished.emit(false, {})
		return
	var items: Array = cat.body.get("data", [])
	var grand_id := -1
	for it in items:
		if it.get("tier", "") == "grand":
			grand_id = int(it.get("id", -1))
			break
	if grand_id < 0:
		reward_finished.emit(false, {})
		return
	var r: Dictionary = await _post("/rewards/redeem",
		{"child_id": child_id, "reward_id": grand_id})
	reward_finished.emit(r.ok, r.body)
