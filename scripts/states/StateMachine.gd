class_name StateMachine
extends Node

var player: CharacterBody3D
var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames() % 180 == 0 and player and player.is_multiplayer_authority():
		print("StateMachine physics_process running, current state: ", current_state.name if current_state else "null")
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		var new_state = current_state.handle_input(event)
		if new_state:
			change_state(new_state)

func change_state(new_state: State) -> void:
	print("Changing state from ", current_state.name if current_state else "null", " to ", new_state.name)
	if current_state:
		current_state.exit()
	
	current_state = new_state
	current_state.enter()

func initialize() -> void:
	# Set up state references
	for child in get_children():
		if child is State:
			child.player = player
	
	states = player.states
	
	print("Available states: ", states.keys())
	
	# Set initial state
	if states.has("idle"):
		print("Setting initial state to Idle")
		current_state = states.idle
		current_state.enter()
	else:
		print("WARNING: No Idle state found!")
