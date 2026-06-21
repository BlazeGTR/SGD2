extends CanvasLayer


# Serio kurwa nie ma lepszego sposobu na to?

func _ready() -> void:
	pass

func resize_hud():
	offset.x = -(get_viewport().size.x / 2)
	offset.y = -(get_viewport().size.y / 2)
