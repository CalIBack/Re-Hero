extends StaticBody2D

@export_group("Configuración de Trampa")
@export var escena_dardo: PackedScene
@export var dispara_izquierda: bool = false

@onready var punto_disparo: Marker2D = $Marker2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Por defecto (false) mira hacia la derecha
	if dispara_izquierda:
		sprite.scale.x = -1
		punto_disparo.position.x = -abs(punto_disparo.position.x)
	else:
		sprite.scale.x = 1
		punto_disparo.position.x = abs(punto_disparo.position.x)

func disparar() -> void:
	if escena_dardo == null:
		print("[TRAMPA] Error: No se asignó la escena del dardo.")
		return
		
	var nuevo_dardo = escena_dardo.instantiate()
	
	nuevo_dardo.global_position = punto_disparo.global_position
	
	# Por defecto (false) dispara hacia la derecha
	if dispara_izquierda:
		nuevo_dardo.direccion = -1.0
		nuevo_dardo.scale.x = -1 
	else:
		nuevo_dardo.direccion = 1.0
		nuevo_dardo.scale.x = 1

	# call_deferred espera a que terminen las físicas de este frame para agregar el nodo.
	get_tree().current_scene.call_deferred("add_child", nuevo_dardo)
