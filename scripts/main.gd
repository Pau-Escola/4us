extends Node2D

@onready var player = $Player
@onready var game_over_screen = $gameOverScreen  # Add this

func _ready():
	# Connect to the restart signal when the scene starts
	game_over_screen.restart_game.connect(_on_restart_game)
	player.died.connect(_on_player_died)

func _on_player_died():
	# Show the game over screen instead of just printing
	game_over_screen.show_game_over()
	
func _on_restart_game():
	# Reload the current scene
	get_tree().reload_current_scene()
	
func _on_enemy_died():
	print("Enemy Defeated!")
