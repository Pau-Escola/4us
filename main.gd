extends Node2D

@onready var player = $Player
@onready var enemy = $Enemy

func _ready():
	# Set initial positions
	player.position = Vector2(100, 180) # Left side of screen
	enemy.position = Vector2(540, 180) # Right side of screen
	
	# Create a simple boundary to keep characters in the play area
	create_boundary()

func create_boundary():
	# Create walls at the edges of the screen
	var walls = [
		{"pos": Vector2(320, -16), "size": Vector2(640, 32)},  # Top
		{"pos": Vector2(320, 376), "size": Vector2(640, 32)},  # Bottom
		{"pos": Vector2(-16, 180), "size": Vector2(32, 360)},   # Left
		{"pos": Vector2(656, 180), "size": Vector2(32, 360)}   # Right
	]
	
	for wall_data in walls:
		var wall = StaticBody2D.new()
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		
		shape.size = wall_data["size"]
		collision.shape = shape
		wall.position = wall_data["pos"]
		
		wall.add_child(collision)
		add_child(wall)
		
func _on_player_died():
	# Handle player death
	print("Game Over!")
	
func _on_enemy_died():
	# Handle enemy death
	print("Enemy Defeated!")
