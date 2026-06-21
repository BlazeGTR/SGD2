extends Control

var max_ammo: int = 30
var current_ammo: int
var start_y: float
var single_bullet_height: float

@onready var weapon_icon: TextureRect = $MarginContainer/WeaponIcon
@onready var ammo_bar: TextureProgressBar = $MarginContainer2/AmmoBar


func _ready() -> void:
	SignalBus.player_ammo_changed.connect(update_ammo)
	SignalBus.player_weapon_changed.connect(change_weapon)


func update_ammo(current: int, max: int) -> void:
	current_ammo = current
	max_ammo = max
	ammo_bar.value = current


func change_weapon(weapon:WeaponResource):
	weapon_icon.texture = weapon.weapon_hud_icon
	ammo_bar.max_value = weapon.magazine_size
	update_ammo(weapon.current_ammo, weapon.magazine_size)
