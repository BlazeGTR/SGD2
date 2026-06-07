extends Control

# --- TOP BAR (Zakładki) ---
@onready var btn_primary = $VBoxContainer/TopBarContainer/SlotButtons/Primary
@onready var btn_secondary = $VBoxContainer/TopBarContainer/SlotButtons/Secondary
@onready var btn_gadget = $VBoxContainer/TopBarContainer/SlotButtons/Gadget
@onready var btn_tactical = $VBoxContainer/TopBarContainer/SlotButtons/Tactical
@onready var btn_armor = $VBoxContainer/TopBarContainer/SlotButtons/Armor
@onready var btn_implant = $VBoxContainer/TopBarContainer/SlotButtons/Implant

# --- BOTTOM HBOX (Zawartość) ---
# UWAGA: Upewnij się, że usunąłeś ScrollContainer i ItemList jest bezpośrednio w ListContainer
@onready var item_list = $VBoxContainer/BottomHBox/ListContainer/ItemList 
@onready var lbl_item_name = $VBoxContainer/BottomHBox/DetailsContainer/VBoxContainer/ItemName
@onready var tex_weapon_image = $VBoxContainer/BottomHBox/DetailsContainer/VBoxContainer/ItemImage
@onready var lbl_description = $VBoxContainer/BottomHBox/DetailsContainer/VBoxContainer/ItemDescription
@onready var lbl_stats = $VBoxContainer/BottomHBox/DetailsContainer/VBoxContainer/ItemStats
@onready var btn_buy = $VBoxContainer/BottomHBox/DetailsContainer/VBoxContainer/BuyButton
@onready var lbl_player_money = $VBoxContainer/TopBarContainer/PlayerMoneyLabel 

var active_slot: String = "primary"
var items_in_current_category: Array[String] = []
var selected_item_id: String = ""

func _ready() -> void:
	_connect_signals()
	# Automatyczne odświeżanie przy każdym pokazaniu sklepu
	visibility_changed.connect(_on_visibility_changed)
	_refresh_shop()

func _on_visibility_changed() -> void:
	if visible:
		_refresh_shop()

func _refresh_shop() -> void:
	_update_money_display()
	_select_category(active_slot)

func _connect_signals() -> void:
	btn_primary.pressed.connect(func(): _select_category("primary"))
	btn_secondary.pressed.connect(func(): _select_category("secondary"))
	btn_gadget.pressed.connect(func(): _select_category("gadget"))
	btn_tactical.pressed.connect(func(): _select_category("tactical"))
	btn_armor.pressed.connect(func(): _select_category("armor"))
	btn_implant.pressed.connect(func(): _select_category("implant"))
	
	item_list.item_selected.connect(_on_item_selected_from_list)
	btn_buy.pressed.connect(_on_buy_pressed)

func _update_money_display() -> void:
	var current_money = SaveManager.current_data.get("current_money", 0)
	lbl_player_money.text = "BUDŻET: $" + str(current_money)

# ==========================================
# LOGIKA WYBORU KATEGORII
# ==========================================

func _select_category(slot_name: String) -> void:
	active_slot = slot_name
	items_in_current_category.clear()
	item_list.clear() 
	
	var enum_mapping = {"primary": 0, "secondary": 1, "gadget": 2, "tactical": 3}
	var index = 0
	
	var all_weapon_ids = ItemDatabase.get_all_weapon_ids()
	
	for w_id in all_weapon_ids:
		if slot_name in ["primary", "secondary", "gadget", "tactical"]:
			var w = ItemDatabase.get_weapon_by_id(w_id)
			if w and w.slotype == enum_mapping[slot_name]:
				items_in_current_category.append(w_id)
				_add_item_to_ui_list(w.name, w_id, index)
				index += 1
				
	for db_id in ItemDatabase.non_weapon_db.keys():
		if slot_name in db_id and db_id != "none" and db_id != "implant_none":
			items_in_current_category.append(db_id)
			_add_item_to_ui_list(ItemDatabase.non_weapon_db[db_id]["name"], db_id, index)
			index += 1

	if items_in_current_category.size() > 0:
		item_list.select(0)
		_on_item_selected_from_list(0)
	else:
		_clear_details()

func _add_item_to_ui_list(display_name: String, item_id: String, index: int) -> void:
	item_list.add_item(display_name)
	
	var unlocked = SaveManager.current_data.get("unlocked_items", [])
	if item_id in unlocked:
		item_list.set_item_custom_fg_color(index, Color.GREEN) 

# ==========================================
# LOGIKA WYBORU DETALI I ZAKUPU
# ==========================================

func _on_item_selected_from_list(index: int) -> void:
	if index < 0 or index >= items_in_current_category.size(): return
	
	selected_item_id = items_in_current_category[index]
	_update_details_panel(selected_item_id)

func _update_details_panel(item_id: String) -> void:
	var item_name = ""
	var desc = ""
	var stats = ""
	var price = 0
	var texture = null
	
	var weapon = ItemDatabase.get_weapon_by_id(item_id)
	if weapon:
		item_name = weapon.name
		desc = weapon.description
		stats = "Obr: " + str(weapon.damage) + "\nMag: " + str(weapon.magazine_size)
		price = weapon.price 
		texture = weapon.weapon_hud_icon if weapon.weapon_hud_icon else weapon.texture
	elif ItemDatabase.non_weapon_db.has(item_id):
		item_name = ItemDatabase.non_weapon_db[item_id]["name"]
		desc = ItemDatabase.non_weapon_db[item_id]["desc"]
		stats = ItemDatabase.non_weapon_db[item_id]["stats"]
		price = ItemDatabase.non_weapon_db[item_id]["price"]
		
	lbl_item_name.text = item_name
	lbl_description.text = desc
	lbl_stats.text = stats
	tex_weapon_image.texture = texture
	
	_update_buy_button(item_id, price)

func _update_buy_button(item_id: String, price: int) -> void:
	var unlocked = SaveManager.current_data.get("unlocked_items", [])
	var current_money = SaveManager.current_data.get("current_money", 0)
	
	if item_id in unlocked:
		btn_buy.text = "POSIADANE"
		btn_buy.disabled = true
	else:
		btn_buy.text = "KUP: $" + str(price)
		btn_buy.disabled = current_money < price

func _on_buy_pressed() -> void:
	if selected_item_id == "": return
	
	var price = 0
	var weapon = ItemDatabase.get_weapon_by_id(selected_item_id)
	if weapon: 
		price = weapon.price
	elif ItemDatabase.non_weapon_db.has(selected_item_id): 
		price = ItemDatabase.non_weapon_db[selected_item_id]["price"]
	
	var current_money = SaveManager.current_data.get("current_money", 0)
	
	if current_money >= price:
		SaveManager.current_data["current_money"] -= price
		SaveManager.unlock_item(selected_item_id) 
		
		_update_money_display()
		_update_buy_button(selected_item_id, price)
		
		var index = items_in_current_category.find(selected_item_id)
		if index != -1:
			item_list.set_item_custom_fg_color(index, Color.GREEN)

func _clear_details() -> void:
	lbl_item_name.text = "Wybierz przedmiot"
	lbl_description.text = ""
	lbl_stats.text = ""
	tex_weapon_image.texture = null
	btn_buy.text = "-"
	btn_buy.disabled = true
