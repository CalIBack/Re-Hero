extends CanvasLayer

@export_group("Texturas de Corazones")
@export var corazon_lleno: Texture2D
@export var corazon_medio: Texture2D
@export var corazon_vacio: Texture2D

@export_group("Texturas de Escudos")
@export var escudo_lleno: Texture2D
@export var escudo_vacio: Texture2D

@export_group("Configuración")
@export var valor_por_corazon: float = 20.0 

# --- Rutas actualizadas basadas en tu imagen ---
@onready var contenedor_vida: HBoxContainer = $Control/MargenIzquierdo/Contenedor/FilaVida
@onready var contenedor_escudos: HBoxContainer = $Control/MargenIzquierdo/Contenedor/FilaEscudo

@onready var texto_esquirlas: Label = $Control/MargenDerecho/Contenedor/FilaEsencia/Esencia
@onready var texto_llaves: Label = $Control/MargenDerecho/Contenedor/FilaLlave/Llaves

func actualizar_vida(hp_actual: int, hp_maximo: int) -> void:
	var total_corazones = ceil(hp_maximo / valor_por_corazon)
	_ajustar_nodos_dinamicos(contenedor_vida, total_corazones)
	
	for i in range(total_corazones):
		var icono = contenedor_vida.get_child(i)
		var hp_teorico_de_este_corazon = hp_actual - (i * valor_por_corazon)
		
		if hp_teorico_de_este_corazon >= valor_por_corazon:
			icono.texture = corazon_lleno
		elif hp_teorico_de_este_corazon > 0:
			icono.texture = corazon_medio
		else:
			icono.texture = corazon_vacio

func actualizar_escudos(usos_disponibles: int) -> void:
	_ajustar_nodos_dinamicos(contenedor_escudos, 3)
	
	for i in range(3):
		var icono = contenedor_escudos.get_child(i)
		if i < usos_disponibles:
			icono.texture = escudo_lleno
		else:
			icono.texture = escudo_vacio

func actualizar_inventario(esquirlas: int, llaves: int) -> void:
	texto_esquirlas.text = str(esquirlas)
	texto_llaves.text = str(llaves)

func _ajustar_nodos_dinamicos(contenedor: Container, cantidad_deseada: int) -> void:
	var cantidad_actual = contenedor.get_child_count()
	
	while cantidad_actual < cantidad_deseada:
		var nuevo_icono = TextureRect.new()
		
		# --- SOLUCIÓN PARA QUE NO SE ESTIREN (16x16 estricto) ---
		nuevo_icono.custom_minimum_size = Vector2(16, 16)
		nuevo_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		nuevo_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		contenedor.add_child(nuevo_icono)
		cantidad_actual += 1
		
	while cantidad_actual > cantidad_deseada:
		var ultimo_nodo = contenedor.get_child(cantidad_actual - 1)
		contenedor.remove_child(ultimo_nodo)
		ultimo_nodo.queue_free()
		cantidad_actual -= 1
