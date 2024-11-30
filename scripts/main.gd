extends Node2D
		
func _on_player_died():
	# Handle player death
	print("Game Over!")
	
func _on_enemy_died():
	# Handle enemy death
	print("Enemy Defeated!")
