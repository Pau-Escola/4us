extends CharacterBody2D
# Movement variables
@export var move_speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1000.0
@export var dash_speed: float = 500.0  # New dash variables
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

# Combat variables
@export var max_health: int = 100
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.5

# Healing variables
@export var heal_amount: int = 30
@export var heal_cooldown: float = 5.0
@export var max_heal_charges: int = 3


enum Direction {N, S, E, W}
enum AnimationState { IDLE, WALKING, ATTACKING, HURT, DEAD, DASHING }
var current_health: int
var current_damage: int
var attacking: bool = false
var target: Node2D = null
var can_dash: bool = true  # Changed from can_jump
var is_dashing: bool = false  # New dash state
var dash_direction: Vector2 = Vector2.ZERO  # Track dash direction
var facing_direction: Direction = Direction.E  # Track facing direction
var heal_charges: int = 3  # Current number of healing charges
var can_heal: bool = true  # Healing cooldown flag
var spawn_position: Vector2
var last_checkpoint_position: Vector2 = Vector2.ZERO
var current_animation_state = AnimationState.IDLE
var original_hitbox_position: Vector2
var is_dying: bool = false
var is_respawning: bool = false
var activated_checkpoints: Array = []
signal checkpoint_activated(checkpoint_data: Dictionary)
signal died
signal show_checkpoint_menu

@onready var sprite = $AnimatedSprite2D
@onready var attack_area = $AttackArea if has_node("AttackArea") else null
@onready var health_display = $HealthDisplay

func _ready():
	current_health = max_health
	heal_charges = max_heal_charges
	spawn_position = global_position
	original_hitbox_position = attack_area.position
	if attack_area:
		attack_area.position.x = abs(attack_area.position.x)
	if health_display:
		health_display.target = self
		
func _physics_process(delta):
	# Get input direction
	if current_animation_state == AnimationState.DEAD or is_dying or is_respawning:
		return
	var input_direction = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	
	# Handle dash input
	if Input.is_action_just_pressed("dash") and can_dash and !is_dashing:  # Space bar
		start_dash(input_direction)
		
	# Handle healing input
	if Input.is_action_just_pressed("heal") and can_heal and heal_charges > 0:
		heal()
	
	# Handle attack input
	if Input.is_action_just_pressed("attack") and !attacking:
		print("Will try to attack")
		attack()
		
	# Handle movement
	if !is_dashing:
		if input_direction != Vector2.ZERO:
			# Accelerate in input direction
			velocity = velocity.move_toward(input_direction * move_speed, acceleration * delta)
			facing_direction = update_direction(input_direction)
			update_hitbox()
			if current_animation_state == AnimationState.WALKING or current_animation_state == AnimationState.IDLE:
				sprite.play("walk_"+ direction_to_str())
				
		else:
			# Apply friction when no input
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
			if current_animation_state == AnimationState.WALKING or current_animation_state == AnimationState.IDLE:
				sprite.play("idle_"+ direction_to_str())
	else:
		# During dash, maintain dash velocity
		velocity = dash_direction * dash_speed
	# Apply movement
	move_and_slide()
	

func get_health() -> int:
	return current_health

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
	

func update_direction(input_direction: Vector2) -> Direction:
	
	if input_direction.x != 0 or input_direction.y != 0:
			if abs(input_direction.x) >= abs(input_direction.y):
				return Direction.E if input_direction.x > 0 else Direction.W
			else:
				return Direction.S if input_direction.y > 0 else Direction.N
	else:
		return facing_direction
	
func get_damage() -> int:
	return current_damage

func update_hitbox():
	match facing_direction:
		Direction.E:
			attack_area.position.x = abs(original_hitbox_position.x)
			attack_area.position.y = original_hitbox_position.y
			attack_area.rotation = 0  # No rotation for East
		Direction.W:
			attack_area.position.x = abs(original_hitbox_position.x) * -1
			attack_area.position.y = original_hitbox_position.y
			attack_area.rotation = 0  # No rotation for West
		Direction.N:
			attack_area.position.x = abs(original_hitbox_position.y)
			attack_area.position.y = abs(original_hitbox_position.x + 3) * -1
			attack_area.rotation = deg_to_rad(90)
		Direction.S:
			attack_area.position.x = abs(original_hitbox_position.y)
			attack_area.position.y = abs(original_hitbox_position.x + 1)
			attack_area.rotation = deg_to_rad(-90)
			
func start_dash(direction: Vector2):
	if direction == Vector2.ZERO:
		# If no direction input, dash in facing direction
		direction = get_correct_vector()
	
	is_dashing = true
	can_dash = false
	dash_direction = direction
	current_animation_state = AnimationState.DASHING
	sprite.play("dash_"+ direction_to_str())
	# End dash after duration
	await get_tree().create_timer(dash_duration).timeout
	end_dash()

func get_correct_vector() -> Vector2:
	match facing_direction:
		Direction.E:
			return Vector2.RIGHT
		Direction.W:
			return Vector2.LEFT
		Direction.N:
			return Vector2.UP
		Direction.S:
			return Vector2.DOWN
		_:
			return Vector2.RIGHT
		
		

func end_dash():
	is_dashing = false
	velocity = Vector2.ZERO
	
	# Start cooldown
	await get_tree().create_timer(dash_cooldown - dash_duration).timeout
	current_animation_state = AnimationState.IDLE
	can_dash = true

func attack():
	attacking = true
	current_animation_state = AnimationState.ATTACKING
	sprite.play("attack_"+ direction_to_str())
	print("Hero attacking with:  ", attack_damage, " damage")
	if target && target.has_method("take_damage"):
		target.take_damage(attack_damage)
		
	await sprite.animation_finished
	attacking = false
	current_animation_state = AnimationState.IDLE

func _on_attack_hitbox_body_entered(body):
	if body.is_in_group("enemy"):
		target = body
		
func _on_attack_hitbox_body_exited(body):
	if body.is_in_group("enemy"):
		target = null
		
func _on_checkpoint_activated(checkpoint: Checkpoint):
	activated_checkpoints.append(checkpoint)
	checkpoint_activated.emit(checkpoint)
	print("Checkpoint activated: ", checkpoint.checkpoint_name)
	print ("Position of checkpoint: ", checkpoint.position)
	print ("Global position of checkpoint: ", checkpoint.global_position)
	

func take_damage(amount: int):
	if current_animation_state == AnimationState.DEAD or is_dying or is_respawning:
		return
	current_health -= amount
	current_damage = -amount
	print("Player took ", amount, " damage. Health: ", current_health)
	current_animation_state = AnimationState.HURT
	sprite.play("hurt_"+ direction_to_str())
	
	if current_health <= 0:
		die()
		return
		
	await sprite.animation_finished
	current_animation_state = AnimationState.IDLE
	current_damage = 0
	
func heal():
	if current_health >= max_health:
		print("Health is already full!")
		return
		
	can_heal = false
	heal_charges -= 1
	
	# Calculate healing amount, but don't exceed max_health
	var actual_heal_amount = min(heal_amount, max_health - current_health)
	current_health += actual_heal_amount
	current_damage = actual_heal_amount  # Show healing amount in health display
	
	print("Player healed for ", actual_heal_amount, " HP. Charges remaining: ", heal_charges)
	  # You'll need to create this animation
	
	# Reset damage display after a short delay
	await get_tree().create_timer(0.5).timeout
	current_damage = 0
	
	# Start cooldown
	await get_tree().create_timer(heal_cooldown).timeout
	can_heal = true


func die():
	if activated_checkpoints.size() > 0:
		current_animation_state = AnimationState.DEAD
		set_physics_process(false)
		sprite.play("dead_" + direction_to_str())
		await sprite.animation_finished
		get_tree().paused = true
		show_checkpoint_menu.emit()
	else:
		start_death()

func respawn_at_checkpoint(checkpoint_data: Checkpoint):
	get_tree().paused = false
	is_respawning = true
	# Reset player state
	current_health = max_health
	heal_charges = max_heal_charges
	velocity = Vector2.ZERO
	
	# Move to selected checkpoint
	global_position = checkpoint_data.global_position
	
	# Update checkpoint visuals
	for i in range(activated_checkpoints.size()):
		var checkpoint = activated_checkpoints[i]
		if checkpoint.position == checkpoint_data.position:
			checkpoint.mark_as_used()
			activated_checkpoints.remove_at(i)
	
	# Reset animation and enable physics
	current_animation_state = AnimationState.IDLE
	sprite.play("idle_" + direction_to_str())
	set_physics_process(true)
	is_respawning = false

func get_checkpoint_list() -> Array:
	return activated_checkpoints

func start_death():
	print("Final death - no checkpoint")
	is_dying = true
	current_animation_state = AnimationState.DEAD
	
	# Disable all processing
	set_physics_process(false)
	set_process(false)
	
	# Disable all collision shapes
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
	
	# Disable attack area
	if attack_area:
		attack_area.monitoring = false
		attack_area.monitorable = false
	
	# Clear all velocities
	velocity = Vector2.ZERO
	
	# Play death animation and wait for it to finish
	sprite.play("dead_" + direction_to_str())
	await sprite.animation_finished
	
	# Emit signal and remove player
	died.emit()
	queue_free()
