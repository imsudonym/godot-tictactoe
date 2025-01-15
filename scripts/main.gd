extends Node

@export var circle_scene : PackedScene
@export var cross_scene : PackedScene
@onready var next_player_panel: Panel = $NextPlayerPanel
@onready var game_over_menu: CanvasLayer = $GameOverMenu

var player: int
var next_player
var grid_data: Array
var grid_pos: Vector2i
var board_width: int
var cell_size: int
var moves: int = 9
var winner: int

func _ready() -> void:
	board_width = $Board.texture.get_width()
	cell_size = board_width / 3 # Divide board_width by 3 to get the size of individual cells
	new_game()

func _input(event) -> void:
	if board_is_clicked(event):
		grid_pos = Vector2i(event.position / cell_size)
		mark_cell()

func mark_cell():
	if grid_data[grid_pos.y][grid_pos.x] == 0:
		grid_data[grid_pos.y][grid_pos.x] = player
		create_marker(player, grid_pos * cell_size + Vector2i(cell_size/2, cell_size/2))
		moves -= 1
		if check_winner() != 0 || moves == 0:
			handle_game_over()
		update_next_player()
		player *= -1

func update_next_player():
	next_player.queue_free()
	create_marker(player, next_player_panel.position + Vector2(cell_size/2, cell_size/2), true)

func handle_game_over():
	get_tree().paused = true
	game_over_menu.show()
	var game_over_msg: String
	if winner == 1:
		game_over_msg = "Player 1 wins!"
	elif winner == -1:
		game_over_msg = "Player 2 wins!"
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
	player = 1
	winner = 0
	moves = 9
	grid_data = [
		[0, 0, 0],
		[0, 0, 0],
		[0, 0, 0]
	]
	get_tree().call_group("circles", "queue_free")
	get_tree().call_group("crosses", "queue_free")
	create_marker(player, next_player_panel.position + Vector2(cell_size/2, cell_size/2), true)
	game_over_menu.hide()
	get_tree().paused = false
	
func create_marker(player, position, is_next_player_marker=false):
	var marker = null
	if player == 1: marker = circle_scene.instantiate()
	else: marker = cross_scene.instantiate()
	if is_next_player_marker: next_player = marker
	marker.position = position
	add_child(marker)

func check_winner():
	var matrix = grid_data
	var diagonal_down_sum: int
	var diagonal_up_sum: int
	for i in len(matrix):
		var row_sum: int
		var col_sum: int
		for j in len(matrix[i]):
			row_sum += matrix[i][j]
			col_sum += matrix[j][i]
		diagonal_up_sum += matrix[i][len(matrix[i])-1-i]
		diagonal_down_sum += matrix[i][i]
		var sums = [row_sum, col_sum, diagonal_up_sum, diagonal_down_sum]
		if 3 in sums: winner = 1
		if -3 in sums: winner = -1
	return winner

func _on_game_over_menu_restart() -> void:
	new_game()
