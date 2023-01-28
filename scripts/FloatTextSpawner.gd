extends Node2D

var float_text_scene = preload("res://scenes/FloatText.tscn")

export var travel: Vector2 = Vector2(0, -80)
export var duration: int = 1
export var spread: float = PI/2

func float_text(value, color) -> void:
	var float_text_instance = float_text_scene.instance()
	add_child(float_text_instance)
	float_text_instance.float_text(str(value), color, travel, duration, spread)
