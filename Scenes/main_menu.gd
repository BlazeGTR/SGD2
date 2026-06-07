extends Control

@export_group("Sceny Docelowe")
@export var new_game_scene: PackedScene 
@export var level_select_scene: PackedScene 

@export_group("Ustawienia Animacji")
@export var slide_duration: float = 0.5 # Czas trwania wjazdu w sekundach

# ==========================================
# KONFIGURACJA ŚCIEŻKI ZAPISU
# ==========================================
const SAVE_FILE_TEMPLATE = "user://save_slot_%s.save"

# ==========================================
# REFERENCJE WĘZŁÓW
# ==========================================

# --- GŁÓWNE MENU ---
@onready var main_buttons_container = $MainButtons
@onready var btn_continue = $MainButtons/VBoxContainer/ButtonContinue
@onready var btn_new_game = $MainButtons/VBoxContainer/ButtonNewGame
@onready var btn_settings = $MainButtons/VBoxContainer/ButtonSettings
@onready var btn_credits = $MainButtons/VBoxContainer/ButtonCredits
@onready var btn_quit = $MainButtons/VBoxContainer/ButtonQuit

# --- PANEL SLOTÓW ---
@onready var save_slots_panel = $SaveSlotsPanel
@onready var btn_slot_1 = $SaveSlotsPanel/VBoxContainer/HBoxContainer/ButtonSlot1
@onready var btn_slot_2 = $SaveSlotsPanel/VBoxContainer/HBoxContainer/ButtonSlot2
@onready var btn_slot_3 = $SaveSlotsPanel/VBoxContainer/HBoxContainer/ButtonSlot3
@onready var btn_back_slots = $SaveSlotsPanel/VBoxContainer/ButtonBack

# --- PANEL USTAWIEŃ ---
@onready var settings_panel = $SettingsPanel
@onready var btn_close_settings = $SettingsPanel/ButtonCloseSettings

# Gra
@onready var sld_sensitivity = $SettingsPanel/TabContainer/Game/VBoxContainer/Sensitivity

# Wideo
@onready var opt_resolution = $SettingsPanel/TabContainer/Video/VBoxContainer/Resolution
@onready var opt_window_mode = $SettingsPanel/TabContainer/Video/VBoxContainer/ScreenMode
@onready var chk_vsync = $SettingsPanel/TabContainer/Video/VBoxContainer/VSync
@onready var sld_brightness = $SettingsPanel/TabContainer/Video/VBoxContainer/Brightness

# Audio
@onready var sld_master = $SettingsPanel/TabContainer/Audio/VBoxContainer/Master
@onready var sld_music = $SettingsPanel/TabContainer/Audio/VBoxContainer/Music
@onready var sld_sfx = $SettingsPanel/TabContainer/Audio/VBoxContainer/SFX
@export var menu_music: AudioStream

# --- ZMIENNE DO POZYCJONOWANIA ---
var main_start_pos: Vector2
var slots_start_pos: Vector2
var slide_distance: float

var is_starting_new_game: bool = false


# ==========================================
# INICJALIZACJA
# ==========================================

func _ready() -> void:
	AudioManager.play_music(menu_music)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	main_start_pos = main_buttons_container.position
	slots_start_pos = save_slots_panel.position
	
	# Obliczamy dystans przesunięcia (szerokość całego okna gry)
	slide_distance = get_viewport_rect().size.x
	
	# PRZYGOTOWANIE SCENY
	main_buttons_container.show()
	save_slots_panel.show()
	settings_panel.hide()
	
	# Wyrzucamy panel slotów poza ekran po prawej stronie
	save_slots_panel.position.x = slots_start_pos.x + slide_distance
	
	_connect_main_signals()
	_connect_settings_signals()
	_sync_settings_ui()
	
	_update_save_slots_text()


func _connect_main_signals() -> void:
	# Podpięcia Głównego Menu
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_settings.pressed.connect(_show_settings)
	btn_credits.pressed.connect(_on_credits_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	
	# Podpięcia Slotów
	btn_slot_1.pressed.connect(func(): _on_slot_selected(1))
	btn_slot_2.pressed.connect(func(): _on_slot_selected(2))
	btn_slot_3.pressed.connect(func(): _on_slot_selected(3))
	btn_back_slots.pressed.connect(_hide_save_slots)
	
	btn_continue.disabled = false


func _connect_settings_signals() -> void:
	btn_close_settings.pressed.connect(_hide_settings)
	
	# Wideo
	opt_resolution.item_selected.connect(func(index): SettingsManager.set_resolution(index))
	opt_window_mode.item_selected.connect(func(index): SettingsManager.set_window_mode(index))
	chk_vsync.toggled.connect(func(toggled_on): SettingsManager.set_vsync(toggled_on))
	sld_brightness.value_changed.connect(func(value): SettingsManager.set_brightness(value))
	
	# Audio
	sld_master.value_changed.connect(func(value): SettingsManager.set_volume("Master", value))
	sld_music.value_changed.connect(func(value): SettingsManager.set_volume("Music", value))
	sld_sfx.value_changed.connect(func(value): SettingsManager.set_volume("SFX", value))
	
	# Sterowanie
	sld_sensitivity.value_changed.connect(func(value): SettingsManager.set_sensitivity(value))


func _sync_settings_ui() -> void:
	# Wypełniamy opcje rozdzielczości
	opt_resolution.clear()
	for res in SettingsManager.RESOLUTIONS:
		opt_resolution.add_item(str(res.x) + "x" + str(res.y))
	
	# Aktualizujemy stan kontrolek
	opt_resolution.selected = SettingsManager.get_resolution_index()
	opt_window_mode.selected = SettingsManager.get_window_mode()
	chk_vsync.button_pressed = SettingsManager.get_vsync()
	sld_brightness.value = SettingsManager.get_brightness()
	
	sld_master.value = SettingsManager.get_volume("Master")
	sld_music.value = SettingsManager.get_volume("Music")
	sld_sfx.value = SettingsManager.get_volume("SFX")
	
	sld_sensitivity.value = SettingsManager.get_sensitivity()

# ==========================================
# LOGIKA MENU GŁÓWNEGO I SLOTÓW (Z ANIMACJĄ)
# ==========================================

func _update_save_slots_text() -> void:
	var buttons = [btn_slot_1, btn_slot_2, btn_slot_3]
	
	for i in range(buttons.size()):
		var slot_id = i + 1
		var file_path = SAVE_FILE_TEMPLATE % str(slot_id)
		
		if FileAccess.file_exists(file_path):
			# Pobieramy czas modyfikacji pliku (w sekundach UNIX)
			var unix_time = FileAccess.get_modified_time(file_path)
			
			# Konwertujemy na format daty, np. "2024-10-25T14:30:00"
			var date_str = Time.get_datetime_string_from_unix_time(unix_time, true)
			
			# Podmieniamy "T" na spację dla ładniejszego wyglądu (2024-10-25 14:30:00)
			date_str = date_str.replace("T", " ")
			
			# Ustawiamy tekst na guziku ze znakiem nowej linii
			buttons[i].text = "Slot " + str(slot_id) + "\n[" + date_str + "]"
		else:
			buttons[i].text = "Slot " + str(slot_id) + "\n[EMPTY]"


func _on_continue_pressed() -> void:
	is_starting_new_game = false
	show_save_slots_panel()


func _hide_save_slots() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(save_slots_panel, "position:x", slots_start_pos.x + slide_distance, slide_duration)
	tween.parallel().tween_property(main_buttons_container, "position:x", main_start_pos.x, slide_duration)


func _on_new_game_pressed() -> void:
	is_starting_new_game = true
	show_save_slots_panel()


func show_save_slots_panel():
	var tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(main_buttons_container, "position:x", main_start_pos.x - slide_distance, slide_duration)
	tween.parallel().tween_property(save_slots_panel, "position:x", slots_start_pos.x, slide_duration)


func _on_slot_selected(slot_id: int) -> void:
	if is_starting_new_game:
		print("Nadpisywanie/Tworzenie nowej gry w slocie nr: ", slot_id)
		
		SaveManager.current_data = SaveManager.get_default_data()
		SaveManager.current_slot = slot_id
		SaveManager.save_game() 
		
		if new_game_scene:
			get_tree().change_scene_to_packed(new_game_scene)
		else:
			push_error("Brak przypisanej sceny New Game!")
			
	else:
		print("Wczytywanie postępu ze slota nr: ", slot_id)
		var has_save = SaveManager.load_game(slot_id)
		
		if has_save:
			if new_game_scene:
				get_tree().change_scene_to_packed(new_game_scene)
			else:
				push_error("Brak przypisanej sceny (new_game_scene) do wczytania!")
		else:
			print("Ten slot jest pusty, nie można wczytać gry.")


# ==========================================
# LOGIKA USTAWIEŃ I POZOSTAŁE
# ==========================================

func _show_settings() -> void:
	settings_panel.show()


func _hide_settings() -> void:
	settings_panel.hide()


func _on_credits_pressed() -> void:
	print("Otwieram ekran twórców...")


func _on_quit_pressed() -> void:
	get_tree().quit()
