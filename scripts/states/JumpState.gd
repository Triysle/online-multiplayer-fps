class_name JumpState
extends State

func enter() -> void:
	if not player.is_multiplayer_authority(): return
	player.velocity.y = player.JUMP_VELOCITY
	
func physics_update(delta: float) -> void:
	if not player.is_multiplayer_authority(): return
	# Get input direction for horizontal movement while jumping
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Handle shooting
	if Input.is_action_just_pressed("shoot"):
		player.state_machine.change_state(player.states.shoot)
		return
	
	# Apply gravity
	player.velocity.y += player.calculate_gravity().y * delta
	
	# Calculate movement direction
	if input_dir != Vector2.ZERO:
		var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		player.velocity.x = direction.x * player.SPEED
		player.velocity.z = direction.z * player.SPEED
	
	# Transition to fall state when velocity becomes negative
	if player.velocity.y < 0:
		player.state_machine.change_state(player.states.fall)
		return
	
	player.move_and_slide()
