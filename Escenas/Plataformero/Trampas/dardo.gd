extends Area2D

const VELOCIDAD = 250.0
var direccion := 1.0 # 1 es derecha, -1 es izquierda por defecto

func _ready() -> void:
	# Conectamos ambas señales. Una detecta tu Area2D (Escudo), otra tu CharacterBody2D (Cuerpo)
	body_entered.connect(_al_chocar_cuerpo)
	area_entered.connect(_al_chocar_area)

func _physics_process(delta: float) -> void:
	# El dardo se mueve constantemente sin gravedad
	position.x += direccion * VELOCIDAD * delta

# --- COLISIÓN CON EL ESCUDO ---
func _al_chocar_area(area: Area2D) -> void:
	if is_queued_for_deletion(): return
	
	if area.is_in_group("arma_escudo"):
		# Obtenemos al jugador (Subiendo la jerarquía: EscudoHitbox -> Rotador -> Jugador)
		var jugador = area.get_parent().get_parent()
		
		if jugador and jugador.has_method("esta_bloqueando") and jugador.esta_bloqueando():
			var lado = "derecha" if direccion < 0 else "izquierda"
			jugador.recibir_impacto_bloqueo(lado)
			queue_free() # Nos destruimos inmediatamente al chocar con el escudo

# --- COLISIÓN CON EL CUERPO ---
func _al_chocar_cuerpo(body: Node2D) -> void:
	if is_queued_for_deletion(): return
	
	if body.name == "Jugador" or body.is_in_group("jugador"):
		# VITAL: Usamos call_deferred para darle 1 frame de ventaja a la función del escudo.
		# Si chocas con ambas hitboxes a la vez, el escudo lo destruirá antes de que esto haga daño.
		call_deferred("_aplicar_danio", body)
	else:
		# Chocó con un muro (StaticBody o TileMap)
		queue_free()

func _aplicar_danio(body: Node2D) -> void:
	# Si el escudo ya nos destruyó en este frame, esta función se cancela sola
	if is_queued_for_deletion(): return 
	
	var lado = "derecha" if direccion < 0 else "izquierda"
	if body.has_method("_recibir_danio"):
		body._recibir_danio(self, lado)
		
	queue_free()
