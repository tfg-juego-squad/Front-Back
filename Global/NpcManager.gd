extends Node

# Catálogo de NPCs disponibles en el mundo. Cada NPC representa un punto
# donde los alumnos pueden recibir pruebas (típicamente por materia).
#
# Mientras el backend no tenga campo `npcId`, la asignación se persiste
# localmente en el cliente del profesor y se envía en el payload para que
# el backend pueda guardarlo cuando lo soporte.

const NPCS = [
	{"id": "npc_actividades", "nombre": "NPC Actividades", "materia": "Actividades",   "color": Color(0.4, 0.95, 0.6)},
	{"id": "npc_examen1",     "nombre": "NPC Examen A",    "materia": "Exámenes",      "color": Color(1, 0.7, 0.3)},
	{"id": "npc_examen2",     "nombre": "NPC Examen B",    "materia": "Exámenes",      "color": Color(1, 0.55, 0.25)},
	{"id": "npc_examen3",     "nombre": "NPC Examen C",    "materia": "Exámenes",      "color": Color(1, 0.45, 0.15)},
	{"id": "npc_dialogo1",    "nombre": "NPC Diálogo Norte", "materia": "Diálogo",    "color": Color(0.6, 0.75, 1)},
	{"id": "npc_dialogo2",    "nombre": "NPC Diálogo Sur",   "materia": "Diálogo",    "color": Color(0.55, 0.65, 0.95)},
]

const RUTA_ASIGNACIONES := "user://npc_asignaciones.json"

var _asignaciones: Dictionary = {}    # prueba_id (String) -> npc_id (String)
var _npc_activo: String = ""           # se llena cuando el alumno habla con un NPC

func _ready():
	_cargar_asignaciones()

func get_npcs() -> Array:
	return NPCS

func buscar_npc(npc_id: String) -> Dictionary:
	for npc in NPCS:
		if npc["id"] == npc_id:
			return npc
	return {}

# --- Asignación de pruebas a NPCs (persistencia local) ---

func asignar_prueba(prueba_id, npc_id: String):
	if prueba_id == null or npc_id.is_empty():
		return
	_asignaciones[str(prueba_id)] = npc_id
	_guardar_asignaciones()

func npc_de_prueba(prueba_id) -> String:
	if prueba_id == null:
		return ""
	return _asignaciones.get(str(prueba_id), "")

func _cargar_asignaciones():
	if not FileAccess.file_exists(RUTA_ASIGNACIONES):
		_asignaciones = {}
		return
	var f = FileAccess.open(RUTA_ASIGNACIONES, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) == TYPE_DICTIONARY:
		_asignaciones = data

func _guardar_asignaciones():
	var f = FileAccess.open(RUTA_ASIGNACIONES, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_asignaciones))
	f.close()

# --- NPC activo (qué NPC ha abierto el alumno) ---

func set_npc_activo(npc_id: String):
	_npc_activo = npc_id

func get_npc_activo() -> String:
	return _npc_activo

func reset_npc_activo():
	_npc_activo = ""
