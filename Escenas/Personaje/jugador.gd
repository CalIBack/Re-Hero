extends CharacterBody2D

const VELOCIDAD = 85.0
const SALTO = -250.0
const FRAMES_GRACIA_ATERRIZAJE := 3

@export_group("Nodos Principales")
@export var rotador: Node2D
@export var anim: AnimatedSprite2D

@export_group("Efectos Visuales")
@export var shader_danio: ShaderMaterial
@export var shader_curacion: ShaderMaterial 

@export_group("Audios Dinámicos")
@export var sfx_ataque: AudioStream
@export var sfx_escudo: AudioStream
@export var sfx_danio: AudioStream
@export var sfx_esencia: AudioStream
@export var sfx_llave: AudioStream
@export var sfx_bloqueado: AudioStream
@export var sfx_desbloqueo: AudioStream

@export_group("Hitboxes de Acción")
@export var hitbox_espada: Area2D
@export var hitbox_escudo: Area2D

@export_group("Áreas de Daño")
@export var area_abajo: Area2D
@export var area_arriba: Area2D
@export var area_izquierda: Area2D
@export var area_derecha: Area2D

@export_group("Estadísticas (Max 10)")
@export_range(1, 10) var constitucion: int = 1
@export_range(1, 10) var resistencia: int = 1
@export_range(1, 10) var fuerza: int = 1
@export_range(1, 10) var agilidad: int = 1
@export_range(1, 10) var percepcion: int = 1
@export_range(1, 10) var inteligencia: int = 1
@export_range(1, 10) var suerte: int = 1
@export_range(1, 10) var carisma: int = 1

@export_group("Banners de Interacción")
@export var banner_lampara: Texture2D
@export var banner_herrero: Texture2D
@export var banner_bloqueado: Texture2D
@export var banner_desbloquear: Texture2D

@export var banner: Sprite2D

var hp_maximo: int
var hp_actual: int
var mod_gravedad := 0.5 
var estado_atacando := false 
var estado_herido := false
var estado_muerto := false
var estado_aterrizando := false 
var fuerza_empuje := Vector2.ZERO 
var en_zona_escalera := false
var estado_escalando := false
var _contador_escaleras := 0
var interactivo_cercano: Node2D = null

var esquirlas_alma: int = 0
var llaves: int = 0

var _atravesando_plataforma := false
var _pos_y_caida_inicio := 0.0

var usos_escudo: int = 3
var tiempo_recarga_escudo: float = 0.0
var estado_bloqueando_impacto := false
var _tiempo_bloqueo_impacto := 0.0

var estado_curando := false
var tiempo_curacion := 0.0
var _tween_curacion: Tween = null

var estado_transicionando := false
var _anim_ataque_bloqueada := ""
var _tiempo_restante_ataque := 0.0
var _contador_aire := 0

var _tiempo_flote_indicador := 0.0
var _pos_y_base_indicador := 0.0

signal vida_cambiada(hp_actual, hp_maximo)
signal escudo_cambiado(usos_escudo)
signal inventario_cambiado(esquirlas, llaves)

func reproducir_sfx(pista: AudioStream) -> void:
	if pista == null: return
	var sfx_player = AudioStreamPlayer2D.new()
	sfx_player.stream = pista
	add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

func _ready() -> void:
	hp_maximo = 90 + (constitucion * 10)
	hp_actual = hp_maximo
	rotador.scale.x = 1

	if EstadoJuego.poseido:
		anim.sprite_frames = preload("res://Escenas/Combate/enemigo_sprite_frames.tres")

	if EstadoJuego.stats_guardados:
		hp_actual = EstadoJuego.hp_guardado
		usos_escudo = EstadoJuego.usos_escudo_guardado
		llaves = EstadoJuego.llaves_guardadas
		esquirlas_alma = EstadoJuego.esquirlas_guardadas

	if hitbox_espada: hitbox_espada.add_to_group("arma_espada")
	if hitbox_escudo: hitbox_escudo.add_to_group("arma_escudo")
	
	area_abajo.body_entered.connect(_recibir_danio.bind("abajo"))
	area_arriba.body_entered.connect(_recibir_danio.bind("arriba"))
	area_izquierda.body_entered.connect(_recibir_danio.bind("izquierda"))
	area_derecha.body_entered.connect(_recibir_danio.bind("derecha"))
	
	anim.animation_finished.connect(_al_terminar_animacion)
	anim.frame_changed.connect(_al_cambiar_frame) # Conectamos la señal para el sonido de ataque exacto
	
	if banner:
		_pos_y_base_indicador = banner.position.y
		banner.visible = false
	
	call_deferred("_notificar_estado_inicial")

func _notificar_estado_inicial() -> void:
	vida_cambiada.emit(hp_actual, hp_maximo)
	escudo_cambiado.emit(usos_escudo)
	notificar_inventario_hud()

func recolectar_llave() -> void:
	llaves += 1
	reproducir_sfx(sfx_llave)
	notificar_inventario_hud()

func usar_llave() -> bool:
	if llaves > 0:
		llaves -= 1
		reproducir_sfx(sfx_desbloqueo)
		notificar_inventario_hud()
		return true
	else:
		reproducir_sfx(sfx_bloqueado)
		return false

func _physics_process(delta: float) -> void:
	if estado_transicionando:
		move_and_slide()
		if not is_on_floor():
			if anim.animation != "Salto": anim.play("Salto")
			_controlar_frames_salto()
		elif velocity.x != 0:
			if anim.animation != "Correr": anim.play("Correr")
		else:
			if anim.animation != "Idle": anim.play("Idle")
		return

	var estaba_en_el_suelo = is_on_floor()
	var vel_y_previa = velocity.y
	
	if usos_escudo < 3:
		tiempo_recarga_escudo -= delta
		if tiempo_recarga_escudo <= 0.0:
			usos_escudo = 3
			escudo_cambiado.emit(usos_escudo)
	
	if _atravesando_plataforma:
		if global_position.y >= _pos_y_caida_inicio + 16.0:
			set_collision_mask_value(2, true)
			_atravesando_plataforma = false
	
	_manejar_interaccion()
	_manejar_icono_interaccion(delta)
	
	if Input.is_action_pressed("curarse") and is_on_floor() and not estado_muerto and not estado_herido and not esta_bloqueando() and not estado_atacando and not estado_escalando:
		velocity.x = move_toward(velocity.x, 0, VELOCIDAD) 
		
		if not estado_curando:
			estado_curando = true
			tiempo_curacion = 0.0
			_iniciar_efecto_curacion()
			
		tiempo_curacion += delta
		
		if tiempo_curacion >= 3.0:
			hp_actual = min(hp_actual + 20, hp_maximo)
			vida_cambiada.emit(hp_actual, hp_maximo)
			reproducir_sfx(sfx_esencia) 
			
			tiempo_curacion = 0.0
			_iniciar_efecto_curacion()
			
	else:
		if estado_curando:
			estado_curando = false
			tiempo_curacion = 0.0
			_detener_efecto_curacion()
	
	if en_zona_escalera and not estado_atacando:
		if Input.is_action_pressed("arriba") or Input.is_action_pressed("abajo"):
			estado_escalando = true
			
	if estado_escalando:
		var direccion_x = Input.get_axis("izquierda", "derecha")
		var direccion_y = Input.get_axis("arriba", "abajo")
		
		velocity.x = direccion_x * VELOCIDAD
		velocity.y = direccion_y * VELOCIDAD
		
		if direccion_x != 0: rotador.scale.x = 1 if direccion_x < 0 else -1
		if anim.animation != "Salto": anim.play("Salto")
		
		if direccion_x == 0 and direccion_y == 0: anim.pause()
		elif not anim.is_playing(): anim.play()
			
		move_and_slide()
		if is_on_floor() and direccion_y > 0: estado_escalando = false
		if Input.is_action_just_pressed("ui_accept"):
			estado_escalando = false
			velocity.y = SALTO
		return 
	
	_aplicar_gravedad(delta)
	
	if estado_muerto:
		_manejar_muerte(delta)
		return
		
	if estado_bloqueando_impacto:
		_tiempo_bloqueo_impacto -= delta
		if _tiempo_bloqueo_impacto <= 0.0:
			estado_bloqueando_impacto = false
		else:
			velocity.x = move_toward(velocity.x, fuerza_empuje.x, VELOCIDAD)
			if fuerza_empuje.x != 0: fuerza_empuje.x = move_toward(fuerza_empuje.x, 0, 600 * delta)
			move_and_slide()
			if anim.animation != "Bloqueo": anim.play("Bloqueo")
			return 
	
	if not estado_curando:
		_manejar_salto()
	
	var direccion := Input.get_axis("izquierda", "derecha")
	if estado_curando: direccion = 0.0
		
	_manejar_movimiento(direccion, delta)
	move_and_slide()
	
	if is_on_floor():
		_contador_aire = 0
	else:
		_contador_aire += 1
	
	if not estaba_en_el_suelo and is_on_floor():
		if vel_y_previa > 20.0 and not estado_atacando: 
			if not esta_bloqueando():
				estado_aterrizando = true
				velocity.y = 0.0 
				anim.play("Salto")
				anim.frame = 3 
	
	if estado_atacando:
		_tiempo_restante_ataque -= delta
		if _tiempo_restante_ataque <= 0.0:
			_terminar_ataque()
	
	_manejar_animaciones(direccion)

func _iniciar_efecto_curacion() -> void:
	if _tween_curacion:
		_tween_curacion.kill()
		
	if shader_curacion:
		anim.material = shader_curacion
		
	anim.modulate = Color(1.0, 1.0, 1.0)
	
	_tween_curacion = create_tween()
	_tween_curacion.tween_property(anim, "modulate", Color(0.2, 2.5, 0.2), 3.0).set_trans(Tween.TRANS_SINE)

func _detener_efecto_curacion() -> void:
	if _tween_curacion:
		_tween_curacion.kill()
	anim.material = null
	anim.modulate = Color(1.0, 1.0, 1.0)

func _manejar_icono_interaccion(delta: float) -> void:
	if not banner: return
	
	if interactivo_cercano == null:
		banner.visible = false
		return
		
	var ya_abierto = false
	if "esta_bloqueado" in interactivo_cercano and not interactivo_cercano.esta_bloqueado:
		ya_abierto = true
	elif "esta_bloqueada" in interactivo_cercano and not interactivo_cercano.esta_bloqueada:
		ya_abierto = true

	if ya_abierto:
		banner.visible = false
		return

	banner.visible = true
	_tiempo_flote_indicador += delta * 5.0
	banner.position.y = _pos_y_base_indicador + sin(_tiempo_flote_indicador) * 3.0

	var tipo = ""
	if "tipo_interaccion" in interactivo_cercano:
		tipo = interactivo_cercano.tipo_interaccion

	match tipo:
		"cofre", "puerta":
			banner.texture = banner_desbloquear if llaves > 0 else banner_bloqueado
		"herrero":
			banner.texture = banner_herrero
		"lampara":
			banner.texture = banner_lampara
		_:
			banner.texture = null

func recolectar_esquirla(valor_base: int) -> void:
	var bonus = suerte * 0.025
	var multiplicador = 1.0 + bonus
	var valor_final: int = roundi(valor_base * multiplicador)
	
	esquirlas_alma += valor_final
	reproducir_sfx(sfx_esencia)
	notificar_inventario_hud()

func notificar_inventario_hud() -> void:
	inventario_cambiado.emit(esquirlas_alma, llaves)

func _manejar_interaccion() -> void:
	if Input.is_action_just_pressed("interactuar") and interactivo_cercano != null:
		if interactivo_cercano.has_method("desbloquear"):
			interactivo_cercano.desbloquear(self)
		elif interactivo_cercano.has_method("interactuar"):
			interactivo_cercano.interactuar(self)

func esta_bloqueando() -> bool:
	return Input.is_action_pressed("bloqueo") and usos_escudo > 0 and not estado_atacando and not estado_muerto and not estado_escalando and not estado_curando

func recibir_impacto_bloqueo(lado_impacto: String) -> void:
	estado_bloqueando_impacto = true
	_tiempo_bloqueo_impacto = 0.5 
	_terminar_ataque()
	estado_aterrizando = false
	estado_escalando = false
	
	usos_escudo -= 1
	tiempo_recarga_escudo = 5.0
	escudo_cambiado.emit(usos_escudo)
	
	velocity.y = 0 
	
	if lado_impacto == "derecha":
		fuerza_empuje.x = -100.0
	else:
		fuerza_empuje.x = 100.0
		
	anim.play("Bloqueo")
	reproducir_sfx(sfx_escudo)

func agregar_escalera() -> void:
	_contador_escaleras += 1
	en_zona_escalera = true

func quitar_escalera() -> void:
	_contador_escaleras -= 1
	if _contador_escaleras <= 0:
		_contador_escaleras = 0
		en_zona_escalera = false
		if estado_escalando:
			estado_escalando = false
			if velocity.y < 0:
				velocity.y = SALTO * 0.5

func _aplicar_gravedad(delta: float) -> void:
	if not is_on_floor():
		velocity += (get_gravity() * mod_gravedad) * delta

func _manejar_muerte(delta: float) -> void:
	velocity.x = move_toward(velocity.x, fuerza_empuje.x, VELOCIDAD)
	if fuerza_empuje.x != 0:
		fuerza_empuje.x = move_toward(fuerza_empuje.x, 0, 600 * delta)
	move_and_slide() 
	
	if not is_on_floor():
		anim.play("Salto")
		anim.pause()
		anim.frame = 2 
	else:
		if anim.animation != "Muerte": anim.play("Muerte") 

func _manejar_salto() -> void:
	if Input.is_action_just_pressed("abajo") and is_on_floor():
		set_collision_mask_value(2, false) 
		_atravesando_plataforma = true
		_pos_y_caida_inicio = global_position.y
		return
		
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("arriba")) and is_on_floor():
		velocity.y = SALTO
		
	if (Input.is_action_just_released("ui_accept") or Input.is_action_just_released("arriba")) and velocity.y < 0:
		velocity.y *= 0.5 

func _manejar_movimiento(direccion: float, delta: float) -> void:
	if direccion:
		rotador.scale.x = 1 if direccion < 0 else -1
		velocity.x = (direccion * VELOCIDAD) + fuerza_empuje.x
	else:
		velocity.x = move_toward(velocity.x, fuerza_empuje.x, VELOCIDAD)

	if fuerza_empuje.x != 0:
		fuerza_empuje.x = move_toward(fuerza_empuje.x, 0, 600 * delta)

func _manejar_animaciones(direccion: float) -> void:
	var en_el_aire_confirmado = _contador_aire > FRAMES_GRACIA_ATERRIZAJE
	
	if estado_aterrizando and anim.animation != "Salto": estado_aterrizando = false
	if estado_atacando and anim.animation not in ["Ataque", "Ataque Correr"]: _terminar_ataque()
	if estado_atacando and estado_aterrizando: estado_aterrizando = false

	if estado_herido and en_el_aire_confirmado:
		if anim.animation != "Salto": anim.play("Salto") 
		_controlar_frames_salto()
		return
		
	if estado_atacando:
		if anim.animation != _anim_ataque_bloqueada: anim.play(_anim_ataque_bloqueada)
		elif not anim.is_playing(): anim.play()
		return 
		
	if Input.is_action_pressed("ataque"):
		_iniciar_ataque(direccion)
		return
		
	if estado_aterrizando:
		if not anim.is_playing(): anim.play()
		return 
		
	if esta_bloqueando(): anim.play("Escudo Correr" if direccion != 0 else "Escudo")
	elif estado_curando: anim.play("Descanso")
	elif en_el_aire_confirmado:
		if anim.animation != "Salto": anim.play("Salto")
		_controlar_frames_salto()
	elif direccion != 0: anim.play("Correr")
	else: anim.play("Idle")

func _controlar_frames_salto() -> void:
	anim.pause() 
	if velocity.y < SALTO * 0.5: anim.frame = 0 
	elif velocity.y < 0: anim.frame = 1 
	else: anim.frame = 2 

func _iniciar_ataque(direccion: float) -> void:
	estado_atacando = true
	estado_aterrizando = false 
	_anim_ataque_bloqueada = "Ataque Correr" if direccion != 0 else "Ataque"
	anim.play(_anim_ataque_bloqueada)
	_tiempo_restante_ataque = _duracion_animacion(_anim_ataque_bloqueada)

func _duracion_animacion(nombre: String) -> float:
	if anim.sprite_frames == null or not anim.sprite_frames.has_animation(nombre): return 0.3 
	var n_frames := anim.sprite_frames.get_frame_count(nombre)
	var velocidad_anim := anim.sprite_frames.get_animation_speed(nombre)
	if velocidad_anim <= 0.0: velocidad_anim = 1.0
	return (n_frames / velocidad_anim) + 0.05 

func _terminar_ataque() -> void:
	estado_atacando = false
	_anim_ataque_bloqueada = ""

func _al_terminar_animacion() -> void:
	if anim.animation in ["Ataque", "Ataque Correr"]: _terminar_ataque()
	elif anim.animation == "Salto": estado_aterrizando = false 

func _al_cambiar_frame() -> void:
	if anim.animation in ["Ataque", "Ataque Correr"] and anim.frame == 4:
		reproducir_sfx(sfx_ataque)

func _recibir_danio(_body: Node2D, lado_impacto: String) -> void:
	if estado_herido or estado_muerto: return
	
	estado_herido = true 
	_terminar_ataque()
	estado_aterrizando = false 
	estado_escalando = false 
	
	_detener_efecto_curacion()
	estado_curando = false 
	tiempo_curacion = 0.0
	
	var danio_base = 15 
	var reduccion = (resistencia * 5.0) / 100.0
	var danio_recibido = int(danio_base * (1.0 - reduccion))
	
	hp_actual -= danio_recibido
	vida_cambiada.emit(hp_actual, hp_maximo)
	reproducir_sfx(sfx_danio)
	
	if hp_actual <= 0: estado_muerto = true
	
	_iniciar_destello_invulnerabilidad()
	
	match lado_impacto:
		"abajo":
			velocity.y = SALTO
			fuerza_empuje.x = 0
		"arriba":
			velocity.y = SALTO * -0.6
			fuerza_empuje.x = 0
		"izquierda":
			velocity.y = SALTO * 0.6
			fuerza_empuje.x = 200.0
		"derecha":
			velocity.y = SALTO * 0.6
			fuerza_empuje.x = -200.0

func _iniciar_destello_invulnerabilidad() -> void:
	anim.material = shader_danio
	var tween = create_tween()
	tween.set_loops(2) 
	tween.tween_property(anim, "modulate:a", 0.3, 0.25)
	tween.tween_property(anim, "modulate:a", 1.0, 0.25)
	tween.finished.connect(_terminar_estado_herido)

func _terminar_estado_herido() -> void:
	if estado_muerto: return 
	
	anim.material = null	 
	anim.modulate.a = 1.0	 
	estado_herido = false 
	
	if area_abajo.has_overlapping_bodies(): _recibir_danio(area_abajo.get_overlapping_bodies()[0], "abajo")
	elif area_izquierda.has_overlapping_bodies(): _recibir_danio(area_izquierda.get_overlapping_bodies()[0], "izquierda")
	elif area_derecha.has_overlapping_bodies(): _recibir_danio(area_derecha.get_overlapping_bodies()[0], "derecha")
	elif area_arriba.has_overlapping_bodies(): _recibir_danio(area_arriba.get_overlapping_bodies()[0], "arriba")
