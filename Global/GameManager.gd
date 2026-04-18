extends Node

var usuario_actual: Dictionary = {}
var es_profesor: bool = false

func guardar_sesion(datos: Dictionary):
	usuario_actual = datos
	es_profesor = false
	
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
