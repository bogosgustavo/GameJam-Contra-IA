extends Node3D
class_name EnemyController

@export var enemy_data_list: Array[EnemyData] = []
@export var combat_scene: PackedScene
@onready var area: Area3D = $Area3D

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

	if cached_player and cached_player.has_method("finish_combat"):
		cached_player.finish_combat()

	queue_free()
