extends Control

@onready var btn_volver = $Layout/Header/HBoxHeader/BtnVolver
@onready var btn_guardar_global = $Layout/Centro/PanelContenedor/VBoxTabs/HBoxFinal/BtnGuardarGlobal

@onready var nombre_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/NombreInput
@onready var descripcion_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/DescripcionInput
@onready var btn_adjunto = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxAdjunto/BtnAdjunto
@onready var nombre_adjunto = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxAdjunto/NombreAdjunto

@onready var btn_descargar_plantilla = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/HBoxPlantillas/BtnDescargarPlantilla
@onready var btn_subir_plantilla = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/HBoxPlantillas/BtnSubirPlantilla
@onready var fecha_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/GridFechas/FechaInput
@onready var hora_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/GridFechas/HoraInput
@onready var check_sin_tiempo = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/HBoxGlobalTime/CheckSinTiempo
@onready var tiempo_global_spin = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/HBoxGlobalTime/TiempoGlobalSpin
@onready var lista_preguntas = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/ListaPreguntas
@onready var btn_add_pregunta = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/BtnAddPregunta
@onready var btn_preview = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/BtnPreview

const TIPO_TEST = "TEST"
const TIPO_DESARROLLO = "DESARROLLO"

var contador_preguntas := 0
var _preguntas_payload: Array = []
var _prueba_id_actual: int = -1

func _ready():
	btn_volver.pressed.connect(_on_volver)
	btn_guardar_global.pressed.connect(_on_guardar)
	btn_adjunto.pressed.connect(_on_btn_adjunto)
	btn_descargar_plantilla.pressed.connect(_on_descargar_plantilla)
	btn_subir_plantilla.pressed.connect(_on_subir_plantilla)
	check_sin_tiempo.toggled.connect(func(on): tiempo_global_spin.editable = not on)
	btn_add_pregunta.pressed.connect(_on_add_pregunta)
	btn_preview.pressed.connect(_on_preview)
	_on_add_pregunta()

func _on_add_pregunta():
	contador_preguntas += 1

	var panel = PanelContainer.new()
	panel.set_meta("es_pregunta", true)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var lbl = Label.new()
	lbl.text = "Pregunta #" + str(contador_preguntas)
	lbl.add_theme_color_override("font_color", Color.AQUAMARINE)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl)

	var opt_tipo = OptionButton.new()
	opt_tipo.name = "TipoPregunta"
	opt_tipo.add_item(TIPO_DESARROLLO)
	opt_tipo.add_item(TIPO_TEST)
	opt_tipo.selected = 0
	header.add_child(opt_tipo)

	var btn_del = Button.new()
	btn_del.text = "X"
	btn_del.custom_minimum_size = Vector2(36, 0)
	btn_del.pressed.connect(func(): panel.queue_free())
	header.add_child(btn_del)

	var enunciado = TextEdit.new()
	enunciado.name = "Enunciado"
	enunciado.placeholder_text = "Escribe el enunciado..."
	enunciado.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(enunciado)

	var bloque_test = VBoxContainer.new()
	bloque_test.name = "BloqueTest"
	bloque_test.visible = false
	bloque_test.add_theme_constant_override("separation", 6)
	vbox.add_child(bloque_test)

	var lbl_resp = Label.new()
	lbl_resp.text = "Respuestas posibles (marca las correctas):"
	lbl_resp.add_theme_color_override("font_color", Color(0.7, 0.85, 1, 1))
	lbl_resp.add_theme_font_size_override("font_size", 12)
	bloque_test.add_child(lbl_resp)

	var lista_respuestas = VBoxContainer.new()
	lista_respuestas.name = "ListaRespuestas"
	lista_respuestas.add_theme_constant_override("separation", 4)
	bloque_test.add_child(lista_respuestas)

	var btn_add_resp = Button.new()
	btn_add_resp.text = "+ Añadir respuesta"
	btn_add_resp.pressed.connect(func(): _add_respuesta(lista_respuestas))
	bloque_test.add_child(btn_add_resp)

	opt_tipo.item_selected.connect(_on_tipo_pregunta_seleccionado.bind(opt_tipo, bloque_test, lista_respuestas))

	lista_preguntas.add_child(panel)

func _on_tipo_pregunta_seleccionado(opt: OptionButton, bloque_test: VBoxContainer, lista_respuestas: VBoxContainer, idx: int):
	var es_test = opt.get_item_text(idx) == TIPO_TEST
	bloque_test.visible = es_test
	if es_test and lista_respuestas.get_child_count() == 0:
		_add_respuesta(lista_respuestas)
		_add_respuesta(lista_respuestas)

func _add_respuesta(contenedor: VBoxContainer):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	var check = CheckBox.new()
	check.name = "EsCorrecta"
	hbox.add_child(check)

	var input = LineEdit.new()
	input.name = "TextoRespuesta"
	input.placeholder_text = "Texto de la respuesta"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(input)

	var btn_quitar = Button.new()
	btn_quitar.text = "−"
	btn_quitar.custom_minimum_size = Vector2(28, 0)
	btn_quitar.pressed.connect(func(): hbox.queue_free())
	hbox.add_child(btn_quitar)

	contenedor.add_child(hbox)

# TODO: Sin endpoint de subida de archivos en el backend
func _on_btn_adjunto():
	nombre_adjunto.text = "Archivo seleccionado: proyecto.zip"
	Notificador.notificar("Adjunto vinculado", Color.CYAN)

# TODO: Sin endpoint de plantillas en el backend
func _on_descargar_plantilla():
	Notificador.notificar("Descargando plantilla...", Color.CYAN)

func _on_subir_plantilla():
	Notificador.notificar("Formulario importado", Color.CYAN)

func _on_preview():
	Notificador.notificar("Abriendo vista previa...", Color.GOLD)

func _on_guardar():
	if nombre_input.text.strip_edges().is_empty():
		Notificador.notificar("El titulo es obligatorio", Color.MAGENTA)
		return
	if GameManager.aula_seleccionada_id.is_empty():
		Notificador.notificar("No hay aula seleccionada, vuelve al Dashboard", Color.MAGENTA)
		return

	_preguntas_payload = _recoger_preguntas()
	if _preguntas_payload.is_empty():
		Notificador.notificar("Añade al menos una pregunta", Color.ORANGE)
		return

	for i in range(_preguntas_payload.size()):
		var pq = _preguntas_payload[i]
		if pq["tipo"] == TIPO_TEST:
			if pq["respuestasPosibles"].is_empty():
				Notificador.notificar("Pregunta %d (TEST) sin respuestas" % (i + 1), Color.ORANGE)
				return
			var hay_correcta = false
			for r in pq["respuestasPosibles"]:
				if r["esCorrecta"]:
					hay_correcta = true
					break
			if not hay_correcta:
				Notificador.notificar("Pregunta %d (TEST) sin respuesta correcta" % (i + 1), Color.ORANGE)
				return

	var payload = {
		"aulaId": int(GameManager.aula_seleccionada_id),
		"titulo": nombre_input.text.strip_edges(),
		"fechaLimite": _construir_fecha_limite(),
		"puntuacionMaxima": _preguntas_payload.size()
	}

	Notificador.notificar("Guardando prueba...", Color.CYAN)
	ConexionManager.peticion_post("/pruebas/crear", payload, _on_prueba_guardada)

func _recoger_preguntas() -> Array:
	var out: Array = []
	for panel in lista_preguntas.get_children():
		if not panel.has_meta("es_pregunta"):
			continue
		var margin = panel.get_child(0)
		var vbox = margin.get_child(0)
		var enunciado_node = vbox.get_node_or_null("Enunciado")
		var bloque_test = vbox.get_node_or_null("BloqueTest")
		var tipo_node = vbox.get_node("HBoxContainer") if vbox.has_node("HBoxContainer") else vbox.get_child(0)
		var opt = tipo_node.get_node_or_null("TipoPregunta")
		if enunciado_node == null or opt == null:
			continue
		var enunciado_text = enunciado_node.text.strip_edges()
		if enunciado_text.is_empty():
			continue

		var tipo = opt.get_item_text(opt.selected)
		var respuestas: Array = []
		if tipo == TIPO_TEST and bloque_test:
			var lista_resp = bloque_test.get_node_or_null("ListaRespuestas")
			if lista_resp:
				for fila in lista_resp.get_children():
					var input_texto = fila.get_node_or_null("TextoRespuesta")
					var check = fila.get_node_or_null("EsCorrecta")
					if input_texto and check:
						var t = input_texto.text.strip_edges()
						if not t.is_empty():
							respuestas.append({"texto": t, "esCorrecta": check.button_pressed})

		out.append({
			"enunciado": enunciado_text,
			"tipo": tipo,
			"respuestasPosibles": respuestas
		})
	return out

func _construir_fecha_limite() -> String:
	var fecha = fecha_input.text.strip_edges()
	var hora = hora_input.text.strip_edges()
	if fecha.is_empty():
		# Fallback: 7 días desde ahora en formato ISO 8601 Instant
		return Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()) + 604800) + "Z"
	if hora.is_empty():
		hora = "23:59:00"
	elif hora.length() == 5:
		hora += ":00"
	return "%sT%sZ" % [fecha, hora]

func _on_prueba_guardada(data, code):
	if not (code == 200 or code == 201) or data == null:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)
		return

	_prueba_id_actual = int(data.get("id", -1))
	if _prueba_id_actual < 0:
		Notificador.notificar("Prueba creada pero sin id válido", Color.ORANGE)
		return

	Notificador.notificar("Subiendo preguntas...", Color.CYAN)
	_enviar_siguiente_pregunta()

func _enviar_siguiente_pregunta():
	if _preguntas_payload.is_empty():
		Notificador.notificar("Prueba y preguntas creadas", Color.GREEN)
		await get_tree().create_timer(1.2).timeout
		get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
		return

	var pq = _preguntas_payload.pop_front()
	var payload = {
		"enunciado": pq["enunciado"],
		"tipo": pq["tipo"],
		"pruebaId": _prueba_id_actual,
		"respuestasPosibles": pq["respuestasPosibles"]
	}
	ConexionManager.peticion_post("/preguntas/crear", payload, _on_pregunta_guardada)

func _on_pregunta_guardada(data, code):
	if code == 200 or code == 201:
		_enviar_siguiente_pregunta()
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

func _on_volver():
	get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
