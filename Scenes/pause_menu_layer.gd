extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var center_container = $CenterContainer
@onready var btn_resume = $CenterContainer/VBoxContainer/ButtonResume
@onready var btn_menu = $CenterContainer/VBoxContainer/ButtonMenu
@onready var btn_quit = $CenterContainer/VBoxContainer/ButtonQuit
@onready var btn_help: Button = $CenterContainer/VBoxContainer/ButtonHelp

func _ready() -> void:
	# Na starcie gry ukrywamy menu pauzy
	hide()
	
	# Podłączamy przyciski
	btn_resume.pressed.connect(toggle_pause)
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_help.pressed.connect(on_help_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
	# Sprawdzamy czy wciśnięto ESC (domyślnie ui_cancel w Godocie)
	if event.is_action_pressed("ui_cancel"):
		
		# Pozwalamy na pauzę tylko, jeśli gracz jest w trakcie misji
		# (Zakładamy, że w Operation Center / Main Menu to pole jest puste)
		if GameManager.current_mission_id != "":
			toggle_pause()

func toggle_pause() -> void:
	var is_paused = get_tree().paused
	
	if is_paused:
		# WZNAWIANIE GRY
		get_tree().paused = false
		hide()
	else:
		# ZATRZYMYWANIE GRY
		get_tree().paused = true
		show_pause_menu()

func show_pause_menu() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 

func hide_pause_menu() -> void:
	#visible = false
	pass

func _on_menu_pressed() -> void:
	# Zdejmujemy pauzę i chowamy to UI przed wyjściem
	get_tree().paused = false
	hide()

	GameManager.go_to_main_menu()

func on_help_pressed():
	TutorialPopup.open_tutorial()

func _on_quit_pressed() -> void:
	get_tree().quit()
