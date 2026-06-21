extends CanvasLayer

# --- WĘZŁY STRON ---
@onready var page_1 = $PanelContainer/MarginContainer/VBoxContainer/Pages/Page1_Controls
@onready var page_2 = $PanelContainer/MarginContainer/VBoxContainer/Pages/Page2_Arrest
@onready var page_3 = $PanelContainer/MarginContainer/VBoxContainer/Pages/Page3_Interact
@onready var page_4 = $PanelContainer/MarginContainer/VBoxContainer/Pages/Page4_Extract


# --- PRZYCISKI ---
@onready var btn_back = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ButtonBack
@onready var btn_next = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ButtonNext

var pages: Array[Control] = []
var current_page_index: int = 0

func _ready() -> void:
	close_tutorial(false)
	# Ładujemy strony do tablicy dla łatwiejszego zarządzania
	pages = [page_1, page_2, page_3, page_4]
	
	# Podłączamy przyciski
	btn_back.pressed.connect(_on_back_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	
	# Resetujemy stan przy otwarciu
	_update_ui()


func open_tutorial() -> void:
	current_page_index = 0
	_update_ui()
	show()
	get_tree().paused = true 


func close_tutorial(keep_paused: bool) -> void:
	hide()
	get_tree().paused = keep_paused


func _on_back_pressed() -> void:
	if current_page_index > 0:
		current_page_index -= 1
		_update_ui()


func _on_next_pressed() -> void:
	# Jeśli jesteśmy na ostatniej stronie, przycisk działa jako "Zamknij"
	if current_page_index == pages.size() - 1:
		close_tutorial(false)
	else:
		current_page_index += 1
		_update_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		
		close_tutorial(true)

		get_viewport().set_input_as_handled()


func _update_ui() -> void:
	# 1. Przełączanie widoczności stron
	for i in range(pages.size()):
		pages[i].visible = (i == current_page_index)
		
	# 2. Ukrywanie przycisku Wstecz na pierwszej stronie
	btn_back.visible = (current_page_index > 0)
	
	# 3. Zmiana tekstu przycisku Dalej na ostatniej stronie
	if current_page_index == pages.size() - 1:
		btn_next.text = "CLOSE"
		# Opcjonalnie: zmiana koloru przycisku na zielony
		btn_next.modulate = Color.GREEN
	else:
		btn_next.text = "NEXT ->"
		btn_next.modulate = Color.WHITE
