extends Node2D

@export var time_between_shots: float = 0.25
@export var full_auto = true
@export var projectile_speed = 1000.0
@export var projectile_deviation =  1.0
@export var projectiles_per_shot = 1
@export var visual_recoil = 100.0
@export var deviation_recoil = 1.0
@export var deviation_recoil_time = 0.2
@export var bullet_scene: PackedScene
var can_shoot = true

@onready var shooting_cooldown: Timer = $ShootingCooldown
@onready var entities_plane: Node = $"../.."



func _ready() -> void:
	shooting_cooldown.one_shot = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if can_shoot && check_trigger():
		shoot()
	pass


func check_trigger() -> bool:
	if full_auto:
		return Input.is_action_pressed("game_shoot")
	else:
		return Input.is_action_just_pressed("game_shoot")


func shoot() -> void:
	can_shoot = false
	shooting_cooldown.start(time_between_shots)
	for i in projectiles_per_shot:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = self.global_position
		bullet.global_rotation = self.global_rotation + (randf_range(-projectile_deviation, projectile_deviation) / 100)
		bullet.set_speed(projectile_speed)
		entities_plane.add_child(bullet)
	pass


func _on_shooting_cooldown_timeout() -> void:
	can_shoot = true
