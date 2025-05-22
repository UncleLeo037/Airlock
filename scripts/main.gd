extends Node2D

@onready var ms : MultiplayerSpawner = $MultiplayerSpawner

var lobby_id : int = 0
var peer  : SteamMultiplayerPeer = SteamMultiplayerPeer.new()

func _ready() -> void:
	ms.spawn_function = spawn_level
	peer.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	open_lobby_list()

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$Button.show()
	if event is InputEventMouseButton and not $StartMenu.is_visible_in_tree():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		$Button.hide()

func spawn_level(map : String):
	var a : Node3D = (load(map) as PackedScene).instantiate()
	return a

func _on_host_pressed() -> void:
	peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC)
	multiplayer.multiplayer_peer = peer
	ms.spawn("res://scenes/world.tscn")
	$StartMenu.hide()

func join_lobby(id : int) -> void:
	peer.connect_lobby(id)
	multiplayer.multiplayer_peer = peer
	lobby_id = id
	$StartMenu.hide()

func _on_lobby_created(connected : bool, id : int) -> void:
	if connected:
		lobby_id = id
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName()+"'s Airlock Server"))
		Steam.setLobbyJoinable(lobby_id, true)
		print(lobby_id)

func open_lobby_list() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func _on_lobby_match_list(lobbies : Array) -> void:
	for lobby in lobbies:
		var lobby_name : String = Steam.getLobbyData(lobby, "name")
		var mem_count: int = Steam.getNumLobbyMembers(lobby)
		
		var but : Button = Button.new()
		but.set_text(str(lobby_name, "| Player Count: ", mem_count))
		but.set_size(Vector2(100, 5))
		but.connect("pressed", Callable(self, "join_lobby").bind(lobby))
		
		$StartMenu/LobbyContainer/Lobbies.add_child(but)

func _on_refresh_pressed() -> void:
	if $StartMenu/LobbyContainer/Lobbies.get_child_count() > 0:
		for n in $StartMenu/LobbyContainer/Lobbies.get_children():
			n.queue_free()
			open_lobby_list()

func _on_button_pressed() -> void:
	get_tree().reload_current_scene()
