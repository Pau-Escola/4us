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

var current_health: int
var current_damage: int
var attacking: bool = false
var can_attack: bool = false
var target: Node2D = null
var can_dash: bool = true  # Changed from can_jump
var is_dashing: bool = false  # New dash state
var dash_direction: Vector2 = Vector2.ZERO  # Track dash direction
var facing_right: bool = true  # Track facing direction
var heal_charges: int = 3  # Current number of healing charges
var can_heal: bool = true  # Healing cooldown flag
signal died

@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var attack_area = $AttackArea if has_node("AttackArea") else null
@onready var health_display = $HealthDisplay

func _ready():
	current_health = max_health
	heal_charges = max_heal_charges
	if attack_area:
		attack_area.position.x = abs(attack_area.position.x)
	if health_display:
		health_display.target = self
		
func _physics_process(delta):
	# Get input direction
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
	
	# Handle movement
	if !is_dashing:
		if input_direction != Vector2.ZERO:
			# Accelerate in input direction
			velocity = velocity.move_toward(input_direction * move_speed, acceleration * delta)
			
			# Update sprite and hitbox facing direction
			if input_direction.x != 0:
				facing_right = input_direction.x > 0
				if sprite:
					sprite.flip_h = !facing_right
				if attack_area:
					# Flip the attack area position based on facing direction
					attack_area.position.x = abs(attack_area.position.x) * (1 if facing_right else -1)
		else:
			# Apply friction when no input
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		# During dash, maintain dash velocity
		velocity = dash_direction * dash_speed
	
	# Handle attack input
	if Input.is_action_just_pressed("attack") and target and can_attack and !attacking:
		print("Will try to attack")
		attack()
	
	# Apply movement
	move_and_slide()

func get_health() -> int:
	return current_health
	
func get_damage() -> int:
	return current_damage

func start_dash(direction: Vector2):
	if direction == Vector2.ZERO:
		# If no direction input, dash in facing direction
		direction = Vector2.RIGHT if facing_right else Vector2.LEFT
	
	is_dashing = true
	can_dash = false
	dash_direction = direction
	
	if animation_player:
		animation_player.play("dash")  # You'll need to create this animation
	
	# End dash after duration
	await get_tree().create_timer(dash_duration).timeout
	end_dash()

func end_dash():
	is_dashing = false
	velocity = Vector2.ZERO
	
	# Start cooldown
	await get_tree().create_timer(dash_cooldown - dash_duration).timeout
	can_dash = true

func attack():
	attacking = true
	can_attack = false
	
	if animation_player:
		animation_player.play("attack")
	
	print("Hero attacking with:  ", attack_damage, " damage")
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
	
	await get_tree().create_timer(attack_cooldown).timeout
	
	attacking = false
	can_attack = true

func _on_attack_hitbox_body_entered(body):
	if body.is_in_group("enemy"):
		can_attack = true
		target = body
		
func _on_attack_hitbox_body_exited(body):
	if body.is_in_group("enemy"):
		can_attack = false
		target = null

func take_damage(amount: int):
	current_health -= amount
	current_damage = -amount
	print("Player took ", amount, " damage. Health: ", current_health)
	
	if animation_player:
		animation_player.play("hurt")
	
	if current_health <= 0:
		die()
		
	await get_tree().create_timer(0.5).timeout
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
	
	if animation_player:
		animation_player.play("heal")  # You'll need to create this animation
	
	# Reset damage display after a short delay
	await get_tree().create_timer(0.5).timeout
	current_damage = 0
	
	# Start cooldown
	await get_tree().create_timer(heal_cooldown).timeout
	can_heal = true


func die():
	print("Player died!")
	died.emit()
	await get_tree().create_timer(0.1).timeout
	queue_free()
