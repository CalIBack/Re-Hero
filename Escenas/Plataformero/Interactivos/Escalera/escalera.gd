extends Node2D

@export var area_deteccion: Area2D

func _ready() -> void:
	if area_deteccion:
		area_deteccion.body_entered.connect(_al_entrar)
		area_deteccion.body_exited.connect(_al_salir)

func _al_entrar(body: Node2D) -> void:
	if body.has_method("agregar_escalera"):
		body.agregar_escalera()

func _al_salir(body: Node2D) -> void:
	if body.has_method("quitar_escalera"):
		body.quitar_escalera()
