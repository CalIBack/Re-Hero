extends Area2D

@export var sprite: Sprite2D

func _ready() -> void:
	body_entered.connect(_al_entrar)
	_iniciar_flote()

func _iniciar_flote() -> void:
	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var pos_y_original = sprite.position.y
	tween.tween_property(sprite, "position:y", pos_y_original - 6.0, 1.0)
	tween.tween_property(sprite, "position:y", pos_y_original, 1.0)

func _al_entrar(body: Node2D) -> void:
	# Verificamos si es el jugador y si tiene la función que creamos
	if body.name == "Jugador" or body.is_in_group("jugador"):
		if body.has_method("recolectar_llave"):
			body.recolectar_llave()
			print("[LLAVE] ¡Llave recogida! Total de llaves: ", body.llaves)
			queue_free()
