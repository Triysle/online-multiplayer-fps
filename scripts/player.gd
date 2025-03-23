extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D
@onready var state_machine = $StateMachine

var health = 3
var states = {}

const SPEED = 7.0
const JUMP_VELOCITY = 10

var gravity = 15.0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
	# Initialize states dict for easy access in state classes
	states.idle = $StateMachine/IdleState
	states.move = $StateMachine/MoveState
	states.jump = $StateMachine/JumpState
	states.fall = $StateMachine/FallState
	states.shoot = $StateMachine/ShootState
	
	# Set the player reference in the state machine
	state_machine.player = self
	state_machine.initialize()
	
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func calculate_gravity() -> Vector3:
	return Vector3.DOWN * gravity

@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc("any_peer")
func receive_damage():
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO
	health_changed.emit(health)
	sync_health.rpc(health)

@rpc("any_peer", "call_remote")
func request_hit_validation(hit_player_name, hit_position):
	if not multiplayer.is_server():
		return
	
	var hit_player = get_node_or_null("../" + hit_player_name)
	if not hit_player:
		return
	
	var distance = hit_player.global_position.distance_to(hit_position)
	if distance > 5.0:
		print("Hit validation failed: Too far")
		return
	
	hit_player.receive_damage()

@rpc("call_local")
func sync_health(new_health):
	health = new_health
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
