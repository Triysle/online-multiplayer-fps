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
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += player.calculate_gravity().y * delta
	
	# Slow down horizontal movement while shooting
	player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED * 0.5)
	player.velocity.z = move_toward(player.velocity.z, 0, player.SPEED * 0.5)
	
	player.move_and_slide()
	
	# Return to appropriate state when animation is done
	# This check works because we connected the animation_finished signal in the player
	if player.anim_player.current_animation != "shoot":
		if not player.is_on_floor():
			player.state_machine.change_state(player.states.fall)
			return
		
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if input_dir != Vector2.ZERO:
			player.state_machine.change_state(player.states.move)
		else:
			player.state_machine.change_state(player.states.idle)
		return
