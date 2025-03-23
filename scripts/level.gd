# level.gd with modifications
extends Node3D

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var network_status_label = $CanvasLayer/HUD/NetworkStatusLabel

# Add a label to show connection status
@onready var status_label = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/StatusLabel

const Player = preload("res://scenes/player.tscn")

func _ready():
	# Connect to network manager signals
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.connected_to_server.connect(_on_connected_to_server)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)
	
	update_network_status("Connected", Color.GREEN)

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		NetworkManager.disconnect_game()
		get_tree().quit()

func _on_host_button_pressed():
	status_label.text = "Creating server..."
	var result = NetworkManager.host_game()
	
	if result == OK:
		main_menu.hide()
		hud.show()
		add_player(multiplayer.get_unique_id())
	else:
		status_label.text = "Failed to create server!"

func _on_join_button_pressed():
	if address_entry.text.is_empty():
		status_label.text = "Please enter an IP address!"
		return
		
	status_label.text = "Attempting to Connect..."
	var result = NetworkManager.join_game(address_entry.text)
	
	if result != OK:
		status_label.text = "Failed to connect!"

# Called when we successfully connect to a server
func _on_connected_to_server():
	main_menu.hide()
	hud.show()
	update_network_status("Connected", Color.GREEN)

# Called when connection fails
func _on_connection_failed():
	status_label.text = "Connection failed!"
	update_network_status("Connection failed", Color.RED)
	
# Called when server disconnects
func _on_server_disconnected():
	main_menu.show()
	hud.hide()
	status_label.text = "Disconnected from server"
	update_network_status("Disconnected from server", Color.RED)
	
	# Remove all players
	for child in get_children():
		if child is CharacterBody3D:  # Assuming Player inherits from CharacterBody3D
			child.queue_free()

# This function is now called when a player connects
func _on_player_connected(peer_id):
	update_network_status("Player " + str(peer_id) + " connected", Color.GREEN)
	# Only the server spawns players
	if multiplayer.is_server():
		add_player(peer_id)

# This function is now called when a player disconnects
func _on_player_disconnected(peer_id):
	update_network_status("Player " + str(peer_id) + " disconnected", Color.YELLOW)
	remove_player(peer_id)

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value

func update_network_status(status, color = Color.WHITE):
	network_status_label.text = status
	network_status_label.modulate = color

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)
