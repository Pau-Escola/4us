extends Camera2D

@export var target_path: NodePath  
@export var smooth_speed: float = 5.0  
@export var zoom_level: Vector2 = Vector2(1, 1)  
var target: Node2D = null
var last_valid_position: Vector2

func _ready():
	zoom = zoom_level
	position_smoothing_enabled = true
	position_smoothing_speed = smooth_speed
	
	if not target_path.is_empty():
		target = get_node(target_path)
	else:
		target = get_tree().get_first_node_in_group("player")
	
	if target:
		last_valid_position = target.global_position
	else:
		print("Warning: Camera target not found!")

func _process(_delta):
	# Check if target exists and is still in the scene tree
	if is_instance_valid(target) and target.is_inside_tree():
		last_valid_position = target.global_position
		global_position = last_valid_position
	else:
		# If target is invalid, stay at last known position
		global_position = last_valid_position
