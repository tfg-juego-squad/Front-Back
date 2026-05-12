extends Control

@onready var lista = $Layout/Scroll/Lista
@onready var vacio = $Layout/Vacio
@onready var btn_volver = $Layout/Header/HBox/BtnVolver

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
	if code == 204 or (data is Array and data.is_empty()):
		vacio.text = "No hay respuestas pendientes de corrección"
		return
	if code != 200 or not (data is Array):
		vacio.text = "Error al cargar pendientes"
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)
		return

	vacio.visible = false
	for r in data:
		_crear_tarjeta(r)

func _crear_tarjeta(r: Dictionary):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 130)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var lbl_meta = Label.new()
	lbl_meta.text = "Alumno %s · Pregunta %s" % [str(r.get("alumnoId", "?")), str(r.get("preguntaId", "?"))]
	lbl_meta.add_theme_color_override("font_color", Color(0.6, 0.8, 1, 1))
	lbl_meta.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_meta)

	var lbl_texto = Label.new()
	lbl_texto.text = str(r.get("textoRespuesta", "(sin texto)"))
	lbl_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_texto)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	var lbl_puntos = Label.new()
	lbl_puntos.text = "Puntos:"
	hbox.add_child(lbl_puntos)

	var spin = SpinBox.new()
	spin.min_value = 0
	spin.max_value = 100
	spin.value = 0
	spin.custom_minimum_size = Vector2(120, 30)
	hbox.add_child(spin)

	var btn = Button.new()
	btn.text = "Corregir"
	btn.custom_minimum_size = Vector2(110, 30)
	var resp_id = GameManager.id_int(r.get("id"))
	btn.pressed.connect(func(): _corregir(resp_id, int(spin.value), panel))
	hbox.add_child(btn)

	lista.add_child(panel)

func _corregir(resp_id: int, puntos: int, tarjeta: Node):
	if resp_id < 0:
		Notificador.notificar("Respuesta sin id válido", Color.RED)
		return
	ConexionManager.peticion_post(
		"/respuestas/%s/corregir" % GameManager.id_str(resp_id),
		{"puntos": puntos},
		_on_correccion_enviada.bind(puntos, tarjeta)
	)

func _on_correccion_enviada(puntos: int, tarjeta: Node, data, code):
	if code == 200 or code == 201:
		Notificador.notificar("Corregida con %d puntos" % puntos, Color.GREEN)
		tarjeta.queue_free()
		if lista.get_child_count() == 0:
			vacio.visible = true
			vacio.text = "No hay respuestas pendientes de corrección"
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

func _on_volver():
	get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
