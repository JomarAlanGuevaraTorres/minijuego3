extends ColorRect

var player: Node2D = null
var lantern_area: Node2D = null

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("DetectionArea"):
		lantern_area = player.get_node("DetectionArea")

func _process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	if not material or not material is ShaderMaterial:
		return

	# Convertir posición del player a UV del ColorRect
	var vp_size := get_viewport_rect().size
	var player_screen_pos := player.get_global_transform_with_canvas().origin
	var uv_pos := Vector2(
		player_screen_pos.x / vp_size.x,
		player_screen_pos.y / vp_size.y
	)

	material.set_shader_parameter("light_pos", uv_pos)

	# Dirección del cono según rotación de DetectionArea
	if lantern_area:
		material.set_shader_parameter("cone_direction", lantern_area.rotation)
