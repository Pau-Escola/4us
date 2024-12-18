# Checkpoint.gd
extends Area2D

var activated = false
var can_activate = false
@onready var sprite = $Sprite2D  # Assuming you'll add a sprite

func _ready():
	# Connect the collision detection signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):
	if can_activate and Input.is_action_just_pressed("activate_checkpoint") and !activated:
		activate_checkpoint()

func activate_checkpoint():
	activated = true
	# Instead of emitting a signal, directly call the player's function
	if can_activate and is_instance_valid(current_player):
		current_player._on_checkpoint_activated(global_position)
	# Change appearance to show it's activated/broken
	if sprite:
		sprite.modulate = Color.DARK_GRAY
	
var current_player = null

func _on_body_entered(body):
	if body.is_in_group("player"):
		can_activate = true
		current_player = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		can_activate = false
		current_player = null
