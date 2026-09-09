extends Node

var poseido := false

var reproductor_musica: AudioStreamPlayer

# --- Punto de regreso desde combate ---
var hay_punto_de_regreso := false
var pantalla_regreso: String = ""
var posicion_regreso: Vector2 = Vector2.ZERO

# --- Enemigos ya derrotados (por id), para que reaparezcan muertos ---
var enemigos_derrotados: Array[String] = []
var id_enemigo_en_combate: String = ""

# --- Stats del jugador, para no resetear vida/escudo/inventario al volver ---
var stats_guardados := false
var hp_guardado := 0
var usos_escudo_guardado := 3
var llaves_guardadas := 0
var esquirlas_guardadas := 0

func _ready() -> void:
	reproductor_musica = AudioStreamPlayer.new()
	add_child(reproductor_musica)

# Vive en el Autoload, así que sobrevive a los cambios de escena
# (plataformero <-> combate) en vez de cortarse cada vez.
func reproducir_musica(pista: AudioStream) -> void:
	if pista == null:
		return
	if reproductor_musica.stream == pista and reproductor_musica.playing:
		return
	reproductor_musica.stream = pista
	reproductor_musica.play()

func guardar_punto_de_regreso(pantalla: String, posicion: Vector2) -> void:
	hay_punto_de_regreso = true
	pantalla_regreso = pantalla
	posicion_regreso = posicion

func marcar_enemigo_derrotado(id_enemigo: String) -> void:
	if id_enemigo != "" and not enemigos_derrotados.has(id_enemigo):
		enemigos_derrotados.append(id_enemigo)

func enemigo_esta_derrotado(id_enemigo: String) -> bool:
	return enemigos_derrotados.has(id_enemigo)

func guardar_stats_jugador(hp: int, usos_escudo: int, llaves: int, esquirlas: int) -> void:
	stats_guardados = true
	hp_guardado = hp
	usos_escudo_guardado = usos_escudo
	llaves_guardadas = llaves
	esquirlas_guardadas = esquirlas
