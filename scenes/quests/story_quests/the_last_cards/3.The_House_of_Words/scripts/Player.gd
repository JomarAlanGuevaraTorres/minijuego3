# player.gd
# Guard modificado para ser el player:
# - Se mueve con WASD/flechas en vez de patrullar
# - La linterna rota hacia donde se mueve (igual que el guard)
# - Cuando la linterna ilumina una letra, la señal player_detected
#   se reemplaza por letra_iluminada
# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0

extends CharacterBody2D

const MOVE_SPEED: float = 150.0

# Señal que emite cuando la linterna ilumina algo del grupo "hidden_letter"
signal letra_iluminada(node: Node2D)
signal letra_oscurecida(node: Node2D)

# ── nodos (mismos nombres que en guard.tscn) ──────────────────────
@onready var detection_area: Area2D       = %DetectionArea
@onready var sight_ray_cast: RayCast2D    = %SightRayCast
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var animation_player: AnimationPlayer    = $AnimationPlayer

# ── estado interno ────────────────────────────────────────────────
var _last_direction: Vector2 = Vector2.RIGHT

# ── constante de giro de la linterna (igual que detection_area.gd del guard) ──
const LOOK_AT_TURN_SPEED: float = 10.0

# =================================================================
func _ready() -> void:
	add_to_group("player")

	# Conectar señales de la DetectionArea
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

# =================================================================
func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input_dir.x = 1.0
		animated_sprite_2d.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		input_dir.x = -1.0
		animated_sprite_2d.flip_h = true

	if Input.is_action_pressed("ui_up"):
		input_dir.y = -1.0
	elif Input.is_action_pressed("ui_down"):
		input_dir.y = 1.0

	velocity = input_dir.normalized() * MOVE_SPEED
	move_and_slide()

	# Guardar última dirección para la linterna
	if not input_dir.is_zero_approx():
		_last_direction = input_dir.normalized()

	# Rotar la linterna hacia donde se mueve — igual que detection_area.gd del guard
	var target_angle := _last_direction.angle()
	detection_area.rotation = rotate_toward(
		detection_area.rotation,
		target_angle,
		delta * LOOK_AT_TURN_SPEED
	)

	# Animación
	_update_animation()

# =================================================================
func _update_animation() -> void:
	if velocity.is_zero_approx():
		animation_player.play(&"idle")
	else:
		animation_player.play(&"walk")

# =================================================================
# Linterna ilumina una letra
func _on_detection_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("hidden_letter"):
		return

	# Verificar línea de visión (igual que el guard)
	if _is_sight_to_point_blocked(body.global_position):
		return

	letra_iluminada.emit(body)

# Linterna deja de iluminar una letra
func _on_detection_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("hidden_letter"):
		return

	letra_oscurecida.emit(body)

# ── línea de visión (copiado directo de guard.gd) ─────────────────
func _is_sight_to_point_blocked(point_position: Vector2) -> bool:
	sight_ray_cast.target_position = sight_ray_cast.to_local(point_position)
	sight_ray_cast.force_raycast_update()
	return sight_ray_cast.is_colliding()
