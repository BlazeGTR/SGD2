extends Node

# in poziom statystyki

var ui_ammo_display: Control

var player: CharacterBody2D

var score: int
var level_timer: float
var current_objective_manager: Node = null

# Gówno pomiędzy misjami
var current_mission_id: String = ""
var last_completed_mission_id: String = ""
var was_mission_successful: bool = false
var last_objective_results: Array = []
var last_enemies_killed: int = 0
var last_enemies_arrested: int = 0
var last_civilians_killed: int = 0
var last_civilians_arrested: int = 0


func _physics_process(delta: float) -> void:
	level_timer += delta


func get_player() -> CharacterBody2D:
	return player


func set_player(new_player: CharacterBody2D) -> void:
	player = new_player


func start_new_level():
	print("clearing game manager")
	
	score = 0
	level_timer = 0
	last_objective_results.clear()
	current_objective_manager = null


func add_score(added_score):
	score += added_score


func get_score() -> int:
	return score


func get_level_timer() -> float:
	return level_timer
