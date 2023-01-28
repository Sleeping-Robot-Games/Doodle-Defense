extends Node2D

var queued_boom = false
var queued_drop = 0

func set_color(color):
	$Sprite.modulate = color
	$Shatter.modulate = color

func drop(rows):
	var start = global_position.y
	var stop = global_position.y + (rows * 36)
	var duration = 0.05 * rows
	$Tween.interpolate_property(self, "global_position:y", start, stop, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()

func queue_drop(num):
	queued_drop += num

func trigger_queued_drop():
	drop(queued_drop)
	queued_drop = 0

func delayed_boom(delay = 0.2):
	$AttackedTimer.wait_time = delay
	$AttackedTimer.start()

func _on_AttackedTimer_timeout():
	boom()

func boom():
	play_shatter_animation()

func play_shatter_animation():
	$Sprite.visible = false
	$Shatter.visible = true
	$Shatter/AnimationPlayer.play("shatter")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == 'shatter':
		queue_free()
