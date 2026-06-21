extends Control

@export var all_missions: Array[MissionResource] # Przeciągnij pliki .tres misji w Inspektorze

@onready var mission_list_container = $MarginContainer/MainVBox/Panels/MissionSelectPanel/MissionSelectPanelVBox/LeftColumn/MissionListVBox
@onready var mission_description_label = $MarginContainer/MainVBox/Panels/MissionSelectPanel/MissionSelectPanelVBox/RightColumnBackground/RightColumn/MarginContainer/DescriptionLabel
@onready var mission_title_label = $MarginContainer/MainVBox/Panels/MissionSelectPanel/MissionSelectPanelVBox/RightColumnBackground/RightColumn/TitleLabel
@onready var animation_player = $CutsceneLayer/AnimationPlayer

@onready var debrief_success_label: Label = $MarginContainer/MainVBox/Panels/DebriefPanel/HBoxContainer/LeftBoxContainer/SuccessLabel
@onready var debrief_objectives_label: Label = $MarginContainer/MainVBox/Panels/DebriefPanel/HBoxContainer/LeftBoxContainer/ObjectivesContainer/ObjectivesLabel
@onready var debrief_objectives_status_label: RichTextLabel = $MarginContainer/MainVBox/Panels/DebriefPanel/HBoxContainer/LeftBoxContainer/ObjectivesContainer/ObjectivesStatusLabel
@onready var debrief_points_breakdown: Label = $MarginContainer/MainVBox/Panels/DebriefPanel/HBoxContainer/RightBoxContainer/PointsBreakdown
@onready var debrief_total_points: Label = $MarginContainer/MainVBox/Panels/DebriefPanel/HBoxContainer/RightBoxContainer/TotalPoints

@onready var briefing_map_texture = $MarginContainer/MainVBox/Panels/BriefingPanel/HBoxContainer/MapBox/MapTexture
@onready var briefing_description_label = $MarginContainer/MainVBox/Panels/BriefingPanel/HBoxContainer/BriefingContainerMargin/BriefingContainer/BriefingText/MissionDescription
@onready var briefing_objectives_label = $MarginContainer/MainVBox/Panels/BriefingPanel/HBoxContainer/BriefingContainerMargin/BriefingContainer/Objectives
# Referencje do paneli
@onready var panels = {
	"mission": $MarginContainer/MainVBox/Panels/MissionSelectPanel,
	"briefing": $MarginContainer/MainVBox/Panels/BriefingPanel,
	"equipment": $MarginContainer/MainVBox/Panels/EquipmentPanel,
	"shop": $MarginContainer/MainVBox/Panels/ShopPanel,
	"debrief": $MarginContainer/MainVBox/Panels/DebriefPanel
}

@export_category("Muzyka")
@export var menu_music: AudioStream

var selected_mission: MissionResource

func _ready() -> void:
	get_tree().paused = false
	AudioManager.play_music(menu_music)
	
	_hide_all_panels()
	
	if not SaveManager.current_data.get("tutorial_seen", false):
		TutorialPopup.open_tutorial()
		SaveManager.current_data["tutorial_seen"] = true
		SaveManager.save_game()
	
	# LOGIKA STARTOWA:
	if GameManager.last_completed_mission_id != "":
		# Gracz właśnie wrócił z misji
		_show_panel("debrief")
		_setup_debrief()
	elif _is_new_save():
		# Nowy zapis - cutscenka
		_play_intro_cutscene()
	else:
		# Zwyczajne wejście do huba
		_show_panel("mission")
		_refresh_mission_list()

# --- LOGIKA PRZEŁĄCZANIA PANELI ---

func _show_panel(panel_name: String) -> void:
	_hide_all_panels()
	if panels.has(panel_name):
		panels[panel_name].show()


func _hide_all_panels() -> void:
	for p in panels.values():
		p.hide()

# --- LOGIKA WYBORU MISJI ---

func _refresh_mission_list() -> void:
	# Czyszczenie starej listy
	for child in mission_list_container.get_children():
		child.queue_free()
		
	for mission in all_missions:
		var btn = Button.new()
		var level_data = SaveManager.current_data["levels"].get(mission.mission_id, {"status": "locked"})
		
		btn.text = mission.title
		
		if level_data["status"] == "locked":
			btn.disabled = true
			btn.text += " [LOCKED]"
		
		btn.pressed.connect(func(): _on_mission_selected(mission))
		mission_list_container.add_child(btn)


func _on_mission_selected(mission: MissionResource) -> void:
	selected_mission = mission
	mission_title_label.text = mission.title
	mission_description_label.text = mission.description

# --- LOGIKA FLOW (NEXT / BACK) ---

func _on_back_pressed() -> void:
	if panels["mission"].visible:
		SceneManager.go_to_main_menu()
	elif panels["briefing"].visible:
		_show_panel("mission")
	elif panels["equipment"].visible:
		_show_panel("briefing")
		
	elif panels["debrief"].visible:
		pass
	elif panels["shop"].visible:
		_show_panel("mission")


func _on_next_pressed() -> void:
	if panels["mission"].visible:
		if selected_mission: 
			_show_panel("briefing")
			setup_briefing()
	elif panels["briefing"].visible:
		_show_panel("equipment")
	elif panels["equipment"].visible:
		_start_mission()
		
	elif panels["debrief"].visible:
		_show_panel("shop")
	elif panels["shop"].visible:
		_show_panel("mission")
		_refresh_mission_list()


func _start_mission() -> void:
	if selected_mission:
		GameManager.current_mission_id = selected_mission.mission_id
		get_tree().change_scene_to_file(selected_mission.level_scene_path)

# --- DODATKI ---

func _is_new_save() -> bool:
	# Sprawdzamy czy poziom 1 ma 0 punktów i status unlocked
	var lvl1 = SaveManager.current_data["levels"].get("level_1", {})
	return lvl1.get("score", 0) == 0 and lvl1.get("status") == "unlocked"


func _play_intro_cutscene() -> void:
	# Kiedy będziesz miał AnimationPlayera, tu go odpalisz
	print("Odtwarzanie Intro...")
	# animation_player.play("intro")
	# Po animacji:
	_show_panel("mission")
	_refresh_mission_list()


func _setup_debrief() -> void:
	var mission_id = GameManager.last_completed_mission_id
	var success = GameManager.was_mission_successful
	
	# 1.1. Ustawienie nagłówka (Sukces / Porażka)
	if success:
		debrief_success_label.text = "MISSION SUCCESSFUL"
		debrief_success_label.modulate = Color.GREEN
		
		# === LOGIKA ODBLOKOWYWANIA NASTĘPNEJ MISJI ===
		for i in range(all_missions.size()):
			if all_missions[i].mission_id == mission_id:
				# Sprawdzamy, czy to nie była ostatnia misja w grze
				if i + 1 < all_missions.size():
					var next_mission_id = all_missions[i + 1].mission_id
					
					# Zabezpieczenie: jeśli misja nie istniała jeszcze w save'ie, tworzymy ją
					if not SaveManager.current_data["levels"].has(next_mission_id):
						SaveManager.current_data["levels"][next_mission_id] = {"status": "locked", "score": 0}
					
					# Odblokowujemy i zapisujemy grę
					SaveManager.current_data["levels"][next_mission_id]["status"] = "unlocked"
					SaveManager.save_game()
				break
		# ===============================================
		
	else:
		debrief_success_label.text = "MISSION FAILED!"
		debrief_success_label.modulate = Color.RED
		
	
	# 1.2. Lista celi
	var objectives_names_text = ""
	var objectives_statuses_text = ""
	
	for obj in GameManager.last_objective_results:
		objectives_names_text += obj["title"] + "\n"
		
		var current_status = obj["status"]
		var colored_status = ""
		
		if current_status == "COMPLETED":
			colored_status = "[color=green]" + current_status + "[/color]"
		elif current_status == "FAILED":
			colored_status = "[color=red]" + current_status + "[/color]"
		else:
			colored_status = "[color=gray]" + current_status + "[/color]"
		
		objectives_statuses_text += colored_status + "\n"
		
	# 1.3 Point breakdown
	debrief_objectives_label.text = objectives_names_text
	debrief_objectives_status_label.text = objectives_statuses_text
	
	debrief_objectives_label.modulate = Color.WHITE
	debrief_objectives_status_label.modulate = Color.WHITE
	
	var total_seconds = int(GameManager.get_level_timer())
	var time_string = "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
	
	var cash_earned = GameManager.score if success else 0
	
	var breakdown_text = "OPERATIONAL STATISTICS\n"
	breakdown_text += "--------------------------------------\n"
	breakdown_text += "Operation Time:\t\t\t\t\t\t" + time_string + "\n"
	breakdown_text += "Suspects Neutralized:\t\t\t\t" + str(GameManager.last_enemies_killed + GameManager.last_enemies_arrested) + "\n"
	breakdown_text += "  - Suspects Killed:\t\t\t\t" + str(GameManager.last_enemies_killed) + "\n"
	breakdown_text += "  - Suspects Arrested:\t\t\t\t" + str(GameManager.last_enemies_arrested) + "\n"
	breakdown_text += "  - Civilians Killed:\t\t\t\t" + str(GameManager.last_civilians_killed) + "\n"
	breakdown_text += "  - Civilians Arrested:\t\t\t\t" + str(GameManager.last_civilians_arrested) + "\n"
	breakdown_text += "Evidence Secured:\t\t\t\t\t" + "0\n"
	breakdown_text += "--------------------------------------\n"
	
	if not success:
		breakdown_text += "OPERATIONAL PENALTIES:\n"
		breakdown_text += "Failure to follow orders"
		
	debrief_points_breakdown.text = breakdown_text

	# 1.4 Total wynik
	var current_total_cash = SaveManager.current_data.get("current_money", 0)
	
	var total_text = " SCORE: " + str(cash_earned)
	
	debrief_total_points.text = total_text
	if success:
		debrief_total_points.modulate = Color.WHITE
	else:
		debrief_total_points.modulate = Color.RED
		
	# 5. Czyszczenie danych w GameManager
	GameManager.last_completed_mission_id = ""
	GameManager.was_mission_successful = false


func setup_briefing() -> void:
	if not selected_mission:
		return
		
	# 1. Ustawienie głównego tekstu odprawy (ScrollContainer)
	var full_briefing = "[b]OPERATION: " + selected_mission.title + "[/b]\n\n"
	full_briefing += selected_mission.briefing_text
	briefing_description_label.text = full_briefing
	
	# 2. Dynamiczne pobranie celów operacyjnych (Osobny Label)
	var objectives_display = "OBJECTIVES:\n"
	
	if selected_mission.objectives.size() > 0:
		for obj in selected_mission.objectives:
			if obj != null:
				var prefix = "[PRIMARY]" if obj.is_mandatory else "[OPTIONAL]"
				objectives_display += "- %s %s\n" % [prefix, obj.title]
	else:
		objectives_display += "- No secondary objectives."
		
	briefing_objectives_label.text = objectives_display
	
	# 3. Ustawienie mapy taktycznej
	if selected_mission.briefing_map_texture:
		briefing_map_texture.texture = selected_mission.briefing_map_texture
		briefing_map_texture.visible = true
	else:
		briefing_map_texture.texture = null
		briefing_map_texture.visible = false
