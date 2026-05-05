extends Node

var usuario_actual: Dictionary = {}
var es_profesor: bool = false
var aula_seleccionada_id: String = ""

func guardar_sesion(datos: Dictionary):
	usuario_actual = datos
	es_profesor = false
	
	if datos.get("rol") == "ROL_PROFESOR":
		es_profesor = true
		return
	
	# Fallback por si el backend devuelve roles como array
	for rol_obj in datos.get("roles", []):
		if typeof(rol_obj) == TYPE_DICTIONARY:
			if rol_obj.get("nombre") == "ROL_PROFESOR":
				es_profesor = true
				break
		elif typeof(rol_obj) == TYPE_STRING:
			if rol_obj == "ROL_PROFESOR":
				es_profesor = true
				break
