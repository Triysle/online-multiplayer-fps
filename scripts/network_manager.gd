extends Node

const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

signal player_connected(peer_id)
signal player_disconnected(peer_id)

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func create_server():
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	_on_peer_connected(multiplayer.get_unique_id())
	upnp_setup()

func create_client(address):
	enet_peer.create_client(address, PORT)
	multiplayer.multiplayer_peer = enet_peer

func _on_peer_connected(id):
	player_connected.emit(id)

func _on_peer_disconnected(id):
	player_disconnected.emit(id)

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

func get_network_id():
	return multiplayer.get_unique_id()

func is_server():
	return multiplayer.is_server()

func is_network_authority():
	return multiplayer.is_server() or get_network_id() > 1
