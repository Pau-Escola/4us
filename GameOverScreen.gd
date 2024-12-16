# GameOverScreen.gd
extends CanvasLayer

signal restart_game

func _ready():
	# Hide the screen initially
	hide()
	# Make sure it's in the overlay layer
	layer = 128

func show_game_over():
	show()
	# Optional: pause the game
	get_tree().paused = true

func _on_restart_button_pressed():
	get_tree().paused = false
	restart_game.emit()
	hide()

func _on_quit_button_pressed():
	get_tree().quit()
