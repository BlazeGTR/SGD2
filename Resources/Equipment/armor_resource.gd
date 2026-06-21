extends Resource
class_name ArmorResource

@export_group("Podstawowe Informacje")
@export var item_id: String
@export var name: String
@export var price: int = 0

@export_group("Lore & UI")
@export var manufacturer: String = "Unknown Corp"
@export var material: String = "9x19mm Parabellum"
@export_multiline var description: String = "Krótki opis broni wyświetlany w menu ekwipunku."

@export_group("Statystyki")
@export var bonus_health: int = 50 # O ile zwiększa maksymalne HP
@export var speed_multiplier: float = 1.0 # Modyfikator prędkości (1.0 = normalna prędkość)

@export_group("Visual")
@export var armor_icon: Texture2D
