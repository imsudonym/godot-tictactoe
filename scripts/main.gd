extends Node

@export var circle_scene : PackedScene
@export var cross_scene : PackedScene
@onready var grid_notes = $GridNotes
@onready var win_lines = $WinLines
@onready var game_over_label = $GameOver
@onready var instruction_label = $Instruction
@onready var replay_delay = $ReplayDelay
@onready var grid: Sprite2D = $Board
@onready var grid_offset = Vector2(60, 100)
@onready var fail_sound = $FailSound

const X_PLAYER = 'X'
const O_PLAYER = 'O'
const AI = O_PLAYER
const HUMAN = X_PLAYER

var board: Array
var active_player
var next_player
var grid_pos: Vector2i
var board_width: float
var board_height: float
var cell_size: float
var moves_left: int = 9
var winner
var is_game_over = false
var replay_delay_counting = false
var winning_line

func _ready() -> void:
	board_width = grid.texture.get_width() * grid.scale.x
	board_height = grid.texture.get_height() * grid.scale.y
	cell_size = board_width / 3.0 # Divide board_width by 3 to get the size of individual cells
	new_game()

func _input(event) -> void:
	if event is InputEventKey or event is InputEventMouseButton and event.pressed:
		if replay_delay_counting:
			return
		
		if is_game_over:
			new_game()
			return
		
		if active_player == AI:
			return
		
		if board_is_clicked(event):
			grid_pos = Vector2i((event.position - grid_offset) / cell_size)
			if active_player == HUMAN:
				human_move(grid_pos)
			await get_tree().create_timer(0.5).timeout
			ai_move()

func human_move(position):
	if active_player != HUMAN:
		return
	move(position, HUMAN)

func ai_move():
	if active_player != AI:
		return
		
	var best_move = best_ai_move()
	move(best_move, AI)
	
func move(position, player):
	#print('move to :', position)
	if board[position.y][position.x] != '':
		return
	
	board[position.y][position.x] = player
	draw_marker(player, grid_offset + position * cell_size + Vector2(cell_size/2.0, cell_size/2.0))
	winner = check_winner()

	if winner != null || not has_moves_left():
		handle_game_over_ui()
		pass
	else:
		# set next player
		if active_player == HUMAN:
			active_player = AI
		else:
			active_player = HUMAN
	
	play_grid_sound()

func play_grid_sound():
	var notes = grid_notes.get_children()
	var note = notes.pick_random()
	note.play()

func handle_game_over_ui():
	is_game_over = true
	game_over_label.show()
	instruction_label.show()
	var game_over_msg: String
	var game_over_color: Color
	if winner == HUMAN:
		game_over_msg = "You Win!"
		game_over_color = Color.GREEN
	elif winner == AI:
		game_over_msg = "You Lose!"
		game_over_color = Color.RED
		fail_sound.play()
	else:
		game_over_msg = "It's a tie!"
		game_over_color = Color.AQUA

	game_over_label.text = game_over_msg
	game_over_label.add_theme_color_override("font_color", game_over_color)
	$StartMessage.hide()
	$StartInstruction.hide()
	show_win_line()
	start_replay_delay()

func show_win_line():
	if winner:
		win_lines.get_node(winning_line).show()

func hide_win_line():
	if winning_line:
		win_lines.get_node(winning_line).hide()
	
func board_is_clicked(event):
	if (event is InputEventMouseButton and
		event.button_index == MOUSE_BUTTON_LEFT and
		event.pressed and
		grid_offset.x < event.position.x and 
		event.position.x < (grid_offset.x + board_width) and
		grid_offset.y < event.position.y and 
		event.position.y < (grid_offset.y + board_height)):
			return true
	return false

func start_replay_delay():
	replay_delay_counting = true
	replay_delay.start()

func new_game():
	is_game_over = false
	active_player = X_PLAYER
	winner = null
	moves_left = 9
	board = [
		['', '', ''],
		['', '', ''],
		['', '', '']
	]
	get_tree().call_group("circles", "queue_free")
	get_tree().call_group("crosses", "queue_free")
	game_over_label.hide()
	instruction_label.hide()
	$StartMessage.show()
	$StartInstruction.show()
	hide_win_line()
	winning_line = ''
	
func draw_marker(player, position, is_next_player_marker=false):
	var marker = null
	if player == O_PLAYER:
		marker = circle_scene.instantiate()
	else:
		marker = cross_scene.instantiate()
	if is_next_player_marker: next_player = marker
	marker.position = position
	add_child(marker)

func has_moves_left():
	for i in range(3) :
		for j in range(3) :
			if (board[i][j] == "") :
				return true
	return false

func check_winner():
	# check rows
	var row_index = 0
	for row in board:
		if row[0] != "" and row[0] == row[1] and row[1] == row[2]:
			winning_line = "LineRow" + str(row_index + 1) 
			return row[0]
		row_index += 1
	
	# check columns
	for c in range(3):
		if board[0][c] != "" and board[0][c] == board[1][c] and board[1][c] == board[2][c]:
			winning_line = "LineCol" + str(c + 1) 
			return board[0][c]
	
	# check diagonals
	if board[0][0] != "" and board[0][0] == board[1][1] and board[1][1] == board[2][2]:
		winning_line = "LineDiagonal1" 
		return board[0][0]
	
	if board[2][0] != "" and board[2][0] == board[1][1] and board[1][1] == board[0][2]:
		winning_line = "LineDiagonal2"
		return board[2][0]

func _on_game_over_menu_restart() -> void:
	new_game()

# --- minimax ----
func minimax (is_maximazing: bool, depth: int) -> int:
	var _winner = check_winner()
	if _winner == AI:
		return 10 - depth
	elif _winner == HUMAN:
		return depth - 10
	elif not has_moves_left():
		return 0
		
	if is_maximazing:
		var best_score = -9999
		for r in range(3):
			for c in range(3):
				if board[r][c] == "":
					board[r][c] = AI
					var score = minimax(false, depth + 1)
					board[r][c] = ""
					best_score = max(best_score, score)
		return best_score
	else:
		var best_score = 9999
		for r in range(3):
			for c in range(3):
				if board[r][c] == "":
					board[r][c] = HUMAN
					var score = minimax(true, depth + 1)
					board[r][c] = ""
					best_score = min(best_score, score)
		return best_score

func best_ai_move() -> Vector2:
	var best_score = -9999
	var best_moves: Array[Vector2] = []
	for r in range(3):
		for c in range(3):
			if board[r][c] == "":
				board[r][c] = AI
				var score = minimax(false, 0)
				board[r][c] = ""
				
				if score > best_score:
					best_score = score
					best_moves = [Vector2(c, r)]
				elif score == best_score:
					best_moves.append(Vector2(c, r))
	
	if best_moves.size() > 0:
		return best_moves.pick_random()
	return Vector2(-1, -1)

func _on_replay_delay_timeout() -> void:
	replay_delay_counting = false
