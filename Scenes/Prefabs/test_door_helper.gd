extends AnimatableBody2D

@onready var interact_area: Area2D = $"../Interact_area"

### Kurwa no głupie ale nie wiem jak to inaczej zrobić bez reworkowania drzwi od 0
var is_open: bool = false

func interact(interactor):
	interact_area.interact(interactor)
