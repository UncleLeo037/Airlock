extends Node3D

const Player = preload("res://scenes/player.tscn")

func _ready() -> void:
	var player = Player.instantiate()
	player.name = str(multiplayer.get_unique_id())
	add_child(player)
