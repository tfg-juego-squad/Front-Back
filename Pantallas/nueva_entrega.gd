extends Control

@onready var btn_volver = $Layout/Header/HBoxHeader/BtnVolver
@onready var btn_guardar_global = $Layout/Centro/PanelContenedor/VBoxTabs/HBoxFinal/BtnGuardarGlobal

# --- Módulo Actividad ---
@onready var nombre_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/NombreInput
@onready var puntuacion_objetivo_spin = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxPuntuacion/PuntuacionObjetivoSpin
@onready var npc_option = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxNpc/NpcOption
@onready var btn_adjunto = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxAdjunto/BtnAdjunto
@onready var nombre_adjunto = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxAdjunto/NombreAdjunto

# --- Módulo Formulario ---
@onready var btn_descargar_plantilla = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/HBoxPlantillas/BtnDescargarPlantilla
@onready var btn_subir_plantilla = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/HBoxPlantillas/BtnSubirPlantilla
@onready var fecha_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/GridFechas/FechaInput
@onready var hora_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/GridFechas/HoraInput
@onready var check_sin_tiempo = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/HBoxGlobalTime/CheckSinTiempo
@onready var tiempo_global_spin = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/HBoxGlobalTime/TiempoGlobalSpin
@onready var lista_preguntas = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/ListaPreguntas
@onready var btn_add_pregunta = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/BtnAddPregunta
@onready var btn_preview = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/BtnPreview
@onready var lbl_total_puntos = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/LblTotalPuntos

# --- FileDialogs CSV ---
@onready var dialogo_descargar = $DialogoDescargar
@onready var dialogo_subir = $DialogoSubir

# --- Constantes ---
const TIPO_TEST = "TEST"
const TIPO_DESARROLLO = "DESARROLLO"
const COLOR_DEFICIT = Color(1, 0.55, 0.4, 1)
const COLOR_EXCESO = Color(1, 0.4, 0.4, 1)
const COLOR_OK = Color(0.4, 0.95, 0.5, 1)

# Header e ejemplo del CSV plantilla.
const CSV_HEADER = "enunciado,tipo,valorPuntos,respuestas"
const CSV_EJEMPLOS = [
	"\"¿Cuánto es 2+2?\",TEST,10,\"3|0;4|1;5|0;6|0\"",
	"\"¿Cuál es la capital de España?\",TEST,10,\"Madrid|1;Barcelona|0;Sevilla|0;Valencia|0\"",
	"\"Explica con tus palabras el ciclo del agua\",DESARROLLO,20,",
]

signal puntuacion_cambiada

var contador_preguntas := 0
var _preguntas_payload: Array = []
var _prueba_id_actual: int = -1
var _npc_seleccionado: String = ""

func _ready():
	btn_volver.pressed.connect(_on_volver)
	btn_guardar_global.pressed.connect(_on_guardar)
	btn_adjunto.pressed.connect(_on_btn_adjunto)
	btn_descargar_plantilla.pressed.connect(_on_descargar_plantilla)
	btn_subir_plantilla.pressed.connect(_on_subir_plantilla)
	check_sin_tiempo.toggled.connect(func(on): tiempo_global_spin.editable = not on)
	btn_add_pregunta.pressed.connect(func(): _on_add_pregunta())
	btn_preview.pressed.connect(_on_preview)
	puntuacion_objetivo_spin.value_changed.connect(func(_v): _actualizar_total_puntos())
	puntuacion_cambiada.connect(_actualizar_total_puntos)
	dialogo_descargar.file_selected.connect(_on_destino_plantilla_seleccionado)
	dialogo_subir.file_selected.connect(_on_csv_seleccionado)

	_poblar_selector_npc()
	_on_add_pregunta()

func _poblar_selector_npc():
	npc_option.clear()
	for npc in NpcManager.get_npcs():
		npc_option.add_item("%s · %s" % [npc["nombre"], npc["materia"]])
	npc_option.selected = 0

# =====================================================================
# CREACIÓN DINÁMICA DE PREGUNTAS
# =====================================================================

func _on_add_pregunta(initial: Dictionary = {}):
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

	# --- Header con tipo + puntos + borrar ---
	var header = HBoxContainer.new()
	header.name = "HeaderPregunta"
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var lbl = Label.new()
	lbl.text = "Pregunta #" + str(contador_preguntas)
	lbl.add_theme_color_override("font_color", Color.AQUAMARINE)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl)

	var opt_tipo = OptionButton.new()
	opt_tipo.name = "TipoPregunta"
	opt_tipo.add_item(TIPO_TEST)        # index 0 -> TEST por defecto
	opt_tipo.add_item(TIPO_DESARROLLO)  # index 1 -> DESARROLLO
	opt_tipo.selected = 0
	header.add_child(opt_tipo)

	var lbl_puntos = Label.new()
	lbl_puntos.text = "Puntuación máxima:"
	header.add_child(lbl_puntos)

	var spin_puntos = SpinBox.new()
	spin_puntos.name = "ValorPuntos"
	spin_puntos.min_value = 1
	spin_puntos.max_value = 100
	spin_puntos.value = 10
	spin_puntos.custom_minimum_size = Vector2(80, 0)
	spin_puntos.value_changed.connect(func(_v): puntuacion_cambiada.emit())
	header.add_child(spin_puntos)

	var btn_del = Button.new()
	btn_del.text = "X"
	btn_del.custom_minimum_size = Vector2(36, 0)
	btn_del.pressed.connect(func():
		panel.queue_free()
		puntuacion_cambiada.emit()
	)
	header.add_child(btn_del)

	# --- Enunciado ---
	var enunciado = TextEdit.new()
	enunciado.name = "Enunciado"
	enunciado.placeholder_text = "Escribe el enunciado..."
	enunciado.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(enunciado)

	# --- Bloque TEST (visible por defecto porque TEST es default) ---
	var bloque_test = VBoxContainer.new()
	bloque_test.name = "BloqueTest"
	bloque_test.add_theme_constant_override("separation", 6)
	vbox.add_child(bloque_test)

	var hbox_generar = HBoxContainer.new()
	hbox_generar.add_theme_constant_override("separation", 8)
	bloque_test.add_child(hbox_generar)

	var lbl_n = Label.new()
	lbl_n.text = "Nº de opciones:"
	lbl_n.add_theme_color_override("font_color", Color(0.7, 0.85, 1, 1))
	hbox_generar.add_child(lbl_n)

	var spin_n = SpinBox.new()
	spin_n.min_value = 2
	spin_n.max_value = 10
	spin_n.value = 4
	spin_n.custom_minimum_size = Vector2(70, 0)
	hbox_generar.add_child(spin_n)

	var lista_respuestas = VBoxContainer.new()
	lista_respuestas.name = "ListaRespuestas"
	lista_respuestas.add_theme_constant_override("separation", 4)
	var grupo = ButtonGroup.new()
	lista_respuestas.set_meta("grupo_correctas", grupo)
	bloque_test.add_child(lista_respuestas)

	var btn_generar = Button.new()
	btn_generar.text = "Regenerar opciones"
	btn_generar.custom_minimum_size = Vector2(170, 0)
	btn_generar.pressed.connect(func(): _regenerar_opciones(lista_respuestas, int(spin_n.value)))
	hbox_generar.add_child(btn_generar)

	var lbl_pista = Label.new()
	lbl_pista.text = "Marca la respuesta correcta (solo una)"
	lbl_pista.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
	lbl_pista.add_theme_font_size_override("font_size", 11)
	bloque_test.add_child(lbl_pista)

	var btn_add_resp = Button.new()
	btn_add_resp.text = "+ Añadir respuesta extra"
	btn_add_resp.pressed.connect(func(): _add_respuesta(lista_respuestas))
	bloque_test.add_child(btn_add_resp)

	opt_tipo.item_selected.connect(_on_tipo_pregunta_seleccionado.bind(opt_tipo, bloque_test, lista_respuestas, spin_n))

	lista_preguntas.add_child(panel)

	# --- Aplicar datos iniciales (si vienen del CSV) o crear 4 opciones por defecto si es TEST ---
	if not initial.is_empty():
		_aplicar_datos_iniciales(panel, initial)
	else:
		# Default = TEST → generar 4 opciones de partida visibles
		_regenerar_opciones(lista_respuestas, int(spin_n.value))

	puntuacion_cambiada.emit()

func _aplicar_datos_iniciales(panel: Node, data: Dictionary):
	var margin = panel.get_child(0)
	var vbox = margin.get_child(0)
	var header = vbox.get_node("HeaderPregunta")
	var enunciado_node = vbox.get_node("Enunciado")
	var bloque_test = vbox.get_node("BloqueTest")
	var opt_tipo = header.get_node("TipoPregunta")
	var spin_puntos = header.get_node("ValorPuntos")
	var lista_resp = bloque_test.get_node("ListaRespuestas")
	var hbox_generar = bloque_test.get_child(0)
	var spin_n = hbox_generar.get_child(1) as SpinBox

	enunciado_node.text = str(data.get("enunciado", ""))
	if data.has("valorPuntos"):
		spin_puntos.value = int(data["valorPuntos"])
	var tipo = str(data.get("tipo", TIPO_TEST)).to_upper()
	if tipo == TIPO_DESARROLLO:
		opt_tipo.selected = 1
		bloque_test.visible = false
	else:
		opt_tipo.selected = 0
		bloque_test.visible = true
		var respuestas = data.get("respuestasPosibles", [])
		spin_n.value = max(respuestas.size(), 2)
		_regenerar_opciones(lista_resp, respuestas.size())
		# Poblar las opciones
		for i in range(respuestas.size()):
			var fila = lista_resp.get_child(i)
			if fila == null:
				continue
			var texto_input = fila.get_node("TextoRespuesta")
			var check = fila.get_node("EsCorrecta")
			texto_input.text = str(respuestas[i].get("texto", ""))
			check.button_pressed = bool(respuestas[i].get("esCorrecta", false))

func _on_tipo_pregunta_seleccionado(opt: OptionButton, bloque_test: VBoxContainer, lista_respuestas: VBoxContainer, spin_n: SpinBox, idx: int):
	var es_test = opt.get_item_text(idx) == TIPO_TEST
	bloque_test.visible = es_test
	if es_test and lista_respuestas.get_child_count() == 0:
		_regenerar_opciones(lista_respuestas, int(spin_n.value))

func _regenerar_opciones(contenedor: VBoxContainer, cantidad: int):
	for hijo in contenedor.get_children():
		hijo.queue_free()
	for i in range(max(cantidad, 2)):
		_add_respuesta(contenedor)

func _add_respuesta(contenedor: VBoxContainer):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	var check = CheckBox.new()
	check.name = "EsCorrecta"
	check.text = "Correcta"
	if contenedor.has_meta("grupo_correctas"):
		check.button_group = contenedor.get_meta("grupo_correctas")
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

# =====================================================================
# CONTADOR DE PUNTUACIÓN EN TIEMPO REAL
# =====================================================================

func _actualizar_total_puntos():
	var total = 0
	for panel in lista_preguntas.get_children():
		if not panel.has_meta("es_pregunta"):
			continue
		var spin = _get_spin_valor_pregunta(panel)
		if spin:
			total += int(spin.value)
	var objetivo = int(puntuacion_objetivo_spin.value)
	var diferencia = objetivo - total
	if diferencia == 0:
		lbl_total_puntos.text = "Total: %d / %d  ✓" % [total, objetivo]
		lbl_total_puntos.add_theme_color_override("font_color", COLOR_OK)
	elif diferencia > 0:
		lbl_total_puntos.text = "Total: %d / %d  (faltan %d)" % [total, objetivo, diferencia]
		lbl_total_puntos.add_theme_color_override("font_color", COLOR_DEFICIT)
	else:
		lbl_total_puntos.text = "Total: %d / %d  (sobran %d)" % [total, objetivo, -diferencia]
		lbl_total_puntos.add_theme_color_override("font_color", COLOR_EXCESO)

func _get_spin_valor_pregunta(panel: Node) -> SpinBox:
	var margin = panel.get_child(0) if panel.get_child_count() > 0 else null
	var vbox = margin.get_child(0) if margin and margin.get_child_count() > 0 else null
	var header = vbox.get_node_or_null("HeaderPregunta") if vbox else null
	return header.get_node_or_null("ValorPuntos") if header else null

# =====================================================================
# HANDLERS DE ARCHIVO / PLANTILLA
# =====================================================================

func _on_btn_adjunto():
	nombre_adjunto.text = "Archivo seleccionado: proyecto.zip"
	Notificador.notificar("Adjunto vinculado", Color.CYAN)

# --- DESCARGAR PLANTILLA ---

func _on_descargar_plantilla():
	dialogo_descargar.popup_centered_ratio(0.6)

func _on_destino_plantilla_seleccionado(path: String):
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		Notificador.notificar("No se pudo escribir el archivo", Color.RED)
		return
	f.store_line(CSV_HEADER)
	for ejemplo in CSV_EJEMPLOS:
		f.store_line(ejemplo)
	f.close()
	Notificador.notificar("Plantilla guardada en %s" % path.get_file(), Color.GREEN)

# --- IMPORTAR CSV ---

func _on_subir_plantilla():
	dialogo_subir.popup_centered_ratio(0.6)

func _on_csv_seleccionado(path: String):
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		Notificador.notificar("No se pudo abrir el archivo", Color.RED)
		return
	var contenido = f.get_as_text()
	f.close()

	var lineas = contenido.split("\n")
	if lineas.size() < 2:
		Notificador.notificar("El CSV no contiene preguntas", Color.ORANGE)
		return

	# Eliminar las preguntas existentes vacías para no acumular
	_limpiar_preguntas_vacias()

	var num_importadas = 0
	var num_error = 0
	for i in range(1, lineas.size()):    # saltar header
		var linea = lineas[i].strip_edges()
		if linea.is_empty():
			continue
		var celdas = _parse_csv_line(linea)
		if celdas.size() < 3:
			num_error += 1
			continue
		var enunciado = celdas[0].strip_edges()
		var tipo = celdas[1].strip_edges().to_upper()
		var valor = celdas[2].strip_edges().to_int()
		if valor <= 0:
			valor = 10
		var respuestas: Array = []
		if tipo == TIPO_TEST and celdas.size() >= 4:
			respuestas = _parse_respuestas_csv(celdas[3])
		_on_add_pregunta({
			"enunciado": enunciado,
			"tipo": tipo if tipo == TIPO_TEST or tipo == TIPO_DESARROLLO else TIPO_TEST,
			"valorPuntos": valor,
			"respuestasPosibles": respuestas
		})
		num_importadas += 1

	if num_importadas > 0:
		Notificador.notificar("Importadas %d preguntas" % num_importadas, Color.GREEN)
	if num_error > 0:
		Notificador.notificar("%d líneas con formato incorrecto" % num_error, Color.ORANGE)

func _limpiar_preguntas_vacias():
	for panel in lista_preguntas.get_children():
		if not panel.has_meta("es_pregunta"):
			continue
		var margin = panel.get_child(0)
		var vbox = margin.get_child(0)
		var enunciado_node = vbox.get_node_or_null("Enunciado")
		if enunciado_node and enunciado_node.text.strip_edges().is_empty():
			panel.queue_free()

# Parser CSV simple: respeta comillas dobles y permite comas dentro.
func _parse_csv_line(linea: String) -> Array:
	var resultado: Array = []
	var actual = ""
	var en_comillas = false
	var i = 0
	while i < linea.length():
		var c = linea[i]
		if c == "\"":
			# comilla doble dentro de comillas = comilla literal
			if en_comillas and i + 1 < linea.length() and linea[i + 1] == "\"":
				actual += "\""
				i += 2
				continue
			en_comillas = not en_comillas
		elif c == "," and not en_comillas:
			resultado.append(actual)
			actual = ""
		else:
			actual += c
		i += 1
	resultado.append(actual)
	return resultado

# Formato respuestas: "texto1|correcta1;texto2|correcta2;..." donde correcta = 0 ó 1 (o true/false)
func _parse_respuestas_csv(raw: String) -> Array:
	var out: Array = []
	for entrada in raw.split(";"):
		var partes = entrada.split("|")
		if partes.size() < 2:
			continue
		var texto = partes[0].strip_edges()
		if texto.is_empty():
			continue
		var marca = partes[1].strip_edges().to_lower()
		var es_correcta = marca == "1" or marca == "true" or marca == "si" or marca == "sí"
		out.append({"texto": texto, "esCorrecta": es_correcta})
	return out

# =====================================================================
# PREVISUALIZACIÓN
# =====================================================================

func _on_preview():
	var preguntas = _recoger_preguntas()
	if preguntas.is_empty():
		Notificador.notificar("Añade al menos una pregunta antes de previsualizar", Color.ORANGE)
		return
	var escena = load("res://Pantallas/preview_prueba.tscn")
	var instancia = escena.instantiate()
	instancia.cargar_preview(nombre_input.text.strip_edges(), preguntas)
	var tree = get_tree()
	tree.root.add_child(instancia)
	tree.current_scene.queue_free()
	tree.current_scene = instancia

# =====================================================================
# GUARDADO Y VALIDACIÓN
# =====================================================================

func _on_guardar():
	if nombre_input.text.strip_edges().is_empty():
		Notificador.notificar("El título es obligatorio", Color.MAGENTA)
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
			if pq["respuestasPosibles"].size() < 2:
				Notificador.notificar("Pregunta %d (TEST) necesita al menos 2 opciones" % (i + 1), Color.ORANGE)
				return
			var correctas = 0
			for r in pq["respuestasPosibles"]:
				if r["esCorrecta"]:
					correctas += 1
			if correctas == 0:
				Notificador.notificar("Pregunta %d (TEST) sin respuesta correcta" % (i + 1), Color.ORANGE)
				return
			if correctas > 1:
				Notificador.notificar("Pregunta %d (TEST): solo puede haber una correcta" % (i + 1), Color.ORANGE)
				return

	# Validación de suma vs objetivo
	var total = 0
	for pq in _preguntas_payload:
		total += int(pq["valorPuntos"])
	var objetivo = int(puntuacion_objetivo_spin.value)
	if total != objetivo:
		Notificador.notificar(
			"La suma de puntos (%d) no coincide con la puntuación objetivo (%d)" % [total, objetivo],
			Color.RED
		)
		return

	# Recordar el NPC elegido para asignar después
	var npcs = NpcManager.get_npcs()
	if npc_option.selected >= 0 and npc_option.selected < npcs.size():
		_npc_seleccionado = npcs[npc_option.selected]["id"]

	var payload = {
		"aulaId": GameManager.id_int(GameManager.aula_seleccionada_id),
		"titulo": nombre_input.text.strip_edges(),
		"fechaLimite": _construir_fecha_limite(),
		# Enviado como hint; el backend puede ignorarlo si aún no lo soporta.
		"npcId": _npc_seleccionado
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
		var header = vbox.get_node_or_null("HeaderPregunta")
		if header == null or enunciado_node == null:
			continue
		var opt = header.get_node_or_null("TipoPregunta")
		var spin = header.get_node_or_null("ValorPuntos")
		if opt == null:
			continue
		var enunciado_text = enunciado_node.text.strip_edges()
		if enunciado_text.is_empty():
			continue

		var tipo = opt.get_item_text(opt.selected)
		var valor_puntos = int(spin.value) if spin else 1
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
			"valorPuntos": valor_puntos,
			"respuestasPosibles": respuestas
		})
	return out

func _construir_fecha_limite() -> String:
	var fecha = fecha_input.text.strip_edges()
	var hora = hora_input.text.strip_edges()
	if fecha.is_empty():
		return Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()) + 604800) + "Z"
	if hora.is_empty():
		hora = "23:59:00"
	elif hora.length() == 5:
		hora += ":00"
	return "%sT%sZ" % [fecha, hora]

# =====================================================================
# COMUNICACIÓN SECUENCIAL CON BACKEND
# =====================================================================

func _on_prueba_guardada(data, code):
	if not (code == 200 or code == 201) or data == null:
		Notificador.notificar("Error creando la prueba: " + ConexionManager.mensaje_error(data, code), Color.RED)
		return

	_prueba_id_actual = GameManager.id_int(data.get("id"))
	if _prueba_id_actual < 0:
		Notificador.notificar("Prueba creada pero sin id válido", Color.ORANGE)
		return

	# Persistir asociación local prueba_id -> npc_id
	if not _npc_seleccionado.is_empty():
		NpcManager.asignar_prueba(_prueba_id_actual, _npc_seleccionado)

	Notificador.notificar("Subiendo preguntas (%d)..." % _preguntas_payload.size(), Color.CYAN)
	_enviar_siguiente_pregunta(1)

func _enviar_siguiente_pregunta(num: int):
	if _preguntas_payload.is_empty():
		Notificador.notificar("Prueba y preguntas creadas con éxito", Color.GREEN)
		await get_tree().create_timer(1.2).timeout
		get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
		return

	var pq = _preguntas_payload.pop_front()
	var payload = {
		"enunciado": pq["enunciado"],
		"tipo": pq["tipo"],
		"valorPuntos": pq["valorPuntos"],
		"pruebaId": _prueba_id_actual,
		"respuestasPosibles": pq["respuestasPosibles"]
	}
	ConexionManager.peticion_post("/preguntas/crear", payload, _on_pregunta_guardada.bind(num))

func _on_pregunta_guardada(num: int, data, code):
	if code == 200 or code == 201:
		_enviar_siguiente_pregunta(num + 1)
	else:
		Notificador.notificar(
			"Error en pregunta %d: %s" % [num, ConexionManager.mensaje_error(data, code)],
			Color.RED
		)

func _on_volver():
	get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
