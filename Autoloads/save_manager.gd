extends Node

# Aktualny stan gry załadowany do pamięci RAM
var current_data: Dictionary = {}
var current_slot: int = 1

# --- HASŁO DO SZYFROWANIA ---
# Gwarantuje, że pliku nie da się łatwo zedytować w Notatniku
const SAVE_PASSWORD = "Cyber_Ninja_Secret_Key_2026!@#"


# ==========================================
# STRUKTURA ZAPISU I INICJALIZACJA
# ==========================================

func get_default_data() -> Dictionary:
	return {
		"unlocked_items": ["Pistol", "light_armor", "Rifle", "Taser"], # Teraz trzyma wszystkie przedmioty
		"active_loadout": {
			"primary": "none",
			"secondary": "Pistol",
			"gadget": "none",
			"tactical": "none",
			"armor": "light_armor",
			"implant": "implant_none"
		},
		"levels": {
			"level_1": {"status": "unlocked", "grade": "none", "score": 0},
			"level_2": {"status": "locked", "grade": "none", "score": 0},
			"level_3": {"status": "locked", "grade": "none", "score": 0}
		},
		"current_money": 0,
		"tutorial_seen": false
	}

# ==========================================
# GŁÓWNA LOGIKA PLIKÓW (ZAPIS / ODCZYT)
# ==========================================

func save_game(slot_id: int = current_slot) -> void:
	var save_path = "user://save_slot_" + str(slot_id) + ".save"
	
	# Otwieramy plik używając szyfrowania
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, SAVE_PASSWORD)
	
	if file:
		var json_string = JSON.stringify(current_data)
		file.store_string(json_string)
		file.close()
		print("Zaszyfrowano i zapisano grę w slocie: ", slot_id)
	else:
		push_error("Nie udało się otworzyć pliku do zapisu: ", save_path)


func load_game(slot_id: int) -> bool:
	var save_path = "user://save_slot_" + str(slot_id) + ".save"
	
	# Jeśli plik nie istnieje, to znaczy, że slot jest pusty
	if not FileAccess.file_exists(save_path):
		print("Brak pliku zapisu w slocie ", slot_id, ". Ładowanie domyślnych danych.")
		current_data = get_default_data()
		current_slot = slot_id
		return false # Zwracamy false, żeby Menu wiedziało, że to "Nowa Gra" na tym slocie
		
	# Odczytujemy plik używając TEGO SAMEGO HASŁA
	var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.READ, SAVE_PASSWORD)
	
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var parsed_data = JSON.parse_string(json_string)
		
		if parsed_data is Dictionary:
			current_data = parsed_data
			current_slot = slot_id
			print("Rozszyfrowano i wczytano grę ze slota: ", slot_id)
			return true
		else:
			push_error("Plik zapisu jest uszkodzony (To nie jest Słownik).")
			current_data = get_default_data()
			return false
	else:
		# Odpali się, jeśli np. ktoś z zewnątrz zmienił plik i suma kontrolna się nie zgadza
		push_error("BŁĄD KRYTYCZNY: Nie można odszyfrować zapisu! Uszkodzony plik lub błędne hasło.")
		current_data = get_default_data()
		return false

# ==========================================
# API DLA RESZTY GRY (ZARZĄDZANIE PROGRESJĄ)
# ==========================================

func unlock_item(item_id: String) -> void:
	if not current_data["unlocked_items"].has(item_id):
		current_data["unlocked_items"].append(item_id)
		save_game()


func update_level_score(level_id: String, status: String, grade: String, score: int) -> void:
	if current_data["levels"].has(level_id):
		current_data["levels"][level_id]["status"] = status
		current_data["levels"][level_id]["grade"] = grade
		
		# Nadpisz wynik tylko jeśli nowy jest wyższy (lepszy) niż poprzedni
		if score > current_data["levels"][level_id]["score"]:
			current_data["levels"][level_id]["score"] = score
			
		save_game() # Zapisujemy statystyki po przejściu poziomu
	else:
		push_error("Próba zapisu wyniku dla nieistniejącego poziomu: ", level_id)
