extends Node3D

@export var required_hits := 5
@onready var area: Area3D = $Area3D

# Arraste o CanvasLayer da sua cena para esta variável no Inspector
@export var combat_ui: CanvasLayer 
@onready var ui_sprite: TextureRect = $CanvasLayer/TextureRect # Ajuste o caminho se necessário

var is_in_battle := false
var current_hits := 0

# Variáveis para o movimento da GUI na tela
var ui_velocity := Vector2(300, 200) # Velocidade de movimento na tela

func _ready():
	area.area_entered.connect(_on_area_entered)
	if combat_ui:
		combat_ui.visible = false

func _process(delta):
	if not is_in_battle:
		return

	# Faz a imagem da GUI se mover pela tela enquanto o jogador tenta clicar nela
	if ui_sprite:
		var screen_size = get_viewport().get_visible_rect().size
		ui_sprite.position += ui_velocity * delta

		# Faz a imagem "quicar" nas bordas da tela
		if ui_sprite.position.x < 0 or ui_sprite.position.x + ui_sprite.size.x > screen_size.x:
			ui_velocity.x *= -1
		if ui_sprite.position.y < 0 or ui_sprite.position.y + ui_sprite.size.y > screen_size.y:
			ui_velocity.y *= -1

var cached_player = null

func _on_area_entered(area_hit):
	var player = area_hit.get_parent()
	if player.has_method("start_combat") and not is_in_battle:
		is_in_battle = true
		cached_player = player # Salva aqui!
		area.set_deferred("monitoring", false)
		
		if combat_ui:
			combat_ui.visible = true
			
		player.start_combat(self)

# E quando atingir os cliques necessários:
func _on_texture_rect_gui_input(event):
	if not is_in_battle:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		current_hits += 1
		if current_hits >= required_hits:
			if combat_ui:
				combat_ui.visible = false
			if cached_player and cached_player.has_method("finish_combat"):
				cached_player.finish_combat()
