extends Button

func _ready():
	visible = false
	disabled = true
	position = Vector2(1200, 400)   # posición fija (X, Y)
	add_to_group("detectables")
	# El Area2D hijo detectará al jugador
	$Area2D.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):   # asigna el grupo "player" al nodo Player
		revelar()

func revelar():
	visible = true
	disabled = false
