extends Control

var player: Node2D

func _ready():
	# Hide menu initially
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Get reference to player
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.show_checkpoint_menu.connect(_on_show_checkpoint_menu)
		player.checkpoint_activated.connect(_on_checkpoint_activated)
	custom_minimum_size = Vector2(200, 200)

func _on_show_checkpoint_menu():
	var viewport_rect = get_viewport_rect()
	position = viewport_rect.size / 2 - size / 2
	show()
	refresh_checkpoint_list()

func refresh_checkpoint_list():
	var checkpoint_list = $CheckpointList  # Your VBoxContainer
	# Clear existing buttons
	for child in checkpoint_list.get_children():
		child.queue_free()
	
	# Add button for each checkpoint
	for checkpoint_data in player.get_checkpoint_list():
		if checkpoint_data is Checkpoint:
			var button = Button.new()
			button.text = checkpoint_data.checkpoint_name
			button.custom_minimum_size.x = 180
			button.set_meta("checkpoint_data", checkpoint_data) 
			button.pressed.connect(_on_checkpoint_selected.bind(checkpoint_data))
			checkpoint_list.add_child(button)

func _on_checkpoint_activated(_checkpoint_data: Checkpoint):
	# Only refresh if menu is visible
	if visible:
		refresh_checkpoint_list()

func _on_checkpoint_selected(checkpoint_data: Checkpoint):
	print("Checkpoint selected:", checkpoint_data)  # Debug print
	hide()
	print ("Checkpointdata has position")
	player.respawn_at_checkpoint(checkpoint_data)
