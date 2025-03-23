class_name MoveState
extends State

func enter() -> void:
	if not player.is_multiplayer_authority(): return
	player.anim_player.play("move")
	
func physics_update(delta: float) -> void:
	if not player.is_multiplayer_authority(): return
	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Check if we should go to idle state
	if input_dir == Vector2.ZERO:
		player.state_machine.change_state(player.states.idle)
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
	
	# Calculate movement direction
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	player.velocity.x = direction.x * player.SPEED
	player.velocity.z = direction.z * player.SPEED
	
	player.move_and_slide()
