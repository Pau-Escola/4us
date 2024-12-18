extends Camera2D

@export var target_path: NodePath  # Set this in the editor to point to your player
@export var smooth_speed: float = 5.0  # Lower = smoother, higher = more responsive
@export var zoom_level: Vector2 = Vector2(1, 1)  # Camera zoom
@export var max_offset: Vector2 = Vector2(100, 100)  # Maximum camera offset from player

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

func _process(delta):
	if target:
		# Get target position
		var target_pos = target.global_position
		
		# Get mouse position in world coordinates
		var mouse_pos = get_global_mouse_position()
		
		# Calculate offset based on mouse position
		var offset = (mouse_pos - target_pos) * 0.2
		offset.x = clamp(offset.x, -max_offset.x, max_offset.x)
		offset.y = clamp(offset.y, -max_offset.y, max_offset.y)
		
		# Set camera position with smooth follow
		global_position = target_pos + offset
