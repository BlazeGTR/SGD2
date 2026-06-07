extends Node

@export var combat_music: AudioStream

func _ready() -> void:
	AudioManager.play_music(combat_music, 0.5)

func _enter_tree() -> void:
	GameManager.start_new_level()
	print("test")
