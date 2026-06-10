extends Node2D

const PALABRAS = ["CARTA"]
const SPEED_ZOMBIE = 40

var palabra_secreta = ""
var intento_actual = 0
var tiempo_restante = 120
var juego_activo = true

func _ready():
	randomize()
	palabra_secreta = PALABRAS[randi() % PALABRAS.size()]

	# Conectar el LineEdit
	$CanvasGroup/InputLetra.text_submitted.connect(_on_palabra_enviada)

	# Temporizador principal
	$Timer.timeout.connect(_on_tiempo_agotado)

	# Tick de 1 segundo para el contador
	var tick = Timer.new()
	tick.wait_time = 1.0
	tick.autostart = true
	add_child(tick)
	tick.timeout.connect(_on_timer_tick)

	_actualizar_timer_display()

	# Señales de letras ocultas
	$Player.letra_iluminada.connect(_on_letra_iluminada)
	$Player.letra_oscurecida.connect(_on_letra_oscurecida)

	# Configurar los 30 Labels del grid
	for i in range(30):
		var label = $CanvasGroup/Panel/GridLetras.get_child(i)
		label.custom_minimum_size = Vector2(70, 70)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.15, 0.15, 0.25)
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_width_top = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.4, 0.4, 0.6)
		label.add_theme_stylebox_override("normal", sb)

	# Mostrar instrucción inicial
	$CanvasGroup/Panel/LabelMensaje.text = "Haz click en el cuadro y escribe"

func _on_letra_iluminada(nodo: Node2D) -> void:
	if nodo.has_method("revelar_desde_player"):
		nodo.revelar_desde_player()

func _on_letra_oscurecida(nodo: Node2D) -> void:
	if nodo.has_method("oscurecer_desde_player"):
		nodo.oscurecer_desde_player()

func _actualizar_timer_display():
	var minutos = int(tiempo_restante) / 60
	var segundos = int(tiempo_restante) % 60
	$CanvasGroup/LabelTiempo.text = "%02d:%02d" % [minutos, segundos]

func _process(delta):
	if not juego_activo:
		return
	# Zombi persigue al jugador
	var dir = ($Player.position - $Zombie.position).normalized()
	$Zombie.position += dir * SPEED_ZOMBIE * delta
	if $Zombie.position.distance_to($Player.position) < 80:
		_game_over()

# El jugador presiona Enter — evaluar palabra
func _on_palabra_enviada(texto: String):
	if not juego_activo:
		return
	var intento = texto.to_upper().strip_edges()
	$CanvasGroup/InputLetra.text = ""
	# Mantener el foco para seguir escribiendo intentos
	$CanvasGroup/InputLetra.grab_focus()

	if intento.length() != 5:
		$CanvasGroup/Panel/LabelMensaje.text = "Escribe exactamente 5 letras"
		return

	_evaluar_intento(intento)

func _evaluar_intento(intento: String):
	for i in range(5):
		var label = $CanvasGroup/Panel/GridLetras.get_child(intento_actual * 5 + i)
		label.text = intento[i]
		if intento[i] == palabra_secreta[i]:
			# Verde: posición correcta
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.2, 0.55, 0.2)))
		elif palabra_secreta.contains(intento[i]):
			# Amarillo: letra existe pero en otra posición
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.6, 0.5, 0.0)))
		else:
			# Gris: letra no existe
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_stylebox_override("normal", _crear_fondo(Color(0.3, 0.3, 0.3)))

	if intento == palabra_secreta:
		juego_activo = false
		$CanvasGroup/Panel/LabelMensaje.text = "¡Correcto! La puerta se abre..."
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/Room2.tscn")
	else:
		intento_actual += 1
		if intento_actual >= 6:
			_game_over()
		else:
			$CanvasGroup/Panel/LabelMensaje.text = "Intento %d/6" % intento_actual

func _crear_fondo(color: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	return sb

func _on_tiempo_agotado():
	_game_over()

func _game_over():
	juego_activo = false
	get_tree().change_scene_to_file("res://scenes/quests/story_quests/the_last_cards/3.The_House_of_Words/scenes/GameOver.tscn")

func _on_timer_tick():
	if not juego_activo:
		return
	tiempo_restante -= 1
	_actualizar_timer_display()
	if tiempo_restante <= 0:
		_game_over()

# Manejar clicks: dar/quitar foco al LineEdit
func _input(event: InputEvent):
	if not juego_activo:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var rect = $CanvasGroup/InputLetra.get_global_rect()
		if rect.has_point(event.position):
			$CanvasGroup/InputLetra.grab_focus()
		else:
			$CanvasGroup/InputLetra.release_focus()
