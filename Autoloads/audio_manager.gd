extends Node

var music_player: AudioStreamPlayer

var ui_sfx_player: AudioStreamPlayer
var ui_click_sound: AudioStream

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	ui_sfx_player = AudioStreamPlayer.new()
	add_child(ui_sfx_player)
	ui_sfx_player.bus = "SFX"
	ui_sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_click_sound = preload("res://External_resources/Audio/Click.mp3")
	_connect_buttons(get_tree().root)
	get_tree().node_added.connect(_on_node_added)

# logika SFX
func play_ui_click() -> void:
	if ui_click_sound:
		ui_sfx_player.stream = ui_click_sound
		ui_sfx_player.play()


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		# Upewniamy się, że nie podpinamy sygnału dwa razy
		if not node.pressed.is_connected(play_ui_click):
			node.pressed.connect(play_ui_click)


func _connect_buttons(root: Node) -> void:
	for child in root.get_children():
		if child is BaseButton:
			if not child.pressed.is_connected(play_ui_click):
				child.pressed.connect(play_ui_click)
		
		_connect_buttons(child)

# Główna funkcja do puszczania muzyki
func play_music(music_stream: AudioStream, crossfade_time: float = 1.0) -> void:
	if music_stream == null:
		return
		
	if music_player.stream == music_stream and music_player.playing:
		return

	if music_player.playing:
		var tween = create_tween()
		# Przyciszamy stary utwór do -60 dB (cisza)
		tween.tween_property(music_player, "volume_db", -60.0, crossfade_time / 2.0)
		# Podmieniamy utwór i odpalamy z powrotem głośność
		tween.tween_callback(func():
			music_player.stream = music_stream
			music_player.play()
		)
		tween.tween_property(music_player, "volume_db", 0.0, crossfade_time / 2.0)
	else:
		music_player.volume_db = 0.0
		music_player.stream = music_stream
		music_player.play()


func stop_music(fade_out_time: float = 1.0) -> void:
	if not music_player.playing:
		return
		
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -60.0, fade_out_time)
	tween.tween_callback(music_player.stop)
