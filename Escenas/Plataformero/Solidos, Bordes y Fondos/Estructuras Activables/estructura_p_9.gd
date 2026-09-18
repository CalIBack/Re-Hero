extends Node2D

@export var bordes: TileMapLayer
@export var solidos: TileMapLayer
@export var interactivos: TileMapLayer

func activar() -> void:
	bordes.enabled = false
	solidos.enabled = true
	interactivos.enabled = true
