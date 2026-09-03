extends Node3D

const GRID_SIZE := 2.0
const TRAVEL_TIME := 0.08
const ACCELERATION_WINDOW := 0.30

@onready var front_ray: RayCast3D = $FrontRay
@onready var back_ray: RayCast3D = $BackRay
@onready var camera: Camera3D = $Camera3D

var tween: Tween
var click_combo := 0
var last_move_click_time := 0.0

var in_combat := false
var current_enemy = null
var map_position: Vector3
var map_basis: Basis

func _input(event):
	if in_combat:
		return # Bloqueia qualquer movimento do grid durante o combate

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if tween != null and tween.is_running():
			return

		var viewport_width = get_viewport().size.x
		var zone_width = viewport_width / 3.0
		var click_x = event.position.x

		if click_x < zone_width:
			_reset_acceleration()
			_turn_left()
		elif click_x > zone_width * 2.0:
			_reset_acceleration()
			_turn_right()
		else:
			_register_move_click()
			_move_forward()


func _register_move_click():
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_between_clicks = current_time - last_move_click_time

	if time_between_clicks <= ACCELERATION_WINDOW:
		click_combo += 1
	else:
		click_combo = 1

	last_move_click_time = current_time


func _get_grids_to_move() -> int:
	if click_combo >= 7:
		return 4
	elif click_combo >= 5:
		return 3
	elif click_combo >= 3:
		return 2

	return 1


func _move_forward():
	if in_combat: 
		return

	var grids = _get_grids_to_move()
	var original_target = front_ray.target_position

	# Atualiza a posição do raio para a distância total do movimento
	front_ray.target_position = Vector3.FORWARD * GRID_SIZE * grids
	front_ray.force_raycast_update()

	var allowed_grids = grids

	if front_ray.is_colliding():
		var collision_point = front_ray.get_collision_point()
		var distance_to_wall = global_position.distance_to(collision_point)
		
		# Desconta uma pequena margem (0.1) para não colar na parede
		allowed_grids = floor((distance_to_wall - 0.1) / GRID_SIZE)

	front_ray.target_position = original_target
	front_ray.force_raycast_update()

	# Se não houver espaço nem para 1 bloco, cancela o movimento
	if allowed_grids <= 0:
		_reset_acceleration()
		return

	var distance = GRID_SIZE * allowed_grids

	# Calcula o destino no espaço global
	var target_pos = global_transform.translated_local(Vector3.FORWARD * distance).origin
	
	# TRAVA NO GRID: Arredonda X e Z para evitar o desvio acumulado para as paredes
	target_pos.x = snapped(target_pos.x, 1.0)
	target_pos.z = snapped(target_pos.z, 1.0)

	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target_pos, TRAVEL_TIME)


func _turn_left():
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	# Rotação cravada no eixo Y para evitar distorção de matriz
	tween.tween_property(self, "rotation:y", rotation.y + (PI / 2.0), TRAVEL_TIME)


func _turn_right():
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	# Rotação cravada no eixo Y para evitar distorção de matriz
	tween.tween_property(self, "rotation:y", rotation.y - (PI / 2.0), TRAVEL_TIME)


func _reset_acceleration():
	click_combo = 0
	last_move_click_time = 0.0


func start_combat(enemy):
	if in_combat:
		return

	in_combat = true
	current_enemy = enemy

	if tween != null:
		tween.kill()
		tween = null

	# Salva a posição e rotação do jogador no grid
	map_position = global_position
	map_basis = global_transform.basis

	# Esconde a imagem 3D do inimigo se ela existir
	if enemy.has_node("Sprite3D"):
		enemy.get_node("Sprite3D").visible = false


func finish_combat():
	if current_enemy:
		current_enemy.queue_free()

	current_enemy = null
	in_combat = false
	
	# Restaura a posição exata
	global_position = map_position
	global_transform.basis = map_basis
	_reset_acceleration()
