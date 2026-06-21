extends Node
class_name LocomotionComponent

@export var speed: float = 150.0
@onready var nav_agent: NavigationAgent2D = $"../NavigationAgent2D"
@onready var parent: CharacterBody2D = get_parent()

var _is_stopped: bool = true
var is_waiting: bool = false
var interaction_pause_duration: float = 0.5
var _interaction_timer: float = 0.0

func _ready():
	nav_agent.velocity_computed.connect(_on_velocity_computed)


func _physics_process(delta: float):
	if is_waiting:
		_interaction_timer -= delta
		if _interaction_timer <= 0:
			is_waiting = false


func move_to(target_pos: Vector2):
	_is_stopped = false # Pozwalamy na ruch
	if nav_agent.target_position.distance_squared_to(target_pos) > 10.0:
		nav_agent.target_position = target_pos
	
	if nav_agent.is_navigation_finished():
		stop()
		return

	var next_pos = nav_agent.get_next_path_position()
	var dir = parent.global_position.direction_to(next_pos)
	var velocity_to_set = dir * speed
	
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(velocity_to_set)
	else:
		_on_velocity_computed(velocity_to_set)


func stop():
	_is_stopped = true # PODNOSIMY BLOKADĘ
	nav_agent.target_position = parent.global_position
	parent.velocity = Vector2.ZERO
	# Wymuszamy natychmiastowe zatrzymanie w silniku fizyki
	parent.move_and_slide() 


func _on_velocity_computed(safe_velocity: Vector2):
	# Jeśli flaga _is_stopped jest aktywna, IGNORUJEMY wszystko co mówi nawigacja
	if _is_stopped or is_waiting:
		parent.velocity = Vector2.ZERO
		# Nie wywołujemy move_and_slide(), żeby nie kontynuować starego ruchu
		return

	parent.velocity = safe_velocity
	parent.move_and_slide()
	
	check_for_interactables()


func flee_from(target_pos: Vector2):
	var dir = target_pos.direction_to(parent.global_position)
	var flee_pos = parent.global_position + dir * 200.0
	move_to(flee_pos)


func check_for_interactables():
	for i in parent.get_slide_collision_count():
		var collision = parent.get_slide_collision(i)
		var collider = collision.get_collider()
		print("interactables: " ,collider)
		
		var target = find_interactable_in_collider(collider)
		if target:
			if "is_open" in target:
				target.interact(parent)
				pause_movement_for_interaction(interaction_pause_duration)
				break


func find_interactable_in_collider(col):
	if not col:
		return null
	if col.has_method("interact"):
		return col
	

func pause_movement_for_interaction(duration: float):
	is_waiting = true
	_interaction_timer = duration
