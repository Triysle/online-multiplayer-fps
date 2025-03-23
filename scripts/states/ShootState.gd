class_name ShootState
extends State

func enter() -> void:
	if not player.is_multiplayer_authority(): return
	player.play_shoot_effects.rpc()
	
	if player.raycast.is_colliding():
		var hit_player = player.raycast.get_collider()
		if hit_player is CharacterBody3D:
			var hit_position = player.raycast.get_collision_point()
			player.request_hit_validation.rpc_id(1, hit_player.name, hit_position)

func physics_update(delta: float) -> void:
	if not player.is_multiplayer_authority(): return
	
	# Handle movement during shooting - copy this from MoveState
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.calculate_gravity().y * delta
	
	# Calculate movement direction - maintain full speed while shooting
	if input_dir != Vector2.ZERO:
		var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		player.velocity.x = direction.x * player.SPEED
		player.velocity.z = direction.z * player.SPEED
	
	player.move_and_slide()
	
	# Handle jumping during shooting
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.state_machine.change_state(player.states.jump)
		return
	
	# Return to appropriate state when animation is done
	if player.anim_player.current_animation != "shoot":
		if not player.is_on_floor():
			player.state_machine.change_state(player.states.fall)
			return
		
		if input_dir != Vector2.ZERO:
			player.state_machine.change_state(player.states.move)
		else:
			player.state_machine.change_state(player.states.idle)
		return
