extends Node


var enemies_left_alive: Array = []
var hostages_left_alive: Array = []
var total_enemies_at_start: int = 0
var total_civilians_at_start: int = 0
var enemies_killed: int = 0
var enemies_arrested: int = 0
var civilians_killed: int = 0
var civilians_arrested: int = 0

func _ready():
	add_to_group("actor_manager")
	SignalBus.arrest_enemy.connect(arrest_enemy)
	SignalBus.arrest_hostage.connect(arrest_hostage)
	SignalBus.kill_enemy.connect(kill_enemy)
	SignalBus.kill_hostage.connect(kill_hostage)


func start_new_level():
	enemies_left_alive = []
	hostages_left_alive = []
	total_enemies_at_start = 0
	enemies_killed = 0
	enemies_arrested = 0


func add_new_enemy(enemy):
	enemies_left_alive.append(enemy)
	total_enemies_at_start += 1


func add_new_hostage(hostage):
	hostages_left_alive.append(hostage)
	total_civilians_at_start += 1


func kill_enemy(enemy):
	enemies_left_alive.erase(enemy)
	enemies_killed += 1
	GameManager.last_enemies_killed = enemies_killed


func arrest_enemy(enemy):
	enemies_left_alive.erase(enemy)
	enemies_arrested += 1
	GameManager.last_enemies_arrested = enemies_arrested


func kill_hostage(hostage):
	hostages_left_alive.erase(hostage)
	civilians_killed += 1
	GameManager.last_civilians_killed = civilians_killed


func arrest_hostage(hostage):
	hostages_left_alive.erase(hostage)
	civilians_arrested += 1
	GameManager.last_civilians_arrested = civilians_arrested


func report_sound(origin: Vector2, radius: float):
	var all_actors = enemies_left_alive + hostages_left_alive
	for actor in all_actors:
		if is_instance_valid(actor):
			var distance = origin.distance_to(actor.global_position)
			
			if distance <= radius:
				var brain = actor.get_node_or_null("BrainComponent")
				if brain and brain.has_method("hear_sound"):
					brain.hear_sound(origin)
