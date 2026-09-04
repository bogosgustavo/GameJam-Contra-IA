extends Resource
class_name EnemyData

## Nome/tipo do inimigo (só pra identificação/debug)
@export var enemy_name: String = "Inimigo"

## Quantos cliques são necessários pra vencer (usado pela mecânica de combate)
@export var required_hits: int = 5

## Velocidade do sprite na tela de combate (usado pela mecânica "bounce")
@export var ui_velocity: Vector2 = Vector2(350, 250)

## Sprite/imagem usada na tela de combate
@export var sprite_texture: Texture2D

## Por quantos segundos o sprite do inimigo no mundo 3D some com fade-out ao morrer
@export var death_fade_duration: float = 1.0
