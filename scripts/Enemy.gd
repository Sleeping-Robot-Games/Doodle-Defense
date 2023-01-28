extends Node2D

var queued_boom = false
var flyer = false
var type = ""
var frozen = true

func _ready():
	type = 'air' if flyer else 'ground'
	play_move_animation()
	$Unfreeze.wait_time = get_parent().get_parent().SPAWN_TIME / 2
	$Unfreeze.start()

func slide_right(columns = 1):
	var start = global_position.x
	var stop = global_position.x + (columns * 36)
	var duration = 0.1 * columns
	$Tween.interpolate_property(self, "global_position:x", start, stop, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()

func delayed_boom(delay = 0.05):
	## TODO: Check if air or ground
	$SquishTimer.wait_time = delay
	$SquishTimer.start()

func play_move_animation():
	$Sprite/AnimationPlayer.play(type + "Move")
	
func play_attack_animation():
	$Sprite/AnimationPlayer.play(type + "Hit")

func _on_SquishTimer_timeout():
	boom()

func boom():
	# TODO: play animation
	queue_free()

func _on_AnimationPlayer_animation_finished(anim_name):
	if 'Hit' in anim_name:
		play_move_animation()


func _on_Unfreeze_timeout():
	frozen = false
