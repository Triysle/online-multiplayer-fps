class_name FallState
extends State

func physics_update(delta: float) -> void:
	# Get input direction for horizontal movement while falling
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Handle shooting
	if Input.is_action_just_pressed("shoot"):
		player.state_machine.change_state(player.states.shoot)
		return
	
	# Apply gravity
	player.velocity.y += player.calculate_gravity().y * delta
	
	# Calculate movement direction (reduced control while in air)
	if input_dir != Vector2.ZERO:
		var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		player.velocity.x = direction.x * player.SPEED * 0.8
		player.velocity.z = direction.z * player.SPEED * 0.8
	
	# Return to ground states if landed
	if player.is_on_floor():
		if input_dir != Vector2.ZERO:
			player.state_machine.change_state(player.states.move)
		else:
			player.state_machine.change_state(player.states.idle)
		return
	
	player.move_and_slide()
