extends Node2D

var speed = 0.0
var damage = 0.0
var morale_damage = 0.0
@export var collision_margin: float = 10.0 # Zasięg "wyczuwania" ściany przed pociskiem
@onready var ray_cast: RayCast2D = $RayCast2D

func set_speed(new_speed: float) -> void:
	speed = new_speed

func set_damage(new_damage: float, new_morale_damage: float) -> void:
	damage = new_damage
	morale_damage = new_morale_damage


func _process(delta: float) -> void:
	var movement_vector = Vector2.RIGHT.rotated(rotation) * speed * delta
	
	# Ustawiamy zasięg raycastu na planowany ruch + margines
	ray_cast.target_position = Vector2(movement_vector.length() + collision_margin, 0)
	ray_cast.force_raycast_update()

	if ray_cast.is_colliding():
		# Jeśli uderzymy, teleportujemy pocisk do punktu styku i odpalamy on_hit
		global_position = ray_cast.get_collision_point()
		on_hit(ray_cast.get_collider())
	else:
		global_position += movement_vector


func on_hit(collider: Node2D) -> void:
	print(collider)
	apply_damage(collider)
	
	var mat: SurfaceMaterial = null
	
	# obsługa walnięcia w tilemap
	if collider is TileMapLayer:
		var hit_pos = ray_cast.get_collision_point()
		var normal = ray_cast.get_collision_normal()
		
		var inside_wall_pos = hit_pos - (normal * 4.0)
		
		var map_pos = collider.local_to_map(collider.to_local(inside_wall_pos))
		var tile_data = collider.get_cell_tile_data(map_pos)
		
		if tile_data:
			var data = tile_data.get_custom_data("surface_type")
			if data is SurfaceMaterial:
				mat = data
			else:
				print("DEBUG: Znaleziono kafelek, ale Custom Data 'surface_material' jest puste lub złego typu.")
		else:
			print("DEBUG: Nie znaleziono danych kafelka na pozycji: ", map_pos)

	# Obsługa zwykłych obiektów (przeciwnicy itp.)
	elif "surface_type" in collider:
		mat = collider.surface_type
		
	if mat:
		spawn_hit_effect(mat)
	else:
		print("DEBUG: Trafienie bez przypisanego materiału.")
	
	queue_free()


func spawn_hit_effect(mat: SurfaceMaterial) -> void:

	if mat.hit_effect:
		var effect = mat.hit_effect.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = global_position
		
		effect.rotation = ray_cast.get_collision_normal().angle()


func apply_damage(collider: Node):
	var health = collider.get_node_or_null("HealthComponent")
	print(health)
	if health:
		#damagable enemy
		if health.has_method("take_damage"):
			health.take_damage(damage, morale_damage)
		else:
			print("DEBUG: Hit enemy but no take_damage method ", collider)
		return
	if collider.has_method("destroy"):
		collider.destroy()
		return
