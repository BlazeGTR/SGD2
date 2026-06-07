extends Node

const SETTINGS_PATH = "user://settings.cfg"
var config = ConfigFile.new()

# na razie to samo aspect ratio chuj
const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

func _ready() -> void:
	_load_settings()

# ==========================================
# WIDEO
# ==========================================

func set_resolution(index: int) -> void:
	if index < 0 or index >= RESOLUTIONS.size(): return
	
	var res = RESOLUTIONS[index]
	config.set_value("Video", "resolution_index", index)
	DisplayServer.window_set_size(res)
	
	# Wyśrodkowujemy okno tylko wtedy, gdy NIE jesteśmy w pełnym ekranie
	if get_window_mode() != 2:
		var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
		var window_pos = screen_center - res / 2
		DisplayServer.window_set_position(window_pos)
		
	_save_settings()


func get_resolution_index() -> int:
	return config.get_value("Video", "resolution_index", 2) # Domyślnie 1920x1080


func set_window_mode(index: int) -> void:
	config.set_value("Video", "window_mode", index)
	match index:
		0: # Windowed (Zwykłe okno z paskiem Windowsa)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			
		1: # Borderless Fullscreen (Szybki Alt-Tab, przykrywa cały ekran, rozciąga obraz)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			
		2: # Exclusive Fullscreen (Ekskluzywny pełny ekran, karta graficzna zmienia tryb monitora)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	# Ponowna aplikacja rozdzielczości (Kluczowe dla Windowed i Exclusive)
	set_resolution(get_resolution_index())
	
	_save_settings()


func get_window_mode() -> int:
	return config.get_value("Video", "window_mode", 0) # Domyślnie Windowed


func set_vsync(enabled: bool) -> void:
	config.set_value("Video", "vsync", enabled)
	var mode = DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)
	_save_settings()


func get_vsync() -> bool:
	return config.get_value("Video", "vsync", true)


func set_brightness(value: float) -> void:
	config.set_value("Video", "brightness", value)
	if SignalBus.has_user_signal("brightness_changed"):
		SignalBus.emit_signal("brightness_changed", value)
	_save_settings()


func get_brightness() -> float:
	return config.get_value("Video", "brightness", 1.0) # Domyślnie 1.0 

# ==========================================
# AUDIO
# ==========================================

func set_volume(bus_name: String, value: float) -> void:
	# value to wartość od 0.0001 (żeby uniknąć błędu logarytmu z 0) do 1.0
	var safe_value = max(value, 0.0001)
	config.set_value("Audio", bus_name, safe_value)
	
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(safe_value))
		AudioServer.set_bus_mute(bus_index, value <= 0.001)
	
	_save_settings()


func get_volume(bus_name: String) -> float:
	if bus_name == "Master": return config.get_value("Audio", "Master", 1.0)
	if bus_name == "Music": return config.get_value("Audio", "Music", 0.8)
	if bus_name == "SFX": return config.get_value("Audio", "SFX", 1.0)
	return 1.0


# ==========================================
# STEROWANIE
# ==========================================

func set_sensitivity(value: float) -> void:
	config.set_value("Controls", "sensitivity", value)
	_save_settings()


func get_sensitivity() -> float:
	return config.get_value("Controls", "sensitivity", 1.0)


func rebind_action(action_name: String, new_event: InputEvent) -> void:
	# Czyszczenie starych przypisań w silniku
	InputMap.action_erase_events(action_name)
	# Dodanie nowego
	InputMap.action_add_event(action_name, new_event)
	# Zapisanie obiektu InputEvent do pliku config
	config.set_value("Binds", action_name, new_event)
	_save_settings()

# ==========================================
# SYSTEM PLIKÓW I INICJALIZACJA
# ==========================================

func _save_settings() -> void:
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var err = config.load(SETTINGS_PATH)
	
	if err != OK:
		print("Brak pliku ustawień. Ładowanie i zapisywanie wartości domyślnych.")
		_apply_default_settings()
		return
	
	print("Wczytano plik ustawień. Aplikowanie...")
	
	# Aplikowanie Wideo
	set_resolution(get_resolution_index())
	set_window_mode(get_window_mode())
	set_vsync(get_vsync())
	# Jasność zaaplikuje się sama, gdy mapa odbierze sygnał (bo WorldEnvironment nie ma w Autoload)
	
	# Aplikowanie Audio
	set_volume("Master", get_volume("Master"))
	set_volume("Music", get_volume("Music"))
	set_volume("SFX", get_volume("SFX"))
	
	# Aplikowanie Sterowania (nadpisywanie InputMap z pliku)
	if config.has_section("Binds"):
		for action_name in config.get_section_keys("Binds"):
			var saved_event = config.get_value("Binds", action_name)
			if saved_event is InputEvent:
				InputMap.action_erase_events(action_name)
				InputMap.action_add_event(action_name, saved_event)


func _apply_default_settings() -> void:
	# Wywoływane tylko przy pierwszym uruchomieniu gry
	set_resolution(2) # 1920x1080
	set_window_mode(0) # Windowed
	set_vsync(true)
	set_brightness(1.0)
	
	set_volume("Master", 1.0)
	set_volume("Music", 0.8)
	set_volume("SFX", 1.0)
	
	set_sensitivity(1.0)
	# Bindy używają tych ustawionych fabrycznie w Godocie (Project Settings -> Input Map),
	# dopóki gracz ich ręcznie nie zmieni.
