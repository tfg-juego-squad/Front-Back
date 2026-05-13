extends CharacterBody2D

# id del NPC dentro del catálogo (NpcManager.NPCS). Cámbialo en el inspector
# en cada NPC del nivel para que muestre solo las pruebas que le tocan.
@export var npc_id: String = "npc_general"

@onready var area_interaccion = $Area2D
var en_zona: bool = false

# Los NPCs cuyo id empiece por "npc_dialogo" muestran el texto asignado
# automáticamente al acercarse (sin pulsar nada).
var _es_npc_dialogo: bool = false
var _prueba_dialogo: Dictionary = {}
var _bubble: Label = null
var _ya_marcado_completado: bool = false

func _ready():
	area_interaccion.body_entered.connect(_on_body_entered)
	area_interaccion.body_exited.connect(_on_body_exited)
	_es_npc_dialogo = npc_id.begins_with("npc_dialogo")
	_crear_bubble()
	if _es_npc_dialogo and not GameManager.es_profesor:
		_precargar_dialogo()

func _crear_bubble():
	_bubble = Label.new()
	_bubble.visible = false
	# Centrado encima del NPC, anchura fija para que rompa por palabras.
	_bubble.position = Vector2(-110, -80)
	_bubble.custom_minimum_size = Vector2(220, 0)
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_bubble.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_bubble.add_theme_constant_override("outline_size", 4)
	_bubble.add_theme_font_size_override("font_size", 10)
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_bubble)

func _precargar_dialogo():
	var alumno_id = GameManager.id_str(GameManager.usuario_actual.get("id"))
	if alumno_id.is_empty():
		return
	ConexionManager.peticion_get("/pruebas/pendientes/%s" % alumno_id, _on_pendientes_recibidas)

func _on_pendientes_recibidas(data, code):
	if code != 200 or not (data is Array):
		return
	var nivel_alumno_raw = GameManager.usuario_actual.get("nivelActual")
	var nivel_alumno = 1 if nivel_alumno_raw == null else int(nivel_alumno_raw)
	for p in data:
		var tipo = str(p.get("tipo", "")).to_upper()
		if tipo != "DIALOGO":
			continue
		var asignado = str(p.get("npcId", ""))
		# El backend devuelve "null" como string en algunos casos.
		if asignado == "null" or asignado == "<null>":
			asignado = ""
		if not asignado.is_empty() and asignado != npc_id:
			continue
		# Respetar el nivel mínimo: si el alumno no llega, el NPC no le
		# muestra el diálogo (como bloquear un examen).
		var nivel_min = int(p.get("nivelMinimo", 1))
		if nivel_min > nivel_alumno:
			continue
		_prueba_dialogo = p
		return

func _on_body_entered(body):
	if body.name != "User-PJ":
		return
	en_zona = true
	if _es_npc_dialogo:
		_mostrar_dialogo_automatico()
		return
	var npc = NpcManager.buscar_npc(npc_id)
	var saludo = "Presiona [E] o [ENTER] para hablar"
	if not npc.is_empty():
		saludo = "%s · Pulsa [E] para hablar" % npc.get("nombre", "NPC")
	Notificador.notificar(saludo, Color.CYAN)

func _on_body_exited(body):
	if body.name != "User-PJ":
		return
	en_zona = false
	if _bubble:
		_bubble.visible = false

func _mostrar_dialogo_automatico():
	if _prueba_dialogo.is_empty():
		# Sin diálogo asignado: no mostramos nada para no llenar de globos vacíos.
		return
	var texto = str(_prueba_dialogo.get("texto", "")).strip_edges()
	if texto.is_empty():
		return
	_bubble.text = texto
	_bubble.visible = true
	# Una vez visto, lo damos por completado para que no salga como pendiente.
	if not _ya_marcado_completado:
		_ya_marcado_completado = true
		var prueba_id = GameManager.id_int(_prueba_dialogo.get("id"))
		if prueba_id >= 0:
			ConexionManager.peticion_post(
				"/puntuacion/alta",
				{"idPrueba": prueba_id},
				func(_d, _c): pass
			)

func _input(event):
	if not en_zona:
		return
	# Los NPCs de diálogo no responden a teclas: el texto sale solo al acercarse.
	if _es_npc_dialogo:
		return
	if event.is_echo() or not event.is_pressed():
		return
	var es_tecla_e = event is InputEventKey and event.physical_keycode == KEY_E
	if not (event.is_action_pressed("ui_accept") or es_tecla_e):
		return

	if GameManager.es_profesor:
		Notificador.notificar("Los profesores gestionan las pruebas desde el dashboard", Color.ORANGE)
		return

	NpcManager.set_npc_activo(npc_id)
	GameManager.guardar_posicion_jugador()
	Notificador.notificar("Abriendo pruebas pendientes...", Color.GOLD)
	get_tree().change_scene_to_file("res://Pantallas/pruebas_pendientes.tscn")
