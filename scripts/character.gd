extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var SENSITIVITY = 0.08

@onready var camera = $Camera3D
@onready var ray : RayCast3D = $Camera3D/RayCast3D
@onready var mark = $Camera3D/RayCast3D/Marker3D
@onready var shape = $ShapeCast3D

var object : CollisionObject3D

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event.is_action_pressed("interact"):
		if object:
			object = null
		else:
			interact()

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
		camera.rotate_x(deg_to_rad(-event.relative.y * SENSITIVITY))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	#print(get_slide_collision(0))
	
	if ray.get_collider() or object:
		$HUD/prompt.show()
	else:
		$HUD/prompt.hide()
	
	if object:
		var a = object.global_transform.origin
		var b = mark.global_transform.origin
		var throw = (b-a) * 9
		object.set_linear_velocity(throw)
	
	# Add the gravity.
	if shape.is_colliding():
		velocity.y = 0
	else:
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("aloft") and (shape.is_colliding() or is_on_floor()):
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("port", "starboard", "forward", "aftward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func interact() -> void:
	var cast = ray.get_collider()
	if cast is RigidBody3D:
		object = cast
