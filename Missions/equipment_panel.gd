extends Control

# --- ZAKŁADKI (Tabs) ---
@onready var btn_primary = $WeaponSlots/Primary
@onready var btn_secondary = $WeaponSlots/Secondary
@onready var btn_gadget = $WeaponSlots/Gadget
@onready var btn_tactical = $WeaponSlots/Tactical
@onready var btn_armor = $WeaponSlots/Armor
@onready var btn_implant = $WeaponSlots/Implant

# --- DETALE I WYBÓR  ---
@onready var tex_weapon_image = $HBoxContainer/SelectedWeaponInfo/HBoxContainer/VBoxContainer/WeaponImage/WeaponImageTexture
@onready var btn_prev = $HBoxContainer/SelectedWeaponInfo/HBoxContainer/VBoxContainer/ItemSelector/BtnPrev
@onready var lbl_item_name = $HBoxContainer/SelectedWeaponInfo/HBoxContainer/VBoxContainer/ItemSelector/LblItemName
@onready var btn_next = $HBoxContainer/SelectedWeaponInfo/HBoxContainer/VBoxContainer/ItemSelector/BtnNext
@onready var lbl_description = $HBoxContainer/SelectedWeaponInfo/HBoxContainer/VBoxContainer/WeaponDescription
@onready var lbl_stats = $HBoxContainer/SelectedWeaponInfo/HBoxContainer/Weaponinfo

# --- PODSUMOWANIE ---
@onready var lbl_cur_primary = $HBoxContainer/LoadoutInfo/VBoxContainer/CurrentPrimary
@onready var lbl_cur_secondary = $HBoxContainer/LoadoutInfo/VBoxContainer/CurrentSecondary
@onready var lbl_cur_gadget = $HBoxContainer/LoadoutInfo/VBoxContainer/CurrentGadget
@onready var lbl_cur_tactical = $HBoxContainer/LoadoutInfo/VBoxContainer/CurrentTactical
@onready var lbl_cur_armor = $HBoxContainer/LoadoutInfo/VBoxContainer/CurrentArmor
@onready var lbl_cur_implant = $HBoxContainer/LoadoutInfo/VBoxContainer/CurrentImplant

# --- STAN UI ---
var current_loadout: Dictionary = {}
var active_slot: String = "primary" 
var available_items: Array[String] = [] 
var current_item_index: int = 0 

@export_category("DEBUG")
@export var unlock_all_weapons: bool = false


func _ready() -> void:
	# Automatyczne odświeżanie przy przełączaniu paneli
	visibility_changed.connect(_on_visibility_changed)
	_refresh_equipment()
	
	btn_primary.pressed.connect(func(): _select_slot("primary"))
	btn_secondary.pressed.connect(func(): _select_slot("secondary"))
	btn_gadget.pressed.connect(func(): _select_slot("gadget"))
	btn_tactical.pressed.connect(func(): _select_slot("tactical"))
	btn_armor.pressed.connect(func(): _select_slot("armor"))
	btn_implant.pressed.connect(func(): _select_slot("implant"))
	
	btn_prev.pressed.connect(_on_prev_pressed)
	btn_next.pressed.connect(_on_next_pressed)

func _on_visibility_changed() -> void:
	if visible:
		_refresh_equipment()

func _refresh_equipment() -> void:
	# Ładujemy najświeższy stan zapisu z RAMu
	current_loadout = SaveManager.current_data.get("active_loadout", {}).duplicate()
	_update_loadout_summary()
	_select_slot(active_slot)

# ==========================================
# LOGIKA ZAKŁADEK I LISTY 
# ==========================================

func _select_slot(slot_name: String) -> void:
	active_slot = slot_name
	available_items = _get_items_for_slot(slot_name)
	
	var equipped_item = current_loadout.get(slot_name, "none")
	current_item_index = available_items.find(equipped_item)
	
	if current_item_index == -1:
		current_item_index = 0
		
	_update_display()


func _get_items_for_slot(slot_name: String) -> Array[String]:
	var list: Array[String] = []
	
	var unlocked: Array = []
	if not unlock_all_weapons:
		unlocked = SaveManager.current_data.get("unlocked_items", [])
	else:
		unlocked.append_array(ItemDatabase.get_all_weapon_ids())
		unlocked.append_array(ItemDatabase.get_all_armor_ids())
		unlocked.append_array(ItemDatabase.non_weapon_db.keys())
	
	var none_id = "implant_none" if slot_name == "implant" else "none"
	list.append(none_id)
	
	var enum_mapping = {"primary": 0, "secondary": 1, "gadget": 2, "tactical": 3}
	
	for item_id in unlocked:
		if slot_name in ["primary", "secondary", "gadget", "tactical"]:
			var weapon = ItemDatabase.get_weapon_by_id(item_id)
			if weapon and weapon.slotype == enum_mapping[slot_name]:
				list.append(item_id)
		elif slot_name == "armor":
			if ItemDatabase.get_armor_by_id(item_id) != null:
				list.append(item_id)
		else:
			# TODO: Dodać implanty
			if slot_name in item_id and ItemDatabase.non_weapon_db.has(item_id):
				list.append(item_id)
				
	return list

# ==========================================
# LOGIKA STRZAŁEK
# ==========================================

func _on_prev_pressed() -> void:
	if available_items.is_empty(): return
	
	current_item_index -= 1
	if current_item_index < 0:
		current_item_index = available_items.size() - 1 
		
	_apply_selection()

func _on_next_pressed() -> void:
	if available_items.is_empty(): return
	
	current_item_index += 1
	if current_item_index >= available_items.size():
		current_item_index = 0 
		
	_apply_selection()

func _apply_selection() -> void:
	var selected_item_id = available_items[current_item_index]
	current_loadout[active_slot] = selected_item_id
	SaveManager.current_data["active_loadout"] = current_loadout
	SaveManager.save_game()
	
	_update_display()
	_update_loadout_summary()

# ==========================================
# WIDOKI (Odświeżanie UI)
# ==========================================

func _update_display() -> void:
	if available_items.is_empty(): return
	var item_id = available_items[current_item_index]
	
	if item_id == "none" or item_id == "implant_none":
		lbl_item_name.text = "NONE"
		lbl_description.text = "Empty loadout slot"
		lbl_stats.text = "-"
		tex_weapon_image.texture = null
		return
		
	var weapon = ItemDatabase.get_weapon_by_id(item_id)
	if weapon:
		lbl_item_name.text = weapon.name
		lbl_description.text = weapon.description
		
		var stats = "Manufacturer:\n" + weapon.manufacturer + "\n"
		stats += "Caliber:\n" + weapon.cartridge + "\n"
		stats += "Action:\n" + weapon.action + "\n\n"
		stats += "Damage:\n" + str(weapon.damage) + "\n"
		stats += "Magazine size:\n" + str(weapon.magazine_size)
		
		lbl_stats.text = stats
		tex_weapon_image.texture = weapon.weapon_hud_icon if weapon.weapon_hud_icon else weapon.texture
		return
		
	var armor = ItemDatabase.get_armor_by_id(item_id)
	if armor:
		lbl_item_name.text = armor.name
		lbl_description.text = armor.description
		
		var stats = "Manufacturer:\n" + armor.manufacturer + "\n"
		stats += "Material:\n" + armor.material + "\n"
		stats += "Bonus HP:\n+" + str(armor.bonus_health) + "\n"
		stats += "Speed multiplier:\n" + str(armor.speed_multiplier * 100) + "%"
		
		lbl_stats.text = stats

		tex_weapon_image.texture = armor.armor_icon if armor.armor_icon else null
		return
		
	#TODO: dodać implanty
	if ItemDatabase.non_weapon_db.has(item_id):
		var item = ItemDatabase.non_weapon_db[item_id]
		lbl_item_name.text = item["name"]
		lbl_description.text = item["desc"]
		lbl_stats.text = item["stats"]
		tex_weapon_image.texture = null


func _update_loadout_summary() -> void:
	lbl_cur_primary.text = "Primary: \n" + _get_item_name(current_loadout.get("primary", "none"))
	lbl_cur_secondary.text = "Secondary: \n" + _get_item_name(current_loadout.get("secondary", "none"))
	lbl_cur_gadget.text = "Gadget:\n" + _get_item_name(current_loadout.get("gadget", "none"))
	lbl_cur_tactical.text = "Tactical: \n" + _get_item_name(current_loadout.get("tactical", "none"))
	lbl_cur_armor.text = "Armor: \n" + _get_item_name(current_loadout.get("armor", "none"))
	lbl_cur_implant.text = "Implant: \n" + _get_item_name(current_loadout.get("implant", "implant_none"))

func _get_item_name(item_id: String) -> String:
	if item_id == "none" or item_id == "implant_none": return "None"
	
	var weapon = ItemDatabase.get_weapon_by_id(item_id)
	if weapon: return weapon.name
	
	var equipment = ItemDatabase.get_armor_by_id(item_id)
	if equipment: return equipment.name
	
	if ItemDatabase.non_weapon_db.has(item_id): 
		return ItemDatabase.non_weapon_db[item_id]["name"]
		
	print("Zla nazwa przedmiotu: ", item_id)
	return "Unknown"
