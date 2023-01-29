extends Node

var BGM = null
var rng = RandomNumberGenerator.new()

func play_bgm(game_over: bool):
	var music_player = AudioStreamPlayer.new()
	music_player.volume_db = -10
	if game_over:
		music_player.stream = load("res://assets/sfx/cat_and_tower.mp3")
	else:
		music_player.stream = load("res://assets/sfx/BGM_cat_tower.mp3")
	call_deferred('add_child', music_player)
	music_player.play()
	BGM = music_player
 
func stop_bgm():
	BGM.queue_free()

func play_sfx(sound, db_override = -10):
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = db_override
	if sound == "menu_select":
		sfx_player.stream = load("res://assets/sfx/sound.wav")
	elif 'death' in sound:
		rng.randomize()
		var track_num = rng.randi_range(1, 3)
		sfx_player.stream = load('res://assets/sfx/'+sound+str(track_num)+'.mp3')
	else:
		sfx_player.stream = load('res://assets/sfx/'+sound+'.mp3')
	sfx_player.connect("finished", sfx_player, "queue_free")
	call_deferred('add_child', sfx_player)
	sfx_player.play()
