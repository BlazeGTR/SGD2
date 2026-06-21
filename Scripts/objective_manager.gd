extends Node
class_name ObjectiveManager

@export var level_objectives: Array[ObjectiveResource] = []

var _active_objectives: Array[ObjectiveResource] = []

var current_extraction_state: String = "LOCKED"
@onready var actor_manager: Node = $"../ActorManager"

func _ready() -> void:
	# Czekamy na załadowanie wrogów przez Managera
	await get_tree().process_frame
	
	GameManager.current_objective_manager = self
	
	var total_enemies = actor_manager.enemies_left_alive.size()
	var total_hostages = actor_manager.hostages_left_alive.size()
	
	actor_manager.total_enemies_at_start = total_enemies
	
	for obj in level_objectives:
		if obj != null:
			var active_obj = obj.duplicate()
			
			active_obj.reset_objective_state(total_enemies, total_hostages)
				
			_active_objectives.append(active_obj)
			
	SignalBus.objective_event_triggered.connect(_on_objective_event)
	SignalBus.player_died.connect(_on_player_died)


func _on_objective_event(event_type: String, amount: int) -> void:
	print("sprawdzanie: ", event_type)
	for obj in _active_objectives:
		# 1. Sprawdzanie natychmiastowej porażki (np. zastrzelenie zakładnika)
		if obj.fail_events.has(event_type):
			obj.is_failed = true
			print("Cel oblany (Event): ", obj.title)
			
		# 2. Dodawanie postępu do celu
		if obj.valid_events.has(event_type):
			print("jest taki cel")
			obj.add_progress(amount)
		else:
			print("nie ma celu")
				
		# 3. Sprawdzanie soft-locka matematycznego (dla celów "Aresztuj X")
		if obj.fail_if_not_enough_enemies:
			obj.check_for_math_failure(actor_manager.total_enemies_at_start, actor_manager.enemies_killed, actor_manager.enemies_arrested,
										actor_manager.total_civilians_at_start, actor_manager.civilians_killed, actor_manager.civilians_arrested)

		_check_mission_status()


func _check_mission_status() -> void:
	var all_mandatory_done = true
	var any_mandatory_failed = false
	
	for obj in _active_objectives:
		if obj.is_mandatory:
			if obj.is_failed: any_mandatory_failed = true
			if not obj.is_completed: all_mandatory_done = false
			
	if any_mandatory_failed and current_extraction_state != "FAIL_FORCED":
		current_extraction_state = "FAIL_FORCED"
		print("Centrala: Straciliście kontrolę! Natychmiastowy odwrót!")
		SignalBus.extraction_enabled.emit(false) # False = Porażka
		
	elif all_mandatory_done and not any_mandatory_failed and current_extraction_state != "SUCCESS_AVALIBLE":
		current_extraction_state = "SUCCESS_AVALIBLE"
		print("Centrala: Teren czysty. Udajcie się do punktu ewakuacji.")
		SignalBus.extraction_enabled.emit(true) # True = Sukces


func save_final_results_and_evaluate_success() -> bool:
	GameManager.last_objective_results.clear()
	var final_mission_success = true
	
	for obj in _active_objectives:
		var status = "SKIPPED"
		
		if obj.is_completed:
			status = "COMPLETED"
		elif obj.is_failed:
			status = "FAILED"
			if obj.is_mandatory: final_mission_success = false
			
		# Zabezpieczenie: jeśli misja nie jest failnięta, ale gracz uciekł bez zrobienia celu głównego
		if obj.is_mandatory and not obj.is_completed:
			status = "INCOMPLETE"
			final_mission_success = false
			
		GameManager.last_objective_results.append({
			"title": obj.title,
			"status": status
		})
		
	return final_mission_success


func _on_player_died() -> void:
	current_extraction_state = "FAIL_FORCED"
	
	# 1. Zmiana statusu wszystkich nieukończonych celów na oblane
	for obj in _active_objectives:
		if not obj.is_completed:
			obj.is_failed = true
			
	# 2. Zapisanie wyników do GameManager (przygotowanie danych pod Debriefing)
	save_final_results_and_evaluate_success()
	
	# 3. Twarde wymuszenie porażki
	GameManager.was_mission_successful = false
	GameManager.last_completed_mission_id = GameManager.current_mission_id
	GameManager.current_mission_id = ""
	
	# 4. Opóźnienie na animację śmierci / wybrzmienie dźwięku
	await get_tree().create_timer(2.0).timeout
	
	# 5. Bezpośrednie przeniesienie do Operation Center na zły debriefing
	get_tree().paused = true
	get_tree().change_scene_to_file("res://Missions/operation_center.tscn")
