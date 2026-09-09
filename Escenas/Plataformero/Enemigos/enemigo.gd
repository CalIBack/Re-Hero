extends Area2D

# Identificador único de esta instancia — si agregás más enemigos, cambiale
# el valor en el Inspector para que cada uno se recuerde por separado.
@export var id_enemigo: String = "enemigo_pantalla1"

@onready var anim: AnimatedSprite2D = $Sprite2D

func _ready() -> void:
	if EstadoJuego.enemigo_esta_derrotado(id_enemigo):
		_mostrar_como_derrotado()
		return

	body_entered.connect(_al_entrar)

func _al_entrar(body: Node2D) -> void:
	if body.name == "Jugador" or body.is_in_group("jugador"):
		EstadoJuego.id_enemigo_en_combate = id_enemigo
		EstadoJuego.guardar_punto_de_regreso(get_parent().name, body.global_position)
		if "hp_actual" in body:
			EstadoJuego.guardar_stats_jugador(body.hp_actual, body.usos_escudo, body.llaves, body.esquirlas_alma)
		get_tree().change_scene_to_file("res://Escenas/Combate/Combate.tscn")

func _mostrar_como_derrotado() -> void:
	monitoring = false
	monitorable = false
	anim.play("Muerte")
