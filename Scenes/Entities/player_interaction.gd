extends Area2D

@onready var interaction_shape: CollisionShape2D = $InteractionShape
@onready var interaction_raycast: RayCast2D = $InteractionRaycast
@onready var player: CharacterBody2D = $".."

var current_target: Node2D = null

func _physics_process(delta: float) -> void:
	get_best_target()


### Updejtuje current_target do najlepszego celu
func get_best_target():
	
	var interactables = get_overlapping_areas()
	var best_target = null
	var closest_angle_dot_product = -1.0
	var forward = Vector2.RIGHT.rotated(global_rotation)

	for interactable in interactables:
		if interactable.has_method("interact"):
			# kradniemy na chwile ten raycast
			# chuj jednak robimy nowy
			var dist = global_position.distance_to(interactable.global_position)
			if dist > interaction_shape.shape.radius/2:
				interaction_raycast.target_position = interaction_raycast.to_local(interactable.global_position)
				interaction_raycast.force_raycast_update()
				if interaction_raycast.is_colliding() and interaction_raycast.get_collider() != interactable:
					continue # jest za daleko i coś blokuje
				
			var to_interactable = (interactable.global_position - global_position). normalized()
			var angle_dot_product = forward.dot(to_interactable)
			
			if angle_dot_product > closest_angle_dot_product:
				closest_angle_dot_product = angle_dot_product
				best_target = interactable
		else:
			print("huh?")
	update_highlight(best_target)
	current_target = best_target


### zmienia podświetlenia tak aby tylko jeden najlepszy miał
func update_highlight(new_target: Node2D):
	if  new_target != current_target:
		if is_instance_valid(current_target) and current_target.has_method("set_highlight"):
			current_target.set_highlight(false)
		if is_instance_valid(new_target) and new_target.has_method("set_highlight"):
			new_target.set_highlight(true)


func interact_with_target():
	if current_target:
		current_target.interact(player)
