extends PanelContainer

var cred_goal: int = 10
var max_competitions: int = 3
onready var game_goal = $"VBC/GameGoal"
onready var difficulty = $"VBC/Difficulty"
onready var competitions_visited = $"VBC/Competitions"
onready var end_game_popup: AcceptDialog = $EndGame

func _ready() -> void:
	if ffc.difficulty <= ffc.Difficulties.REDUCED_CRED_REQ:
		cred_goal -= 1
	if ffc.difficulty >= ffc.Difficulties.FIRST_CRED_REQ_INCREASE:
		cred_goal += 1
	if ffc.difficulty >= ffc.Difficulties.SECOND_CRED_REQ_INCREASE:
		cred_goal += 1
	if ffc.difficulty >= ffc.Difficulties.THIRD_CRED_REQ_INCREASE:
		cred_goal += 1
	if ffc.difficulty <= ffc.Difficulties.EXTRA_COMPETITION:
		max_competitions += 1
	game_goal.text = "Game Goal: " + str(cred_goal) + " Cred"
	difficulty.text = "Difficulty: " + str(ffc.difficulty)

func _process(_delta: float) -> void:
#	if cfc.NMAP.get("board"):
	if cfc.NMAP.board.counters.get_counter("cred") >= cred_goal\
			and not end_game_popup.visible:
		win_game()
	if cfc.NMAP.board.counters.get_counter("motivation") <= 0\
			and not end_game_popup.visible:
		lose_game_motivation()
	if cfc.NMAP.board.competitions.current_round > max_competitions\
			and not end_game_popup.visible:
		lose_game()

	var competitions_visited_text = "Competitions: "\
			+ str(cfc.NMAP.board.competitions.current_round)\
			+ "/" + str(max_competitions)
	if competitions_visited_text != competitions_visited.text:
		competitions_visited.text = competitions_visited_text

func compile_game_detals() -> Dictionary:
	ffc.game_stats["motivation"] = cfc.NMAP.board.counters.get_counter("motivation")
	ffc.game_stats["cred"] = cfc.NMAP.board.counters.get_counter("cred")
	var game_details := ffc.game_stats
	game_details["difficulty"] = ffc.difficulty
	return(game_details)

func send_end_game_stats(state: String, state_type: String = '') -> void:
	if cfc.NMAP.board.stats:
		var game_details := compile_game_detals()
		if state_type != '':
			game_details[state + "_type"] = state_type
		var game_data = {"state": state, "details": game_details}
		cfc.NMAP.board.stats.complete_game(game_data)

func win_game() -> void:
	end_game_popup.window_title = "Congratulations!"
	end_game_popup.dialog_text = "You have amassed the required cred "\
			+ "to become the envy of your peers. Well done!\n\nPress OK to play again."
	send_end_game_stats("victory")
	finish_game()


func lose_game() -> void:
	end_game_popup.window_title = "Game Over!"
	end_game_popup.dialog_text = "Unfortunately, you have not managed to achieve "\
			+ " the required cred to win this game.\n\nPress OK to play again."
	send_end_game_stats("defeat", "time")
	finish_game()

func lose_game_motivation() -> void:
	end_game_popup.window_title = "Game Over!"
	end_game_popup.dialog_text = "Unfortunately, the stress of these competitions "\
			+ " was too much and you have ended with bad case of Burnout. "\
			+ "You have dropped out!\n\nPress OK to play again."
	send_end_game_stats("defeat", "motivation")
	finish_game()


func finish_game() -> void:
	end_game_popup.popup_centered()
	$EndGameTween.interpolate_property(
			cfc.NMAP.board,'modulate:a',1, 0, 1,
			Tween.TRANS_SINE, Tween.EASE_IN)
	$EndGameTween.start()


func _on_EndGame_confirmed() -> void:
	if cfc.NMAP.board.stats:
		cfc.NMAP.board.stats.thread.wait_to_finish()
	cfc.reset_game()
	ffc.reset_game()
