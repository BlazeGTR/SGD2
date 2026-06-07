extends Node2D

@export_group("Movement Settings")
@export var rotation_speed: float = 10.0

@export_group("Combat Settings")
@export var attack_range: float = 400.0
@export var stop_range: float = 250.0
@export var resume_range: float = 300.0
@export var fire_angle_threshold: float = 0.1

@export_group("Behavior Toggles")
@export var run_and_gun: bool = false
@export var aim_time: float = 0.5
@export var los_forget_time: float = 2.0 

@export_group("Investigation & Vision")
@export var look_around_time: float = 4.0 

@onready var normal_sprite = $"../NormalSprite"
@onready var surrender_sprite: Sprite2D = $"../SurrenderSprite"
@onready var arrested_sprite: Sprite2D = $"../ArrestedSprite"
@onready var current_sprite = normal_sprite

# patrol
var patrol_wait_time: float = 2.0

# Stan i Komponenty
enum State { IDLE, CHASE, SEARCH, RETREAT, ATTACK, SURRENDER, INVESTIGATE, PATROL, ARRESTED }
var current_state: State = State.IDLE

@onready var locomotion = $"../LocomotionComponent"
@onready var health = $"../HealthComponent"
@onready var weapon = $"../WeaponComponent"
@onready var debug_label: Label = $"../DebugLabel"
@onready var interact_area: Area2D = $"../Interact_area"

# Zmiana: Sensory są teraz w głowie
@onready var head: Node2D = $"../Head"
@onready var raycast: RayCast2D = $"../Head/RayCast2D"
@onready var vision_cone_normal: Area2D = $"../Head/VisionConeNormal"
@onready var vision_cone_alert: Area2D = $"../Head/VisionConeAlert"

# Zmienne pomocnicze
var last_known_position: Vector2
var player_in_cone: Node2D = null
var current_aim_timer: float = 0.0
var los_timer: float = 0.0
var is_holding_position: bool = false
var is_stunned: bool = false
@onready var player = GameManager.player

var has_been_alerted: bool = false
var is_looking_around: bool = false

# Zmienne do płynnego rozglądania (zastąpiły look_timer)
var sweep_progress: float = 0.0
var current_look_speed: float = 1.0

# Zmienne patrolu
var _patrol_points: Array[Dictionary] = []
var _current_patrol_index: int = 0
var _patrol_timer: float = 0.0


func _ready() -> void:
	var parent = get_parent()
	GameManager.add_new_enemy(parent)
	print("adding enemy")
	
	if "patrol_wait_time" in parent:
		patrol_wait_time = parent.patrol_wait_time
	
	_setup_initial_vision()
	
	# patrol
	if "patrol_path_node" in parent and not parent.patrol_path_node.is_empty():
		var path_parent = parent.get_node_or_null(parent.patrol_path_node)
		if path_parent:
			for child in path_parent.get_children():
				if child is Node2D:
					var forward_dir = Vector2.RIGHT.rotated(child.global_rotation)
					_patrol_points.append({
						"position": child.global_position,
						"direction": forward_dir
					})
	
	if _patrol_points.size() > 0:
		current_state = State.PATROL


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): 
		return

	_update_debug_text()
	
	if is_stunned:
		locomotion.stop()
		return
		
	match current_state:
		State.IDLE:        _state_idle()
		State.CHASE:       _state_chase()
		State.SEARCH:      _state_search(delta)
		State.RETREAT:     _state_retreat()
		State.ATTACK:      _state_attack(delta)
		State.SURRENDER:   _state_surrender()
		State.INVESTIGATE: _state_investigate(delta)
		State.PATROL:      _state_patrol(delta)
		State.ARRESTED:    _state_arrested()
	
	handle_rotation(delta)

# --- SENSORIKA I ALARMY ---

func _can_see_player() -> bool:
	if player_in_cone == null:
		return false
	
	# Raycast zawsze celuje relatywnie do głowy
	raycast.target_position = raycast.to_local(player_in_cone.global_position)
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var can_see = raycast.get_collider() == player_in_cone
		if can_see: _alert_enemy()
		return can_see
	return false


func _on_vision_cone_body_entered(body):
	if body == GameManager.player:
		player_in_cone = body


func _on_vision_cone_body_exited(body):
	if body == player_in_cone:
		player_in_cone = null


func hear_sound(sound_origin: Vector2):
	if current_state in [State.IDLE, State.PATROL, State.INVESTIGATE, State.SEARCH]:
		# Jeśli już bada dźwięk, nie resetuj stanu całkowicie, chyba że dźwięk jest daleko
		if current_state == State.INVESTIGATE and sound_origin.distance_to(last_known_position) < 100:
			return 
			
		last_known_position = sound_origin
		current_state = State.INVESTIGATE
		is_looking_around = false
		locomotion.move_to(last_known_position)
		_alert_enemy()


func just_took_damage():
	_alert_enemy()
	if current_state not in [State.SURRENDER, State.ATTACK, State.RETREAT, State.ARRESTED]:
		current_state = State.CHASE
		last_known_position = GameManager.player.global_position
		
		locomotion.move_to(last_known_position)


func _alert_enemy():
	if not has_been_alerted:
		has_been_alerted = true
		
		if is_instance_valid(vision_cone_normal) and is_instance_valid(vision_cone_alert):
			# Wyłączamy wąski
			vision_cone_normal.set_deferred("monitoring", false)
			vision_cone_normal.visible = false
			
			# Włączamy szeroki
			vision_cone_alert.set_deferred("monitoring", true)
			vision_cone_alert.visible = true


func _setup_initial_vision():
	# Używamy set_deferred dla bezpieczeństwa fizyki
	if is_instance_valid(vision_cone_normal):
		vision_cone_normal.set_deferred("monitoring", true)
		vision_cone_normal.visible = true 
		
	if is_instance_valid(vision_cone_alert):
		vision_cone_alert.set_deferred("monitoring", false)
		vision_cone_alert.visible = false

# --- LOGIKA STANÓW ---

func _state_idle():
	if _can_see_player():
		current_state = State.CHASE


func _state_patrol(delta: float):
	if _can_see_player():
		current_state = State.CHASE
		is_looking_around = false
		return

	if _patrol_points.is_empty():
		current_state = State.IDLE
		return

	if is_looking_around:
		if _execute_look_around(delta, patrol_wait_time):
			_current_patrol_index = (_current_patrol_index + 1) % _patrol_points.size()
			locomotion.move_to(_patrol_points[_current_patrol_index].position)
		return

	if locomotion.nav_agent.is_navigation_finished():
		_execute_look_around(delta, patrol_wait_time)
	else:
		locomotion.move_to(_patrol_points[_current_patrol_index].position)


func _state_chase():
	if _can_see_player():
		last_known_position = player.global_position
		var dist = global_position.distance_to(last_known_position)
		
		if dist <= attack_range:
			current_state = State.ATTACK
		else:
			locomotion.move_to(last_known_position)
	else:
		if last_known_position != Vector2.ZERO:
			current_state = State.SEARCH
		else:
			current_state = State.IDLE


func _state_attack(delta):
	var dist = global_position.distance_to(player.global_position)
	var can_see = _can_see_player()

	if can_see:
		los_timer = los_forget_time
		last_known_position = player.global_position
	else:
		los_timer -= delta
		if los_timer <= 0:
			_reset_attack_state()
			current_state = State.SEARCH 
			locomotion.move_to(last_known_position)
			return

	if dist > attack_range * 1.2:
		_reset_attack_state()
		current_state = State.CHASE
		return

	_handle_movement_logic(dist)
	_handle_combat_logic(delta)


func _state_search(delta: float):
	if _can_see_player():
		is_looking_around = false
		current_state = State.CHASE
		return
		
	if is_looking_around:
		if _execute_look_around(delta):
			current_state = State.PATROL if _patrol_points.size() > 0 else State.IDLE
		return
		
	if locomotion.nav_agent.is_navigation_finished():
		_execute_look_around(delta)
	else:
		locomotion.move_to(last_known_position)


func _state_investigate(delta: float):
	if _can_see_player():
		is_looking_around = false
		current_state = State.CHASE
		return
		
	if is_looking_around:
		if _execute_look_around(delta):
			current_state = State.PATROL if _patrol_points.size() > 0 else State.IDLE
		return
		
	if locomotion.nav_agent.is_navigation_finished():
		_execute_look_around(delta)
	else:
		locomotion.move_to(last_known_position)


func _execute_look_around(delta: float, custom_time: float = -1.0) -> bool:
	if not is_looking_around:
		is_looking_around = true
		sweep_progress = 0.0
		
		var time_to_use = custom_time if custom_time > 0 else look_around_time
		current_look_speed = (2 * PI) / time_to_use
		
		locomotion.stop()
		
	sweep_progress += current_look_speed * delta
	
	if sweep_progress >= 2 * PI:
		is_looking_around = false
		sweep_progress = 0.0
		return true 
	return false


func _state_retreat():
	if weapon.current_ammo <= 0 and not weapon.is_reloading:
		weapon.start_reload()
		
	var is_escaping = locomotion.flee_dynamic()
	
	if not is_escaping:
		current_aim_timer = aim_time 
		current_state = State.ATTACK
		return
		
	if global_position.distance_to(player.global_position) > 600:
		current_state = State.PATROL if _patrol_points.size() > 0 else State.IDLE


func _state_surrender():
	locomotion.stop()
	interact_area.enable()

func _state_arrested():
	locomotion.stop()

# --- FUNKCJE POMOCNICZE WALKI ---

func _handle_movement_logic(dist):
	if is_holding_position:
		if dist > resume_range: is_holding_position = false
	else:
		if dist <= stop_range: is_holding_position = true

	if not is_holding_position:
		locomotion.move_to(last_known_position)
		if not run_and_gun:
			get_parent().velocity *= 0.8 
			current_aim_timer = 0
	else:
		locomotion.stop()


func _handle_combat_logic(delta):
	if not _can_see_player():
		current_aim_timer = max(0, current_aim_timer - delta * 2)
		return

	if weapon.current_ammo <= 0:
		if not weapon.is_reloading: weapon.start_reload()
		current_aim_timer = 0
		return

	var angle_to_p = global_position.direction_to(player.global_position).angle()
	var angle_diff = abs(angle_difference(get_parent().global_rotation, angle_to_p))
	var is_stable = is_holding_position or run_and_gun
	
	if angle_diff < fire_angle_threshold and is_stable:
		current_aim_timer += delta
		if current_aim_timer >= aim_time: weapon.fire()
	else:
		current_aim_timer = max(0, current_aim_timer - delta)


func _reset_attack_state():
	current_aim_timer = 0
	los_timer = 0
	is_holding_position = false

# --- ROTACJA ---

func handle_rotation(delta: float):
	# Obrót Głowy (Sensory)
	if is_looking_around:
		head.rotation = sin(sweep_progress) * deg_to_rad(70) 
	else:
		head.rotation = lerp_angle(head.rotation, 0.0, rotation_speed * delta)

	# ZABEZPIECZENIE: Czeka na interakcję (np. otwarcie drzwi) -> nie obraca ciała
	if locomotion.is_waiting:
		return

	# Obrót Ciała (Ruch i Celowanie)
	var target_pos: Vector2 = Vector2.ZERO
	var parent_velocity = get_parent().velocity
	
	match current_state:
		State.ATTACK:
			if _can_see_player(): target_pos = player.global_position
			else: target_pos = last_known_position
		State.CHASE:
			target_pos = player.global_position
		State.SEARCH, State.INVESTIGATE:
			if parent_velocity.length() > 0.1 and not is_looking_around:
				target_pos = global_position + parent_velocity
			else:
				target_pos = last_known_position
		State.PATROL:
			if parent_velocity.length() > 0.1 and not is_looking_around:
				target_pos = global_position + parent_velocity
			elif _patrol_points.size() > 0:
				target_pos = global_position + _patrol_points[_current_patrol_index].direction
		State.RETREAT, State.IDLE:
			if parent_velocity.length() > 0.1:
				target_pos = global_position + parent_velocity

	if target_pos != Vector2.ZERO:
		_smooth_look_at(target_pos, delta)


func _smooth_look_at(target: Vector2, delta: float):
	var parent_node = get_parent()
	var angle_to_target = parent_node.global_position.direction_to(target).angle()
	parent_node.global_rotation = lerp_angle(parent_node.global_rotation, angle_to_target, rotation_speed * delta)


func _update_debug_text():
	debug_label.text = "State: %s\nHolding: %s\nAim: %.2f\nAlert: %s" % [
		State.find_key(current_state), 
		str(is_holding_position),
		current_aim_timer,
		str(has_been_alerted)
	]

# --- INNE ---

func force_surrender():
	current_state = State.SURRENDER
	
	current_sprite.hide()
	surrender_sprite.show()
	current_sprite = surrender_sprite

func arrest():
	var parent_node = get_parent()
	current_state = State.ARRESTED
	GameManager.remove_enemy(parent_node)
	GameManager.add_score(parent_node.score * parent_node.score_surrender_multiplier)
	GameManager.enemies_arrested += 1
	health.get_arrested()
	interact_area.disable()
	
	#idk jakaś animacja
	current_sprite.hide()
	arrested_sprite.show()
	current_sprite = arrested_sprite
	
	SignalBus.objective_event_triggered.emit("enemy_arrested", 1)
	print("arrested")
