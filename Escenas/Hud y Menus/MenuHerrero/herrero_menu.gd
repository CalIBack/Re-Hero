extends CanvasLayer

@export var lista_articulos: VBoxContainer
@export var label_esquirlas: Label
@export var boton_cerrar: Button
@export var fila_stat_escena: PackedScene
@export var control_hud: Control

const ARTICULOS := ["arma", "armadura"]
const NOMBRES := {
	"arma": "Espada",
	"armadura": "Armadura",
}
const PRECIO_INICIAL := 10

var jugador_actual: CharacterBody2D = null
var precios: Dictionary = {}
var filas: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group("menu_mejora")

	if boton_cerrar:
		boton_cerrar.pressed.connect(cerrar)

	for item in ARTICULOS:
		precios[item] = PRECIO_INICIAL

		var fila = fila_stat_escena.instantiate()
		lista_articulos.add_child(fila)
		filas[item] = fila

		fila.get_node("Nombre").text = NOMBRES[item]
		fila.get_node("Subir").text = "+"
		fila.get_node("Subir").pressed.connect(_on_subir_presionado.bind(item))

	if boton_cerrar:
		lista_articulos.move_child(boton_cerrar, -1)

func abrir(jugador: CharacterBody2D) -> void:
	jugador_actual = jugador
	visible = true
	get_tree().paused = true
	if control_hud:
		control_hud.visible = false
	_actualizar_todo()

func cerrar() -> void:
	visible = false
	get_tree().paused = false
	jugador_actual = null
	if control_hud:
		control_hud.visible = true

func _actualizar_todo() -> void:
	if not jugador_actual:
		return
	label_esquirlas.text = "Esquirlas: %d" % jugador_actual.esquirlas_alma
	for item in ARTICULOS:
		_actualizar_fila(item)

func _nombre_variable(item: String) -> String:
	return "bonus_arma" if item == "arma" else "bonus_armadura"

func _actualizar_fila(item: String) -> void:
	var fila = filas[item]
	var valor_actual: int = jugador_actual.get(_nombre_variable(item))

	fila.get_node("Valor").text = str(valor_actual)
	fila.get_node("Precio").text = str(precios[item])
	fila.get_node("Subir").disabled = jugador_actual.esquirlas_alma < precios[item]

func _on_subir_presionado(item: String) -> void:
	if not jugador_actual:
		return

	var precio: int = precios[item]
	if jugador_actual.esquirlas_alma < precio:
		return

	var stat_var = _nombre_variable(item)
	var valor_actual: int = jugador_actual.get(stat_var)

	jugador_actual.esquirlas_alma -= precio
	jugador_actual.set(stat_var, valor_actual + 1)
	jugador_actual.notificar_inventario_hud()

	precios[item] = roundi(precio * 1.5)

	_actualizar_todo()
