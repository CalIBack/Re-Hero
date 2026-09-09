extends StaticBody2D

@export_group("Nodos Internos")
@export var sprite_abierta: Sprite2D
@export var sprite_cerrada: Sprite2D
@export var sprite_candado: Sprite2D
@export var area_deteccion: Area2D
@export var bloqueo: CollisionShape2D

@export var tipo_interaccion: String = "puerta"

@export var esta_bloqueada: bool = true
var _jugador_en_area: bool = false

func _ready() -> void:
	area_deteccion.body_entered.connect(_al_entrar_area)
	area_deteccion.body_exited.connect(_al_salir_area)
	_actualizar_estado()

func desbloquear(jugador: Node2D) -> void:
	if esta_bloqueada:
		if jugador.has_method("usar_llave") and jugador.usar_llave():
			esta_bloqueada = false
			_actualizar_estado()
		else:
			print("[PUERTA] Está cerrada con llave. Necesitas una.")

func _actualizar_estado() -> void:
	sprite_candado.visible = esta_bloqueada
	
	if esta_bloqueada:
		sprite_cerrada.visible = true
		sprite_abierta.visible = false
		set_collision_layer_value(1, true)
		bloqueo.set_deferred("disabled", false)
	else:
		sprite_cerrada.visible = not _jugador_en_area
		sprite_abierta.visible = _jugador_en_area
		set_collision_layer_value(1, false)
		bloqueo.set_deferred("disabled", true)

func _al_entrar_area(body: Node2D) -> void:
	if "interactivo_cercano" in body:
		body.interactivo_cercano = self
		
	if body.name == "Jugador" or body.is_in_group("jugador"):
		_jugador_en_area = true
		_actualizar_estado()

func _al_salir_area(body: Node2D) -> void:
	if "interactivo_cercano" in body and body.interactivo_cercano == self:
		body.interactivo_cercano = null
		
	if body.name == "Jugador" or body.is_in_group("jugador"):
		_jugador_en_area = false
		_actualizar_estado()
