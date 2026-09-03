extends CanvasLayer
class_name CombatBase

signal combat_won
signal combat_lost

func start_combat(_data_list: Array) -> void:
	push_error("start_combat() precisa ser implementado na cena de combate filha")
