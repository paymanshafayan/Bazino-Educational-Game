## Coop3D — کو-اوپ LAN گیم‌نت (۲ نفر روی ENet)، پورت وفادار نسخهٔ 2D به سه‌بعد.
## هاست = سرور حرکتی؛ بازیکن دوم به‌صورت «روح» زرد همگام می‌شود.
class_name Coop3D
extends Node

signal peer_connected(id: int)
signal session_started

const DEFAULT_PORT := 34197

var active := false
var is_host := false
var remote_ghost: Node3D
var _local_player: Player3D
var _t := 0.0


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


func attach_local_player(pl: Player3D) -> void:
	_local_player = pl


func _on_peer(id: int) -> void:
	peer_connected.emit(id)
	Sfx.play("gate_ok", -8.0, 1.2)


func spawn_ghost(parent: Node3D) -> void:
	remote_ghost = Node3D.new()
	var sil := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.45
	cap.height = 1.6
	sil.mesh = cap
	sil.position = Vector3(0, 0.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ffd166")
	mat.emission_enabled = true
	mat.emission = Color("ffd166")
	mat.emission_energy_multiplier = 0.9
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.75
	sil.material_override = mat
	remote_ghost.add_child(sil)
	remote_ghost.global_position = Vector3(2.5, 0.5, 14)
	parent.add_child(remote_ghost)


@rpc("any_peer", "unreliable")
func sync_pos(pos: Vector3, facing: float) -> void:
	if remote_ghost:
		remote_ghost.global_position = pos
		remote_ghost.rotation.y = facing


func _physics_process(delta: float) -> void:
	_t += delta
	if _t < 0.05:
		return
	_t = 0.0
	if active and _local_player and multiplayer.has_multiplayer_peer():
		rpc("sync_pos", _local_player.global_position,
			atan2(_local_player.facing.x, _local_player.facing.z))
