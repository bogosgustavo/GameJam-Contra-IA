extends Node3D

@export var required_hits := 5
@export var combat_ui: CanvasLayer 

@onready var area: Area3D = $Area3D
@export var ui_sprite: TextureRect

var is_in_battle := false
var current_hits := 0
var ui_velocity := Vector2(350, 250)
var cached_player: Node3D = null

func _ready():
	area.area_entered.connect(_on_area_entered)
	if combat_ui:
		combat_ui.visible = false

func _process(delta):
	if not is_in_battle or ui_sprite == null:
		return
	if not is_in_battle or not ui_sprite:
		return

	var screen_size = get_viewport().get_visible_rect().size
	var sprite_size = ui_sprite.size

	# Atualiza a posição da GUI
	ui_sprite.position += ui_velocity * delta

	# Rebatedor das bordas da tela (evita prender nas extremidades)
	if ui_sprite.position.x <= 0:
		ui_sprite.position.x = 1
		ui_velocity.x = abs(ui_velocity.x)
	elif ui_sprite.position.x + sprite_size.x >= screen_size.x:
		ui_sprite.position.x = screen_size.x - sprite_size.x - 1
		ui_velocity.x = -abs(ui_velocity.x)

	if ui_sprite.position.y <= 0:
		ui_sprite.position.y = 1
		ui_velocity.y = abs(ui_velocity.y)
	elif ui_sprite.position.y + sprite_size.y >= screen_size.y:
		ui_sprite.position.y = screen_size.y - sprite_size.y - 1
		ui_velocity.y = -abs(ui_velocity.y)

func _on_area_entered(area_hit):
	var player = area_hit.get_parent()
	if player.has_method("start_combat") and not is_in_battle:
		is_in_battle = true
		cached_player = player
		current_hits = 0
		area.set_deferred("monitoring", false)
		
		if combat_ui:
			combat_ui.visible = true
			# Posiciona a imagem no centro da tela ao iniciar a luta
			var screen_size = get_viewport().get_visible_rect().size
			ui_sprite.position = (screen_size / 2.0) - (ui_sprite.size / 2.0)
			
		player.start_combat(self)

func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if not is_in_battle:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		current_hits += 1
		print("Hit registrado: ", current_hits, "/", required_hits)

		if current_hits >= required_hits:
			if combat_ui:
				combat_ui.visible = false
			
			if cached_player and cached_player.has_method("finish_combat"):
				cached_player.finish_combat()

			queue_free()
