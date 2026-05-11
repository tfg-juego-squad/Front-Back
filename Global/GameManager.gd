extends Node

var usuario_actual: Dictionary = {}
var es_profesor: bool = false
var aula_seleccionada_id: String = ""
var token: String = ""

func guardar_sesion(datos: Dictionary):
	usuario_actual = datos
	es_profesor = false
	token = datos.get("token", "")

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
	usuario_actual = {}
	es_profesor = false
	aula_seleccionada_id = ""
	token = ""
	if not motivo.is_empty():
		Notificador.notificar(motivo, Color.MAGENTA)
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		tree.change_scene_to_file("res://Pantallas/login.tscn")
