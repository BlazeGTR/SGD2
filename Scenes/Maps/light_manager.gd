extends Node

var lights_array: Array
@export var amount_of_blinking_lights: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lights_array = get_children()
	var amount_of_total_lights = lights_array.size()
	if amount_of_blinking_lights > amount_of_total_lights:
		amount_of_blinking_lights = amount_of_total_lights
	
	lights_array.shuffle()
	for i in range(amount_of_blinking_lights):
		var rand_light = lights_array.pop_front()
		if rand_light.has_method("start_blinking"):
			rand_light.start_blinking()
