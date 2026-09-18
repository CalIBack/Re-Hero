extends Area2D

@export var objetivo: Node2D
@export var sprite: Sprite2D

var tipo_interaccion: String = "palanca"
var esta_activada: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func interactuar(_jugador) -> void:
	if esta_activada or not objetivo:
		return

	esta_activada = true
	objetivo.activar()

	if sprite:
		sprite.scale.y *= -1

func _on_body_entered(body: Node2D) -> void:
	if "interactivo_cercano" in body:
		body.interactivo_cercano = self

func _on_body_exited(body: Node2D) -> void:
	if "interactivo_cercano" in body and body.interactivo_cercano == self:
		body.interactivo_cercano = null
