extends Control

# Pantalla del profesor para corregir respuestas DESARROLLO que los alumnos
# han entregado en exámenes. Los minijuegos NO pasan por aquí: se autocalifican
# durante el juego.
#
# UX en dos pasos:
#   1) Vista LISTA: card por alumno con el número de respuestas pendientes.
#   2) Doble clic en un alumno → vista DETALLE con todas sus respuestas
#      individuales y la UI para asignar puntos y "Corregir".
#   Cuando un alumno ya no tiene pendientes, volvemos automáticamente al listado.

@onready var lista = $Layout/Scroll/Lista
@onready var vacio = $Layout/Vacio
@onready var btn_volver = $Layout/Header/HBox/BtnVolver
@onready var titulo = $Layout/Header/HBox/Titulo

enum Vista { ALUMNOS, DETALLE }

var _vista: int = Vista.ALUMNOS
# alumno_id (int) → { "nombre": String, "respuestas": Array[Dictionary] }
var _pendientes_por_alumno: Dictionary = {}
var _alumno_actual_id: int = -1

func _ready():
	btn_volver.pressed.connect(_on_volver)
	_cargar_pendientes()

func _cargar_pendientes():
	for hijo in lista.get_children():
		hijo.queue_free()
	vacio.visible = true
	vacio.text = "Cargando..."
	ConexionManager.peticion_get("/respuestas/pendientes-correccion", _on_pendientes_recibidas)

func _on_pendientes_recibidas(data, code):
	_pendientes_por_alumno.clear()
	if code == 204 or (data is Array and data.is_empty()):
		vacio.visible = true
		vacio.text = "No hay respuestas pendientes de corrección"
		return
	if code != 200 or not (data is Array):
		vacio.visible = true
		vacio.text = "Error al cargar pendientes"
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)
		return

	# Agrupar respuestas por alumno. El backend envía nombreReal + apellidos
	# (preferentes) y nombreUsuario como fallback, todo en cada respuesta.
	for r in data:
		var alumno_id = GameManager.id_int(r.get("alumnoId", -1))
		if alumno_id < 0:
			continue
		if not _pendientes_por_alumno.has(alumno_id):
			_pendientes_por_alumno[alumno_id] = {
				"nombre": GameManager.nombre_alumno(r),
				"respuestas": []
			}
		_pendientes_por_alumno[alumno_id]["respuestas"].append(r)

	_mostrar_vista_alumnos()

# =====================================================================
# VISTA 1 — listado de alumnos con pendientes
# =====================================================================

func _mostrar_vista_alumnos():
	_vista = Vista.ALUMNOS
	_alumno_actual_id = -1
	titulo.text = "Correcciones Pendientes"
	btn_volver.text = "Volver"
	for hijo in lista.get_children():
		hijo.queue_free()
	if _pendientes_por_alumno.is_empty():
		vacio.visible = true
		vacio.text = "No hay respuestas pendientes de corrección"
		return
	vacio.visible = false
	# Orden alfabético por nombre.
	var ordenados: Array = _pendientes_por_alumno.keys()
	ordenados.sort_custom(func(a, b): return str(_pendientes_por_alumno[a]["nombre"]) < str(_pendientes_por_alumno[b]["nombre"]))
	for alumno_id in ordenados:
		lista.add_child(_crear_card_alumno(alumno_id))

func _crear_card_alumno(alumno_id: int) -> Control:
	var info = _pendientes_por_alumno[alumno_id]
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 70)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = "Doble clic para ver respuestas pendientes"
	panel.gui_input.connect(_on_card_alumno_input.bind(alumno_id))

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)

	var lbl_nombre = Label.new()
	lbl_nombre.text = str(info["nombre"])
	lbl_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_nombre.add_theme_color_override("font_color", Color(0.92, 0.94, 1, 1))
	lbl_nombre.add_theme_font_size_override("font_size", 16)
	lbl_nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl_nombre)

	var n = int(info["respuestas"].size())
	var lbl_count = Label.new()
	lbl_count.text = "%d pendiente%s" % [n, "" if n == 1 else "s"]
	lbl_count.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
	lbl_count.add_theme_font_size_override("font_size", 14)
	lbl_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl_count)

	return panel

func _on_card_alumno_input(event: InputEvent, alumno_id: int):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			_mostrar_vista_detalle(alumno_id)

# =====================================================================
# VISTA 2 — respuestas pendientes de un alumno
# =====================================================================

func _mostrar_vista_detalle(alumno_id: int):
	if not _pendientes_por_alumno.has(alumno_id):
		return
	_vista = Vista.DETALLE
	_alumno_actual_id = alumno_id
	var info = _pendientes_por_alumno[alumno_id]
	titulo.text = "Pendientes · %s" % str(info["nombre"])
	btn_volver.text = "< Volver al listado"
	for hijo in lista.get_children():
		hijo.queue_free()
	vacio.visible = false
	for r in info["respuestas"]:
		lista.add_child(_crear_tarjeta_respuesta(r))

func _crear_tarjeta_respuesta(r: Dictionary) -> Control:
	var panel = PanelContainer.new()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Cabecera: título de la prueba (si lo conocemos) + valor en puntos.
	var titulo_prueba = str(r.get("tituloPrueba", "")).strip_edges()
	var max_puntos = int(r.get("valorPuntosPregunta", 0))
	var lbl_meta = Label.new()
	if titulo_prueba.is_empty():
		lbl_meta.text = "Pregunta %s" % str(r.get("preguntaId", "?"))
	else:
		lbl_meta.text = titulo_prueba
	if max_puntos > 0:
		lbl_meta.text += "  ·  vale %d pts" % max_puntos
	lbl_meta.add_theme_color_override("font_color", Color(0.6, 0.8, 1, 1))
	lbl_meta.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_meta)

	# Enunciado de la pregunta (si lo trae el backend).
	var enunciado = str(r.get("enunciadoPregunta", "")).strip_edges()
	if not enunciado.is_empty():
		var lbl_enun = Label.new()
		lbl_enun.text = enunciado
		lbl_enun.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_enun.add_theme_color_override("font_color", Color(0.85, 0.9, 1, 1))
		lbl_enun.add_theme_font_size_override("font_size", 14)
		vbox.add_child(lbl_enun)

	# Texto de la respuesta del alumno.
	var lbl_texto = Label.new()
	lbl_texto.text = str(r.get("textoRespuesta", "(sin texto)"))
	lbl_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_texto.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1))
	vbox.add_child(lbl_texto)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	var lbl_puntos = Label.new()
	lbl_puntos.text = "Puntos:"
	hbox.add_child(lbl_puntos)

	# El máximo del spin se ajusta al valor de la pregunta; si no nos llega,
	# caemos a 100 como antes.
	var spin = SpinBox.new()
	spin.min_value = 0
	spin.max_value = max_puntos if max_puntos > 0 else 100
	spin.value = 0
	spin.custom_minimum_size = Vector2(120, 30)
	hbox.add_child(spin)

	var btn = Button.new()
	btn.text = "Corregir"
	btn.custom_minimum_size = Vector2(110, 30)
	var resp_id = GameManager.id_int(r.get("id"))
	btn.pressed.connect(func(): _corregir(resp_id, int(spin.value), panel))
	hbox.add_child(btn)

	return panel

# =====================================================================
# CORRECCIÓN
# =====================================================================

func _corregir(resp_id: int, puntos: int, tarjeta: Node):
	if resp_id < 0:
		Notificador.notificar("Respuesta sin id válido", Color.RED)
		return
	ConexionManager.peticion_post(
		"/respuestas/%s/corregir" % GameManager.id_str(resp_id),
		{"puntos": puntos},
		_on_correccion_enviada.bind(puntos, tarjeta, resp_id)
	)

func _on_correccion_enviada(data, code, puntos: int, tarjeta: Node, resp_id: int):
	# Callable.bind añade los args bindeados AL FINAL: ConexionManager llama
	# (data, code) y luego van puntos, tarjeta, resp_id.
	if not (code == 200 or code == 201):
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)
		return
	Notificador.notificar("Corregida con %d puntos" % puntos, Color.GREEN)
	if is_instance_valid(tarjeta):
		tarjeta.queue_free()
	# Actualizamos el modelo en memoria para reflejar la corrección.
	if _alumno_actual_id >= 0 and _pendientes_por_alumno.has(_alumno_actual_id):
		var resps: Array = _pendientes_por_alumno[_alumno_actual_id]["respuestas"]
		for i in range(resps.size()):
			if GameManager.id_int(resps[i].get("id", -1)) == resp_id:
				resps.remove_at(i)
				break
		if resps.is_empty():
			# Ya no quedan pendientes de este alumno → volvemos al listado.
			_pendientes_por_alumno.erase(_alumno_actual_id)
			await get_tree().create_timer(0.6).timeout
			if is_inside_tree():
				_mostrar_vista_alumnos()

func _on_volver():
	# En vista DETALLE, "Volver" regresa al listado de alumnos; solo desde la
	# vista de alumnos saltamos al dashboard.
	if _vista == Vista.DETALLE:
		_mostrar_vista_alumnos()
		return
	get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
