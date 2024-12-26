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

enum Direction { N, S, E, W }
enum AnimationState { IDLE, WALKING, ATTACKING, HURT, DEAD }

# State variables
var current_health: int
var current_damage: int
var can_attack: bool = true
var player: Node2D = null
var player_in_range: bool = false
var facing_right: bool = true
var facing_direction: Direction = Direction.E 
var current_animation_state = AnimationState.IDLE
var original_hitbox_position: Vector2
var is_dying: bool = false

@onready var detection_area = $DetectionArea
@onready var sprite = $AnimatedSprite2D
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
	original_hitbox_position = hitbox.position

func _physics_process(delta):
	if current_animation_state == AnimationState.DEAD or is_dying:
		return
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
			facing_direction = update_direction(direction)
			update_hitbox()
			
			# Attack if in range
			if player_in_range and can_attack:
				attack(player)
			if current_animation_state == AnimationState.WALKING or current_animation_state == AnimationState.IDLE:
				sprite.play("walk_"+ direction_to_str())
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		if current_animation_state == AnimationState.WALKING or current_animation_state == AnimationState.IDLE:
			sprite.play("idle_"+ direction_to_str())
	move_and_slide()

func update_direction(input_direction: Vector2) -> Direction:
	if input_direction.x != 0 or input_direction.y != 0:
			if abs(input_direction.x) >= abs(input_direction.y):
				return Direction.E if input_direction.x > 0 else Direction.W
			else:
				return Direction.S if input_direction.y > 0 else Direction.N
	else:
		return facing_direction
		
func update_hitbox():
	match facing_direction:
		Direction.E:
			hitbox.position.x = abs(original_hitbox_position.x)
			hitbox.position.y = original_hitbox_position.y
			hitbox.rotation = 0  # No rotation for East
		Direction.W:
			hitbox.position.x = abs(original_hitbox_position.x) * -1
			hitbox.position.y = original_hitbox_position.y
			hitbox.rotation = 0  # No rotation for West
		Direction.N:
			hitbox.position.x = abs(original_hitbox_position.y)
			hitbox.position.y = abs(original_hitbox_position.x + 3) * -1
			hitbox.rotation = deg_to_rad(90)
		Direction.S:
			hitbox.position.x = abs(original_hitbox_position.y)
			hitbox.position.y = abs(original_hitbox_position.x + 1)
			hitbox.rotation = deg_to_rad(-90)

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
	if current_animation_state != AnimationState.DEAD:
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
	current_animation_state = AnimationState.ATTACKING
	sprite.play("attack_basic_" + direction_to_str())
	
	print("Enemy attacking player for ", attack_damage, " damage")
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	
	await sprite.animation_finished
	current_animation_state = AnimationState.IDLE
	can_attack = true

func take_damage(amount: int):
	current_health -= amount
	current_damage = -amount
	print("Enemy took ", amount, " damage. Health: ", current_health)
	print(current_animation_state)
	current_animation_state = AnimationState.HURT
	sprite.play("hurt_" + direction_to_str())
	
	if current_health <= 0:
		die()
	await sprite.animation_finished
	current_animation_state = AnimationState.IDLE
	current_damage = 0

func die():
	print("Enemy died!")
	is_dying = true  # Set the dying flag
	current_animation_state = AnimationState.DEAD    
		# Disable physics processing and collisions
	set_physics_process(false)
	set_process(false)
		
		# Disable collision shapes
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
	
	# Disable areas
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false
	
	# Clear any remaining signals
	if detection_area.is_connected("body_entered", Callable(self, "_on_detection_area_body_entered")):
		detection_area.disconnect("body_entered", Callable(self, "_on_detection_area_body_entered"))
	if detection_area.is_connected("body_exited", Callable(self, "_on_detection_area_body_exited")):
		detection_area.disconnect("body_exited", Callable(self, "_on_detection_area_body_exited"))
	
	# Stop all movement
	velocity = Vector2.ZERO
	if navigation_agent:
		navigation_agent.set_velocity_forced(Vector2.ZERO)
	
	# Play death animation
	sprite.play("dead_" + direction_to_str())
	
	# Queue free after animation
	await sprite.animation_finished
	queue_free()
	
func direction_to_str() -> String:
	match facing_direction:
		Direction.E:
			return "E"
		Direction.W:
			return "W"
		Direction.N:
			return "N"
		Direction.S:
			return "S"
		_:
			return "S"
