class_name IdleState
extends State

func enter() -> void:
	player.anim_player.play("idle")
	
func physics_update(delta: float) -> void:
	# Check for movement input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir != Vector2.ZERO:
		player.state_machine.change_state(player.states.move)
		return
	
	# Handle jumping
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		player.state_machine.change_state(player.states.jump)
		return
	
	# Handle shooting
	if Input.is_action_just_pressed("shoot"):
		player.state_machine.change_state(player.states.shoot)
		return
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.calculate_gravity().y * delta
		player.state_machine.change_state(player.states.fall)
		return
	
	# Slow down horizontal movement
	player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
	player.velocity.z = move_toward(player.velocity.z, 0, player.SPEED)
	
	player.move_and_slide()
