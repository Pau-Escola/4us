# GameOverScreen.gd
extends CanvasLayer

signal restart_game

@onready var restart_button =  $Control/VBoxContainer/RestartButton  # Add references to your buttons
@onready var quit_button =  $Control/VBoxContainer/QuitButton
@onready var continue_button =  $Control/VBoxContainer/ContinueButton
@onready var menu_title =  $Control/VBoxContainer/Label
@onready var control = $Control

var hidden: bool = true

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
	
func _physics_process(delta):
	if Input.is_action_just_pressed("show_menu") and hidden:
		print("input detected")
		show_game_menu(false)

func show_game_menu(isPlayerDead: bool):
	show()
	if !isPlayerDead :
		menu_title.text = "Game Menu"
		continue_button.show()
	else:
		menu_title.text = "Game Over"
		continue_button.hide()
	hidden = false
	var viewport_rect = control.get_viewport_rect()
	control.position = viewport_rect.size / 2 - control.size / 2
	# Optional: pause the game
	get_tree().paused = true

func _on_restart_button_pressed():
	get_tree().paused = false
	restart_game.emit()
	hide()
	hidden = true

func _on_quit_button_pressed():
	get_tree().quit()

func _on_continue_button_pressed():
	get_tree().paused = false
	hide()
	hidden = true
