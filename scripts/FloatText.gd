extends Label


func float_text(value: String, color: Color, travel: Vector2, duration: int, spread: float):
	# Set the text value and color
	text = value
	set("custom_colors/font_color", color)
	# For scaling, set the pivot offset to the center
	rect_pivot_offset = rect_size / 2
	var movement: Vector2 = travel.rotated(rand_range(-spread/2, spread/2))
	# Animate the position
	$Tween.interpolate_property(self, "rect_position", rect_position,
			rect_position + movement, duration,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	# Animate the fade-out
	$Tween.interpolate_property(self, "modulate:a", 1.0, 0.0, duration,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	queue_free()
