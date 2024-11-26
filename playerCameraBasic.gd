extends Camera2D

@export var target_path: NodePath  # Set this in the editor to point to your player
@export var smooth_speed: float = 5.0  # Lower = smoother, higher = more responsive
@export var zoom_level: Vector2 = Vector2(1, 1)  # Camera zoom

var target: Node2D = null

func _ready():
	# Set up initial camera properties
	zoom = zoom_level
	position_smoothing_enabled = true
	position_smoothing_speed = smooth_speed
	
	# Get the target (player) node
	if not target_path.is_empty():
		target = get_node(target_path)
	else:
		# Try to find the player in the scene
		target = get_tree().get_first_node_in_group("player")
	
	if not target:
		print("Warning: Camera target not found!")

func _process(_delta):
	if target:
		# Simply follow the target's position
		global_position = target.global_position
