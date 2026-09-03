extends CombatBase
class_name CombatBounce

@onready var template: TextureRect = $Control/UISprite

@export var icon_size: Vector2 = Vector2(120, 120)

var _targets: Array = []
var _active := false

func _ready() -> void:
	visible = false
	template.visible = false

func start_combat(data_list: Array) -> void:
	_clear_targets()

	var screen_size = get_viewport().get_visible_rect().size
	var container = template.get_parent()

	for data in data_list:
		var rect: TextureRect = template.duplicate()
		rect.visible = true
		if data.sprite_texture:
			rect.texture = data.sprite_texture

		rect.custom_minimum_size = icon_size
		rect.size = icon_size
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		rect.position = Vector2(
			randf_range(0, max(screen_size.x - rect.size.x, 1)),
			randf_range(0, max(screen_size.y - rect.size.y, 1))
		)

		container.add_child(rect)
		rect.gui_input.connect(_on_target_gui_input.bind(rect))

		_targets.append({
			"rect": rect,
			"data": data,
			"hits": 0,
			"velocity": data.ui_velocity
		})

	_active = true
	visible = true

func _clear_targets() -> void:
	for target in _targets:
		if is_instance_valid(target["rect"]):
			target["rect"].queue_free()
	_targets.clear()

func _process(delta: float) -> void:
	if not _active:
		return

	var screen_size = get_viewport().get_visible_rect().size

	for target in _targets:
		var rect: TextureRect = target["rect"]
		if not is_instance_valid(rect):
			continue

		var vel: Vector2 = target["velocity"]
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

		target["velocity"] = vel

func _on_target_gui_input(event: InputEvent, rect: TextureRect) -> void:
	if not _active:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	for target in _targets:
		if target["rect"] == rect:
			target["hits"] += 1
			print("Hit em ", target["data"].enemy_name, ": ", target["hits"], "/", target["data"].required_hits)
			if target["hits"] >= target["data"].required_hits:
				rect.queue_free()
				_targets.erase(target)
			break

	if _targets.is_empty():
		_active = false
		visible = false
		combat_won.emit()
