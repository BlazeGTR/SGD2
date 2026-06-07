extends Control
@onready var health_bar: TextureProgressBar = $HealthBar

func _ready() -> void:
	SignalBus.player_health_changed.connect(update_health)


func update_health(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	
	#TODO: dać jakieś efekty koloru jak jest low hp idk
	
	#if current < (max_health * 0.25):
		#health_bar.tint_progress = Color.RED
	#else:
		#health_bar.tint_progress = Color.WHITE # Lub Twój domyślny kolor paska
