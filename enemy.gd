extends CharacterBody2D

# Movement variables
@export var move_speed: float = 100.0
@export var detection_radius: float = 200.0
@export var acceleration: float = 800.0
@export var path_update_interval: float = 0.5  # How often to recalculate path

# Combat variables
@export var max_health: int = 50
@export var attack_damage: int = 5
@export var attack_cooldown: float = 1.0

# Navigation variables
var path: PackedVector2Array
var path_index: int = 0
var next_path_update: float = 0.0

# State variables
var current_health: int
var current_damage: int
var can_attack: bool = true
var player: Node2D = null
var player_in_range: bool = false
var facing_right: bool = true

@onready var detection_area = $DetectionArea
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var hitbox = $Hitbox if has_node("Hitbox") else null
@onready var health_display = $HealthDisplay
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	# Configure NavigationAgent2D
	navigation_agent.path_desired_distance = 4.0
	navigation_agent.target_desired_distance = 4.0
	
	# Enable and configure avoidance
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 12.0
	navigation_agent.neighbor_distance = 50.0
	navigation_agent.max_neighbors = 10
	navigation_agent.time_horizon = 0.5
	navigation_agent.max_speed = move_speed
	navigation_agent.path_max_distance = 50.0
	
	# Connect navigation signals
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	# Initialize other components
	current_health = max_health
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = detection_radius
	$DetectionArea/CollisionShape2D.shape = circle_shape
	
	if hitbox:
		hitbox.position.x = abs(hitbox.position.x)
		
	if health_display:
		health_display.target = self

func _physics_process(delta):
	if player:
		# Update navigation path periodically
		if Time.get_ticks_msec() > next_path_update:
			update_navigation_path()
			next_path_update = Time.get_ticks_msec() + (path_update_interval * 1000)
		
		if not navigation_agent.is_navigation_finished():
			var next_path_position = navigation_agent.get_next_path_position()
			var direction = (next_path_position - global_position).normalized()
			
			# Calculate desired velocity
			var desired_velocity = direction * move_speed
			
			if navigation_agent.avoidance_enabled:
				navigation_agent.set_velocity(desired_velocity)
			else:
				_on_velocity_computed(desired_velocity)
			
			# Update facing direction
			facing_right = direction.x > 0
			if sprite:
				sprite.flip_h = !facing_right
			if hitbox:
				hitbox.position.x = abs(hitbox.position.x) * (1 if facing_right else -1)
			
			# Attack if in range
			if player_in_range and can_attack:
				attack(player)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	
	move_and_slide()

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = velocity.move_toward(safe_velocity, acceleration * get_physics_process_delta_time())

func update_navigation_path():
	if player:
		navigation_agent.target_position = player.global_position

func get_health() -> int:
	return current_health

func get_damage() -> int:
	return current_damage

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		print("Player detected!")
		player = body
		update_navigation_path()

func _on_detection_area_body_exited(body):
	if body == player:
		print("Player lost!")
		player = null
		path = PackedVector2Array()

func _on_hitbox_area_entered(body):
	if body.is_in_group("player"):
		print("Player in attack range")
		player_in_range = true

func _on_hitbox_area_exited(body):
	if body.is_in_group("player"):
		print("Player left attack range")
		player_in_range = false

func attack(target):
	can_attack = false
	
	if animation_player:
		animation_player.play("attack")
	
	print("Enemy attacking player for ", attack_damage, " damage")
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int):
	current_health -= amount
	current_damage = -amount
	print("Enemy took ", amount, " damage. Health: ", current_health)
	
	if animation_player:
		animation_player.play("hurt")
	
	if current_health <= 0:
		die()
	await get_tree().create_timer(0.5).timeout
	current_damage = 0

func die():
	print("Enemy died!")
	queue_free()
