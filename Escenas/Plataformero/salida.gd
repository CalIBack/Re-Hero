extends Area2D

@export_group("Configuración de Cámara")
@export var nombre_pantalla_destino: String = "pantalla" 

func _ready() -> void:
	body_entered.connect(_al_entrar)

func _al_entrar(body: Node2D) -> void:
	# Verificamos si es el jugador
	if (body.name == "Jugador" or body.is_in_group("jugador")) and not body.estado_transicionando:
		var main = get_tree().current_scene
		
		# Le decimos a Main que mueva la cámara a esa pantalla
		if main.has_method("cambiar_camara_a_pantalla"):
			main.cambiar_camara_a_pantalla(nombre_pantalla_destino)
