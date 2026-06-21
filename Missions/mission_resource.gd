extends Resource
class_name MissionResource

@export_group("Podstawowe Informacje")
@export var mission_id: String
@export var title: String
@export_multiline var description: String

@export_group("Dane Misji")
@export_multiline var briefing_text: String
@export var level_scene_path: String # Ścieżka do pliku .tscn mapy
@export var mission_icon: Texture2D
@export var briefing_map_texture: Texture2D

@export_group("Cele")
@export var objectives: Array[ObjectiveResource] = []

@export_group("Nagrody")
@export var max_reward_money: int = 100
