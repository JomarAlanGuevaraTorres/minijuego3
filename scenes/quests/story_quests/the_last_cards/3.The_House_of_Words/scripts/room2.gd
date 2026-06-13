extends Node2D

const PALABRAS = ["FUTURO"]  # Puedes añadir más palabras de 6 letras
const SPEED_NUBE = 55

var palabra_secreta = ""
var intento_actual = 0
var tiempo_restante = 120
var juego_activo = false  # Empieza en false hasta que termine el diálogo
var escribiendo = false

@onready var dialogue_balloon = $Dialogue  # Nodo balloon.tscn hijo de Room2
@onready var input_letra = $CanvasGroup/InputLetra
@onready var grid_letras = $CanvasGroup/Panel/GridLetras
@onready var label_mensaje = $CanvasGroup/Panel/LabelMensaje
@onready var label_tiempo = $CanvasGroup/LabelTiempo
@onready var timer_principal = $Timer
@onready var nube = $NubeNegra
@onready var player = $Player

func _ready():
	randomize()
	palabra_secreta = PALABRAS[randi() % PALABRAS.size()]
	
	# Configurar grid de letras (36 labels para 6 intentos x 6 letras)
	for i in range(36):
		var label = grid_letras.get_child(i)
		label.custom_minimum_size = Vector2(65, 65)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 26)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.15, 0.15, 0.25)
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_width_top = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.4, 0.4, 0.6)
		label.add_theme_stylebox_override("normal", sb)
	
	# Deshabilitar UI hasta el diálogo
	input_letra.editable = false
	input_letra.focus_mode = Control.FOCUS_NONE
	label_mensaje.text = "Escucha el diálogo..."
	timer_principal.stop()
	label_tiempo.text = "00:00"
	
	# Conectar señales
	input_letra.text_submitted.connect(_on_palabra_enviada)
	input_letra.focus_entered.connect(_on_input_focus)
	input_letra.focus_exited.connect(_on_input_unfocus)
	timer_principal.timeout.connect(_on_tiempo_agotado)
	
	# Tick de 1 segundo
	var tick = Timer.new()
	tick.wait_time = 1.0
	tick.autostart = false
	add_child(tick)
	tick.timeout.connect(_on_timer_tick)
	set_meta("tick_timer", tick)
	
	# Diálogo inicial
	if dialogue_balloon:
		dialogue_balloon.tree_exited.connect(_on_dialogue_finished)
		_iniciar_dialogo()
	else:
		_iniciar_juego()

func _iniciar_dialogo():
	var dialogue_resource = load("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/dialogues/room2.dialogue")
	if dialogue_resource:
		dialogue_balloon.start(dialogue_resource, "start")
	else:
		print("No se pudo cargar el diálogo de room2")
		_iniciar_juego()

func _on_dialogue_finished():
	await get_tree().process_frame
	_iniciar_juego()

func _iniciar_juego():
	juego_activo = true
	input_letra.editable = true
	input_letra.focus_mode = Control.FOCUS_ALL
	input_letra.mouse_filter = Control.MOUSE_FILTER_STOP
	await get_tree().process_frame
	input_letra.grab_focus()
	label_mensaje.text = "Escribe tu intento (6 letras)"
	tiempo_restante = 120
	_actualizar_timer_display()
	timer_principal.start(120)
	var tick = get_meta("tick_timer")
	if tick:
		tick.start()

func _process(delta):
	if not juego_activo:
		return
	var dir = (player.position - nube.position).normalized()
	nube.position += dir * SPEED_NUBE * delta
	if nube.position.distance_to(player.position) < 80:
		_game_over()

func _physics_process(delta):
	if not juego_activo or escribiendo:
		return
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		velocity.x = 150
		player.get_node("AnimatedSprite2D").flip_h = false
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -150
		player.get_node("AnimatedSprite2D").flip_h = true
	if Input.is_action_pressed("ui_up"):
		velocity.y = -150
	elif Input.is_action_pressed("ui_down"):
		velocity.y = 150
	player.velocity = velocity
	player.move_and_slide()

func _on_palabra_enviada(texto):
	if not juego_activo:
		return
	var intento = texto.to_upper().strip_edges()
	if intento.length() != 6:
		label_mensaje.text = "Escribe exactamente 6 letras"
		return
	_evaluar_intento(intento)
	input_letra.text = ""
	input_letra.grab_focus()

func _evaluar_intento(intento):
	for i in range(6):
		var label = grid_letras.get_child(intento_actual * 6 + i)
		label.text = intento[i]
		if intento[i] == palabra_secreta[i]:
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.2, 0.5, 0.2)))
			label.add_theme_color_override("font_color", Color.GREEN)
		elif palabra_secreta.contains(intento[i]):
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.5, 0.4, 0.1)))
			label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.2, 0.2, 0.2)))
			label.add_theme_color_override("font_color", Color.WHITE)
	
	if intento == palabra_secreta:
		juego_activo = false
		label_mensaje.text = "¡Correcto! Siguiente habitación..."
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room3.tscn")
	else:
		intento_actual += 1
		if intento_actual >= 6:
			_game_over()
		else:
			label_mensaje.text = "Intento %d/6" % intento_actual

func _crear_fondo(color: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	return sb

func _on_tiempo_agotado():
	_game_over()

func _on_timer_tick():
	if not juego_activo:
		return
	tiempo_restante -= 1
	_actualizar_timer_display()
	if tiempo_restante <= 0:
		_game_over()

func _actualizar_timer_display():
	var minutos = int(tiempo_restante) / 60
	var segundos = int(tiempo_restante) % 60
	label_tiempo.text = "%02d:%02d" % [minutos, segundos]

func _game_over():
	juego_activo = false
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/GameOver.tscn")

func _on_input_focus():
	escribiendo = true

func _on_input_unfocus():
	escribiendo = false

func _input(event: InputEvent):
	if not juego_activo:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var rect = input_letra.get_global_rect()
		if rect.has_point(event.position):
			input_letra.grab_focus()
		else:
			input_letra.release_focus()
