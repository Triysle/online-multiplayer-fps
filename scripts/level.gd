extends Node3D

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var shield_bar = $CanvasLayer/HUD/ShieldBar
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var respawn_message = $CanvasLayer/HUD/RespawnMessage
@onready var respawn_timer = $CanvasLayer/HUD/RespawnTimer
@onready var ammo_display = $CanvasLayer/HUD/AmmoDisplay
@onready var reticle = $CanvasLayer/HUD/Reticle

var is_shield_recharging = false

const Player = preload("res://scenes/player.tscn")
var current_respawn_time = 0.0

func _ready():
	respawn_message.hide()
	respawn_timer.hide()
	
	health_bar.max_value = 100
	health_bar.value = 100
	
	shield_bar.max_value = 100 
	shield_bar.value = 100
	
	NetworkManager.player_connected.connect(add_player)
	NetworkManager.player_disconnected.connect(remove_player)

func _process(delta):
	if respawn_timer.visible:
		current_respawn_time -= delta
		if current_respawn_time <= 0:
			current_respawn_time = 0
		respawn_timer.text = str(int(ceil(current_respawn_time)))

func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	
	NetworkManager.create_server()

func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	NetworkManager.create_client(address_entry.text)

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)
		player.shields_changed.connect(update_shield_bar)
		player.respawning.connect(show_respawn_ui)
		player.shield_recharge_started.connect(on_shield_recharge_started)
		player.ammo_changed.connect(update_ammo_display)
		player.target_aimed_at.connect(update_reticle_color)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value

func update_shield_bar(shield_value):
	shield_bar.value = shield_value
	
	if shield_value < 100:
		is_shield_recharging = true
	else:
		is_shield_recharging = false
		
		var style = shield_bar.get_theme_stylebox("fill")
		if style is StyleBoxFlat:
			style.bg_color = Color(0, 1, 1, 1)

func update_ammo_display(current_ammo, total_ammo):
	ammo_display.text = "%d / %d" % [current_ammo, total_ammo]

func update_reticle_color(is_aiming_at_target):
	if is_aiming_at_target:
		reticle.modulate = Color(1.0, 0.3, 0.3)
	else:
		reticle.modulate = Color(1.0, 1.0, 1.0)

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
		node.ammo_changed.connect(update_ammo_display)
		node.target_aimed_at.connect(update_reticle_color)

func on_shield_recharge_started(is_recharging):
	is_shield_recharging = is_recharging
