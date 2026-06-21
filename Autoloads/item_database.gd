extends Node

var weapons: Dictionary = {}
var equipment: Dictionary = {}

# TODO: zamienić to na resource tak jak bronie
var non_weapon_db: Dictionary = {
	"none": {"name": "None", "desc": "Empty slot", "stats": "-", "price": 0},
	"implant_none": {"name": "None", "desc": "No implants", "stats": "-", "price": 0},
	"implant_reflex": {"name": "Synaptic connection", "desc": "Allows you to slow down time (not working rn)", "stats": "Czas trwania: 3s\nCD: 15s", "price": 2500}
}


func _ready() -> void:
	_load_resources_from_dir("res://Resources/Weapons/", weapons)
	_load_resources_from_dir("res://Resources/Equipment/", equipment)
	print(get_all_armor_ids())
	print(get_all_weapon_ids())


func _load_resources_from_dir(path: String, target_dict: Dictionary) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				# Naprawa pod wyeksportowaną wersję gry
				var clean_name = file_name.replace(".remap", "")
				
				if clean_name.ends_with(".tres") or clean_name.ends_with(".res"):
					var item_id = clean_name.get_basename()
					var resource_path = path + "/" + clean_name
					var res = load(resource_path)
					if res:
						target_dict[item_id] = res
			file_name = dir.get_next()
		dir.list_dir_end()
		print("ItemDatabase: Załadowano zasoby z ", path, " (", target_dict.size(), " szt.)")
	else:
		push_error("ItemDatabase: Nie można otworzyć ścieżki: " + path)


func get_weapon_by_id(item_id: String) -> WeaponResource:
	return weapons.get(item_id, null)

func get_armor_by_id(item_id: String) -> ArmorResource:
	return equipment.get(item_id, null)

# Zwraca wszystkie ID broni jako tablicę
func get_all_weapon_ids() -> Array[String]:
	var keys: Array[String] = []
	for key in weapons.keys():
		keys.append(key as String)
	return keys


func get_all_armor_ids() -> Array[String]:
	var keys: Array[String] = []
	for key in equipment.keys():
		keys.append(key as String)
	return keys
