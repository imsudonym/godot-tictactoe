extends Node

@export var circle_scene : PackedScene
@export var cross_scene : PackedScene
@onready var next_player_panel: Panel = $NextPlayerPanel
@onready var game_over_menu: CanvasLayer = $GameOverMenu

const PLAYER: int = 1
const COMPUTER: int = -1

var active_player: int
var next_player
var grid_data: Array
var grid_pos: Vector2i
var board_width: int
var cell_size: int
var moves_left: int = 9
var winner: int

func _ready() -> void:
	board_width = $Board.texture.get_width()
	# Divide board_width by 3 to get the size of individual cells
	cell_size = board_width / 3
	new_game()

func _input(event) -> void:
	if board_is_clicked(event):
		grid_pos = Vector2i(event.position / cell_size)
		mark_cell()

func mark_cell():
	# Marks a cell with X or O and checks if theres a winner
	if grid_data[grid_pos.y][grid_pos.x] == 0:
		grid_data[grid_pos.y][grid_pos.x] = PLAYER
		create_marker(active_player, grid_pos * cell_size + Vector2i(cell_size/2, cell_size/2))
		winner = evaluate_winner(grid_data)
		print('winner:', winner, ' not has_moves_left():',  not has_moves_left())
		if winner != 0 || not has_moves_left():
			handle_game_over_ui()
		else:
			update_next_player()
			active_player = COMPUTER
			ai_move()
		
func ai_move():
	var board = grid_data.duplicate(true)
	var best_move = find_best_move(board)
	grid_data[best_move.y][best_move.x] = COMPUTER
	create_marker(active_player, best_move * cell_size + Vector2i(cell_size/2, cell_size/2))
	winner = evaluate_winner(grid_data)
	if winner != 0 || not has_moves_left():
		handle_game_over_ui()
	else:
		update_next_player()
		active_player = PLAYER

func update_next_player():
	# Updates the next player UI
	next_player.queue_free()
	create_marker(active_player, next_player_panel.position + Vector2(cell_size/2, cell_size/2), true)

func handle_game_over_ui():
	get_tree().paused = true
	game_over_menu.show()
	var game_over_msg: String
	if winner == 1:
		game_over_msg = "O wins!"
	elif winner == -1:
		game_over_msg = "X wins!"
	else:
		game_over_msg = "It's a tie!"
	game_over_menu.get_node("WinnerLabel").text = game_over_msg
	
func board_is_clicked(event):
	if (event is InputEventMouseButton and 
		event.button_index == MOUSE_BUTTON_LEFT and 
		event.pressed and 
		event.position.x < board_width):
			return true
	return false

func new_game():
	active_player = PLAYER
	winner = 0
	moves_left = 9
	grid_data = [
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0]
	]
	get_tree().call_group("circles", "queue_free")
	get_tree().call_group("crosses", "queue_free")
	create_marker(active_player, next_player_panel.position + Vector2(cell_size/2, cell_size/2), true)
	game_over_menu.hide()
	get_tree().paused = false
	
func create_marker(player, position, is_next_player_marker=false):
	var marker = null
	if player == 1: marker = circle_scene.instantiate()
	else: marker = cross_scene.instantiate()
	if is_next_player_marker: next_player = marker
	marker.position = position
	add_child(marker)

func has_moves_left():
	for i in range(3) : 
		for j in range(3) : 
			if (grid_data[i][j] == 0) : 
				return true 
	return false

func evaluate_winner(board):
	var diagonal_down_sum: int
	var diagonal_up_sum: int
	for i in len(board):
		var row_sum: int
		var col_sum: int
		# Sums of rows/col
		for j in len(board[i]):
			row_sum += board[i][j]
			col_sum += board[j][i]
		# Sums on diagonals
		diagonal_up_sum += board[i][len(board[i])-1-i]
		diagonal_down_sum += board[i][i]
		var sums = [row_sum, col_sum, diagonal_up_sum, diagonal_down_sum]
		# If sum is 3 winner is X (value=1)
		# If sum is -3 winner is O (value=-1)
		# Else no winner (value=0)
		if 3 in sums: return 1
		if -3 in sums: return -1
	return 0

func evaluate_b(b, depth):
	var score = 0
	for row in range(3) :      
		if (b[row][0] == b[row][1] and b[row][1] == b[row][2]) :         
			if (b[row][0] == active_player) : 
				score = 10
			elif (b[row][0] == active_player * -1) : 
				score = -10
	
	 # Checking for Columns for X or O victory.  
	for col in range(3) : 
	   
		if (b[0][col] == b[1][col] and b[1][col] == b[2][col]) : 
			if (b[0][col] == active_player) :  
				return 10
			elif (b[0][col] == active_player * -1) : 
				return -10
	
	# Checking for Diagonals for X or O victory.  
	if (b[0][0] == b[1][1] and b[1][1] == b[2][2]) :       
		if (b[0][0] == active_player) : 
			return 10
		elif (b[0][0] == active_player * -1) : 
			return -10
			
	if (b[0][2] == b[1][1] and b[1][1] == b[2][0]) : 
		if (b[0][2] == active_player) : 
			return 10
		elif (b[0][2] == active_player * -1) : 
			return -10
	
	# Else if none of them have won then return 0  
	if score == 10: score -= depth
	if score == -10: score += depth
	return score

func minimax(board, depth, is_max):
	var score = evaluate_b(board, depth)
	
	# if maximizer has won the game, return score
	if (score == 10):
		return score + depth
	# if minimizer has won the game, return score
	if (score == -10):
		return score - depth
	
	# if no more moves left, it's a tie
	if (not has_moves_left()): return 0
	
	# maximizers move
	if (is_max):
		var best = -1000
		# traverse all cells
		for i in range(3):
			for j in range(3):
				# check if cell is empty
				if(board[i][j]==0):
					board[i][j] = active_player # make the move
					# call minimimax recursively and choose the maximum value
					best = max(best, minimax(board, depth + 1, not is_max))
					board[i][j] = 0 # undo the move
		return best
	else: # minimizers move
		var best = 1000
		
		# traverse all cells
		for i in range(3):
			for j in range(3):
				# check if cell is empty
				if board[i][j] == 0:
					board[i][j] = active_player * -1 # make the move
					# call minimimax recursively and choose the minimum value
					best = min(best, minimax(board, depth + 1, not is_max))
					board[i][j] = 0 # undo the move
		return best

#func score(board, depth):
	#if winner == PLAYER:
		#return 10 - depth
	#elif winner == OPPONENT:
		#return depth - 10
	#return 0

#func minimax2(board, depth):
	#var score = evaluate_b(board)
	#
	#
	#if (not has_moves_left()): return 0
	#
	#var scores = []
	#var moves = []
	#
	#var available_moves = get_available_moves(board)
	#for move in available_moves:
		#var possible_game = get_new_state(board, move)
		#scores.append(minimax2(possible_game, depth + 1))
		#moves.append(move)
	#
	#print(scores)
	#
	## Do the min or the max calculation
	#if player == OPPONENT:
		## This is the max calculation
		##var max_score_index = scores.find(scores.max())
		##var chosen_move = moves[max_score_index]
		##return scores[max_score_index]
		#return 10
	#else:
		## This is the min calculation
		##var min_score_index = scores.find(scores.min())
		##var chosen_move = moves[min_score_index]
		##return scores[min_score_index]
		#return 10
	#
#func get_available_moves(board):
	#var moves: Array[Vector2i]
	#for y in range(3):
		#for x in range(3):
			#if board[y][x] == 0:
				#moves.append(Vector2i(x, y))
	#return moves
	#
#func get_new_state(board, move):
	#board[move.y][move.x] = OPPONENT
	#return board
	
func find_best_move(board):
	print(board)
	print('find_best_move | active_player: ', active_player)
	var best_val = -1000
	var best_move = Vector2i(-1, -1)
	# Traverse all cells, evaluate minimax function for  
	# all empty cells. And return the cell with optimal  
	# value.  
	for y in range(3):
		for x in range(3):
			#print('[', y,'][',x,']:',board[y][x],' | board[i][j] == 0:', board[y][x] == 0)
			# Check if cell is empty
			if board[y][x] == 0:
				# Make the move
				board[y][x] = active_player
				# Compute evaluation function for this move
				var move_val = minimax(board, 0, true)
				print('checking move: (', x,',', y,'):', move_val, ' | best_val:', best_val)
				#print('move_val: ', move_val, '| best_val:', best_val)
				# Undo the move
				board[y][x] = 0
				# If the value of the current move is  
				# more than the best value, then update  
				# best/  
				if (move_val >= best_val) :
					best_move = Vector2i(x, y)
					best_val = move_val 
					
	print("-----------best_val :", best_val, ', best_move: ', best_move)
	return best_move 

func _on_game_over_menu_restart() -> void:
	new_game()
