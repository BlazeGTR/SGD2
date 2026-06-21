extends Node

const MAIN_MENU_PATH = "res://Scenes/main_menu.tscn"


func go_to_main_menu() -> void:
	get_tree().paused = false
	
	GameManager.current_mission_id = ""
	GameManager.last_completed_mission_id = ""
	GameManager.was_mission_successful = false
	GameManager.last_objective_results.clear()
	
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
