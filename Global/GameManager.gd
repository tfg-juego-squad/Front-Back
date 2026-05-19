extends Node

var usuario_actual: Dictionary = {}
var es_profesor: bool = false
var aula_seleccionada_id: String = ""
var token: String = ""

# Prueba seleccionada por el alumno para jugar el minijuego: la guardamos
# aquí para no tener que reabrir la lista al cambiar de escena.
var minijuego_pendiente: Dictionary = {}

# Prueba tipo=DIALOGO que el alumno acaba de abrir; la lee
# Pantallas/pantalla_dialogo.gd al cargar para mostrar su texto.
var dialogo_pendiente: Dictionary = {}

var _cerrando_sesion: bool = false

# Posición del jugador en el mundo. Se guarda antes de cambiar a otra pantalla
# (NPC, pruebas, dialogo, minijuego) para volver al mismo sitio en el mapa.
var posicion_jugador: Vector2 = Vector2.ZERO
var posicion_jugador_guardada: bool = false

# Guarda la posición global del nodo "User-PJ" de la escena actual (si existe).
func guardar_posicion_jugador():
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var pj = tree.current_scene.get_node_or_null("User-PJ")
	if pj == null:
		return
	posicion_jugador = pj.global_position
	posicion_jugador_guardada = true

# Restaura la posición sobre el nodo "User-PJ" de la escena actual si hay una
# guardada. Devuelve true si efectivamente colocó al jugador.
func restaurar_posicion_jugador() -> bool:
	if not posicion_jugador_guardada:
		return false
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return false
	var pj = tree.current_scene.get_node_or_null("User-PJ")
	if pj == null:
		return false
	pj.global_position = posicion_jugador
	return true

func guardar_sesion(datos: Dictionary):
	usuario_actual = datos
	es_profesor = false
	token = datos.get("token", "")
	_cerrando_sesion = false

	# Opción 1: El backend envía un campo "rol" (String) - Caso actual del backend Java
	if datos.get("rol") == "ROL_PROFESOR":
		es_profesor = true
		return

	# Opción 2: El backend envía una lista de objetos "roles" (Caso antiguo o alternativo)
	for rol_obj in datos.get("roles", []):
		if typeof(rol_obj) == TYPE_DICTIONARY:
			if rol_obj.get("nombre") == "ROL_PROFESOR":
				es_profesor = true
				break
		elif typeof(rol_obj) == TYPE_STRING:
			if rol_obj == "ROL_PROFESOR":
				es_profesor = true
				break

func cerrar_sesion(motivo: String = ""):
	if _cerrando_sesion:
		return
	_cerrando_sesion = true
	usuario_actual = {}
	es_profesor = false
	aula_seleccionada_id = ""
	token = ""
	if not motivo.is_empty():
		Notificador.notificar(motivo, Color.MAGENTA)
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		tree.change_scene_to_file("res://Pantallas/login.tscn")

# Convierte un valor numérico (float, int o string) a su representación entera
# como String. Necesario porque el JSON de Godot parsea números como float
# y "1.0" rompería los path params del backend.
func id_str(valor) -> String:
	if valor == null:
		return ""
	if typeof(valor) == TYPE_STRING:
		if valor.is_empty():
			return ""
		return str(int(float(valor)))
	return str(int(valor))

func id_int(valor) -> int:
	if valor == null:
		return -1
	if typeof(valor) == TYPE_STRING:
		if valor.is_empty():
			return -1
		return int(float(valor))
	return int(valor)

# Devuelve el nombre legible de un alumno a partir de un dict con cualquier
# combinación de nombreReal/apellidos/nombreUsuario/alumnoId. Pensado para que
# el profesor vea "Juan García" en lugar de "alumno_aula1_3".
func nombre_alumno(data: Dictionary) -> String:
	var nombre := str(data.get("nombreReal", "")).strip_edges()
	var apellidos := str(data.get("apellidos", "")).strip_edges()
	var completo := (nombre + " " + apellidos).strip_edges()
	if not completo.is_empty():
		return completo
	var usuario := str(data.get("nombreUsuario", "")).strip_edges()
	if not usuario.is_empty():
		return usuario
	var alumno_id = data.get("alumnoId", data.get("id", -1))
	var aid := id_int(alumno_id)
	if aid >= 0:
		return "Alumno %d" % aid
	return "Alumno"

# Aplica los datos devueltos por /puntuacion/alta sobre el usuario_actual
# y devuelve true si el alumno ha subido de nivel.
func aplicar_recompensa(data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var nivel_raw = usuario_actual.get("nivelActual")
	var nivel_anterior = 0 if nivel_raw == null else int(float(str(nivel_raw)))
	if data.has("nivelActual") and data["nivelActual"] != null:
		usuario_actual["nivelActual"] = int(float(str(data["nivelActual"])))
	if data.has("experienciaActual") and data["experienciaActual"] != null:
		usuario_actual["experienciaActual"] = int(float(str(data["experienciaActual"])))
	var nivel_nuevo_raw = usuario_actual.get("nivelActual")
	var nivel_nuevo = nivel_anterior if nivel_nuevo_raw == null else int(float(str(nivel_nuevo_raw)))
	return nivel_nuevo > nivel_anterior
