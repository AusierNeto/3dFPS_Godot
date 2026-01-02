extends CharacterBody3D

# --- CONFIGURAÇÕES ---
const SPEED = 2.0
const ATTACK_RANGE = 1.5 # Distância para começar a atacar
const DAMAGE_DELAY = 0.8 # Tempo até o dano ser aplicado na animação (aprox frame 20 de 30)

# --- ESTADOS ---
enum {CHASE, ATTACK, DEAD}
var state = CHASE

# --- REFERÊNCIAS ---
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player = $square_zombie/AnimationPlayer 

var player = null

# --- STATUS ---
var max_health = 100
var current_health = 100
var is_dead = false # Variável de controle extra para segurança

func _ready():
	player = get_tree().get_first_node_in_group("player")
	current_health = max_health
	
	# Conecta o sinal para saber quando uma animação acaba
	# Isso é vital para saber quando o ataque terminou
	anim_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# Gravidade sempre se aplica
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Se morreu, não faz mais nada de movimento
	if state == DEAD:
		move_and_slide() # Apenas cai com gravidade
		return

	if not player: return

	match state:
		CHASE:
			_process_chase(delta)
		ATTACK:
			_process_attack(delta)

	move_and_slide()

# --- LÓGICA DE PERSEGUIÇÃO ---
func _process_chase(delta):
	# 1. Define destino
	nav_agent.target_position = player.global_position
	
	# 2. Verifica distância para ATACAR
	# distance_to é mais preciso que nav_agent.is_target_reached() para combate
	var dist = global_position.distance_to(player.global_position)
	
	if dist <= ATTACK_RANGE:
		enter_attack_state()
	else:
		# Movimento normal
		var next = nav_agent.get_next_path_position()
		var dir = (next - global_position).normalized()
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		
		look_at(Vector3(next.x, global_position.y, next.z), Vector3.UP)
		anim_player.play("Walk")

# --- LÓGICA DE ATAQUE ---
func _process_attack(delta):
	velocity.x = 0
	velocity.z = 0
	# O zumbi deve olhar para o player enquanto ataca?
	# Se sim, descomente a linha abaixo:
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

func enter_attack_state():
	state = ATTACK
	anim_player.play("Attack")
	# Aqui você poderia adicionar um Timer ou verificar frame para causar dano ao player

# --- EVENTOS ---
func _on_animation_finished(anim_name):
	if anim_name == "Attack":
		# Se o player ainda estiver perto, ataca de novo. Se não, volta a perseguir.
		if global_position.distance_to(player.global_position) <= ATTACK_RANGE:
			anim_player.play("Attack")
		else:
			state = CHASE

# --- SISTEMA DE DANO ---
func take_damage(damage_amount):
	if state == DEAD or is_dead:
		return # Chutar cachorro morto não adianta

	current_health -= damage_amount
	print("Zumbi atingido! Vida restante: ", current_health) # Debug útil

	if current_health <= 0:
		die()
	else:
		# Opcional: Aqui você pode tocar um som de "Grunhido de dor"
		# ou fazer uma pequena animação de recuo (flinch)
		pass

func die():
	if is_dead: return
	is_dead = true
	state = DEAD
	
	# Para o movimento imediatamente
	velocity = Vector3.ZERO
	
	# Toca a animação de morte
	anim_player.play("Death")
	
	# Opcional: Sumir com o corpo após 10 segundos
	await get_tree().create_timer(5.0).timeout
	queue_free()
