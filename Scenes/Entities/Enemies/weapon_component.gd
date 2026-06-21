# weapon_component.gd
extends Node

signal weapon_fired
signal reload_started
signal reload_finished
signal out_of_ammo

@export var weapon_data: WeaponResource # Używamy tego samego Resource co gracz
var is_reloading: bool = false
@onready var current_ammo: int = weapon_data.magazine_size
@onready var muzzle: Marker2D = $"../Muzzle"
@onready var enemy: Enemy = $".."
@onready var sfx_player: AudioStreamPlayer2D = $"../SfxPlayer"

var poly_playback: AudioStreamPlaybackPolyphonic = null

var current_recoil: float = 0.0
var _fire_cooldown_timer: float = 0.0
var _reload_timer: float = 0.0

func _ready() -> void:
	sfx_player.play()
	poly_playback = sfx_player.get_stream_playback()
	
	print("SFX PLAYBACK:", sfx_player)
	print(poly_playback)


func _physics_process(delta: float):
	# Odmierzanie cooldownu między strzałami
	if _fire_cooldown_timer > 0:
		_fire_cooldown_timer -= delta
		
	# Odmierzanie czasu przeładowania
	if is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0:
			finish_reload()


func fire() -> bool:
	if is_reloading:
		return false
	
	if current_ammo <= 0:
		out_of_ammo.emit()
		start_reload()
		return false

	if _fire_cooldown_timer > 0:
		return false
		
	_spawn_projectile()
	current_ammo -= 1
	_fire_cooldown_timer = weapon_data.fire_rate
	weapon_fired.emit()
	
		# Effects
	play_sfx(weapon_data.sound_fire)
	if weapon_data.muzzle_flash_effect:
		var muzzle_flash_fx = weapon_data.muzzle_flash_effect.instantiate()
		muzzle.add_child(muzzle_flash_fx)
	

	return true


func play_sfx(stream: AudioStream):
	if not stream or not poly_playback:
		print(poly_playback)
		print_debug("Missing audio from: ", weapon_data)
		return
	poly_playback.play_stream(
		stream,
		0,
		0,
		randf_range(1.0 - weapon_data.pitch_variation, 1.0 + weapon_data.pitch_variation)
	)


func start_reload():
	if is_reloading or current_ammo == weapon_data.magazine_size:
		return
		
	is_reloading = true
	_reload_timer = weapon_data.reload_time
	reload_started.emit()


func finish_reload():
	current_ammo = weapon_data.magazine_size
	is_reloading = false
	reload_finished.emit()


func _spawn_projectile():
	for i in weapon_data.projectiles_per_shot:
		var bullet = weapon_data.projectile_scene.instantiate()
		get_tree().root.add_child(bullet) 
		
		bullet.global_position = muzzle.global_position
		
		# spread
		var deviation = randf_range(-weapon_data.spread - current_recoil, weapon_data.spread + current_recoil)
		bullet.global_rotation = enemy.global_rotation + deg_to_rad(deviation)
		
		if bullet.has_method("set_speed"):
			bullet.set_speed(weapon_data.projectile_speed)

		if bullet.has_method("set_damage"):
			bullet.set_damage(weapon_data.damage, 0)


func drop_weapon():
	var dropped_gun = weapon_data.dropped_weapon_object.instantiate()
	
	dropped_gun.global_position = enemy.global_position
	get_parent().get_parent().add_child(dropped_gun)
	
	dropped_gun.linear_velocity = (Vector2.LEFT.rotated(randf_range(0, 2*PI))) * randf_range(300.0, 400.0)
	dropped_gun.angular_velocity = randf_range(-50.0, 50.0)
