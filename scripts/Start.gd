extends Control


func _on_Button_pressed():
	$Tween.interpolate_property($Button, "rect_position:y", 64, 512, 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()

func _on_Tween_tween_all_completed():
	# TODO: play dust animation
	$Timer.start()


func _on_Timer_timeout():
	get_tree().change_scene("res://scenes/Game.tscn")
