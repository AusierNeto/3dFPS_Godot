extends CharacterBody3D

const MOUSE_SENSITIVITY:float = 0.002
const SPEED:float = 5.0
const JUMP_VELOCITY:float = 4.5

# --- Animation ---
const SWAY_AMOUNT = 0.05       # O quanto a arma balança (Amplitude)
const SWAY_FREQ = 10.0         # Velocidade do balanço (Frequência)
const RECOIL_AMOUNT = 0.3      # O quanto a arma vai pra trás no tiro
const RECOIL_RETURN_SPEED = 5.0 # Quão rápido ela volta ao normal

@onready var head = $Head
@onready var arms = $Head/Arms
@onready var ray_cast = $Head/Camera3D/RayCast3D
@onready var gun_sound = $Head/GunShot
@onready var gun_particles = $Head/MuzzleFlash

var weapon_damage: int = 25 # 4 tiros para matar (100 / 25)
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var default_hand_position: Vector3

func _ready() -> void:
	# Faz com que o mouse fique preso à camera
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("Arms position", arms.position)
	default_hand_position = arms.position
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-60), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	# Jumping and vertical movement
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# WASD Movement
	var input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var normalized_direction = (transform.basis * Vector3(input_direction.x, 0, input_direction.y))

	if normalized_direction:
		velocity.x = normalized_direction.x * SPEED
		velocity.z = normalized_direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	
	if Input.is_action_just_pressed("shoot"):
		fire_weapon()
	process_weapon_animation(delta, input_direction)
	
func process_weapon_animation(delta, input_direction):
	# Parte A: Recoil Recovery (Voltar ao normal)
	# Usamos lerp para mover da posição atual (que pode estar recuada) para a original
	arms.position = arms.position.lerp(default_hand_position, delta * RECOIL_RETURN_SPEED)
	
	# Head Bobbing
	
func fire_weapon():
	gun_sound.play()
	
	gun_particles.restart()
	gun_particles.emitting=true
	
	# recoil animation
	arms.position.z += 0.2
	#arms.rotation.x += 0.1
	
	if ray_cast.is_colliding():
		var target = ray_cast.get_collider()
		var hit_point = ray_cast.get_collision_point()		
		print("Target: ", target, " Hit Point: ", hit_point)
		if target.has_method("take_damage"):
			target.take_damage(weapon_damage)
			
			# Opcional: Criar partícula de sangue no ponto de impacto
			# create_blood_effect(raycast.get_collision_point())
		else:
			# Acertou parede/chão
			# create_bullet_hole(raycast.get_collision_point())
			pass
	else:
		print("OFF")
