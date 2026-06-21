extends Node2D
class_name CivilianBrainComponent

@export_group("Movement Settings")
@export var rotation_speed: float = 10.0

@export_group("Civilian Settings")
@export var flee_distance: float = 400.0
@export var panic_duration: float = 5.0

enum State { IDLE, PANIC, COWER, SURRENDER, ARRESTED }
var current_state: State = State.IDLE

@onready var locomotion = $"../LocomotionComponent"
@onready var health = $"../HealthComponent"
@onready var interact_area: Area2D = $"../Interact_area"
@onready var debug_label: Label = $"../DebugLabel"

# --- SENSORY WZROKOWE ---
@onready var head: Node2D = $"../Head"
@onready var raycast: RayCast2D = $"../Head/RayCast2D"
@onready var vision_cone_normal: Area2D = $"../Head/VisionConeNormal"
@onready var vision_cone_alert: Area2D = $"../Head/VisionConeAlert"

@onready var normal_sprite = $"../NormalSprite"
@onready var surrender_sprite: Sprite2D = $"../SurrenderSprite"
@onready var arrested_sprite: Sprite2D = $"../ArrestedSprite"
@onready var current_sprite = normal_sprite

var player_in_cone: Node2D = null
var current_flee_target: Vector2 = Vector2.ZERO # Zapamiętany cel ucieczki
var danger_position: Vector2 = Vector2.ZERO
var panic_timer: float = 0.0
var is_stunned: bool = false

var actor_manager

func _ready() -> void:
	var parent = get_parent()
	
	actor_manager = get_tree().get_first_node_in_group("actor_manager")
	actor_manager.add_new_hostage(parent)
	_setup_initial_vision()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(GameManager.player): 
		return
		
	_update_debug_text()
	
	if locomotion.is_waiting:
		return
		
	if is_stunned:
		locomotion.stop()
		return
		
	match current_state:
		State.IDLE:      _state_idle()
		State.PANIC:     _state_panic(delta)
		State.COWER:     _state_cower()
		State.SURRENDER: _state_surrender()
		State.ARRESTED:  _state_arrested()
		
	handle_rotation(delta)

# --- LOGIKA STANÓW ---

func _state_idle():
	if _can_see_player():
		_start_panic(GameManager.player.global_position)


func _state_panic(delta: float):
	panic_timer -= delta
	if panic_timer <= 0:
		current_state = State.COWER
		locomotion.stop()
	elif locomotion.nav_agent.is_navigation_finished():
		current_state = State.COWER
		locomotion.stop()
	else:
		locomotion.move_to(current_flee_target)


func _state_cower():
	locomotion.stop()


func _state_surrender():
	locomotion.stop()


func _state_arrested():
	locomotion.stop()

# --- SENSORIKA I WZROK ---

func _can_see_player() -> bool:
	if player_in_cone == null or not is_instance_valid(GameManager.player):
		return false
	
	raycast.target_position = raycast.to_local(player_in_cone.global_position)
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		return raycast.get_collider() == player_in_cone
	return false


func _on_vision_cone_body_entered(body):
	if body == GameManager.player:
		player_in_cone = body


func _on_vision_cone_body_exited(body):
	if body == player_in_cone:
		player_in_cone = null


func _setup_initial_vision():
	if is_instance_valid(vision_cone_normal):
		vision_cone_normal.set_deferred("monitoring", true)
		vision_cone_normal.visible = true 
	if is_instance_valid(vision_cone_alert):
		vision_cone_alert.set_deferred("monitoring", false)
		vision_cone_alert.visible = false

# --- REAKCJE NA OTOCZENIE ---

func hear_sound(sound_origin: Vector2):
	if current_state in [State.IDLE, State.COWER]:
		_start_panic(sound_origin)


func just_took_damage():
	if current_state not in [State.SURRENDER, State.ARRESTED]:
		_start_panic(GameManager.player.global_position)


func hear_shout():
	if current_state in [State.SURRENDER, State.ARRESTED]:
		return
		
	health.morale_check()
	
	if current_state != State.SURRENDER:
		current_state = State.COWER
		locomotion.stop()

# --- LOGIKA UCIECZKI ---

func _start_panic(danger_source: Vector2):
	current_state = State.PANIC
	panic_timer = panic_duration
	danger_position = danger_source
	
	current_flee_target = _calculate_flee_point(danger_source)
	locomotion.move_to(current_flee_target)


func _calculate_flee_point(threat_pos: Vector2) -> Vector2:
	var parent_pos = global_position
	var dir_away = threat_pos.direction_to(parent_pos)
	
	var random_angle = randf_range(-PI/4, PI/4)
	dir_away = dir_away.rotated(random_angle)
	
	var target_pos = parent_pos + (dir_away * flee_distance)
	
	var map = get_world_2d().navigation_map
	return NavigationServer2D.map_get_closest_point(map, target_pos)

# --- ROTACJA (Skopiowana i ujednolicona z Wroga) ---

func handle_rotation(delta: float):
	if is_instance_valid(head):
		head.rotation = lerp_angle(head.rotation, 0.0, rotation_speed * delta)

	if locomotion.is_waiting:
		return

	var parent_velocity = get_parent().velocity
	var target_pos: Vector2 = Vector2.ZERO
	
	if parent_velocity.length() > 0.1:
		target_pos = global_position + parent_velocity

	if target_pos != Vector2.ZERO:
		_smooth_look_at(target_pos, delta)


func _smooth_look_at(target: Vector2, delta: float):
	var parent_node = get_parent()
	var angle_to_target = parent_node.global_position.direction_to(target).angle()
	
	parent_node.global_rotation = lerp_angle(parent_node.global_rotation, angle_to_target, rotation_speed * delta)

# --- INTERAKCJE I DEBUG ---

func _update_debug_text():
	if is_instance_valid(debug_label):
		debug_label.text = "State: %s\nPanic: %.1f\nStunned: %s" % [
			State.find_key(current_state), 
			panic_timer,
			str(is_stunned)
		]


func force_surrender():
	current_state = State.SURRENDER
	interact_area.enable()
	locomotion.stop()
	
	current_sprite.hide()
	surrender_sprite.show()
	current_sprite = surrender_sprite


func arrest():
	var parent_node = get_parent()
	current_state = State.ARRESTED
	
	SignalBus.emit_signal("arrest_hostage", parent_node)
	GameManager.add_score(parent_node.score * parent_node.score_surrender_multiplier)
	
	health.get_arrested()
	interact_area.disable()
	
	
	current_sprite.hide()
	arrested_sprite.show()
	current_sprite = arrested_sprite
	
	SignalBus.objective_event_triggered.emit("hostage_arrested", 1)
