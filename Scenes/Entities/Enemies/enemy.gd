extends CharacterBody2D
class_name Enemy

@export_group("Patrol Settings")
@export var patrol_path_node: NodePath
@export var patrol_wait_time: float = 2.0

@export_group("Other Settings")
@export var score: int
@export var score_surrender_multiplier: float
