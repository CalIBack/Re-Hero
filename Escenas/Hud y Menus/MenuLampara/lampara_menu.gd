extends CanvasLayer

@export var lista_stats: VBoxContainer
@export var label_esquirlas: Label
@export var boton_cerrar: Button
@export var fila_stat_escena: PackedScene
@export var control_hud: Control

const STATS := ["constitucion", "resistencia", "fuerza", "agilidad", "percepcion", "inteligencia", "suerte", "carisma"]
const NOMBRES := {
	"constitucion": "Constitución",
	"resistencia": "Resistencia",
	"fuerza": "Fuerza",
	"agilidad": "Agilidad",
	"percepcion": "Percepción",
	"inteligencia": "Inteligencia",
	"suerte": "Suerte",
	"carisma": "Carisma",
}
const PRECIO_INICIAL := 10
const VALOR_MAXIMO := 10

var jugador_actual: CharacterBody2D = null
var precios: Dictionary = {}
var filas: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	print("[MENU] _ready() arrancando")
	print("[MENU] lista_stats asignado=", lista_stats != null)
	print("[MENU] label_esquirlas asignado=", label_esquirlas != null)
	print("[MENU] boton_cerrar asignado=", boton_cerrar != null)
	print("[MENU] fila_stat_escena asignado=", fila_stat_escena != null)
	print("[MENU] control_hud asignado=", control_hud != null)

	visible = false
	add_to_group("menu_subida_nivel")

	if boton_cerrar:
		boton_cerrar.pressed.connect(cerrar)
		print("[MENU] boton_cerrar.pressed conectado a cerrar()")
	else:
		print("[MENU] ATENCION: boton_cerrar es null, no se pudo conectar")

	if not fila_stat_escena:
		print("[MENU] ATENCION: fila_stat_escena es null, no se pueden crear filas")
		return

	if not lista_stats:
		print("[MENU] ATENCION: lista_stats es null, no se pueden agregar filas")
		return

	for stat in STATS:
		precios[stat] = PRECIO_INICIAL

		var fila = fila_stat_escena.instantiate()
		lista_stats.add_child(fila)
		filas[stat] = fila

		var nodo_nombre = fila.get_node_or_null("Nombre")
		var nodo_valor = fila.get_node_or_null("Valor")
		var nodo_subir = fila.get_node_or_null("Subir")
		var nodo_precio = fila.get_node_or_null("Precio")

		print("[MENU][", stat, "] Nombre=", nodo_nombre, " Valor=", nodo_valor, " Subir=", nodo_subir, " (clase=", nodo_subir.get_class() if nodo_subir else "NULO", ") Precio=", nodo_precio)

		if nodo_nombre:
			nodo_nombre.text = NOMBRES[stat]
		if nodo_subir:
			nodo_subir.text = "+"
			nodo_subir.pressed.connect(_on_subir_presionado.bind(stat))
			print("[MENU][", stat, "] boton Subir conectado")

	if boton_cerrar:
		lista_stats.move_child(boton_cerrar, -1)

	print("[MENU] _ready() terminado. process_mode=", process_mode)

func abrir(jugador: CharacterBody2D) -> void:
	print("[MENU] abrir() llamado con jugador=", jugador)
	jugador_actual = jugador
	visible = true
	get_tree().paused = true
	if control_hud:
		control_hud.visible = false
	_actualizar_todo()

func cerrar() -> void:
	print("[MENU] cerrar() llamado")
	visible = false
	get_tree().paused = false
	jugador_actual = null
	if control_hud:
		control_hud.visible = true

func _actualizar_todo() -> void:
	if not jugador_actual:
		print("[MENU] _actualizar_todo() sin jugador_actual, abortando")
		return

	label_esquirlas.text = "Esquirlas: %d" % jugador_actual.esquirlas_alma
	for stat in STATS:
		_actualizar_fila(stat)

func _actualizar_fila(stat: String) -> void:
	var fila = filas[stat]
	var valor_actual: int = jugador_actual.get(stat)

	fila.get_node("Valor").text = str(valor_actual)
	fila.get_node("Precio").text = str(precios[stat])
	fila.get_node("Subir").disabled = valor_actual >= VALOR_MAXIMO or jugador_actual.esquirlas_alma < precios[stat]

func _on_subir_presionado(stat: String) -> void:
	print("[MENU] _on_subir_presionado(", stat, ")")

	if not jugador_actual:
		print("[MENU] ATENCION: jugador_actual es null")
		return

	var precio: int = precios[stat]
	var valor_actual: int = jugador_actual.get(stat)

	print("[MENU] precio=", precio, " valor_actual=", valor_actual, " esquirlas=", jugador_actual.esquirlas_alma)

	if jugador_actual.esquirlas_alma < precio or valor_actual >= VALOR_MAXIMO:
		print("[MENU] no alcanza o ya esta al maximo, no se compra")
		return

	jugador_actual.esquirlas_alma -= precio
	jugador_actual.set(stat, valor_actual + 1)
	jugador_actual.recalcular_stats()
	jugador_actual.notificar_inventario_hud()

	precios[stat] = roundi(precio * 1.5)

	print("[MENU] compra exitosa. nuevo valor=", jugador_actual.get(stat), " nuevo precio=", precios[stat])

	_actualizar_todo()
