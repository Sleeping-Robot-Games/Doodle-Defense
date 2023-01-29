extends Control


func _ready():
	g.play_bgm(false)

func _on_Button_pressed():
	get_tree().change_scene("res://scenes/Game.tscn")
