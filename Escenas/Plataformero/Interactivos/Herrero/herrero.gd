extends Area2D

var tipo_interaccion: String = "herrero"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func interactuar(jugador) -> void:
	var menu = get_tree().get_first_node_in_group("menu_mejora")
	if menu:
		menu.abrir(jugador)

func _on_body_entered(body: Node2D) -> void:
	if "interactivo_cercano" in body:
		body.interactivo_cercano = self

func _on_body_exited(body: Node2D) -> void:
	if "interactivo_cercano" in body and body.interactivo_cercano == self:
		body.interactivo_cercano = null
