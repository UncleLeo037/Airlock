extends RigidBody3D

const SPEED : float = 5.0
const JUMP_VELOCITY : float = 5.0

@export var SENSITIVITY : float = 0.08

@onready var head : CollisionShape3D = $CollisionShape3D
@onready var camera : Camera3D = $CollisionShape3D/Camera3D
@onready var shape : RayCast3D = $CollisionShape3D/Array/Down #redo to use node array for better coverage
@onready var ray : RayCast3D = $CollisionShape3D/Camera3D/RayCast3D
@onready var mark : Marker3D = $CollisionShape3D/Camera3D/Marker3D

var object : CollisionObject3D
var max_jitter : int = 50

func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	#mouse mode is being used like bool for if player is controlable or in menu
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

#called 2nd in input stack
#func _input(event: InputEvent) -> void:
	#if not is_multiplayer_authority(): return

#called 7th in input stack
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event.is_action_pressed("interact"):
		interact()
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY))
		camera.rotate_x(deg_to_rad(-event.relative.y * SENSITIVITY))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	if ray.get_collider() is RigidBody3D:
		$HUD/prompt.show()
	else:
		$HUD/prompt.hide()
	
	move()
	
	if object:
		force()


func move() -> void:
	# Handle jump.
	if Input.is_action_just_pressed("jump") and shape.is_colliding():
		if shape.get_collider() != object:
			linear_velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		linear_velocity.x = direction.x * SPEED
		linear_velocity.z = direction.z * SPEED
	else:
		linear_velocity.x = move_toward(linear_velocity.x, 0, SPEED)
		linear_velocity.z = move_toward(linear_velocity.z, 0, SPEED)


func force() -> void:
	if head.global_transform.origin.distance_to(object.global_transform.origin) > object.mass:
			interact()
	else:
		var a : Vector3 = object.global_transform.origin
		var b : Vector3 = mark.global_transform.origin
		var diff : Vector3 = (b-a)*10#*object.mass #adjust the multiplier here
		diff = diff.clamp(-Vector3.ONE*10, Vector3.ONE*10)
		object.linear_damp = 30 - diff.length()
		if shape.get_collider() == object:
			diff.y = 0
		object.apply_impulse(diff)
		#will have to replace following with better rotation code
		#object.rotation.x = camera.rotation.x
		#object.rotation.y = head.rotation.y
		#object.rotation.z = 0


func interact() -> void:
	if object:
		#object.set_collision_layer_value(1, true)
		object.linear_damp = 0
		object = null
	elif ray.get_collider() is RigidBody3D:
		var cast : CollisionObject3D = ray.get_collider()
		object = cast
		#object.set_collision_layer_value(1, false)
