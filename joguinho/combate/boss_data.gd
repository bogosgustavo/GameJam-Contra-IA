extends EnemyData
class_name BossData

## Textura do papel que o boss joga periodicamente
@export var paper_texture: Texture2D

## Textura da impressora (alvo onde os papéis precisam ser soltos)
@export var printer_texture: Texture2D

## Segundos entre uma jogada de papel e a próxima
@export var throw_interval: float = 4.0

## Segundos que o boss fica vulnerável depois de TODOS os papéis serem entregues
@export var vulnerable_duration: float = 3.0

## Quantos papéis são jogados de uma vez (usado se Hp Thresholds estiver vazio)
@export var papers_per_throw: int = 1

## Velocidade com que cada papel se move pela tela (direção é sorteada)
@export var paper_speed: float = 200.0

## Sprite do boss enquanto está jogando o(s) papel(is)
@export var throwing_texture: Texture2D

## Sprite do boss enquanto está vulnerável (se vazio, usa sprite_texture com tom avermelhado)
@export var vulnerable_texture: Texture2D

## Por quanto tempo mostra o sprite de "jogando papel" antes dos papéis aparecerem
@export var throwing_display_time: float = 0.4

## Sprites de "levando dano", alternados a cada clique enquanto vulnerável
@export var hit_textures: Array[Texture2D] = []

## Por quanto tempo cada sprite de dano fica visível antes de voltar ao sprite vulnerável
@export var hit_flash_duration: float = 0.15

## Quanto de vida cada clique tira (vida total = Required Hits, herdado de EnemyData)
@export var damage_per_click: int = 1

## Limiares de vida (fração de 0.0 a 1.0), em ordem decrescente. Ex: [1.0, 0.66, 0.33]
@export var hp_thresholds: Array[float] = []

## Quantos papéis jogar em cada limiar acima (mesmo índice = mesmo limiar)
@export var papers_at_threshold: Array[int] = []

## Sprite mostrado no mundo 3D depois do fade-out de derrota, antes do jogo terminar
@export var final_texture: Texture2D

## Por quanto tempo o final_texture fica visível antes do jogo finalizar
@export var final_display_time: float = 2.0

# Required Hits (herdado de EnemyData) = vida total do boss (ex: 200).
# Sprite Texture (herdado) = sprite do boss parado (estado padrão).
# Death Fade Duration (herdado) = duração do fade-out do sprite ao morrer.
