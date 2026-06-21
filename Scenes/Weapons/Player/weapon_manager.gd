extends Node2D

const WEAPONS_FOLDER_PATH = "res://Resources/Weapons/"

var primary_weapon: WeaponResource
var secondary_weapon: WeaponResource
var gadget_weapon: WeaponResource
var tactical_weapon: WeaponResource

@onready var timer: Timer = $ShootTimer
@onready var reload_timer: Timer = $ReloadTimer
@onready var visual: Sprite2D = $WeaponVisual
@onready var muzzle: Marker2D = $MuzzlePosition
@onready var hitscan_ray: RayCast2D = $HitscanRaycast
@onready var sfx_player: AudioStreamPlayer2D = $SfxPlayer

var current_weapon: WeaponResource
var can_shoot: bool = true
var is_reloading: bool = false
var poly_playback: AudioStreamPlaybackPolyphonic = null
var current_recoil: float = 0.0

var actor_manager # for sound reporting

signal player_reload_started(duration)
signal player_reload_finished()

func _ready() -> void:
	actor_manager = get_tree().get_first_node_in_group("actor_manager")
	_load_loadout_from_save()
	
	# na start misji przeładuj wszystkie bronie
	for w in [primary_weapon, secondary_weapon, gadget_weapon]:
		if w:
			w.current_ammo = w.magazine_size
	# na start misji wyekwipuj broń główną
	if primary_weapon:
		await get_tree().create_timer(0.1).timeout
		equip_weapon(primary_weapon)
	elif secondary_weapon:
		await get_tree().create_timer(0.1).timeout
		equip_weapon(secondary_weapon)
	# ogarnij to zjebane audio
	sfx_player.play()
	poly_playback = sfx_player.get_stream_playback()


func _load_loadout_from_save() -> void:
	# Pobieramy słownik aktywnego loadoutu z SaveManager
	var loadout = SaveManager.current_data.get("active_loadout", {})
	
	# Ładujemy zasoby na podstawie string ID zapisanego w pliku
	primary_weapon = _load_weapon_resource(loadout.get("primary", "none"))
	secondary_weapon = _load_weapon_resource(loadout.get("secondary", "none"))
	gadget_weapon = _load_weapon_resource(loadout.get("gadget", "none"))
	tactical_weapon = _load_weapon_resource(loadout.get("tactical", "none"))
	
	
func _load_weapon_resource(weapon_id: String) -> WeaponResource:
	# Jeśli slot jest pusty, zwracamy null
	if weapon_id == "none" or weapon_id == "":
		return null
		
	var full_path = WEAPONS_FOLDER_PATH + weapon_id + ".tres"
	
	# Bezpieczne sprawdzenie, czy taki plik fizycznie istnieje w projekcie
	if ResourceLoader.exists(full_path):
		# Zwracamy unikalną instancję zasobu (.duplicate()), aby zmiany amunicji 
		# w trakcie misji nie nadpisywały oryginalnego pliku na dysku!
		return load(full_path).duplicate() as WeaponResource
		
	print_debug("Błąd: Nie znaleziono pliku broni o ścieżce: ", full_path)
	return null


func _process(_delta: float) -> void:
	if(current_recoil > 0) and current_weapon and can_shoot:
		current_recoil -= current_weapon.recoil_spread_recovery_speed * _delta
		current_recoil = clamp(current_recoil,0,current_weapon.max_recoil)
	if current_weapon and can_shoot and current_weapon.current_ammo:
		if check_trigger():
			shoot()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("slot_1") and primary_weapon and current_weapon != primary_weapon:
		equip_weapon(primary_weapon)
	elif event.is_action_pressed("slot_2") and secondary_weapon and current_weapon != secondary_weapon:
		equip_weapon(secondary_weapon)
	elif event.is_action_pressed("slot_3") and gadget_weapon and current_weapon != gadget_weapon:
		equip_weapon(gadget_weapon)
	
	if event.is_action_pressed("reload") and !is_reloading:
		print("reloading!")
		start_reloading()


func equip_weapon(weapon: WeaponResource) -> void:
	timer.stop()
	reload_timer.stop()
	is_reloading = false
	play_sfx(weapon.sound_equip)
	current_weapon = weapon
	visual.texture = weapon.texture
	timer.wait_time = weapon.fire_rate
	SignalBus.player_ammo_changed.emit( current_weapon.current_ammo, current_weapon.magazine_size)
	SignalBus.player_weapon_changed.emit(current_weapon)
	can_shoot = false
	await get_tree().create_timer(weapon.equip_time).timeout
	can_shoot = true


func check_trigger() -> bool:
	if current_weapon.is_full_auto:
		return Input.is_action_pressed("game_shoot")
	return Input.is_action_just_pressed("game_shoot")


func shoot() -> void:
	can_shoot = false
	current_weapon.current_ammo -= 1
	current_recoil += current_weapon.recoil_spread_per_shot + (current_recoil * (1 + current_weapon.recoil_spread_per_shot))
	current_recoil = clamp(current_recoil, 0, current_weapon.max_recoil)
	SignalBus.player_ammo_changed.emit( current_weapon.current_ammo, current_weapon.magazine_size)
	
	# Effects
	play_sfx(current_weapon.sound_fire)
	if current_weapon.muzzle_flash_effect:
		var muzzle_flash_fx = current_weapon.muzzle_flash_effect.instantiate()
		muzzle.add_child(muzzle_flash_fx)
	
	actor_manager.report_sound(global_position, current_weapon.noise_radius)
	timer.start() 
	match current_weapon.attack_type:
		0:
			_fire_projectile()
		1:
			_fire_hitscan()
		2:
			_fire_beam()


func play_sfx(stream: AudioStream):
	if not stream or not poly_playback:
		print_debug("Missing audio from: ", current_weapon)
		return
	poly_playback.play_stream(
		stream,
		0,
		0,
		randf_range(1.0 - current_weapon.pitch_variation, 1.0 + current_weapon.pitch_variation)
	)


func start_reloading() -> void:
	timer.stop() # zatrzymujemy shoot timer żeby nie rozjebał przeładowania
	reload_timer.start(current_weapon.reload_time)
	play_sfx(current_weapon.sound_reload)
	is_reloading = true
	can_shoot = false


func _on_reload_timer_timeout() -> void:
	current_weapon.current_ammo = current_weapon.magazine_size
	SignalBus.player_ammo_changed.emit(current_weapon.current_ammo, current_weapon.magazine_size)
	is_reloading = false
	can_shoot = true


func _fire_projectile() -> void:
	for i in current_weapon.projectiles_per_shot:
		var bullet = current_weapon.projectile_scene.instantiate()
		get_tree().root.add_child(bullet) 
		
		bullet.global_position = muzzle.global_position
		
		# spread
		var deviation = randf_range(-current_weapon.spread - current_recoil, current_weapon.spread + current_recoil)
		bullet.global_rotation = global_rotation + deg_to_rad(deviation)
		
		if bullet.has_method("set_speed"):
			bullet.set_speed(current_weapon.projectile_speed)

		if bullet.has_method("set_damage"):
			bullet.set_damage(current_weapon.damage, current_weapon.morale_damage)


func _fire_hitscan() -> void:
	var max_range = current_weapon.hitscan_range
	hitscan_ray.target_position = Vector2(max_range, 0)
	
	hitscan_ray.force_raycast_update()
	
	if hitscan_ray.is_colliding():
		var target = hitscan_ray.get_collider()
		var hit_point = hitscan_ray.get_collision_point()
		
		# Tu dodać spawnowanie efektu gdzie trafie
		
		var target_health_component = target.get_node_or_null("HealthComponent")
		if target_health_component:
			target_health_component.take_damage(current_weapon.damage, current_weapon.morale_damage)
			if current_weapon.stun_time != 0 and target_health_component.has_method("stun_enemy"):
				target_health_component.stun_enemy(current_weapon.stun_time)
	
	print("Wykonuję hitscan dla: ", current_weapon.name)


func _fire_beam() -> void:
	print("Uruchamiam promień: ", current_weapon.name)


func _on_shoot_timer_timeout() -> void:
	can_shoot = true
