extends Node2D
@onready var sprite_2d: Sprite2D = $"../Sprite2D"
@onready var starting_modulate = sprite_2d.modulate

func interact(player):
	print("AAA")


func set_highlight(state: bool):
	if state:
		sprite_2d.modulate *= 4
	else:
		sprite_2d.modulate = starting_modulate
