extends Area2D

@export_group("Trampas Vinculadas")
# Este array aparecerá en el Inspector. Podés asignarle todos los nodos de trampa que quieras.
@export var trampas_a_activar: Array[Node2D]

@onready var sprite: Sprite2D = $Sprite2D

var esta_presionada: bool = false

func _ready() -> void:
	body_entered.connect(_al_pisar)
	body_exited.connect(_al_soltar)

func _al_pisar(body: Node2D) -> void:
	if not esta_presionada and (body.name == "Jugador" or body.is_in_group("jugador")):
		esta_presionada = true
		
		# Efecto visual de hundimiento (oscurece la placa)
		sprite.modulate = Color(0.6, 0.6, 0.6)
		
		# Avisar a TODAS las trampas que asignaste en el editor que deben disparar
		for trampa in trampas_a_activar:
			if trampa != null and trampa.has_method("disparar"):
				trampa.disparar()

func _al_soltar(body: Node2D) -> void:
	if esta_presionada and (body.name == "Jugador" or body.is_in_group("jugador")):
		esta_presionada = false
		
		# Restaura el color original
		sprite.modulate = Color(1.0, 1.0, 1.0)
