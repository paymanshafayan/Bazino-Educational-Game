class_name CoopSession
extends Node
## CoopSession — کو-اوپ LAN گیم‌نت (۲ نفر روی ENet). هاست=سرورِ حرکتی، مهمان همگام از راه دور.
## v1: همگام‌سازی موقعیت/حمله بازیکن دوم به‌صورت روح خاموش (Godot Multiplayer API).

signal peer_connected(id: int)
signal session_started

const DEFAULT_PORT := 34197

var active := false
var is_host := false
var remote_ghost: Node2D
var _local_player: Player


func host(port: int = DEFAULT_PORT) -> Error:
	var p := ENetMultiplayerPeer.new()
	var err := p.create_server(port, 4)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = p
	active = true
	is_host = true
	multiplayer.peer_connected.connect(_on_peer)
	session_started.emit()
	return OK


func join(ip: String, port: int = DEFAULT_PORT) -> Error:
	var p := ENetMultiplayerPeer.new()
	var err := p.create_client(ip, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = p
	active = true
	is_host = false
	session_started.emit()
	return OK


func attach_local_player(pl: Player) -> void:
	_local_player = pl


func _on_peer(id: int) -> void:
	peer_connected.emit(id)


func spawn_ghost(parent: Node2D) -> void:
	remote_ghost = Node2D.new()
	var sil := Polygon2D.new()
	sil.polygon = PackedVector2Array([
		Vector2(-11, -17), Vector2(11, -17), Vector2(11, 17), Vector2(-11, 17)])
	sil.color = Color("ffd166")
	remote_ghost.add_child(sil)
	remote_ghost.global_position = Vector2(120, 470)
	parent.add_child(remote_ghost)


@rpc("any_peer", "unreliable")
func sync_pos(pos: Vector2, facing: int) -> void:
	if remote_ghost:
		remote_ghost.global_position = pos
		remote_ghost.scale.x = absf(remote_ghost.scale.x) * facing


func _physics_process(_d: float) -> void:
	if active and _local_player and multiplayer.has_multiplayer_peer():
		rpc("sync_pos", _local_player.global_position, _local_player.facing)
