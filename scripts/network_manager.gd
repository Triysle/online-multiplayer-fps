# network_manager.gd
extends Node

signal player_connected(peer_id)
signal player_disconnected(peer_id)
signal connected_to_server
signal connection_failed
signal server_disconnected

const PORT = 9999
const MAX_RECONNECT_ATTEMPTS = 3

var enet_peer = ENetMultiplayerPeer.new()
var reconnect_attempts = 0
var reconnect_timer = null
var server_address = ""

# Player information dictionary
var players_info = {}

func _ready():
	# Connect to multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game():
	# Create server
	var error = enet_peer.create_server(PORT)
	if error != OK:
		print("Failed to create server: ", error)
		return error
	
	multiplayer.multiplayer_peer = enet_peer
	
	# Add host to players
	var host_id = multiplayer.get_unique_id()
	players_info[host_id] = {"name": "Host", "ready": true}
	
	# Setup UPNP
	upnp_setup()
	
	return OK

func join_game(address):
	server_address = address  # Store for reconnection attempts
	var error = enet_peer.create_client(address, PORT)
	if error != OK:
		print("Failed to create client: ", error)
		return error
	
	multiplayer.multiplayer_peer = enet_peer
	return OK

func attempt_reconnect():
	if reconnect_attempts >= MAX_RECONNECT_ATTEMPTS:
		print("Max reconnection attempts reached")
		emit_signal("connection_failed")
		return
	
	reconnect_attempts += 1
	print("Attempting to reconnect... (%d/%d)" % [reconnect_attempts, MAX_RECONNECT_ATTEMPTS])
	
	join_game(server_address)

func disconnect_game():
	multiplayer.multiplayer_peer = null
	players_info.clear()
	enet_peer.close()

# Signal callbacks
func _on_peer_connected(id):
	print("Peer connected: ", id)
	
	# If we're the server, tell this new peer about all existing players
	if multiplayer.is_server():
		# Register the new player first
		players_info[id] = {"name": "Player " + str(id), "ready": false}
		
		# Tell the new player about all existing players (including themselves)
		for peer_id in players_info:
			rpc_id(id, "register_player", peer_id, players_info[peer_id])
	
	player_connected.emit(id)

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	
	# Remove this player from our list
	if players_info.has(id):
		players_info.erase(id)
	
	player_disconnected.emit(id)

func _on_connected_to_server():
	print("Connected to server!")
	
	# Reset reconnection attempts on successful connection
	reconnect_attempts = 0
	
	# We successfully connected, register ourselves with the server
	var id = multiplayer.get_unique_id()
	players_info[id] = {"name": "Player " + str(id), "ready": true}
	
	connected_to_server.emit()

func _on_connection_failed():
	print("Connection failed!")
	
	# Try to reconnect
	if server_address != "" and reconnect_attempts < MAX_RECONNECT_ATTEMPTS:
		if reconnect_timer == null:
			reconnect_timer = Timer.new()
			add_child(reconnect_timer)
			reconnect_timer.one_shot = true
			reconnect_timer.wait_time = 2.0
			reconnect_timer.timeout.connect(attempt_reconnect)
		
		print("Will try to reconnect in 2 seconds...")
		reconnect_timer.start()
	else:
		disconnect_game()
		connection_failed.emit()

func _on_server_disconnected():
	print("Server disconnected!")
	
	# Try to reconnect
	if server_address != "" and reconnect_attempts < MAX_RECONNECT_ATTEMPTS:
		if reconnect_timer == null:
			reconnect_timer = Timer.new()
			add_child(reconnect_timer)
			reconnect_timer.one_shot = true
			reconnect_timer.wait_time = 2.0
			reconnect_timer.timeout.connect(attempt_reconnect)
		
		print("Will try to reconnect in 2 seconds...")
		reconnect_timer.start()
	else:
		disconnect_game()
		server_disconnected.emit()

# Player registration
@rpc("authority")
func register_player(id, info):
	print("Registering player: ", id)
	players_info[id] = info

# The UPNP setup function you already have
func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Discover Failed! Error %s" % discover_result)
		return
	
	if not upnp.get_gateway() or not upnp.get_gateway().is_valid_gateway():
		print("UPNP Invalid Gateway!")
		return
	
	var map_result = upnp.add_port_mapping(PORT)
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Port Mapping Failed! Error %s" % map_result)
		return
	
	print("Success! Join Address: %s" % upnp.query_external_address())
