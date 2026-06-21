extends Node
class_name HealthComponent

@export var max_health: float = 100
@export var max_morale: float = 100
var current_health = max_health
var current_morale = max_morale
var morale_changed: bool = true
@onready var brain_component: Node2D = $"../BrainComponent"
var stun_timer: Timer
var is_arrested: bool = false

var actor_manager

func _ready() -> void:
	actor_manager = get_tree().get_first_node_in_group("actor_manager")
	stun_timer = Timer.new()
	stun_timer.one_shot = true
	stun_timer.timeout.connect(finish_stun)
	add_child(stun_timer)


func take_damage(damage: float, morale_damage: float):
	current_health -= damage
	current_morale -= morale_damage
	brain_component.just_took_damage()
	if morale_damage > 0:
		morale_changed = true
	if current_health <= 0:
		die()


func stun_enemy(stun_time: float):
	stun_timer.start(stun_time)
	brain_component.is_stunned = true


func finish_stun():
	brain_component.is_stunned = false


func morale_check() -> void:
	if not morale_changed:
		return
	morale_changed = false
	var morale_roll = randf_range(0, 100)
	if morale_roll >= current_morale:
		brain_component.force_surrender()


func die():
	var parent = get_parent()
	
	if not is_arrested:
		if parent is Enemy:
			GameManager.add_score(parent.score)
			SignalBus.objective_event_triggered.emit("enemy_killed", 1)
			SignalBus.kill_enemy.emit(parent)
			
		elif parent is Hostage:
			GameManager.add_score(parent.score) 
			SignalBus.objective_event_triggered.emit("hostage_killed", 1)
			SignalBus.kill_hostage.emit(parent)
			
	else:
		if parent is Enemy:
			GameManager.add_score(-parent.score)
			SignalBus.objective_event_triggered.emit("arrested_enemy_killed", 1)
		elif parent is Hostage:
			GameManager.add_score(-parent.score * 3)
			SignalBus.objective_event_triggered.emit("arrested_hostage_killed", 1)
			
	#TODO: dać tu jakąś animacje umierania zamiast queue free
	parent.queue_free()


func get_arrested():
	is_arrested = true
