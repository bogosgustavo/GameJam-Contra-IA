extends CharacterBody3D

@export_group("camera")
@export_range(0.0, 1,0) var senb := 0.25

var _direcao := Vector2.ZERO

@onready var pivot: Node3D = %Camerapivot

func _unhandled_input(event: InputEvent) -> void:
	var movimenta := (
		event is InputEventMouseMotion and 
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if movimenta:
		_direcao = event.screen_relative * senb

func _physics_process(delta: float) -> void:
	pivot.rotation.x += _direcao.y * delta
	pivot.rotation.x = clamp(pivot.rotation.x, -PI / 6.0, PI / 3.0)
	pivot.rotation.y -= _direcao.x * delta
