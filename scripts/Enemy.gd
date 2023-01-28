extends Node2D

var queued_boom = false

func slide_right(columns = 1):
	var start = global_position.x
	var stop = global_position.x + (columns * 36)
	var duration = 0.1 * columns
	$Tween.interpolate_property(self, "global_position:x", start, stop, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()

func delayed_boom(delay = 0.05):
	$SquishTimer.wait_time = delay
	$SquishTimer.start()

func _on_SquishTimer_timeout():
	boom()

func boom():
	# TODO: play animation
	queue_free()


