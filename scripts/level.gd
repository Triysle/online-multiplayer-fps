extends Node3D

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var shield_bar = $CanvasLayer/HUD/ShieldBar
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var respawn_message = $CanvasLayer/HUD/RespawnMessage
@onready var respawn_timer = $CanvasLayer/HUD/RespawnTimer

var shield_pulse_timer = 0.0
var is_shield_pulsing = false
var is_shield_recharging = false

const Player = preload("res://scenes/player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()
var current_respawn_time = 0.0

func _ready():
	respawn_message.hide()
	respawn_timer.hide()
	
	var shield_fill = StyleBoxFlat.new()
	shield_fill.bg_color = Color(0, 1, 1, 1)
	
	var shield_background = StyleBoxFlat.new()
	shield_background.bg_color = Color(0, 0, 0, 0)  
	
	shield_bar.add_theme_stylebox_override("fill", shield_fill)
	shield_bar.add_theme_stylebox_override("background", shield_background)
	
	health_bar.max_value = 100
	health_bar.value = 100
	
	shield_bar.max_value = 100 
	shield_bar.value = 100
	
	var health_background = StyleBoxFlat.new()
	health_background.bg_color = Color(1, 0, 0, 1) 
	
	var health_fill = StyleBoxFlat.new()
	health_fill.bg_color = Color(0, 1, 0, 1) 
	
	health_bar.add_theme_stylebox_override("background", health_background)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	
	health_bar.max_value = 100

func _process(delta):
	if respawn_timer.visible:
		current_respawn_time -= delta
		if current_respawn_time <= 0:
			current_respawn_time = 0
		respawn_timer.text = str(int(ceil(current_respawn_time)))
	
	if is_shield_pulsing:
		shield_pulse_timer += delta * 4.0 
		var pulse_value = (sin(shield_pulse_timer) + 1.0) / 2.0
		var yellow_color = Color(1.0, 1.0, 0.3, pulse_value)
		
		var style = shield_bar.get_theme_stylebox("fill")
		if style is StyleBoxFlat:
			style.bg_color = yellow_color
	
	elif is_shield_recharging:
		var style = shield_bar.get_theme_stylebox("fill")
		if style is StyleBoxFlat:
			style.bg_color = Color(0, 1, 1, 1)

func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

	add_player(multiplayer.get_unique_id())
	
	upnp_setup()

func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
		player.shields_changed.connect(update_shield_bar)
		player.respawning.connect(show_respawn_ui)
		player.shield_recharge_started.connect(on_shield_recharge_started)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value

func update_shield_bar(shield_value):
	shield_bar.value = shield_value
	
	if shield_value <= 0:
		is_shield_pulsing = true
		is_shield_recharging = false
	elif shield_value < 100:
		is_shield_pulsing = false
		is_shield_recharging = true
	else:
		is_shield_pulsing = false
		is_shield_recharging = false
		
		var style = shield_bar.get_theme_stylebox("fill")
		if style is StyleBoxFlat:
			style.bg_color = Color(0, 1, 1, 1)

func show_respawn_ui(is_respawning):
	if is_respawning:
		respawn_message.show()
		respawn_timer.show()
		current_respawn_time = 3.0
	else:
		respawn_message.hide()
		respawn_timer.hide()

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)
		node.shields_changed.connect(update_shield_bar)
		node.respawning.connect(show_respawn_ui)
		node.shield_recharge_started.connect(on_shield_recharge_started)

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Discover Failed! Error %s" % discover_result)
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert (map_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())

func on_shield_recharge_started(is_recharging):
	is_shield_pulsing = false
	is_shield_recharging = is_recharging
