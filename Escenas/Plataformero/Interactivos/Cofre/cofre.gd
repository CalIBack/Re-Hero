extends RigidBody2D

@export_group("Nodos Internos")
@export var sprite_abierto: Sprite2D
@export var sprite_cerrado: Sprite2D
@export var area_deteccion: Area2D
@export var spawn_punto: Marker2D

@export_group("Recompensas")
@export var esquirla_escena: PackedScene

@export var tipo_interaccion: String = "cofre"

@export var esta_bloqueado: bool = true

func _ready() -> void:
	_actualizar_visual()
	
	if area_deteccion:
		area_deteccion.body_entered.connect(_al_entrar_area)
		area_deteccion.body_exited.connect(_al_salir_area)

func interactuar(jugador: Node2D) -> void:
	if esta_bloqueado:
		if jugador.has_method("usar_llave") and jugador.usar_llave():
			esta_bloqueado = false
			_actualizar_visual()
			_soltar_recompensas()
		else:
			print("[COFRE] Está cerrado. Necesitas una llave.")
			
func _soltar_recompensas() -> void:
	if esquirla_escena == null or spawn_punto == null:
		print("[COFRE] Faltan nodos de recompensa por configurar en el editor.")
		return
		
	randomize()
	
	for i in range(5):
		var nueva_esquirla = esquirla_escena.instantiate()
		
		var offset_x = randf_range(-10.0, 10.0)
		var offset_y = randf_range(-10.0, 10.0)
		var pos_final = spawn_punto.global_position + Vector2(offset_x, offset_y)
		
		get_parent().call_deferred("add_child", nueva_esquirla)
		nueva_esquirla.set_deferred("global_position", pos_final)

func _actualizar_visual() -> void:
	sprite_cerrado.visible = esta_bloqueado
	sprite_abierto.visible = not esta_bloqueado

func _al_entrar_area(body: Node2D) -> void:
	if "interactivo_cercano" in body:
		body.interactivo_cercano = self

func _al_salir_area(body: Node2D) -> void:
	if "interactivo_cercano" in body and body.interactivo_cercano == self:
		body.interactivo_cercano = null
