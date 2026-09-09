class_name DestruibleBase
extends RigidBody2D

@export_group("Configuración Destruible")
@export var area_deteccion: Area2D
@export var es_empujable: bool = true

@export_group("Recompensas de Loot")
@export var da_loot: bool = false
@export var cantidad_esquirlas: int = 1 # Aquí pondrás 3 para la caja y 1 para la urna
@export var esquirla_escena: PackedScene
@export var spawn_punto: Marker2D

func _physics_process(_delta: float) -> void:
	var puede_ser_empujada = false
	var velocidad_empuje = 0.0
	
	if area_deteccion:
		for area in area_deteccion.get_overlapping_areas():
			
			# 1. ROMPER EN EL FRAME EXACTO (Siempre destructible)
			if area.is_in_group("arma_espada"):
				var heroe = area.get_parent().get_parent() 
				if heroe and heroe.get("estado_atacando") == true:
					if heroe.anim.frame == 4: 
						_destruir()
						return
						
			# 2. EMPUJAR CON ESCUDO (Solo si es empujable)
			elif area.is_in_group("arma_escudo") and es_empujable:
				var heroe = area.get_parent().get_parent()
				if heroe and Input.is_action_pressed("bloqueo"):
					var direccion_input = Input.get_axis("izquierda", "derecha")
					if direccion_input != 0:
						puede_ser_empujada = true
						velocidad_empuje = direccion_input * 85.0
						
	# 3. APLICAR FÍSICA
	if puede_ser_empujada:
		linear_velocity.x = velocidad_empuje
	else:
		linear_velocity.x = 0

# Función interna que maneja la secuencia de destrucción
func _destruir() -> void:
	if da_loot:
		soltar_loot()
	queue_free()

# Como ambas comparten el script, resolvemos el loot directamente aquí
func soltar_loot() -> void:
	if esquirla_escena == null or spawn_punto == null:
		print("[DESTRUIBLE] Faltan configurar nodos de recompensa en: ", name)
		return

	randomize()

	# Generamos exactamente la cantidad de esquirlas dictadas por el inspector
	for i in range(cantidad_esquirlas):
		var nueva_esquirla = esquirla_escena.instantiate()
		
		# 1. Calculamos la posición final deseada
		var offset_x = randf_range(-10.0, 10.0)
		var offset_y = randf_range(-10.0, 10.0)
		var pos_final = spawn_punto.global_position + Vector2(offset_x, offset_y)
		
		# 2. VITAL: Primero la agregamos al árbol de forma diferida (segura)
		get_parent().call_deferred("add_child", nueva_esquirla)
		
		# 3. VITAL: Le asignamos la posición global DESPUÉS de que ya es hija, 
		# también de forma diferida para que la matemática de coordenadas sea perfecta.
		nueva_esquirla.set_deferred("global_position", pos_final)
