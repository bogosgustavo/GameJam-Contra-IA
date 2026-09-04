extends CombatBase
class_name CombatBoss

@onready var container: Control = $Control
@onready var boss_rect: TextureRect = $Control/BossSprite
@onready var paper_template: TextureRect = $Control/Paper
@onready var printer_rect: TextureRect = $Control/Printer

## Tamanhos fixos (em pixels) de cada elemento, não importa a resolução da imagem original.
@export var boss_size: Vector2 = Vector2(220, 220)
@export var paper_size: Vector2 = Vector2(90, 90)
@export var printer_size: Vector2 = Vector2(140, 140)

enum State { WAITING, THROWING, PAPERS_ACTIVE, VULNERABLE }

var _state: State = State.WAITING
var _boss_data: BossData

var _max_health := 200
var _current_health := 200
var _hit_index := 0
var _hit_flash_timer := 0.0

var _throw_timer := 0.0
var _throw_display_timer := 0.0
var _vulnerable_timer := 0.0

# rect (TextureRect) -> {"velocity": Vector2}
var _papers: Dictionary = {}
var _dragging_rect: TextureRect = null
var _drag_offset := Vector2.ZERO

func _ready() -> void:
	visible = false
	paper_template.visible = false
	boss_rect.gui_input.connect(_on_boss_gui_input)

	_lock_size(boss_rect, boss_size)
	_lock_size(paper_template, paper_size)
	_lock_size(printer_rect, printer_size)

func _lock_size(rect: TextureRect, size: Vector2) -> void:
	rect.custom_minimum_size = size
	rect.size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func start_combat(data_list: Array) -> void:
	# O boss usa só o primeiro item da lista (um BossData).
	_boss_data = data_list[0]
	_max_health = max(_boss_data.required_hits, 1)
	_current_health = _max_health
	_hit_index = 0
	_hit_flash_timer = 0.0
	_clear_papers()

	if _boss_data.printer_texture:
		printer_rect.texture = _boss_data.printer_texture

	_position_fixed_elements()
	_enter_waiting()
	visible = true

func _position_fixed_elements() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	boss_rect.position = (screen_size / 2.0) - (boss_size / 2.0)
	printer_rect.position = Vector2(40, screen_size.y - printer_size.y - 40)

func _clear_papers() -> void:
	for rect in _papers.keys():
		if is_instance_valid(rect):
			rect.queue_free()
	_papers.clear()
	_dragging_rect = null

func _process(delta: float) -> void:
	if not visible or _boss_data == null:
		return

	match _state:
		State.WAITING:
			_throw_timer -= delta
			if _throw_timer <= 0.0:
				_begin_throw()
		State.THROWING:
			_throw_display_timer -= delta
			if _throw_display_timer <= 0.0:
				_spawn_papers()
		State.PAPERS_ACTIVE:
			_update_papers(delta)
		State.VULNERABLE:
			_vulnerable_timer -= delta
			if _vulnerable_timer <= 0.0:
				_end_vulnerability()
			elif _hit_flash_timer > 0.0:
				_hit_flash_timer -= delta
				if _hit_flash_timer <= 0.0:
					_apply_boss_sprite()  # volta pro sprite vulnerável normal

# --- Estados / sprite do boss -------------------------------------------------

func _enter_waiting() -> void:
	_state = State.WAITING
	_throw_timer = _boss_data.throw_interval
	_apply_boss_sprite()

func _begin_throw() -> void:
	_state = State.THROWING
	_throw_display_timer = _boss_data.throwing_display_time
	_apply_boss_sprite()

func _apply_boss_sprite() -> void:
	match _state:
		State.THROWING:
			if _boss_data.throwing_texture:
				boss_rect.texture = _boss_data.throwing_texture
			boss_rect.modulate = Color(1, 1, 1)
		State.VULNERABLE:
			if _boss_data.vulnerable_texture:
				boss_rect.texture = _boss_data.vulnerable_texture
				boss_rect.modulate = Color(1, 1, 1)
			else:
				if _boss_data.sprite_texture:
					boss_rect.texture = _boss_data.sprite_texture
				boss_rect.modulate = Color(1, 0.55, 0.55)
		_:
			if _boss_data.sprite_texture:
				boss_rect.texture = _boss_data.sprite_texture
			boss_rect.modulate = Color(1, 1, 1)

# --- Papéis: quantidade conforme a vida atual ---------------------------------

func _current_papers_per_throw() -> int:
	if _boss_data.hp_thresholds.is_empty():
		return max(_boss_data.papers_per_throw, 1)

	var fraction: float = float(_current_health) / float(_max_health)
	var papers := _boss_data.papers_per_throw

	for i in range(_boss_data.hp_thresholds.size()):
		if fraction <= _boss_data.hp_thresholds[i] and i < _boss_data.papers_at_threshold.size():
			papers = _boss_data.papers_at_threshold[i]

	return max(papers, 1)

func _spawn_papers() -> void:
	_state = State.PAPERS_ACTIVE
	_apply_boss_sprite()  # volta ao sprite parado enquanto os papéis estão soltos

	var papers_now := _current_papers_per_throw()

	for i in range(papers_now):
		var rect: TextureRect = paper_template.duplicate()
		rect.visible = true
		if _boss_data.paper_texture:
			rect.texture = _boss_data.paper_texture
		_lock_size(rect, paper_size)
		rect.position = boss_rect.position + (boss_size / 2.0) - (paper_size / 2.0)

		var angle := randf() * TAU
		var velocity := Vector2(cos(angle), sin(angle)) * _boss_data.paper_speed

		container.add_child(rect)
		rect.gui_input.connect(_on_paper_gui_input.bind(rect))
		_papers[rect] = {"velocity": velocity}

func _update_papers(delta: float) -> void:
	var screen_size = get_viewport().get_visible_rect().size

	for rect in _papers.keys():
		if rect == _dragging_rect or not is_instance_valid(rect):
			continue

		var data: Dictionary = _papers[rect]
		var vel: Vector2 = data["velocity"]
		var size = rect.size

		rect.position += vel * delta

		if rect.position.x <= 0:
			rect.position.x = 1
			vel.x = abs(vel.x)
		elif rect.position.x + size.x >= screen_size.x:
			rect.position.x = screen_size.x - size.x - 1
			vel.x = -abs(vel.x)

		if rect.position.y <= 0:
			rect.position.y = 1
			vel.y = abs(vel.y)
		elif rect.position.y + size.y >= screen_size.y:
			rect.position.y = screen_size.y - size.y - 1
			vel.y = -abs(vel.y)

		data["velocity"] = vel

func _on_paper_gui_input(event: InputEvent, rect: TextureRect) -> void:
	if _state != State.PAPERS_ACTIVE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dragging_rect = rect
		_drag_offset = rect.position - get_viewport().get_mouse_position()

func _input(event: InputEvent) -> void:
	if _dragging_rect == null:
		return

	if event is InputEventMouseMotion:
		_dragging_rect.position = get_viewport().get_mouse_position() + _drag_offset

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var rect := _dragging_rect
		_dragging_rect = null
		_try_deliver_paper(rect)

func _try_deliver_paper(rect: TextureRect) -> void:
	if not is_instance_valid(rect):
		return

	var paper_global_rect := Rect2(rect.global_position, rect.size)
	var printer_global_rect := Rect2(printer_rect.global_position, printer_rect.size)

	if paper_global_rect.intersects(printer_global_rect):
		_papers.erase(rect)
		rect.queue_free()
		if _papers.is_empty():
			_start_vulnerability()
	# Se não acertou a impressora, o papel continua em _papers e volta a
	# se mover sozinho no próximo _process (retoma o "bounce").

# --- Vulnerabilidade e dano ----------------------------------------------------

func _start_vulnerability() -> void:
	_state = State.VULNERABLE
	_vulnerable_timer = _boss_data.vulnerable_duration
	_hit_flash_timer = 0.0
	_apply_boss_sprite()

func _end_vulnerability() -> void:
	_enter_waiting()

func _on_boss_gui_input(event: InputEvent) -> void:
	if _state != State.VULNERABLE:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_current_health = max(_current_health - _boss_data.damage_per_click, 0)
		print("Vida do boss: ", _current_health, "/", _max_health)

		_show_hit_flash()

		if _current_health <= 0:
			visible = false
			combat_won.emit()

func _show_hit_flash() -> void:
	if _boss_data.hit_textures.is_empty():
		return
	boss_rect.texture = _boss_data.hit_textures[_hit_index % _boss_data.hit_textures.size()]
	boss_rect.modulate = Color(1, 1, 1)
	_hit_index += 1
	_hit_flash_timer = _boss_data.hit_flash_duration
