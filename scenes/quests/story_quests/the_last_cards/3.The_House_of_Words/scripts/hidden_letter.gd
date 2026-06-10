extends Area2D

@export var letra: String = "A"
@export var indice_en_palabra: int = 0

var recogida: bool = false

@onready var label: Label = $Label

signal letra_iluminada(letra: String, indice: int)
signal letra_oscurecida(letra: String, indice: int)

func _ready() -> void:
	if label:
		label.modulate.a = 0.0
		label.text = letra
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "DetectionArea":
		return
	if recogida:
		return
	_revelar()
	letra_iluminada.emit(letra, indice_en_palabra)

func _on_body_exited(body: Node2D) -> void:
	if body.name != "DetectionArea":
		return
	if recogida:
		return
	_oscurecer()
	letra_oscurecida.emit(letra, indice_en_palabra)

func _revelar() -> void:
	if label:
		var tween := create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.25)

func _oscurecer() -> void:
	if label:
		var tween := create_tween()
		tween.tween_property(label, "modulate:a", 0.0, 0.4)

func marcar_recogida() -> void:
	recogida = true
	if label:
		label.modulate = Color(0.4, 1.0, 0.4)
