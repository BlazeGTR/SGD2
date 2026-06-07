extends Resource
class_name ObjectiveResource

@export var title: String = "Nowy Cel"
@export_multiline var description: String = ""

@export_group("Eventy (Co nasłuchuje)")
@export var valid_events: Array[String] = [] # Np. ["enemy_killed", "enemy_arrested"]
@export var fail_events: Array[String] = [] # Np. ["hostage_killed"]

@export_group("Wymagania")
@export var is_mandatory: bool = true
@export var target_amount: int = 1
@export var auto_set_to_all_enemies: bool = false
@export var fail_if_not_enough_enemies: bool = false

# Zmienne wewnętrzne na czas trwania misji
var current_amount: int = 0
var is_completed: bool = false
var is_failed: bool = false

func reset_objective_state(total_enemies: int) -> void:
	current_amount = 0
	is_completed = false
	is_failed = false
	if auto_set_to_all_enemies:
		target_amount = total_enemies

func add_progress(amount: int) -> void:
	if is_completed or is_failed: return
	
	current_amount += amount
	if current_amount >= target_amount:
		current_amount = target_amount
		is_completed = true

func check_for_math_failure(total_enemies: int, enemies_killed: int, enemies_arrested: int) -> void:
	if is_completed or is_failed or not fail_if_not_enough_enemies: return
	
	# Obliczamy ilu wrogów fizycznie biega jeszcze po mapie
	var alive_enemies = total_enemies - (enemies_killed + enemies_arrested)
	
	# Jeśli dotychczasowy postęp + wszyscy żyjący wrogowie to wciąż za mało, żeby wygrać:
	print("Total enemies: ", current_amount + alive_enemies)
	print("Target amount: ", target_amount)
	if (current_amount + alive_enemies) < target_amount:
		is_failed = true
