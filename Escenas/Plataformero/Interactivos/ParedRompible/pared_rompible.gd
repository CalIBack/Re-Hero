extends DestruibleBase

@export_group("Pared Rompible")
@export var vida_maxima: int = 2
@export var mira_a_la_izquierda: bool = false
@export var sprite: Sprite2D

var vida_actual: int
var _pos_original: Vector2

func _ready() -> void:
	vida_actual = vida_maxima
	freeze = true
	gravity_scale = 0.0

	if sprite:
		_pos_original = sprite.position
		if mira_a_la_izquierda:
			sprite.scale.x = -1

func _recibir_golpe() -> void:
	vida_actual -= 1
	if vida_actual <= 0:
		_destruir()
	else:
		_efecto_impacto()

func _efecto_impacto() -> void:
	if not sprite:
		return

	var tween_temblor = create_tween()
	tween_temblor.tween_property(sprite, "position", _pos_original + Vector2(2, 0), 0.04)
	tween_temblor.tween_property(sprite, "position", _pos_original + Vector2(-2, 0), 0.04)
	tween_temblor.tween_property(sprite, "position", _pos_original + Vector2(1, 0), 0.04)
	tween_temblor.tween_property(sprite, "position", _pos_original, 0.04)

	var tween_flash = create_tween()
	tween_flash.tween_property(sprite, "modulate", Color(1.6, 1.6, 1.6), 0.05)
	tween_flash.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
