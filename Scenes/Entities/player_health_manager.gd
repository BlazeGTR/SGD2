extends Node
class_name PlayerHealthComponent

@export var base_max_health: int = 100
var current_max_health: int
var health: int
var is_dead: bool = false

func _ready() -> void:
	current_max_health = base_max_health

	var loadout = SaveManager.current_data.get("active_loadout", {})
	var equipped_armor_id = loadout.get("armor", "none")
	
	var armor_data = ItemDatabase.get_armor_by_id(equipped_armor_id)
	
	if armor_data != null:
		current_max_health += armor_data.bonus_health
		print("PlayerHealthComponent: Wyposażono ", armor_data.name, ". Nowe max HP: ", current_max_health)
	else:
		print("PlayerHealthComponent: Gracz nie ma pancerza. Max HP: ", current_max_health)
		
	health = current_max_health
	
	await get_tree().process_frame
	SignalBus.player_health_changed.emit(health, current_max_health)


func take_damage(damage: int, _morale_damage: int):
	if is_dead: 
		return
		
	health -= damage
	SignalBus.player_health_changed.emit(health, current_max_health)
	
	if health <= 0:
		die()


func die():
	is_dead = true
	
	var player = get_parent()
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
		# TODO: Odpalenie animacji śmierci gracza
	
	SignalBus.player_died.emit()
