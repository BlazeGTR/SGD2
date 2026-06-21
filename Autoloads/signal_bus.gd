extends Node


# Weapon and UI
signal player_ammo_changed(current_ammo, magazine_size) 
signal player_weapon_changed(weapon_data)
signal player_health_changed(current: int, max_health: int)

# Ustawienia
signal brightness_changed(value)

# Gameplay
signal extraction_enabled(was_successful: bool)
signal objective_event_triggered(event_name, amount)
signal player_died

signal arrest_hostage
signal arrest_enemy
signal kill_hostage
signal kill_enemy
