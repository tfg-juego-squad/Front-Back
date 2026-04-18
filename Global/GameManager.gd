extends Node

var usuario_actual: Dictionary = {}
var es_profesor: bool = false

func guardar_sesion(datos: Dictionary):
	usuario_actual = datos
	es_profesor = false
	for rol in datos.get("roles", []):
		if rol.get("nombre") == "ROL_PROFESOR":
			es_profesor = true
			break
