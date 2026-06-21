# neon_light.gd
extends Node2D

@export_group("Flicker Settings (Bursts)")
@export var min_flicker_delay: float = 0.04
@export var max_flicker_delay: float = 0.15

@export_group("Noise Settings (Subtle)")
@export var noise_speed: float = 15.0 # Jak szybko drży światło
@export var noise_intensity: float = 0.1 # Amplituda drżenia

@onready var env_light: PointLight2D = $EnviromentLighting
@onready var ent_light: PointLight2D = $EntityLighting
@onready var amb_light: PointLight2D = $NearGLow
@onready var sprite: Sprite2D = $Sprite2D

var is_blinking: bool = false
var original_color: Color
var off_color: Color
var lights: Array[PointLight2D]
var original_energies: Dictionary = {}
var time_passed: float
var random_offset: float

func _ready() -> void:
	lights = [env_light, ent_light, amb_light]
	original_color = sprite.self_modulate
	random_offset = randf_range(0, PI)
	time_passed = random_offset
	
	# Obliczamy kolor zgaszony (bez HDR i ciemny)
	off_color = Color(original_color.r * 0.1, original_color.g * 0.1, original_color.b * 0.1, 1.0)
	
	# Zapamiętujemy bazowe jasności każdego światła z osobna
	for l in lights:
		original_energies[l.name] = l.energy

func _physics_process(delta: float) -> void:
	# Subtelny szum (zawsze aktywny, jeśli światła są włączone)
	if env_light.enabled:
		time_passed += delta * noise_speed
		# Używamy sinusa z lekkim randomem dla organicznego efektu "skwierczenia"
		var noise = 1.0 + (sin(time_passed) * noise_intensity)
		
		for l in lights:
			l.energy = original_energies[l.name] * noise

func start_blinking() -> void:
	if is_blinking: return
	is_blinking = true
	_flicker_loop()

func stop_blinking() -> void:
	is_blinking = false
	_set_state(true)

func _flicker_loop() -> void:
	while is_blinking:
		# Przerwa między seriami gwałtownego migania
		await get_tree().create_timer(randf_range(2.0, 6.0)).timeout
		if not is_blinking: break
		
		var burst_count = randi_range(2, 6)
		for i in burst_count:
			_set_state(false)
			await get_tree().create_timer(randf_range(min_flicker_delay, max_flicker_delay)).timeout
			_set_state(true)
			await get_tree().create_timer(randf_range(min_flicker_delay, max_flicker_delay)).timeout

func _set_state(on: bool) -> void:
	for l in lights:
		l.enabled = on
	
	# Zmiana koloru sprajta (HDR ON/OFF)
	sprite.self_modulate = original_color if on else off_color

func destroy() -> void:
	is_blinking = false
	set_process(false) # Wyłączamy szum
	_set_state(false)
	# Opcjonalnie: spawn_glass_shards()
