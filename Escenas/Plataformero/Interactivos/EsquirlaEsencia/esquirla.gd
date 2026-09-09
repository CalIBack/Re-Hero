extends RigidBody2D

var valor: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var area_recolectar: Area2D = $Area2D

func _ready() -> void:
	# 1. Definimos cuánto vale esta esquirla
	valor = randi_range(1, 5)
	
	# 2. Escalar según el valor (para que se note que es un "billete grande")
	var escala_calculada = 1.0 + ((valor - 1) * 0.2)
	sprite.scale = Vector2(escala_calculada, escala_calculada)
	area_recolectar.scale = Vector2(escala_calculada, escala_calculada)
	
	# 3. Conectamos la recolección
	area_recolectar.body_entered.connect(_al_entrar)
	
	# 4. Le aplicamos físicas reales y animamos el Sprite
	_explotar()
	_iniciar_flote_visual()

func _explotar() -> void:
	randomize() # Asegura que el siguiente cálculo sea 100% nuevo
	var impulso_x = randf_range(-150.0, 150.0)
	var impulso_y = randf_range(-300.0, -150.0) 
	
	linear_velocity = Vector2(impulso_x, impulso_y)

func _iniciar_flote_visual() -> void:
	# IMPORTANTE: Movemos SOLO el Sprite2D, no el RigidBody2D.
	# Así, el cuerpo físico puede quedarse quieto en el suelo mientras el PNG flota arriba y abajo.
	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var pos_y_original = sprite.position.y
	tween.tween_property(sprite, "position:y", pos_y_original - 6.0, 1.0)
	tween.tween_property(sprite, "position:y", pos_y_original, 1.0)

func _al_entrar(body: Node2D) -> void:
	# Cuando el jugador toca el Area2D recolectar
	if body.name == "Jugador" or body.is_in_group("jugador"):
		if body.has_method("recolectar_esquirla"):
			body.recolectar_esquirla(valor)
			queue_free()
