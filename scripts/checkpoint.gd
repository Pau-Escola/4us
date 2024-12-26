class_name Checkpoint
extends Area2D

@export var texture_unactive: Texture2D
@export var texture_active: Texture2D
@export var texture_used: Texture2D

var checkpoint_name: String  # Added for menu identification
var adjectives = ["Hidden", "Ancient", "Mystic", "Crystal", "Shadow", "Forest", "Mountain", "Cave", "River", "Sacred"]
var nouns = ["Sanctuary", "Gateway", "Portal", "Haven", "Refuge", "Waypoint", "Pinnacle", "Passage", "Anchor", "Beacon"]
var activated = false
var can_activate = false
var used = false
@onready var sprite = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.texture = texture_unactive
	var random_adjective = adjectives[randi() % adjectives.size()]
	var random_noun = nouns[randi() % nouns.size()]
	checkpoint_name = random_adjective + " " + random_noun
	add_to_group("checkpoint")

func _process(_delta):
	if can_activate and Input.is_action_just_pressed("activate_checkpoint") and !activated:
		activate_checkpoint()

func activate_checkpoint():
	activated = true
	if can_activate and is_instance_valid(current_player):
		current_player._setStateToPray()
		current_player.sprite.play("pray_"+ current_player.direction_to_str())
		await current_player.sprite.animation_finished
		current_player._setStateToIdle()
		current_player._on_checkpoint_activated(self)
	sprite.texture = texture_active

var current_player = null

func mark_as_used():
	used = true
	sprite.texture = texture_used

func _on_body_entered(body):
	if body.is_in_group("player") and !used:
		can_activate = true
		current_player = body

func _on_body_exited(body):
	if body.is_in_group("player"):
		can_activate = false
		current_player = null
