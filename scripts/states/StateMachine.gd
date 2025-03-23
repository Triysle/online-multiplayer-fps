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
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		var new_state = current_state.handle_input(event)
		if new_state:
			change_state(new_state)

func change_state(new_state: State) -> void:
	if current_state:
		current_state.exit()
	
	current_state = new_state
	current_state.enter()

func initialize() -> void:
	# Set up state references
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.player = player
	
	# Set initial state
	if states.has("idle"):
		current_state = states.idle
		current_state.enter()
