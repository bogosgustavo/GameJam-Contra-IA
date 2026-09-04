extends Node3D
class_name EnemyController

## Status de cada inimigo desta luta (1 item = luta solo, 2+ = luta em grupo)
@export var enemy_data_list: Array[EnemyData] = []

## Qual mecânica de combate este grupo usa (arraste um .tscn com script CombatBase)
@export var combat_scene: PackedScene

@onready var area: Area3D = $Area3D

# Opcional: só usado pelo boss, pra mostrar o sprite final depois do fade-out.
@onready var final_sprite: Sprite3D = get_node_or_null("FinalSprite")

var is_in_battle := false
var cached_player: Node3D = null
var combat_instance: CombatBase = null

func _ready():
	area.area_entered.connect(_on_area_entered)

func _on_area_entered(area_hit: Area3D) -> void:
	if is_in_battle:
		return

	var player = area_hit.get_parent()
	if not player.has_method("start_combat"):
		return

	if "in_combat" in player and player.in_combat:
		return

	if enemy_data_list.is_empty() or combat_scene == null:
		push_warning("Enemy '%s': enemy_data_list vazio ou combat_scene não configurado." % name)
		return

	is_in_battle = true
	cached_player = player
	area.set_deferred("monitoring", false)

	_start_combat_ui()
	player.start_combat(self)

func _start_combat_ui() -> void:
	combat_instance = combat_scene.instantiate()
	get_tree().root.add_child(combat_instance)
	combat_instance.combat_won.connect(_on_combat_won)
	combat_instance.start_combat(enemy_data_list)

func _on_combat_won() -> void:
	if combat_instance:
		combat_instance.queue_free()
		combat_instance = null

	var data: EnemyData = enemy_data_list[0] if not enemy_data_list.is_empty() else null

	if data is BossData:
		_play_boss_defeat_sequence(data)
	else:
		_play_fade_then_finish(data)

func _fade_out_sprites(duration: float) -> void:
	var sprites: Array = []
	for child in get_children():
		if child is Sprite3D and child != final_sprite:
			sprites.append(child)

	print("DEBUG fade -> sprites encontrados: ", sprites.size(), " | duration: ", duration)

	if sprites.is_empty() or duration <= 0.0:
		print("DEBUG fade -> SAIU CEDO (sem sprites ou duration <= 0)")
		return

	var tween := create_tween()
	tween.set_parallel(true)
	for sprite in sprites:
		var target_color: Color = sprite.modulate
		target_color.a = 0.0
		tween.tween_property(sprite, "modulate", target_color, duration)

	await tween.finished

func _play_fade_then_finish(data: EnemyData) -> void:
	var duration: float = data.death_fade_duration if data else 1.0
	print("DEBUG fade -> data: ", data, " | duration: ", duration)
	await _fade_out_sprites(duration)
	print("DEBUG fade -> terminou o fade, chamando finish")
	_finish_and_free()

func _finish_and_free() -> void:
	if cached_player and cached_player.has_method("finish_combat"):
		cached_player.finish_combat()
	queue_free()

func _play_boss_defeat_sequence(data: BossData) -> void:
	var duration: float = data.death_fade_duration
	await _fade_out_sprites(duration)

	if final_sprite and data.final_texture:
		final_sprite.texture = data.final_texture
		final_sprite.modulate = Color(1, 1, 1, 1)
		final_sprite.visible = true

	if data.final_display_time > 0.0:
		await get_tree().create_timer(data.final_display_time).timeout

	if cached_player and cached_player.has_method("finish_combat"):
		cached_player.finish_combat()

	_finish_game()

func _finish_game() -> void:
	# Ponto único pra você plugar o que quiser quando o jogo terminar de vez:
	# trocar de cena pra uma tela de vitória, mostrar um texto, pausar, etc.
	print("JOGO FINALIZADO — boss derrotado!")
	queue_free()
