extends Node2D

@export_group("Audio")
@export var musica_fondo: AudioStream # Arrastra tu música aquí

@export_group("Configuración de Inicio")
@export var pantalla_inicial: String = "Pantalla1"

@onready var region: Node2D = $Region
@onready var camara: Camera2D = $Camera2D
@onready var jugador: CharacterBody2D = $Jugador
@onready var hud: CanvasLayer = $Hud 

var _pantalla_actual_nodo: Node2D = null

func _ready() -> void:
	# --- REPRODUCTOR BGM GLOBAL (vive en el Autoload, no se corta al cambiar de escena) ---
	EstadoJuego.reproducir_musica(musica_fondo)


	# 1. CONEXIÓN DE LA HUD Y EL JUGADOR
	jugador.vida_cambiada.connect(hud.actualizar_vida)
	jugador.escudo_cambiado.connect(hud.actualizar_escudos)
	jugador.inventario_cambiado.connect(hud.actualizar_inventario)
	
	# =========================================================
	# 2. OPTIMIZACIÓN Y CONFIGURACIÓN DEL MUNDO
	# =========================================================
	for pantalla in region.get_children():
		if pantalla is Node2D:
			pantalla.visible = false
			pantalla.process_mode = Node.PROCESS_MODE_DISABLED

	# Si venimos de un combate, volvemos a la pantalla donde nos cruzamos
	# con el enemigo en vez de arrancar siempre desde la pantalla inicial.
	var pantalla_a_usar = pantalla_inicial
	if EstadoJuego.hay_punto_de_regreso:
		pantalla_a_usar = EstadoJuego.pantalla_regreso

	if region.has_node(pantalla_a_usar):
		_pantalla_actual_nodo = region.get_node(pantalla_a_usar)
		_pantalla_actual_nodo.visible = true
		_pantalla_actual_nodo.process_mode = Node.PROCESS_MODE_INHERIT

		var centro = _pantalla_actual_nodo.find_child("Camara", true, false)
		if centro:
			camara.global_position = centro.global_position

		if EstadoJuego.hay_punto_de_regreso:
			jugador.global_position = EstadoJuego.posicion_regreso
			camara.global_position = jugador.global_position
			EstadoJuego.hay_punto_de_regreso = false
	else:
		print("[MAIN] Error: La pantalla '", pantalla_a_usar, "' no está dentro del nodo Region.")

# Función llamada por las Salidas (Area2D)
func cambiar_camara_a_pantalla(nombre_destino: String) -> void:
	if not region.has_node(nombre_destino):
		print("[MAIN] Error: No se encontró la pantalla destino en Region: ", nombre_destino)
		return
		
	var nivel_nuevo = region.get_node(nombre_destino)
	
	if nivel_nuevo == _pantalla_actual_nodo:
		return
		
	var centro = nivel_nuevo.find_child("Camara", true, false)
	
	if centro:
		_transicion_suave_camara(_pantalla_actual_nodo, nivel_nuevo, centro)
	else:
		print("[MAIN] Error: La pantalla ", nombre_destino, " no tiene un Marker2D llamado 'Camara'.")

func _transicion_suave_camara(nivel_viejo: Node2D, nivel_nuevo: Node2D, centro: Marker2D) -> void:
	jugador.estado_transicionando = true
	
	# VITAL: Hacemos visible Y activamos las físicas del nuevo nivel ANTES de que la cámara viaje
	nivel_nuevo.visible = true
	nivel_nuevo.process_mode = Node.PROCESS_MODE_INHERIT
	
	var tween = create_tween()
	tween.tween_property(camara, "global_position", centro.global_position, 0.6).set_trans(Tween.TRANS_SINE)
	
	tween.finished.connect(func():
		# VITAL: Ocultamos Y apagamos las físicas del nivel viejo DESPUÉS de que la cámara llega
		if nivel_viejo and nivel_viejo != nivel_nuevo:
			nivel_viejo.visible = false
			nivel_viejo.process_mode = Node.PROCESS_MODE_DISABLED
			
		_pantalla_actual_nodo = nivel_nuevo
		jugador.estado_transicionando = false
	)
