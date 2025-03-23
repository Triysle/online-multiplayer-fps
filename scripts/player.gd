extends CharacterBody3D

signal health_changed(health_value)
signal shields_changed(shield_value)
signal respawning(is_respawning)
signal shield_recharge_started(is_recharging)
signal ammo_changed(current_ammo, total_ammo)  # New signal for UI updates

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D
@onready var mesh_instance = $MeshInstance3D

var health = 100 
var shields = 100 
var is_dead = false
var respawn_timer = 0.0
const RESPAWN_TIME = 3.0

# Ammo properties
var max_ammo = 12  # Pistol magazine size
var current_ammo = 12  # Start with a full magazine
var total_ammo = 48  # Total spare ammo
var is_reloading = false  # Reload state flag
var reload_time = 1.5  # Time in seconds to reload
var reload_timer = 0.0  # Timer for reload progress

# Shield properties
var shield_recharge_delay = 5.0 
var shield_recharge_rate = 10.0 
var shield_last_hit_time = 0.0

const SPEED = 10.0
const JUMP_VELOCITY = 10

var gravity = 20.0
var hit_flash_time = 0.0

var mouse_captured = true

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
	health_changed.emit(health)
	shields_changed.emit(shields)
	ammo_changed.emit(current_ammo, total_ammo)  # Initial ammo UI update

func toggle_mouse_capture():
	mouse_captured = !mouse_captured
	
	if mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event.is_action_pressed("quit"):
		toggle_mouse_capture()
		get_viewport().set_input_as_handled()
		return
	
	if not mouse_captured:
		return
		
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if is_dead or is_reloading: return
		
	if Input.is_action_just_pressed("shoot") and anim_player.current_animation != "shoot":
		if current_ammo > 0:
			current_ammo -= 1
			ammo_changed.emit(current_ammo, total_ammo)
			play_shoot_effects.rpc()
			
			if raycast.is_colliding():
				var hit_player = raycast.get_collider()
				if hit_player.has_method("receive_damage"):
					hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())
					
			# Automatic reload when magazine is empty
			if current_ammo == 0 and total_ammo > 0:
				start_reload()
		else:
			# Click sound when empty (would need to add this sound)
			pass
	
	if Input.is_action_just_pressed("reload"):
		start_reload()

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	if is_dead:
		handle_respawn(delta)
		return
	
	# Handle reload timer
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			complete_reload()
	
	if hit_flash_time > 0:
		hit_flash_time -= delta
		if hit_flash_time <= 0:
			reset_player_material.rpc()
	
	if shields < 100 and Time.get_ticks_msec() / 1000.0 - shield_last_hit_time >= shield_recharge_delay:
		shields += shield_recharge_rate * delta
		shields = min(shields, 100)
		shields_changed.emit(shields)
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if mouse_captured:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		
		if anim_player.current_animation == "shoot" or is_reloading:
			pass
		elif input_dir != Vector2.ZERO and is_on_floor():
			anim_player.play("move")
		else:
			anim_player.play("idle")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		if anim_player.current_animation != "shoot" and not is_reloading:
			anim_player.play("idle")

	if shields < 100:
		if Time.get_ticks_msec() / 1000.0 - shield_last_hit_time >= shield_recharge_delay:
			if shields == 0:
				shield_recharge_started.emit(true)
				
			shields += shield_recharge_rate * delta
			shields = min(shields, 100)
			shields_changed.emit(shields)
			
	move_and_slide()

func handle_respawn(delta):
	respawn_timer -= delta
	if respawn_timer <= 0:
		is_dead = false
		respawning.emit(false)
		health = 100 
		shields = 100
		current_ammo = max_ammo
		total_ammo = 48  # Reset total ammo too
		health_changed.emit(health)
		shields_changed.emit(shields)
		ammo_changed.emit(current_ammo, total_ammo)
		reset_player_material.rpc()

func start_reload():
	if is_reloading or current_ammo == max_ammo or total_ammo <= 0:
		return
		
	is_reloading = true
	reload_timer = reload_time
	play_reload_animation.rpc()  # This would be a new animation to add

func complete_reload():
	is_reloading = false
	
	var ammo_needed = max_ammo - current_ammo
	var ammo_to_reload = min(ammo_needed, total_ammo)
	
	current_ammo += ammo_to_reload
	total_ammo -= ammo_to_reload
	
	ammo_changed.emit(current_ammo, total_ammo)

@rpc("call_local")
func play_reload_animation():
	# You'll need to create a reload animation and add it to your AnimationPlayer
	# For now, we'll just play the idle animation
	anim_player.stop()
	anim_player.play("idle")
	# When you create a reload animation, replace "idle" with "reload"

@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc("any_peer")
func receive_damage():
	if is_dead:
		return
	
	# Update last hit time for shield recharge delay
	shield_last_hit_time = Time.get_ticks_msec() / 1000.0
	
	# Damage amount for pistol
	var damage = 10
	
	if shields > 0:
		if shields >= damage:
			shields -= damage
			damage = 0
		else:
			damage -= shields
			shields = 0
		
		shields_changed.emit(shields)
	
	if damage > 0:
		health -= damage
		health_changed.emit(health)
	
	if health <= 0:
		die()
	else:
		flash_damage.rpc()
		hit_flash_time = 0.3

func die():
	is_dead = true
	is_reloading = false  # Cancel any reload if player dies
	respawn_timer = RESPAWN_TIME
	respawning.emit(true)
	position = Vector3.ZERO
	velocity = Vector3.ZERO
	flash_death.rpc()

@rpc("call_local")
func flash_damage():
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.3, 0.3)
		mesh_instance.set_surface_override_material(0, material)

@rpc("call_local")
func flash_death():
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.1, 0.1, 0.1)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.5
		mesh_instance.set_surface_override_material(0, material)

@rpc("call_local")
func reset_player_material():
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, null)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
	# When you create a reload animation, add this:
	# elif anim_name == "reload":
	#     is_reloading = false
	#     complete_reload()
