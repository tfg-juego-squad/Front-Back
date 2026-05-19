extends Control

@onready var btn_volver = $Layout/Header/HBoxHeader/BtnVolver
@onready var btn_guardar_global = $Layout/Centro/PanelContenedor/VBoxTabs/HBoxFinal/BtnGuardarGlobal

# --- Módulo Actividad ---
@onready var nombre_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/NombreInput
@onready var puntuacion_objetivo_spin = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxPuntuacion/PuntuacionObjetivoSpin
@onready var npc_option = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxNpc/NpcOption
@onready var check_evaluable = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxEvaluable/CheckEvaluable
@onready var nivel_minimo_spin = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxNivelMinimo/NivelMinimoSpin
@onready var xp_recompensa_spin = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxNivelMinimo/XpRecompensaSpin
@onready var btn_adjunto = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxAdjunto/BtnAdjunto
@onready var btn_quitar_adjunto = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxAdjunto/BtnQuitarAdjunto
@onready var nombre_adjunto = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxAdjunto/NombreAdjunto
@onready var dialogo_adjunto = $DialogoAdjunto

# --- Módulo Formulario ---
@onready var fecha_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/GridFechas/FechaInput
@onready var hora_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/GridFechas/HoraInput
@onready var check_sin_tiempo = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/HBoxGlobalTime/CheckSinTiempo
@onready var tiempo_global_spin = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/HBoxGlobalTime/TiempoGlobalSpin
@onready var lista_preguntas = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/ListaPreguntas
@onready var btn_add_pregunta = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/BtnAddPregunta
@onready var btn_preview = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/BtnPreview
@onready var lbl_total_puntos = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Formulario/Scroll/VBox/LblTotalPuntos

# --- Módulo Avanzado (minijuego) ---
@onready var niveles_minijuego_spin = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Avanzado/ScrollAv/VBoxAv/HBoxNiveles/NivelesSpin
@onready var subtipo_minijuego_option = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Avanzado/ScrollAv/VBoxAv/HBoxSubtipo/SubtipoOption
@onready var lista_preguntas_av = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Avanzado/ScrollAv/VBoxAv/ListaPreguntasAv
@onready var btn_add_pregunta_av = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Avanzado/ScrollAv/VBoxAv/BtnAddPreguntaAv

# --- Módulo Diálogo (NPC parlante) ---
@onready var texto_dialogo_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Dialogo/VBoxDialogo/TextoDialogoInput

# --- Constantes ---
const TIPO_TEST = "TEST"
const TIPO_DESARROLLO = "DESARROLLO"
const COLOR_DEFICIT = Color(1, 0.55, 0.4, 1)
const COLOR_EXCESO = Color(1, 0.4, 0.4, 1)
const COLOR_OK = Color(0.4, 0.95, 0.5, 1)

# Tiempo por pregunta: 5 s mínimo, sin tope inicial hasta que el profesor
# active el tiempo máximo global (entonces se recalcula).
const TIEMPO_PREG_MIN := 5
const TIEMPO_PREG_DEFAULT := 30
const TIEMPO_PREG_TOPE_SIN_LIMITE := 3600

signal puntuacion_cambiada

var _preguntas_payload: Array = []
var _prueba_id_actual: int = -1
var _npc_seleccionado: String = ""
var _adjunto_path: String = ""
# Contadores para el reporte final cuando se sube la cola de preguntas. Si
# alguna falla, seguimos con la siguiente en lugar de cortar la cola en seco
# (antes una pregunta rota dejaba la prueba a medio crear sin avisar bien).
var _preguntas_total: int = 0
var _preguntas_fallidas: int = 0

func _ready():
	btn_volver.pressed.connect(_on_volver)
	btn_guardar_global.pressed.connect(_on_guardar)
	btn_adjunto.pressed.connect(_on_btn_adjunto)
	btn_quitar_adjunto.pressed.connect(_on_quitar_adjunto)
	dialogo_adjunto.file_selected.connect(_on_adjunto_seleccionado)
	check_sin_tiempo.toggled.connect(_on_check_sin_tiempo_toggled)
	tiempo_global_spin.value_changed.connect(func(_v): _refrescar_topes_tiempo_pregunta())
	btn_add_pregunta.pressed.connect(func(): _on_add_pregunta())
	btn_add_pregunta_av.pressed.connect(func(): _on_add_pregunta({}, lista_preguntas_av, true))
	btn_preview.pressed.connect(_on_preview)
	puntuacion_objetivo_spin.value_changed.connect(func(_v): _actualizar_total_puntos())
	puntuacion_cambiada.connect(_actualizar_total_puntos)

	_poblar_selector_npc()
	_on_add_pregunta()
	_refrescar_topes_tiempo_pregunta()
	_instalar_filtros_fecha_hora()

# =====================================================================
# VALIDACIÓN DE ENTRADAS DE FECHA Y HORA
# Filtra cualquier carácter que no sea dígito o separador permitido.
# fecha: dígitos + "/" + "-"   |   hora: dígitos + ":"
# =====================================================================

func _instalar_filtros_fecha_hora():
	fecha_input.text_changed.connect(_on_fecha_text_changed)
	hora_input.text_changed.connect(_on_hora_text_changed)

func _on_fecha_text_changed(nuevo: String):
	_aplicar_filtro_line_edit(fecha_input, nuevo, "0123456789/-")

func _on_hora_text_changed(nuevo: String):
	_aplicar_filtro_line_edit(hora_input, nuevo, "0123456789:")

func _aplicar_filtro_line_edit(le: LineEdit, valor: String, permitidos: String):
	var limpio := ""
	for c in valor:
		if permitidos.contains(c):
			limpio += c
	if limpio == valor:
		return
	# Conservamos el caret donde estaba (ajustado por los caracteres eliminados
	# que quedaban a la izquierda del cursor).
	var caret_antes = le.caret_column
	var eliminados_antes_caret := 0
	for i in range(min(caret_antes, valor.length())):
		if not permitidos.contains(valor[i]):
			eliminados_antes_caret += 1
	le.text = limpio
	le.caret_column = max(0, caret_antes - eliminados_antes_caret)

func _poblar_selector_npc():
	npc_option.clear()
	for npc in NpcManager.get_npcs():
		npc_option.add_item("%s · %s" % [npc["nombre"], npc["materia"]])
	npc_option.selected = 0

func _on_check_sin_tiempo_toggled(on: bool):
	tiempo_global_spin.editable = not on
	_refrescar_topes_tiempo_pregunta()

# =====================================================================
# CREACIÓN DINÁMICA DE PREGUNTAS
# =====================================================================

func _on_add_pregunta(initial: Dictionary = {}, contenedor: VBoxContainer = null, modo_simple: bool = false):
	if contenedor == null:
		contenedor = lista_preguntas

	var panel = PanelContainer.new()
	panel.set_meta("es_pregunta", true)
	panel.set_meta("modo_simple", modo_simple)

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
	lbl.name = "LblNumero"
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
		# La numeración se recalcula tras eliminar; queue_free() es diferido
		# así que esperamos un frame para no ver al panel borrado todavía.
		call_deferred("_renumerar_preguntas", contenedor)
		puntuacion_cambiada.emit()
	)
	header.add_child(btn_del)

	# --- Fila tiempo por pregunta (en segundos, tope = tiempo global) ---
	var hbox_tiempo = HBoxContainer.new()
	hbox_tiempo.name = "HBoxTiempoPregunta"
	hbox_tiempo.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox_tiempo)

	var lbl_tiempo = Label.new()
	lbl_tiempo.text = "Tiempo (segundos):"
	lbl_tiempo.add_theme_color_override("font_color", Color(0.7, 0.85, 1, 1))
	hbox_tiempo.add_child(lbl_tiempo)

	var spin_tiempo = SpinBox.new()
	spin_tiempo.name = "TiempoPregunta"
	spin_tiempo.min_value = TIEMPO_PREG_MIN
	spin_tiempo.max_value = TIEMPO_PREG_TOPE_SIN_LIMITE
	spin_tiempo.value = TIEMPO_PREG_DEFAULT
	spin_tiempo.custom_minimum_size = Vector2(100, 0)
	hbox_tiempo.add_child(spin_tiempo)

	var lbl_tope = Label.new()
	lbl_tope.name = "LblTope"
	lbl_tope.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	lbl_tope.add_theme_font_size_override("font_size", 11)
	hbox_tiempo.add_child(lbl_tope)

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

	# --- Bloque DESARROLLO (oculto por defecto) ---
	# En DESARROLLO el alumno escribe libremente; aquí el profesor no
	# necesita configurar nada, solo dejamos un placeholder informativo.
	var bloque_desarrollo = VBoxContainer.new()
	bloque_desarrollo.name = "BloqueDesarrollo"
	bloque_desarrollo.add_theme_constant_override("separation", 6)
	bloque_desarrollo.visible = false
	vbox.add_child(bloque_desarrollo)

	var lbl_desarrollo = Label.new()
	lbl_desarrollo.text = "El alumno escribirá libremente su respuesta. La corregirás manualmente desde \"Corregir Pendientes\"."
	lbl_desarrollo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desarrollo.add_theme_color_override("font_color", Color(0.75, 0.85, 1, 1))
	lbl_desarrollo.add_theme_font_size_override("font_size", 12)
	bloque_desarrollo.add_child(lbl_desarrollo)

	var preview_desarrollo = TextEdit.new()
	preview_desarrollo.placeholder_text = "(Vista previa) — aquí escribirá el alumno..."
	preview_desarrollo.editable = false
	preview_desarrollo.custom_minimum_size = Vector2(0, 70)
	bloque_desarrollo.add_child(preview_desarrollo)

	# IMPORTANTE: Callable.bind añade args al final, así que la firma del
	# handler debe ser (idx_emitido, *bindeados).
	opt_tipo.item_selected.connect(
		_on_tipo_pregunta_seleccionado.bind(opt_tipo, bloque_test, lista_respuestas, spin_n, bloque_desarrollo)
	)

	contenedor.add_child(panel)

	# En modo simple (Avanzado/minijuego) ocultamos la puntuación porque no
	# hay objetivo agregado: cada pregunta vale lo que diga su propio spin.
	if modo_simple:
		lbl_puntos.visible = false
		spin_puntos.visible = false

	# --- Aplicar datos iniciales o crear 4 opciones por defecto si es TEST ---
	if not initial.is_empty():
		_aplicar_datos_iniciales(panel, initial)
	else:
		# Default = TEST → generar 4 opciones de partida visibles
		_regenerar_opciones(lista_respuestas, int(spin_n.value))

	_aplicar_tope_tiempo_a_pregunta(spin_tiempo, lbl_tope, modo_simple)
	_renumerar_preguntas(contenedor)
	puntuacion_cambiada.emit()

func _aplicar_datos_iniciales(panel: Node, data: Dictionary):
	var margin = panel.get_child(0)
	var vbox = margin.get_child(0)
	var header = vbox.get_node("HeaderPregunta")
	var enunciado_node = vbox.get_node("Enunciado")
	var bloque_test = vbox.get_node("BloqueTest")
	var bloque_desarrollo = vbox.get_node_or_null("BloqueDesarrollo")
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
		if bloque_desarrollo:
			bloque_desarrollo.visible = true
	else:
		opt_tipo.selected = 0
		bloque_test.visible = true
		if bloque_desarrollo:
			bloque_desarrollo.visible = false
		var respuestas = data.get("respuestasPosibles", [])
		spin_n.value = max(respuestas.size(), 2)
		_regenerar_opciones(lista_resp, respuestas.size())
		for i in range(respuestas.size()):
			var fila = lista_resp.get_child(i)
			if fila == null:
				continue
			var texto_input = fila.get_node("TextoRespuesta")
			var check = fila.get_node("EsCorrecta")
			texto_input.text = str(respuestas[i].get("texto", ""))
			check.button_pressed = bool(respuestas[i].get("esCorrecta", false))

func _on_tipo_pregunta_seleccionado(idx: int, opt: OptionButton, bloque_test: VBoxContainer, lista_respuestas: VBoxContainer, spin_n: SpinBox, bloque_desarrollo: VBoxContainer):
	var es_test = opt.get_item_text(idx) == TIPO_TEST
	bloque_test.visible = es_test
	bloque_desarrollo.visible = not es_test
	# Reload completo del constructor de la pregunta al cambiar el tipo:
	# tiramos las opciones anteriores y, si es TEST, regeneramos limpias.
	for hijo in lista_respuestas.get_children():
		hijo.queue_free()
	# Reseteamos también el grupo de "correcta" para que no quede una marcada
	# residual al cambiar de tipo y volver.
	var grupo = ButtonGroup.new()
	lista_respuestas.set_meta("grupo_correctas", grupo)
	if es_test:
		spin_n.value = max(int(spin_n.value), 2)
		# call_deferred evita pisar las queue_free() recién pedidas.
		call_deferred("_regenerar_opciones", lista_respuestas, int(spin_n.value))

func _regenerar_opciones(contenedor: VBoxContainer, cantidad: int):
	for hijo in contenedor.get_children():
		hijo.queue_free()
	for i in range(max(cantidad, 2)):
		_add_respuesta(contenedor)

# Reasigna "Pregunta #N" en cada panel según su posición actual en el
# contenedor. Llamado al añadir/borrar para que la numeración siempre
# refleje las preguntas vivas, no un contador acumulado.
func _renumerar_preguntas(contenedor: VBoxContainer):
	if contenedor == null:
		return
	var n := 0
	for panel in contenedor.get_children():
		if not panel.has_meta("es_pregunta"):
			continue
		if not is_instance_valid(panel) or panel.is_queued_for_deletion():
			continue
		n += 1
		var lbl = _get_lbl_numero_pregunta(panel)
		if lbl:
			lbl.text = "Pregunta #%d" % n

func _get_lbl_numero_pregunta(panel: Node) -> Label:
	var margin = panel.get_child(0) if panel.get_child_count() > 0 else null
	var vbox = margin.get_child(0) if margin and margin.get_child_count() > 0 else null
	var header = vbox.get_node_or_null("HeaderPregunta") if vbox else null
	return header.get_node_or_null("LblNumero") if header else null

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
# TIEMPO POR PREGUNTA: tope = tiempo global (si está activado)
# =====================================================================

func _tope_tiempo_pregunta_segundos() -> int:
	if check_sin_tiempo.button_pressed:
		return TIEMPO_PREG_TOPE_SIN_LIMITE
	return max(TIEMPO_PREG_MIN, int(tiempo_global_spin.value) * 60)

func _refrescar_topes_tiempo_pregunta():
	if not is_inside_tree() or lista_preguntas == null:
		return
	for panel in lista_preguntas.get_children():
		if not panel.has_meta("es_pregunta"):
			continue
		var spin = _get_spin_tiempo_pregunta(panel)
		var lbl = _get_lbl_tope_pregunta(panel)
		if spin and lbl:
			_aplicar_tope_tiempo_a_pregunta(spin, lbl)

func _aplicar_tope_tiempo_a_pregunta(spin: SpinBox, lbl: Label, modo_simple: bool = false):
	# El modo simple (minijuego) no usa tiempo global del Formulario, así que
	# cada pregunta puede durar lo que quiera el profesor.
	if modo_simple:
		spin.max_value = TIEMPO_PREG_TOPE_SIN_LIMITE
		lbl.text = "(sin tope)"
		return
	var tope = _tope_tiempo_pregunta_segundos()
	spin.max_value = tope
	if spin.value > tope:
		spin.value = tope
	if check_sin_tiempo.button_pressed:
		lbl.text = "(sin límite global)"
	else:
		lbl.text = "máx %d s" % tope

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

func _get_spin_tiempo_pregunta(panel: Node) -> SpinBox:
	var margin = panel.get_child(0) if panel.get_child_count() > 0 else null
	var vbox = margin.get_child(0) if margin and margin.get_child_count() > 0 else null
	var hbox = vbox.get_node_or_null("HBoxTiempoPregunta") if vbox else null
	return hbox.get_node_or_null("TiempoPregunta") if hbox else null

func _get_lbl_tope_pregunta(panel: Node) -> Label:
	var margin = panel.get_child(0) if panel.get_child_count() > 0 else null
	var vbox = margin.get_child(0) if margin and margin.get_child_count() > 0 else null
	var hbox = vbox.get_node_or_null("HBoxTiempoPregunta") if vbox else null
	return hbox.get_node_or_null("LblTope") if hbox else null

# =====================================================================
# ADJUNTO (.zip) — selección local; se sube cuando el backend lo soporte
# =====================================================================

func _on_btn_adjunto():
	dialogo_adjunto.popup_centered_ratio(0.6)

func _on_adjunto_seleccionado(path: String):
	if path.is_empty():
		return
	_adjunto_path = path
	nombre_adjunto.text = path.get_file()
	nombre_adjunto.add_theme_color_override("font_color", Color(0.5, 0.95, 0.6, 1))
	btn_quitar_adjunto.visible = true
	Notificador.notificar("Adjunto vinculado: %s" % path.get_file(), Color.CYAN)

func _on_quitar_adjunto():
	_adjunto_path = ""
	nombre_adjunto.text = "Sin adjunto"
	nombre_adjunto.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	btn_quitar_adjunto.visible = false

# =====================================================================
# PREVISUALIZACIÓN
# =====================================================================

func _on_preview():
	# Si ya hay un preview montado lo retiramos antes de abrir otro
	var existente = get_node_or_null("PreviewOverlay")
	if existente:
		existente.queue_free()

	# Buscamos en las dos listas: una previsualización con sentido es la primera
	# que tenga preguntas. Así el botón funciona tanto en el constructor de
	# examen como en el banco del minijuego.
	var preguntas = _recoger_preguntas()
	if preguntas.is_empty():
		preguntas = _recoger_preguntas_avanzado()
	if preguntas.is_empty():
		Notificador.notificar("Añade al menos una pregunta antes de previsualizar", Color.ORANGE)
		return

	# Montamos el preview como hijo de esta escena (overlay) en lugar de
	# cambiar la escena: así no se pierde nada del formulario al cerrar.
	var escena = load("res://Pantallas/preview_prueba.tscn")
	var instancia = escena.instantiate()
	instancia.name = "PreviewOverlay"
	instancia.set_meta("modo_overlay", true)
	instancia.cargar_preview(nombre_input.text.strip_edges(), preguntas)
	add_child(instancia)

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

	var preguntas_examen = _recoger_preguntas()
	var preguntas_minijuego = _recoger_preguntas_avanzado()
	var texto_dialogo = texto_dialogo_input.text.strip_edges() if texto_dialogo_input else ""
	var hay_dialogo = not texto_dialogo.is_empty()

	# El profesor solo puede rellenar una pestaña "de contenido" a la vez.
	var rellenas = 0
	if not preguntas_examen.is_empty(): rellenas += 1
	if not preguntas_minijuego.is_empty(): rellenas += 1
	if hay_dialogo: rellenas += 1
	if rellenas > 1:
		Notificador.notificar(
			"Solo puedes rellenar una de las pestañas Formulario / Avanzado / Diálogo",
			Color.RED
		)
		return

	var tipo := "ACTIVIDAD"
	var niveles_minijuego = null
	var subtipo_minijuego = null
	var npc_forzado := ""

	if not preguntas_examen.is_empty():
		tipo = "EXAMEN"
		_preguntas_payload = preguntas_examen
		if not _validar_preguntas_examen(_preguntas_payload):
			return
	elif not preguntas_minijuego.is_empty():
		tipo = "MINIJUEGO"
		_preguntas_payload = preguntas_minijuego
		if not _validar_preguntas_minijuego(_preguntas_payload):
			return
		niveles_minijuego = int(niveles_minijuego_spin.value)
		subtipo_minijuego = _subtipo_minijuego_actual()
		# El minijuego siempre vive en el NPC de Actividades.
		npc_forzado = "npc_actividades"
	elif hay_dialogo:
		tipo = "DIALOGO"
		_preguntas_payload = []
	else:
		_preguntas_payload = []

	# Recordar el NPC elegido para asignar después
	var npcs = NpcManager.get_npcs()
	if not npc_forzado.is_empty():
		_npc_seleccionado = npc_forzado
		# Reflejarlo en el selector para coherencia visual.
		for i in range(npcs.size()):
			if npcs[i]["id"] == npc_forzado:
				npc_option.selected = i
				break
	elif npc_option.selected >= 0 and npc_option.selected < npcs.size():
		_npc_seleccionado = npcs[npc_option.selected]["id"]

	var payload = {
		"aulaId": GameManager.id_int(GameManager.aula_seleccionada_id),
		"titulo": nombre_input.text.strip_edges(),
		"fechaLimite": _construir_fecha_limite(),
		"npcId": _npc_seleccionado,
		"tipo": tipo,
		"evaluable": check_evaluable.button_pressed if check_evaluable else true,
		"nivelMinimo": int(nivel_minimo_spin.value) if nivel_minimo_spin else 1,
		"xpRecompensa": int(xp_recompensa_spin.value) if xp_recompensa_spin else 10
	}
	if niveles_minijuego != null:
		payload["nivelesMinijuego"] = niveles_minijuego
	if subtipo_minijuego != null:
		payload["subtipoMinijuego"] = subtipo_minijuego
	if hay_dialogo:
		payload["texto"] = texto_dialogo

	Notificador.notificar("Guardando %s..." % tipo.to_lower(), Color.CYAN)
	ConexionManager.peticion_post("/pruebas/crear", payload, _on_prueba_guardada)

# Devuelve el código del subtipo de minijuego seleccionado en el OptionButton.
func _subtipo_minijuego_actual() -> String:
	if subtipo_minijuego_option == null:
		return "SECUENCIA"
	match subtipo_minijuego_option.selected:
		1: return "ESQUIVA"
		2: return "HOTLINE"
		_: return "SECUENCIA"

func _validar_preguntas_examen(preguntas: Array) -> bool:
	for i in range(preguntas.size()):
		var pq = preguntas[i]
		if pq["tipo"] == TIPO_TEST:
			if pq["respuestasPosibles"].size() < 2:
				Notificador.notificar("Pregunta %d (TEST) necesita al menos 2 opciones" % (i + 1), Color.ORANGE)
				return false
			var correctas = 0
			for r in pq["respuestasPosibles"]:
				if r["esCorrecta"]:
					correctas += 1
			if correctas == 0:
				Notificador.notificar("Pregunta %d (TEST) sin respuesta correcta" % (i + 1), Color.ORANGE)
				return false
			if correctas > 1:
				Notificador.notificar("Pregunta %d (TEST): solo puede haber una correcta" % (i + 1), Color.ORANGE)
				return false

	# Validación de suma vs objetivo
	var total = 0
	for pq in preguntas:
		total += int(pq["valorPuntos"])
	var objetivo = int(puntuacion_objetivo_spin.value)
	if total != objetivo:
		Notificador.notificar(
			"La suma de puntos (%d) no coincide con la puntuación objetivo (%d)" % [total, objetivo],
			Color.RED
		)
		return false
	return true

func _validar_preguntas_minijuego(preguntas: Array) -> bool:
	# En el minijuego solo exigimos coherencia interna por pregunta TEST.
	# El valorPuntos se ignora a efectos de puntuación agregada.
	for i in range(preguntas.size()):
		var pq = preguntas[i]
		if pq["tipo"] == TIPO_TEST:
			if pq["respuestasPosibles"].size() < 2:
				Notificador.notificar("Pregunta %d (TEST) necesita al menos 2 opciones" % (i + 1), Color.ORANGE)
				return false
			var correctas = 0
			for r in pq["respuestasPosibles"]:
				if r["esCorrecta"]:
					correctas += 1
			if correctas != 1:
				Notificador.notificar("Pregunta %d (TEST): marca exactamente 1 correcta" % (i + 1), Color.ORANGE)
				return false
	return true

func _recoger_preguntas_avanzado() -> Array:
	return _leer_preguntas_de(lista_preguntas_av)

func _recoger_preguntas() -> Array:
	return _leer_preguntas_de(lista_preguntas)

func _leer_preguntas_de(contenedor: VBoxContainer) -> Array:
	var out: Array = []
	for panel in contenedor.get_children():
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
		# En modo simple no hay valor de puntuación; usamos 0 como neutro.
		var modo_simple = panel.get_meta("modo_simple", false)
		var valor_puntos: int
		if modo_simple:
			valor_puntos = 0
		elif spin:
			valor_puntos = int(spin.value)
		else:
			valor_puntos = 1
		var spin_tiempo = _get_spin_tiempo_pregunta(panel)
		var tiempo_seg = int(spin_tiempo.value) if spin_tiempo else TIEMPO_PREG_DEFAULT
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
			"tiempoLimiteSegundos": tiempo_seg,
			"respuestasPosibles": respuestas
		})
	return out

func _construir_fecha_limite() -> String:
	var fecha_iso = _normalizar_fecha(fecha_input.text.strip_edges())
	var hora = hora_input.text.strip_edges()
	if fecha_iso.is_empty():
		# Sin fecha: por defecto +7 días desde ahora (UTC).
		return Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()) + 604800) + "Z"
	if hora.is_empty():
		hora = "23:59:00"
	elif hora.length() == 5:
		hora += ":00"
	return "%sT%sZ" % [fecha_iso, hora]

# Acepta dd/mm/yyyy, dd-mm-yyyy o yyyy-mm-dd y devuelve siempre YYYY-MM-DD.
# Si el texto no es reconocible devuelve cadena vacía → defaultea a +7 días.
func _normalizar_fecha(raw: String) -> String:
	if raw.is_empty():
		return ""
	# Aceptamos / o - como separador
	var partes = raw.replace("/", "-").split("-")
	if partes.size() != 3:
		return ""
	# Si el primer trozo tiene 4 dígitos asumimos ya formato ISO yyyy-mm-dd.
	if partes[0].length() == 4:
		return "%s-%s-%s" % [partes[0], _pad2(partes[1]), _pad2(partes[2])]
	# Formato español dd-mm-yyyy → yyyy-mm-dd.
	if partes[2].length() == 4:
		return "%s-%s-%s" % [partes[2], _pad2(partes[1]), _pad2(partes[0])]
	return ""

func _pad2(s: String) -> String:
	if s.length() >= 2:
		return s
	return "0" + s

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

	if not _npc_seleccionado.is_empty():
		NpcManager.asignar_prueba(_prueba_id_actual, _npc_seleccionado)

	if _preguntas_payload.is_empty():
		Notificador.notificar("Actividad creada con éxito", Color.GREEN)
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
		return

	_preguntas_total = _preguntas_payload.size()
	_preguntas_fallidas = 0
	Notificador.notificar("Subiendo preguntas (%d)..." % _preguntas_total, Color.CYAN)
	_enviar_siguiente_pregunta(1)

func _enviar_siguiente_pregunta(num: int):
	if _preguntas_payload.is_empty():
		var subidas = _preguntas_total - _preguntas_fallidas
		if _preguntas_fallidas == 0:
			Notificador.notificar("Prueba y preguntas creadas con éxito", Color.GREEN)
		else:
			Notificador.notificar(
				"Subidas %d/%d preguntas (%d fallaron)" % [subidas, _preguntas_total, _preguntas_fallidas],
				Color.ORANGE
			)
		await get_tree().create_timer(1.6).timeout
		get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
		return

	var pq = _preguntas_payload.pop_front()
	var payload = {
		"enunciado": pq["enunciado"],
		"tipo": pq["tipo"],
		"valorPuntos": pq["valorPuntos"],
		"tiempoLimiteSegundos": pq["tiempoLimiteSegundos"],
		"pruebaId": _prueba_id_actual,
		"respuestasPosibles": pq["respuestasPosibles"]
	}
	ConexionManager.peticion_post("/preguntas/crear", payload, _on_pregunta_guardada.bind(num))

func _on_pregunta_guardada(data, code, num: int):
	# Callable.bind añade el num al final, por eso este orden.
	# Si una pregunta falla, anotamos el fallo pero SEGUIMOS con la siguiente
	# para no dejar la prueba a medio crear sin avisar al profesor.
	if not (code == 200 or code == 201):
		_preguntas_fallidas += 1
		Notificador.notificar(
			"Error en pregunta %d: %s" % [num, ConexionManager.mensaje_error(data, code)],
			Color.RED
		)
	_enviar_siguiente_pregunta(num + 1)

func _on_volver():
	get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
