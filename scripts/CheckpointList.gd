extends Control

var player: Node2D

func _ready():
	# Hide menu initially
	hide()
	# Get reference to player
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.show_checkpoint_menu.connect(_on_show_checkpoint_menu)
		player.checkpoint_activated.connect(_on_checkpoint_activated)

func _on_show_checkpoint_menu():
	show()
	refresh_checkpoint_list()

func refresh_checkpoint_list():
	var checkpoint_list = $CheckpointList  # Your VBoxContainer
	# Clear existing buttons
	for child in checkpoint_list.get_children():
		child.queue_free()
	
	# Add button for each checkpoint
	for checkpoint_data in player.get_checkpoint_list():
		var button = Button.new()
		button.text = checkpoint_data.name
		button.pressed.connect(_on_checkpoint_selected.bind(checkpoint_data))
		checkpoint_list.add_child(button)

func _on_checkpoint_activated(_checkpoint_data: Dictionary):
	# Only refresh if menu is visible
	if visible:
		refresh_checkpoint_list()

func _on_checkpoint_selected(checkpoint_data: Dictionary):
	hide()
	player.respawn_at_checkpoint(checkpoint_data)
