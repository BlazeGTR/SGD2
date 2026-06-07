extends Area2D

# Zmień nazwy węzłów w ścieżkach, jeśli w drzewie nazywają się inaczej!
@onready var normal_sprite: Sprite2D = $"../NormalSprite"
@onready var surrender_sprite: Sprite2D = $"../SurrenderSprite"
@onready var arrested_sprite: Sprite2D = $"../ArrestedSprite"

@onready var brain_component: Node2D = $"../BrainComponent"
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var starting_modulate: Color
var sprites: Array[Sprite2D] = []

func _ready() -> void:
	starting_modulate = normal_sprite.modulate
	
	sprites = [normal_sprite, surrender_sprite, arrested_sprite]
	
	disable()


func interact(player):
	brain_component.arrest()


func set_highlight(state: bool):
	for sprite in sprites:
		if sprite != null:
			if state:
				sprite.modulate = starting_modulate * 2 
			else:
				sprite.modulate = starting_modulate


func disable():
	collision_shape_2d.set_deferred("disabled", true)


func enable():
	collision_shape_2d.set_deferred("disabled", false)
