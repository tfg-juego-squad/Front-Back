extends Node

var usuario_actual: Dictionary = {}
var es_profesor: bool = false
var aula_seleccionada_id: String = ""
var token: String = ""

var _cerrando_sesion: bool = false

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

# Aplica los datos devueltos por /puntuacion/alta sobre el usuario_actual
# y devuelve true si el alumno ha subido de nivel.
func aplicar_recompensa(data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var nivel_anterior = int(usuario_actual.get("nivelActual", 0))
	if data.has("nivelActual"):
		usuario_actual["nivelActual"] = int(data["nivelActual"])
	if data.has("experienciaActual"):
		usuario_actual["experienciaActual"] = int(data["experienciaActual"])
	return int(usuario_actual.get("nivelActual", nivel_anterior)) > nivel_anterior
