extends Node2D

@onready var health_label = $HealthBar
@onready var damage_label = $DamageBar
var target: Node2D  # The character this health display follows

# Offset from the character's position (how high above the character)
@export var offset: Vector2 = Vector2(0, -50)



func _process(_delta):
	# Update position to follow target
	global_position = target.global_position + offset
	
	# Update health display if target has current_health
	if target and target.has_method("get_health"):
		health_label.text = str(target.get_health())
		damage_label.text = str(target.get_damage())
	elif target and "current_health" in target:
		health_label.text = str(target.current_health)
		damage_label.text = str(target.current_damage)
	
