extends CenterContainer

onready var start_button = $PC/VBC/HBC/Start
onready var back_button = $PC/VBC/HBC/Back
onready var deck_title = $PC/VBC/DeckTitle
onready var deck_details = $PC/VBC/DeckDetails
onready var difficulty_level = $PC/VBC/Difficulty/Level
onready var diff_popup = $PC/VBC/Difficulty/Level/Difficulties
onready var diff_title = $PC/VBC/DifficultyLabel
onready var diff_legend = $PC/VBC/Difficulty/Level/Difficulties/MC/VBC/DifficultyLegend

func _ready() -> void:
	_adjust_difficulty()

func _process(_delta: float) -> void:
	diff_popup.rect_global_position.y = $PC.rect_global_position.y + $PC.rect_size.y / 2 - diff_popup.rect_size.y / 2
	diff_popup.rect_global_position.x = $PC.rect_global_position.x + $PC.rect_size.x
	diff_popup.set_as_minsize()


func _on_Start_pressed() -> void:
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://src/fragment_forge/Main.tscn")


func _on_DeckLoader_deck_loaded(deck) -> void:
	ffc.current_deck = deck.cards
	if deck.has('persona'):
		ffc.current_persona = Persona.new(deck.persona)
	else:
		ffc.current_persona = null
	deck_title.visible = true
	deck_title.text = deck.name
	deck_details.visible = true
	deck_details.text = str(deck.total) + " Cards"
	start_button.disabled = false

func _on_Decrease_pressed() -> void:
	if ffc.difficulty > ffc.Difficulties.START + 1:
		ffc.difficulty -= 1
	_adjust_difficulty()

func _on_Increase_pressed() -> void:
	if ffc.difficulty < ffc.Difficulties.END - 1:
		ffc.difficulty += 1
	_adjust_difficulty()


func _adjust_difficulty() -> void:
	difficulty_level.text = str(ffc.difficulty)
	_adjust_difficulty_legend()


func _on_Level_mouse_entered() -> void:
	diff_popup.visible = true
	diff_legend.visible = true




func _on_Level_mouse_exited() -> void:
	diff_popup.visible = false
	diff_legend.visible = false

func _adjust_difficulty_legend() -> void:
	var diff_text = ''
	if ffc.difficulty == ffc.Difficulties.NORMAL:
		diff_text = "0: Normal Difficulty"
		diff_title.text = "Normal"
	elif ffc.difficulty > ffc.Difficulties.NORMAL:
		if ffc.difficulty > 10:
			diff_title.text = "Shader Guru"
		elif ffc.difficulty > 5:
			diff_title.text = "Very Hard"
		elif ffc.difficulty > 0:
			diff_title.text = "Hard"
		for difficulty in range(1,ffc.difficulty+1):
			diff_text += str(difficulty) + ': '\
					+ ffc.DIFFICULTIES_DESCRIPTIONS[difficulty] + '\n'
	else:
		if ffc.difficulty <= -4:
			diff_title.text = "Trivial"
		elif ffc.difficulty < 0:
			diff_title.text = "Easy"
		for difficulty in range(ffc.difficulty, 0):
			diff_text += str(difficulty) + ': '\
					+ ffc.DIFFICULTIES_DESCRIPTIONS[difficulty] + '\n'
	diff_legend.text = diff_text
#	diff_legend.rect_size = Vector2(0,0)
#	$PC/VBC/Difficulty/Level/Difficulties/VBC.rect_size = Vector2(0,0)
#	$PC/VBC/Difficulty/Level/Difficulties.rect_size = Vector2(0,0)

