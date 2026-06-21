# weapon_resource.gd
extends Resource
class_name WeaponResource

enum AttackType { PROJECTILE, HITSCAN, CONTINUOUS } # typ ataku broni
enum SlotType { PRIMARY, SECONDARY, GADGET, TACTICAL } # w jakim slocie jest broń

@export_group("General")
@export var name: String = "Weapon"
@export var attack_type: AttackType
@export var slotype: SlotType
@export var price: int

@export_group("Lore & UI")
@export var manufacturer: String = "Unknown Corp"
@export var cartridge: String = "9x19mm Parabellum"
@export var action: String = "Semi-Automatic"
@export_multiline var description: String = "Krótki opis broni wyświetlany w menu ekwipunku."

@export_group("Visual")
@export var visual_recoil: float
@export var texture: Texture2D
@export var weapon_hud_icon: Texture2D
@export var muzzle_flash_effect: PackedScene
@export var dropped_weapon_object: PackedScene

@export_group("Audio")
@export var sound_fire: AudioStream
@export var sound_reload: AudioStream
@export var sound_equip: AudioStream
@export var pitch_variation: float = 0.1

@export_group("Stats")
@export_subgroup("Damage")
@export var damage: float = 20
@export var morale_damage: float = 20
@export var fire_rate: float = 0.2
@export var is_full_auto: bool = true
@export_subgroup("Other")
@export var spread: float = 2
@export var recoil_spread_per_shot: float = 0.1
@export var recoil_spread_recovery_speed: float = 0.2
@export var max_recoil: float = 10.0
@export var magazine_size: int = 10
var current_ammo: int
@export var reload_time: float = 2
@export var equip_time: float = 1
@export var noise_radius: float = 800
## Ustawić na inne niz 0 jeśli ma stunować
@export var stun_time: float = 0

@export_group("Projectile Settings") # tylko jak jest projectile
@export var projectile_speed: float = 1000.0
@export var projectiles_per_shot: int = 1
@export var projectile_scene: PackedScene

@export_group("Hitscan Settings") # tylko jak jest hitscan
@export var hitscan_range: float = 2000.0

@export_group("Continuous Settings") # etc
