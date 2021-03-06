extends Counters


func _ready() -> void:
	counters_container = $VBC
	value_node = "Value"
	needed_counters = {
		"time": {
			"CounterTitle": "Time Available: ",
			"Value": 0},
		"skill":{
			 "CounterTitle": "Skill: ",
			"Value": 0},
		"cred":{
			 "CounterTitle": "Cred: ",
			"Value": 0},
		"kudos":{
			 "CounterTitle": "Kudos: ",
			"Value": 0},
		"motivation":{
			 "CounterTitle": "Motivation: ",
			"Value": 5},
	}
	if ffc.difficulty >= ffc.Difficulties.STARTING_MOTIVATION_DECREASE:
		needed_counters["motivation"]["Value"] -= 1
	spawn_needed_counters()
