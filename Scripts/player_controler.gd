extends CharacterBody2D


@export var max_speed = 300.0
var current_speed: float
@export var acceleration = 100
@onready var muzzle_position: Marker2D = $WeaponManager/MuzzlePosition
@onready var shout_raycast: RayCast2D = $ShoutRaycast
@onready var interaction_area: Area2D = $InteractionArea
@onready var health_manager: Node = $HealthManager


func _ready() -> void:
	GameManager.set_player(self)


func _process(delta: float) -> void:
	queue_redraw()


func _physics_process(delta: float) -> void:
	
	### Movement
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	if direction:
		velocity = velocity.move_toward(direction * max_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration)

	move_and_slide()

	### Looking
	var mouse_pos = get_global_mouse_position()
	
	var to_mouse = mouse_pos - global_position
	var dist_to_mouse = to_mouse.length()

	var m_pos = muzzle_position.position

	var angle_to_mouse = to_mouse.angle()
	var convergence_offset = atan2(m_pos.y, dist_to_mouse) 
	
	global_rotation = angle_to_mouse - convergence_offset


func _input(event: InputEvent) -> void:
### Yelling
	if event.is_action_pressed("Shout"):
		# Łączymy wrogów i cywili w jedną tymczasową listę do sprawdzenia
		var all_targets = GameManager.enemies_left_alive + GameManager.hostages_left_alive
		
		for target in all_targets:
			if not is_instance_valid(target):
				continue
				
			shout_raycast.target_position = shout_raycast.to_local(target.global_position)
			shout_raycast.force_raycast_update()
			
			if shout_raycast.is_colliding():
				var collider = shout_raycast.get_collider()
				if collider == target:
					# Pobieramy mózg celu i każemy mu zareagować na krzyk
					var brain = collider.get_node_or_null("BrainComponent")
					if brain and brain.has_method("hear_shout"):
						brain.hear_shout()
					else:
						# Fallback dla starego kodu wrogów
						var h = collider.get_node_or_null("HealthComponent")
						if h: h.morale_check()
	
	if event.is_action_pressed("Interact"):
		interaction_area.interact_with_target()
