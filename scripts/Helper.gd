class_name Helper

static func get_animation_duration(animated_sprite: AnimatedSprite2D, animation_name: String) -> float:
	var sprite_frames = animated_sprite.sprite_frames
	if sprite_frames.has_animation(animation_name):
		var frame_count = sprite_frames.get_frame_count(animation_name)
		var fps = sprite_frames.get_animation_fps(animation_name)
		return frame_count / fps
	else:
		return 0.0
