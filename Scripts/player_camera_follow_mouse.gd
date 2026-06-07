extends Camera2D

@export var distance_to_mouse_weight = 0.5
@export var max_mouse_distance = 500
@onready var player_object = self.get_parent()
var distance: float

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	distance = (player_object.global_position - get_global_mouse_position()).length()
	self.position.x = clamp(distance * distance_to_mouse_weight,0,max_mouse_distance)
	
	pass
