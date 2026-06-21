extends Node2D

@onready var door_sprite_right: Sprite2D = $"../Mask/Door_sprite_right"
@onready var door_sprite_left: Sprite2D = $"../Mask/Door_sprite_left"
@onready var door_hitbox_left: AnimatableBody2D = $"../Test_Door_left"
@onready var door_hitbox_right: AnimatableBody2D = $"../Test_Door_right"
@onready var starting_modulate = door_sprite_left.modulate
@onready var parent_node: Node2D = $".."

@export var open_speed: float
@export var slide_distance: float = 64.0
@export var slide_direction: Vector2 = Vector2.RIGHT

var visual_initial_position_left: Vector2
var hitbox_initial_position_left: Vector2
var visual_initial_position_right: Vector2
var hitbox_initial_position_right: Vector2
var is_open: bool = false

func _ready():
	visual_initial_position_left = door_sprite_left.position
	hitbox_initial_position_left = door_hitbox_left.position
	visual_initial_position_right = door_sprite_right.position
	hitbox_initial_position_right = door_hitbox_right.position


func interact(interactor):
	is_open =  !is_open
	
	var visual_target_position_left = visual_initial_position_left
	var hitbox_target_position_left = hitbox_initial_position_left
	var visual_target_position_right = visual_initial_position_right
	var hitbox_target_position_right = hitbox_initial_position_right
	
	if is_open:
		visual_target_position_left = visual_initial_position_left + (-slide_direction * slide_distance)
		hitbox_target_position_left = hitbox_initial_position_left + (-slide_direction * slide_distance)
		visual_target_position_right = visual_initial_position_right + (slide_direction * slide_distance)
		hitbox_target_position_right = hitbox_initial_position_right + (slide_direction * slide_distance)
	
	var visual_tween_left = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	visual_tween_left.tween_property(door_sprite_left, "position", visual_target_position_left, open_speed)
	var hitbox_tween_left = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hitbox_tween_left.tween_property(door_hitbox_left, "position", hitbox_target_position_left, open_speed)
	var visual_tween_right = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	visual_tween_right.tween_property(door_sprite_right, "position", visual_target_position_right, open_speed)
	var hitbox_tween_right = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	hitbox_tween_right.tween_property(door_hitbox_right, "position", hitbox_target_position_right, open_speed)


func set_highlight(state: bool):
	if state:
		door_sprite_left.modulate *= 4
		door_sprite_right.modulate *= 4
	else:
		door_sprite_left.modulate = starting_modulate
		door_sprite_right.modulate = starting_modulate
