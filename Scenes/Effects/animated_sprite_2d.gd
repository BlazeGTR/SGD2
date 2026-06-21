extends AnimatedSprite2D

@export var flash_energy: float = 5.0 # Siła początkowa błysku

@onready var muzzle_light: PointLight2D = $"../PointLight2D"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_finished.connect(get_parent().queue_free)

	var current_anim_name = animation
	var frame_count = float(sprite_frames.get_frame_count(current_anim_name))
	var fps = float(sprite_frames.get_animation_speed(current_anim_name))
	var flash_duration = frame_count / fps
	if is_instance_valid(muzzle_light):
		muzzle_light.set_deferred("enabled", true)
		muzzle_light.energy = flash_energy
		
		var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		tween.tween_property(muzzle_light, "energy", 0.0, flash_duration)
