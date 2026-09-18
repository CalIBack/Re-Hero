class_name DestruibleBase
extends RigidBody2D

@export_group("Configuración Destruible")
@export var area_deteccion: Area2D
@export var es_empujable: bool = true

@export_group("Recompensas de Loot")
@export var da_loot: bool = false
@export var cantidad_esquirlas: int = 1
@export var esquirla_escena: PackedScene
@export var spawn_punto: Marker2D

var _golpe_ya_registrado: bool = false

func _physics_process(_delta: float) -> void:
	var puede_ser_empujada = false
	var velocidad_empuje = 0.0

	if not area_deteccion:
		return

	for area in area_deteccion.get_overlapping_areas():
		if area.is_in_group("arma_espada"):
			var heroe = area.get_parent().get_parent()
			if not heroe:
				continue

			if heroe.get("estado_atacando") == true and heroe.anim.frame == 4:
				if not _golpe_ya_registrado:
					_golpe_ya_registrado = true
					_recibir_golpe()
				return
			else:
				_golpe_ya_registrado = false

		elif area.is_in_group("arma_escudo") and es_empujable:
			var heroe = area.get_parent().get_parent()
			if heroe and Input.is_action_pressed("bloqueo"):
				var direccion_input = Input.get_axis("izquierda", "derecha")
				if direccion_input != 0:
					puede_ser_empujada = true
					velocidad_empuje = direccion_input * 85.0

	if puede_ser_empujada:
		linear_velocity.x = velocidad_empuje
	else:
		linear_velocity.x = 0

func _recibir_golpe() -> void:
	_destruir()

func _destruir() -> void:
	if da_loot:
		soltar_loot()
	queue_free()

func soltar_loot() -> void:
	if esquirla_escena == null or spawn_punto == null:
		print("[DESTRUIBLE] Faltan configurar nodos de recompensa en: ", name)
		return

	randomize()

	for i in range(cantidad_esquirlas):
		var nueva_esquirla = esquirla_escena.instantiate()
		var offset_x = randf_range(-10.0, 10.0)
		var offset_y = randf_range(-10.0, 10.0)
		var pos_final = spawn_punto.global_position + Vector2(offset_x, offset_y)
		get_parent().call_deferred("add_child", nueva_esquirla)
		nueva_esquirla.set_deferred("global_position", pos_final)
