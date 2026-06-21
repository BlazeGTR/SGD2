extends Label

@onready var starting_rotation = self.rotation
@onready var starting_scale = self.scale
@onready var starting_position = self.position

var time: float = 0

@export var max_rotation: float
@export var rotation_speed: float
@export var max_scale: float
@export var scale_speed: float
@export var max_position: float
@export var position_speed: float

func _process(delta: float) -> void:
	position = starting_position + Vector2.UP * sin(time * position_speed) * max_position
	rotation = starting_rotation + sin(time * rotation_speed) * max_rotation
	scale = starting_scale + Vector2.ONE * sin(time * scale_speed) * max_scale
	time += delta
