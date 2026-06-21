extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@export var sprite_2d: Sprite2D
var current_signal_state: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_shape_2d.set_deferred("disabled", true)
	sprite_2d.visible = false
	SignalBus.extraction_enabled.connect(enable_extract)


func enable_extract(was_successful: bool):
	current_signal_state = was_successful
	collision_shape_2d.set_deferred("disabled", false)
	sprite_2d.visible = true
	#zrobić wizualnie coś żeby widać ekstrakt


func interact(_player):
	print("Gracz ewakuowany!")
	
	var completed_id = GameManager.current_mission_id
	var final_success = false
	
	if is_instance_valid(GameManager.current_objective_manager):
		final_success = GameManager.current_objective_manager.save_final_results_and_evaluate_success()
	else:
		# Fallback na wypadek błędu menedżera
		final_success = current_signal_state
	
	GameManager.was_mission_successful = final_success
	
	# Przyznajemy gotówkę i zapisujemy wynik tylko, jeśli misja była udana
	if final_success:
		var money_earned = GameManager.score
		var current_money = SaveManager.current_data.get("current_money", 0)
		SaveManager.current_data["current_money"] = current_money + money_earned
		
		if not SaveManager.current_data["levels"].has(completed_id):
			SaveManager.current_data["levels"][completed_id] = {"status": "unlocked", "score": 0}
			
		var old_score = SaveManager.current_data["levels"][completed_id]["score"]
		if money_earned > old_score:
			SaveManager.current_data["levels"][completed_id]["score"] = money_earned
	
	SaveManager.save_game()
	
	GameManager.last_completed_mission_id = completed_id
	GameManager.current_mission_id = ""
	
	get_tree().paused = true
	get_tree().change_scene_to_file("res://Missions/operation_center.tscn")
	
	#var money_earned = GameManager.score
	#var current_money = SaveManager.current_data.get("current_money", 0)
	#
	#SaveManager.current_data["current_money"] = current_money + money_earned
	#SaveManager.save_game()
	#
	#print("ASDASD")
	#GameManager.last_completed_mission_id = GameManager.current_mission_id
	#GameManager.was_mission_successful = true
	#GameManager.current_mission_id = ""
	#get_tree().change_scene_to_file("res://Missions/operation_center.tscn")
