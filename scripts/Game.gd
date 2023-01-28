extends Node2D

onready var block_scene = preload('res://scenes/Block.tscn')
onready var enemy_scene = preload('res://scenes/Enemy.tscn')

const SPAWN_TIME = 3.0

var random = RandomNumberGenerator.new()

var hp = 5

var green = Color(0.04, 0.52, 0.11, 1.0)
var red = Color(0.52, 0.04, 0.04, 1.0)
var yellow = Color(0.88, 0.77, 0.23, 1.0)
var purple = Color(0.32, 0.05, 0.54, 1.0)
var colors = [green, red, purple]

var spawn_color = 0
var spawn_column = 4
# -1 = enemy, 0 = empty, 1 = green, 2 = red, 3 = yellow, 4 = purple
var grid = [
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
]
var node_refs = [
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
	[null, null, null, null, null, null, null, null],
]

var enemies_that_attacked = []
var enemies_that_moved = []

func _ready():
	next_color()

func next_color():
	random.randomize()
	spawn_color = random.randi_range(0, colors.size() - 1)
	$IncomingBlock.set_color(colors[spawn_color])
	$Selector.modulate = colors[spawn_color]
	$BlockProgress/Tween1.interpolate_property($BlockProgress, 'value', 0, 50, SPAWN_TIME / 2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$BlockProgress/Tween1.start()
	# enemy_phase() # Doesn't work because rats move at the same time as drops and "dodge but doesn't look like it

func _on_BlockProgressTween1_tween_all_completed():
	$BlockProgress/Tween2.interpolate_property($BlockProgress, 'value', 50, 100, SPAWN_TIME / 2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$BlockProgress/Tween2.start()
	enemy_phase()

func _on_BlockProgressTween2_tween_all_completed():
	spawn_enemy()
	spawn_block()

func spawn_block():
	if grid[0][spawn_column] == 0:
		grid[0][spawn_column] = spawn_color + 1
		var block = block_scene.instance()
		node_refs[0][spawn_column] = block
		block.global_position = $Selector.global_position
		block.set_color(colors[spawn_color])
		$Blocks.add_child(block)
	
	# if column is full find next avail column
	var full_column = true
	for x in range(0, grid.size()):
		if grid[x][spawn_column] <= 0:
			full_column = false
			break
	if full_column:
		find_avail_column()
	next_color()
	slide_down_blocks()

func find_avail_column():
	for y in range(4, 8):
		if grid[0][y] <= 0:
			change_column(y)
			break

func change_column(num):
	if grid[0][num] == 0:
		# if column isn't full, change to it
		spawn_column = num
		$Selector.global_position = get_node('BlockSpawn'+str(num)).global_position
	else:
		# TODO: play invalid column sfx?
		pass

func combo_check():
	var combo_cells = []
	var row_combo_cells = []
	var col_combo_cells = []
	var diag_combo_cells = []
	
	# horizontal combo pass
	for x in range(0, grid.size()):
		var prev_color = 0
		var buffer = []
		for y in range(4, 8):
			var cur_color = grid[x][y]
			if prev_color > 0 and prev_color == cur_color:
				if not buffer.has(Vector2(x,y-1)):
					buffer.append(Vector2(x,y-1))
				if not buffer.has(Vector2(x, y)):
					buffer.append(Vector2(x, y))
				if buffer.size() >= 3:
					for cell in buffer:
						if not row_combo_cells.has(cell):
							row_combo_cells.append(cell)
			else:
				buffer = []
				prev_color = cur_color
			
	# vertical combo pass
	for y in range(4, 8):
		var prev_color = 0
		var buffer = []
		for x in range(0, grid.size()):
			var cur_color = grid[x][y]
			if prev_color > 0 and prev_color == cur_color:
				if not buffer.has(Vector2(x-1,y)):
					buffer.append(Vector2(x-1,y))
				if not buffer.has(Vector2(x, y)):
					buffer.append(Vector2(x, y))
				if buffer.size() >= 3:
					for cell in buffer:
						if not col_combo_cells.has(cell):
							col_combo_cells.append(cell)
			else:
				buffer = []
				prev_color = cur_color
				
	# combine combo cells into one array
	for cell in row_combo_cells:
		if not combo_cells.has(cell):
			combo_cells.append(cell)
	for cell in col_combo_cells:
		if not combo_cells.has(cell):
			combo_cells.append(cell)
	for cell in diag_combo_cells:
		if not combo_cells.has(cell):
			combo_cells.append(cell)
	
	# loop through all combo cells and destruct them
	for cell in combo_cells:
		destroy_nearest_enemy()
		node_refs[cell.x][cell.y].boom()
		grid[cell.x][cell.y] = 0
		node_refs[cell.x][cell.y] = null
	# slide down any blocks now sitting on air
	if combo_cells.size() > 0:
		slide_down_blocks()

func slide_down_blocks():
	# search down columns for gaps or enemies to squish
	for y in range(4, 8):
		for x in range(0, grid.size()):
			# if non-empty block is above an empty block...
			if grid[x][y] > 0 and x+1 <= grid.size()-1 and grid[x+1][y] <= 0:
				# if we're landing on an enemy, squish em
				if grid[x+1][y] == -1:
					node_refs[x+1][y].delayed_boom()
				# slide block down by 1, then recursively re-run function
				grid[x+1][y] = grid[x][y]
				node_refs[x+1][y] = node_refs[x][y]
				node_refs[x+1][y].queue_drop(1)
				grid[x][y] = 0
				node_refs[x][y] = null
				slide_down_blocks()
				return
	
	# if we've made it out of the recursion, trigger queued drops
	for y in range(4, 8):
		for x in range(0, grid.size()):
			if node_refs[x][y] != null and node_refs[x][y].is_in_group("blocks"):
				node_refs[x][y].trigger_queued_drop()
	# then re-check for combos
	if $ComboRecheckTimer.time_left == 0:
		$ComboRecheckTimer.start()

func destroy_nearest_enemy():
	# reverse loop through rows and columns
	for x in range(7, 3, -1):
		for y in range(7, -1, -1):
			if grid[x][y] == -1:
				print('destroying nearest enemy')
				node_refs[x][y].boom()
				node_refs[x][y] = null
				grid[x][y] = 0
				return

func enemy_phase():
	# attack loop
	var attack_time = 0.2
	var enemy_attacked = false
	for x in range(0, grid.size()):
		for y in range(0, 8):
			# enemy to left of block
			if grid[x][y] == -1 and y < 7 and grid[x][y + 1] > 0:
				enemy_attacked = true
				node_refs[x][y].play_attack_animation()
				grid[x][y+1] = 0
				node_refs[x][y+1].delayed_boom(attack_time)
				node_refs[x][y+1] = null
				enemies_that_attacked.append(Vector2(x, y))
			# enemy to left of castle
			elif grid[x][y] == -1 and y == 7:
				enemy_attacked = true
				node_refs[x][y].play_attack_animation()
				$HUD/HP/FloatTextSpawner.float_text('-1', red)
				hp = max(0, hp - 1)
				$HUD/HP.text = 'HP: ' + str(hp)
				if hp == 0:
					# TODO: gameover
					print('GAME OVER')
	
	if enemy_attacked:
		$EnemyAttackTimer.wait_time = attack_time
		$EnemyAttackTimer.start()
	else:
		move_enemies()

func move_enemies():
	for x in range(4, grid.size()):
		# reverse loop through walkable columns
		for y in range(7, 0, -1):
			# open space to right of enemy
			if grid[x][y] == 0 and grid[x][y-1] == -1 \
				and not enemies_that_attacked.has(Vector2(x,y-1)) \
				and not enemies_that_moved.has(Vector2(x,y-1)):
					node_refs[x][y] = node_refs[x][y-1]
					# See comment on line 55 
#					if node_refs[x][y].frozen:
#						break
					grid[x][y] = -1
					grid[x][y-1] = 0
					node_refs[x][y].slide_right()
					node_refs[x][y-1] = null
					enemies_that_moved.append(Vector2(x,y))
	enemies_that_attacked = []
	enemies_that_moved = []

func _on_EnemyAttackTimer_timeout():
	slide_down_blocks()
	move_enemies()

func spawn_enemy():
	random.randomize()
	var i = random.randi_range(5, 7)
	if grid[i][0] == 0:
		grid[i][0] = -1
		var enemy = enemy_scene.instance()
		enemy.flyer = i == 5 or i == 6
		node_refs[i][0] = enemy
		enemy.global_position = get_node('EnemySpawn'+str(i)).global_position
		$Enemies.add_child(enemy)
	# TODO: if random lane is full, try another?

func _on_Column4_pressed():
	change_column(4)

func _on_Column5_pressed():
	change_column(5)

func _on_Column6_pressed():
	change_column(6)

func _on_Column7_pressed():
	change_column(7)

func _on_BlockLandTimer_timeout():
	combo_check()

func _on_ComboRecheckTimer_timeout():
	combo_check()
