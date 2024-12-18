# GameOverScreen.gd
extends CanvasLayer

signal restart_game

@onready var restart_button =  $Control/VBoxContainer/RestartButton  # Add references to your buttons
@onready var quit_button =  $Control/VBoxContainer/QuitButton

func _ready():
	# Hide the screen initially
	hide()
	# Make sure it's in the overlay layer
	layer = 128
	# Set the entire CanvasLayer and its children to process while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Connect button signals
	restart_button.pressed.connect(_on_restart_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

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
