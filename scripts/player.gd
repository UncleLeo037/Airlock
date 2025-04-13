extends CharacterBody3D

const WALK_SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.08

signal health_changed(health_value)

@onready var _view = $View
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $"View/blaster-h3/MuzzleFlash"
@onready var raycast = $View/RayCast3D

var health = 3

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())


func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_view.current = true


func  _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return

	#handles mouse look
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
		_view.rotate_x(deg_to_rad(-event.relative.y * SENSITIVITY))
		_view.rotation.x = clamp(_view.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
	if Input.is_action_just_pressed("shoot") and anim_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "ahead", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var speed = WALK_SPEED * 2 if input_dir.y < 0 and Input.is_action_pressed("sprint") else WALK_SPEED
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0,speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	if anim_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move")
	else:
		anim_player.play("idle")

	move_and_slide()

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


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shoot":
		anim_player.play("idle")
