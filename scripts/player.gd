extends RigidBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 6.0

@export var SENSITIVITY = 0.08

@onready var head : Node3D = $CollisionShape3D
@onready var camera = $CollisionShape3D/Camera3D
@onready var feet : ShapeCast3D = $CollisionShape3D/Feet
@onready var hands : RayCast3D = $CollisionShape3D/Camera3D/Hands
@onready var lock = $CollisionShape3D/Camera3D/Hands/Lock

var object : CollisionObject3D

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if object:
			object.set_collision_layer_value(1, true)
			object = null
		else:
			interact()

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
		camera.rotate_x(deg_to_rad(-event.relative.y * SENSITIVITY))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	# Handle jump.
	if Input.is_action_just_pressed("aloft") and feet.is_colliding():
		linear_velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("port", "starboard", "forward", "aftward")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		linear_velocity.x = direction.x * SPEED
		linear_velocity.z = direction.z * SPEED
	else:
		linear_velocity.x = move_toward(linear_velocity.x, 0, SPEED)
		linear_velocity.z = move_toward(linear_velocity.z, 0, SPEED)
	
	if hands.get_collider() or object:
		$HUD/prompt.show()
	else:
		$HUD/prompt.hide()
	
	if object:
		var a = object.global_transform.origin
		var b = lock.global_transform.origin
		var throw = (b-a)*9
		object.set_linear_velocity(throw)

func interact() -> void:
	var cast = hands.get_collider()
	if cast is RigidBody3D:
		object = cast
		object.set_collision_layer_value(1, false)
