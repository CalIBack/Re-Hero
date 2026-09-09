extends Node2D

@export_group("Configuración de Combate")
@export var jugador_hp_max: int = 100
@export var enemigo_hp_max: int = 100

@export_group("Audio")
@export var sfx_ataque: AudioStream
@export var sfx_danio: AudioStream

@onready var fondo: Sprite2D = $Fondo
@onready var anim_jugador: AnimatedSprite2D = $Escenario/Jugador
@onready var anim_enemigo: AnimatedSprite2D = $Escenario/Enemigo
@onready var barra_vida_jugador: ProgressBar = %BarraVidaJugador
@onready var label_hp_jugador: Label = %LabelHPJugador
@onready var barra_vida_enemigo: ProgressBar = %BarraVidaEnemigo
@onready var label_hp_enemigo: Label = %LabelHPEnemigo
@onready var label_mensaje: Label = %LabelMensaje
@onready var label_banner: Label = %LabelBanner
@onready var botones_habilidad: Array[TextureButton] = [%BotonHabilidad1, %BotonHabilidad2, %BotonHabilidad3]
@onready var labels_cooldown: Array[Label] = [%LabelCooldown1, %LabelCooldown2, %LabelCooldown3]
@onready var panel_posesion: PanelContainer = %PanelPosesion
@onready var boton_poseer_si: Button = %BotonPoseerSi
@onready var boton_poseer_no: Button = %BotonPoseerNo

const ACCIONES_HABILIDAD := ["habilidad_1", "habilidad_2", "habilidad_3"]
const DURACION_DESCANSO := 2.0 # segundos que se mantiene la pose de curación

const DURACION_BANNER := 1.8
const DURACION_COMBO_JUGADOR := 4.0 # tiempo libre despues del golpe automático
const DURACION_VENTANA_ENEMIGO := 2.0
const DANIO_BASICO_ENEMIGO := 10

const DURACION_EMBESTIDA := 0.15

# Distancia de Jugador/Enemigo al centro de la pantalla, tal como quedaron
# ubicados en el editor (que muestra el lienzo declarado, 612x420).
const DESPLAZAMIENTO_JUGADOR_X := -156.0
const DESPLAZAMIENTO_ENEMIGO_X := 153.0

var posicion_inicial_jugador: Vector2
var posicion_inicial_enemigo: Vector2
var jugador_hp: int
var enemigo_hp: int
var combate_terminado := false
var ocupado := false # true mientras se reproduce una animación, bloquea nuevas habilidades
var puede_actuar := false # true solo durante el tramo de combo libre de tu turno
var _animando_golpe_basico := false # true mientras el Ataque en curso es el golpe rápido

# Cada habilidad es un diccionario: nombre, daño al enemigo, curación al jugador,
# cooldown_max (segundos que tarda en volver a estar disponible) y cooldown_actual.
var habilidades: Array[Dictionary] = [
	{"nombre": "[1] Golpe Rápido", "danio": 10, "curacion": 0, "cooldown_max": 1.0, "cooldown_actual": 0.0, "embestida": 45.0},
	{"nombre": "[2] Golpe Fuerte", "danio": 25, "curacion": 0, "cooldown_max": 6.0, "cooldown_actual": 0.0, "embestida": 90.0},
	{"nombre": "[3] Curación", "danio": 0, "curacion": 15, "cooldown_max": 10.0, "cooldown_actual": 0.0, "embestida": 0.0},
]

func _ready() -> void:
	jugador_hp = jugador_hp_max
	enemigo_hp = enemigo_hp_max

	_centrar_segun_pantalla_real()

	for i in botones_habilidad.size():
		botones_habilidad[i].pressed.connect(_usar_habilidad.bind(i))

	anim_jugador.play("Idle")
	anim_enemigo.play("Idle")
	anim_jugador.frame_changed.connect(_al_cambiar_frame_jugador)
	anim_enemigo.frame_changed.connect(_al_cambiar_frame_enemigo)
	label_banner.hide()
	panel_posesion.hide()
	boton_poseer_si.pressed.connect(_on_poseer_si)
	boton_poseer_no.pressed.connect(_on_poseer_no)
	posicion_inicial_jugador = anim_jugador.position
	posicion_inicial_enemigo = anim_enemigo.position
	_actualizar_hud()
	_iniciar_combate()

# El HUD se autoajusta al ancho real de la ventana porque usa anclas, pero
# Fondo/Jugador/Enemigo tienen posición fija de Node2D. Con
# stretch/aspect="expand" y una ventana más ancha que el lienzo declarado,
# el centro real de pantalla no coincide con el que se ve en el editor.
# Recalculamos el centro real y reubicamos todo en base a eso.
func _centrar_segun_pantalla_real() -> void:
	var centro_real_x = get_viewport_rect().size.x / 2.0
	fondo.position.x = centro_real_x
	anim_jugador.position.x = centro_real_x + DESPLAZAMIENTO_JUGADOR_X
	anim_enemigo.position.x = centro_real_x + DESPLAZAMIENTO_ENEMIGO_X

func reproducir_sfx(pista: AudioStream) -> void:
	if pista == null:
		return
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = pista
	add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

# Mismo frame (4) en el que jugador.gd dispara el sonido del golpe en el plataformero.
func _al_cambiar_frame_jugador() -> void:
	if anim_jugador.animation == "Ataque" and anim_jugador.frame == 4 and _animando_golpe_basico:
		reproducir_sfx(sfx_ataque)

func _al_cambiar_frame_enemigo() -> void:
	if anim_enemigo.animation == "Ataque" and anim_enemigo.frame == 4:
		reproducir_sfx(sfx_danio)

func _process(delta: float) -> void:
	for habilidad in habilidades:
		if habilidad["cooldown_actual"] > 0.0:
			habilidad["cooldown_actual"] = max(habilidad["cooldown_actual"] - delta, 0.0)
	_actualizar_hud()

	for i in ACCIONES_HABILIDAD.size():
		if Input.is_action_just_pressed(ACCIONES_HABILIDAD[i]):
			_usar_habilidad(i)

# ----------------------------------------------------
# BUCLE DE TURNOS
# ----------------------------------------------------
func _iniciar_combate() -> void:
	label_banner.text = "¡Inicia la pelea!"
	label_banner.show()
	await get_tree().create_timer(DURACION_BANNER).timeout
	label_banner.hide()

	while not combate_terminado:
		await _turno_jugador()
		if combate_terminado:
			break
		await _turno_enemigo()

func _turno_jugador() -> void:
	puede_actuar = false
	label_mensaje.text = "¡Tu turno!"
	_actualizar_hud()

	await _ejecutar_habilidad(0) # golpe rápido automático, marca el inicio del turno
	if combate_terminado:
		return

	puede_actuar = true
	_actualizar_hud()
	await get_tree().create_timer(DURACION_COMBO_JUGADOR).timeout
	puede_actuar = false
	_actualizar_hud()

func _turno_enemigo() -> void:
	label_mensaje.text = "Turno del enemigo..."
	_actualizar_hud()

	anim_enemigo.play("Ataque")
	var tween_ida = create_tween()
	tween_ida.tween_property(anim_enemigo, "position:x", posicion_inicial_enemigo.x - habilidades[0]["embestida"], DURACION_EMBESTIDA)
	await anim_enemigo.animation_finished
	var tween_vuelta = create_tween()
	tween_vuelta.tween_property(anim_enemigo, "position:x", posicion_inicial_enemigo.x, DURACION_EMBESTIDA)
	await tween_vuelta.finished
	anim_enemigo.play("Idle")

	jugador_hp = max(jugador_hp - DANIO_BASICO_ENEMIGO, 0)
	label_mensaje.text = "El enemigo golpeó: %d de daño" % DANIO_BASICO_ENEMIGO
	_actualizar_hud()

	await get_tree().create_timer(DURACION_VENTANA_ENEMIGO).timeout

# ----------------------------------------------------
# HABILIDADES DEL JUGADOR
# ----------------------------------------------------
func _usar_habilidad(indice: int) -> void:
	if not puede_actuar or combate_terminado or ocupado:
		return
	await _ejecutar_habilidad(indice)

func _ejecutar_habilidad(indice: int) -> void:
	var habilidad = habilidades[indice]
	if habilidad["cooldown_actual"] > 0.0:
		return

	var es_curacion = habilidad["curacion"] > 0

	if habilidad["danio"] > 0:
		enemigo_hp = max(enemigo_hp - habilidad["danio"], 0)
		label_mensaje.text = "Usaste %s: %d de daño" % [habilidad["nombre"], habilidad["danio"]]
	elif es_curacion:
		jugador_hp = min(jugador_hp + habilidad["curacion"], jugador_hp_max)
		label_mensaje.text = "Usaste %s: +%d HP" % [habilidad["nombre"], habilidad["curacion"]]

	habilidad["cooldown_actual"] = habilidad["cooldown_max"]
	_actualizar_hud()

	ocupado = true
	if es_curacion:
		anim_jugador.play("Descanso")
		await get_tree().create_timer(DURACION_DESCANSO).timeout
	else:
		_animando_golpe_basico = indice == 0
		anim_jugador.play("Ataque")
		var tween_ida = create_tween()
		tween_ida.tween_property(anim_jugador, "position:x", posicion_inicial_jugador.x + habilidad["embestida"], DURACION_EMBESTIDA)
		await anim_jugador.animation_finished
		var tween_vuelta = create_tween()
		tween_vuelta.tween_property(anim_jugador, "position:x", posicion_inicial_jugador.x, DURACION_EMBESTIDA)
		await tween_vuelta.finished
		_animando_golpe_basico = false
	anim_jugador.play("Idle")
	ocupado = false

	_revisar_fin_combate()

func _actualizar_hud() -> void:
	barra_vida_jugador.max_value = jugador_hp_max
	barra_vida_jugador.value = jugador_hp
	label_hp_jugador.text = "%d / %d" % [jugador_hp, jugador_hp_max]

	barra_vida_enemigo.max_value = enemigo_hp_max
	barra_vida_enemigo.value = enemigo_hp
	label_hp_enemigo.text = "%d / %d" % [enemigo_hp, enemigo_hp_max]

	for i in botones_habilidad.size():
		var habilidad = habilidades[i]
		var boton = botones_habilidad[i]
		var en_cooldown = habilidad["cooldown_actual"] > 0.0

		labels_cooldown[i].text = str(ceili(habilidad["cooldown_actual"])) if en_cooldown else ""
		boton.disabled = en_cooldown or ocupado or combate_terminado or not puede_actuar
		boton.modulate = Color(0.45, 0.45, 0.45, 1) if boton.disabled else Color(1, 1, 1, 1)

func _revisar_fin_combate() -> void:
	if enemigo_hp <= 0 and not combate_terminado:
		combate_terminado = true
		EstadoJuego.marcar_enemigo_derrotado(EstadoJuego.id_enemigo_en_combate)
		anim_enemigo.play("Muerte")
		label_mensaje.text = "¡Victoria!"
		await get_tree().create_timer(1.5).timeout
		panel_posesion.show()

func _on_poseer_si() -> void:
	panel_posesion.hide()
	EstadoJuego.poseido = true
	anim_jugador.play("Muerte")
	await anim_jugador.animation_finished
	get_tree().change_scene_to_file("res://Escenas/Main.tscn")

func _on_poseer_no() -> void:
	panel_posesion.hide()
	get_tree().change_scene_to_file("res://Escenas/Main.tscn")
