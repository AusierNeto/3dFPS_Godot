extends CharacterBody3D

const MOUSE_SENSITIVITY:float = 0.002
const SPEED:float = 5.0
const JUMP_VELOCITY:float = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@onready var ray_cast = $Head/Camera3D/RayCast3D
@onready var gun_sound = $Head/GunShot
@onready var gun_particles = $Head/MuzzleFlash

func _ready() -> void:
	# Faz com que o mouse fique preso à camera
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-60), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("shoot"):
		fire_weapon()
		
	var input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var normalized_direction = (transform.basis * Vector3(input_direction.x, 0, input_direction.y))

	if normalized_direction:
		velocity.x = normalized_direction.x * SPEED
		velocity.z = normalized_direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
func fire_weapon():
	gun_sound.play()
	
	gun_particles.restart()
	gun_particles.emitting=true
	
	if ray_cast.is_colliding():
		var target = ray_cast.get_collider()
		var hit_point = ray_cast.get_collision_point()		
		print("Target: ", target, " Hit Point: ", hit_point)
	else:
		print("OFF")
