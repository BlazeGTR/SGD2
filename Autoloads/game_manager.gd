extends Node

# in poziom statystyki
var player: CharacterBody2D
var ui_ammo_display: Control
var enemies_left_alive: Array = []
var hostages_left_alive: Array = []
var total_enemies_at_start: int = 0
var enemies_killed: int = 0
var enemies_arrested: int = 0
var score: int
var level_timer: float
var current_objective_manager: Node = null

# Gówno pomiędzy misjami
var current_mission_id: String = ""
var last_completed_mission_id: String = ""
var was_mission_successful: bool = false
var last_objective_results: Array = []

const MAIN_MENU_PATH = "res://Scenes/main_menu.tscn"

func _physics_process(delta: float) -> void:
	level_timer += delta


func go_to_main_menu() -> void:
	get_tree().paused = false
	
	current_mission_id = ""
	last_completed_mission_id = ""
	was_mission_successful = false
	last_objective_results.clear()
	
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func start_new_level():
	print("clearing game manager")
	enemies_left_alive = []
	hostages_left_alive = []
	score = 0
	level_timer = 0
	total_enemies_at_start = 0
	enemies_killed = 0
	enemies_arrested = 0
	last_objective_results.clear()
	current_objective_manager = null


func add_score(added_score):
	score += added_score


func get_score() -> int:
	return score


func get_level_timer() -> float:
	return level_timer


func add_new_enemy(enemy):
	enemies_left_alive.append(enemy)


func add_new_hostage(hostage):
	hostages_left_alive.append(hostage)
	
	
func remove_enemy(enemy):
	enemies_left_alive.erase(enemy)


func remove_hostage(hostage):
	hostages_left_alive.erase(hostage)

func get_player() -> CharacterBody2D:
	return player


func set_player(new_player: CharacterBody2D) -> void:
	player = new_player


func report_sound(origin: Vector2, radius: float):
	var all_actors = enemies_left_alive + hostages_left_alive
	for actor in all_actors:
		if is_instance_valid(actor):
			var distance = origin.distance_to(actor.global_position)
			
			if distance <= radius:
				var brain = actor.get_node_or_null("BrainComponent")
				if brain and brain.has_method("hear_sound"):
					brain.hear_sound(origin)
