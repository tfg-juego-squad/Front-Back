extends Control

@onready var titulo_alumnos = $Layout/MainContent/PanelAlumnos/MargenAlumnos/VBoxAlumnos/HeaderAlumnos/TituloAlumnos
@onready var contenedor_aulas = $Layout/MainContent/PanelAulas/MargenAulas/VBoxAulas/ScrollAulas/ContenedorAulas
@onready var contenedor_alumnos = $Layout/MainContent/PanelAlumnos/MargenAlumnos/VBoxAlumnos/ScrollAlumnos/ContenedorAlumnos
@onready var btn_nueva_aula = $Layout/MainContent/PanelAulas/MargenAulas/VBoxAulas/BtnNuevaAula
@onready var btn_anadir_alumno = $Layout/MainContent/PanelAlumnos/MargenAlumnos/VBoxAlumnos/HeaderAlumnos/BtnAnadirAlumno

@onready var btn_nueva_entrega = $Layout/MainContent/PanelBotones/MargenBotones/VBoxBotones/BtnNuevaEntrega
@onready var btn_revisar = $Layout/MainContent/PanelBotones/MargenBotones/VBoxBotones/BtnRevisar
@onready var btn_corregir = $Layout/MainContent/PanelBotones/MargenBotones/VBoxBotones/BtnCorregir
@onready var btn_estadisticas = $Layout/MainContent/PanelBotones/MargenBotones/VBoxBotones/BtnEstadisticas

@onready var btn_ajustes = $Layout/Header/MargenHeader/HBoxHeader/BtnAjustes
@onready var btn_avatar = $Layout/Header/MargenHeader/HBoxHeader/BtnAvatar
@onready var popup_sesion: PopupMenu = $Layout/Header/MargenHeader/HBoxHeader/BtnAvatar/PopupSesion

@onready var panel_flotante = $PanelFlotante
@onready var titulo_flotante = $PanelFlotante/MargenFlotante/VBoxFlotante/HeaderFlotante/TituloFlotante
@onready var btn_cerrar_flotante = $PanelFlotante/MargenFlotante/VBoxFlotante/HeaderFlotante/BtnCerrarFlotante
@onready var contenido_texto = $PanelFlotante/MargenFlotante/VBoxFlotante/ContenidoFlotante
@onready var tree_puntuaciones = $PanelFlotante/MargenFlotante/VBoxFlotante/TreePuntuaciones
@onready var vbox_generacion = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxGeneracion

@onready var edit_nombre_aula = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxGeneracion/EditNombreAula
@onready var spin_alumnos = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxGeneracion/SpinAlumnos
@onready var btn_confirmar_generar = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxGeneracion/BtnConfirmarGenerar
@onready var text_resultado = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxGeneracion/TextResultado

@onready var vbox_estadisticas = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxEstadisticas
@onready var cmb_pruebas_stats = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxEstadisticas/HBoxSelectorPrueba/CmbPruebas
@onready var tree_stats = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxEstadisticas/TreeStats

@onready var scroll_gestion = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion
@onready var lbl_gestion_titulo = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/LblGestionTitulo
@onready var edit_usuario = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/GridDatos/EditUsuario
@onready var edit_nombre = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/GridDatos/EditNombre
@onready var edit_apellidos = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/GridDatos/EditApellidos
@onready var edit_email = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/GridDatos/EditEmail
@onready var edit_password = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/GridDatos/EditPassword
@onready var edit_experiencia: SpinBox = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/GridDatos/EditExperiencia
@onready var btn_guardar_alumno = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HBoxAccionesAlumno/BtnGuardarAlumno
@onready var btn_borrar_alumno = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HBoxAccionesAlumno/BtnBorrarAlumno
@onready var puntos_nota_spin = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HBoxNotaManual/PuntosNotaSpin
@onready var edit_motivo_nota = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HBoxNotaManual/EditMotivoNota
@onready var btn_anadir_nota = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HBoxNotaManual/BtnAnadirNota
@onready var historial_notas = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HistorialNotas

@onready var _styles_node = $StylesPlantillas

var aulas_data: Array = []
var alumnos_data: Array = []
var alumno_seleccionado: Dictionary = {}
var pruebas_stats: Array = []
var aula_seleccionada_idx: int = -1
var _botones_aulas: Array = []

# Estado del panel flotante de generación:
# - false → modo "crear aula + generar alumnos" (botón engranaje / + nueva aula)
# - true  → modo "añadir alumnos al aula actual" (botón + del header de alumnos)
var _modo_solo_alumnos: bool = false
var _aula_id_para_anadir: String = ""

const COLOR_GOLD := Color(1, 0.839, 0.039, 1)
const COLOR_CYAN := Color(0, 0.941, 1, 1)
const COLOR_MAGENTA := Color(1, 0.176, 0.835, 1)
const COLOR_TEXT := Color(0.925, 0.937, 1, 1)
const COLOR_MUTED := Color(0.541, 0.541, 0.722, 1)

func _ready():
	btn_nueva_entrega.pressed.connect(_on_nueva_entrega)
	btn_revisar.pressed.connect(_on_revisar_puntuaciones)
	btn_corregir.pressed.connect(_on_corregir_pendientes)
	btn_estadisticas.pressed.connect(_on_abrir_estadisticas)
	cmb_pruebas_stats.item_selected.connect(_on_prueba_stats_elegida)
	btn_ajustes.pressed.connect(_on_abrir_generacion)
	btn_cerrar_flotante.pressed.connect(_cerrar_panel_flotante)
	btn_nueva_aula.pressed.connect(_on_abrir_generacion)
	btn_anadir_alumno.pressed.connect(_on_anadir_alumno_individual)
	btn_confirmar_generar.pressed.connect(_on_iniciar_proceso_generacion)

	btn_guardar_alumno.pressed.connect(_on_guardar_alumno)
	btn_borrar_alumno.pressed.connect(_on_borrar_alumno)
	btn_anadir_nota.pressed.connect(_on_anadir_nota_manual)

	btn_avatar.pressed.connect(_on_avatar_pressed)
	popup_sesion.clear()
	popup_sesion.add_item("Cerrar sesión", 0)
	popup_sesion.id_pressed.connect(_on_popup_sesion_id)

	panel_flotante.visible = false

	tree_puntuaciones.set_column_title(0, "#")
	tree_puntuaciones.set_column_title(1, "Alumno")
	tree_puntuaciones.set_column_title(2, "Puntos")
	tree_puntuaciones.set_column_title(3, "Nivel")

	_actualizar_avatar()
	_cargar_aulas()

func _actualizar_avatar():
	var nombre = ""
	if typeof(GameManager.usuario_actual) == TYPE_DICTIONARY:
		nombre = str(GameManager.usuario_actual.get("nombreUsuario", ""))
		if nombre.is_empty():
			nombre = str(GameManager.usuario_actual.get("usuario", ""))
	if nombre.is_empty():
		nombre = "Profesor"
	btn_avatar.text = "  %s  ▾  " % nombre

func _on_avatar_pressed():
	var pos = btn_avatar.global_position + Vector2(0, btn_avatar.size.y + 4)
	popup_sesion.popup(Rect2i(Vector2i(pos), Vector2i(180, 0)))

func _on_popup_sesion_id(id: int):
	if id == 0:
		GameManager.cerrar_sesion()

# =====================================================================
# AULAS — sidebar dinámico
# =====================================================================

func _cargar_aulas():
	var prof_id = GameManager.id_str(GameManager.usuario_actual.get("id"))
	if prof_id.is_empty():
		return
	ConexionManager.peticion_get("/aulas/profesor/%s" % prof_id, _on_aulas_recibidas)

func _on_aulas_recibidas(data, code):
	if code == 200 and data is Array:
		aulas_data = data
		_pintar_botones_aulas()
		if aulas_data.size() > 0:
			_seleccionar_aula(0)
		else:
			_mostrar_aulas_vacias()
	elif code == 204:
		aulas_data = []
		_mostrar_aulas_vacias()
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.ORANGE)

func _mostrar_aulas_vacias():
	_limpiar_contenedor(contenedor_aulas)
	_botones_aulas.clear()
	var aviso = Label.new()
	aviso.text = "Sin aulas creadas"
	aviso.add_theme_color_override("font_color", COLOR_MUTED)
	contenedor_aulas.add_child(aviso)
	titulo_alumnos.text = "ALUMNOS · Crea un aula"
	_limpiar_contenedor(contenedor_alumnos)

func _pintar_botones_aulas():
	_limpiar_contenedor(contenedor_aulas)
	_botones_aulas.clear()
	for i in range(aulas_data.size()):
		var aula = aulas_data[i]
		var btn := Button.new()
		btn.text = str(aula.get("nombre", "Aula"))
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", COLOR_CYAN)
		btn.add_theme_color_override("font_hover_color", COLOR_CYAN)
		btn.add_theme_color_override("font_pressed_color", COLOR_CYAN)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_aplicar_estilo_aula(btn, false)
		btn.pressed.connect(_seleccionar_aula.bind(i))
		contenedor_aulas.add_child(btn)
		_botones_aulas.append(btn)

func _aplicar_estilo_aula(btn: Button, activo: bool):
	var st_normal: StyleBox = _styles_node.get_meta("sb_aula_activa") if activo else _styles_node.get_meta("sb_aula_normal")
	var st_hover: StyleBox = _styles_node.get_meta("sb_aula_activa") if activo else _styles_node.get_meta("sb_aula_hover")
	btn.add_theme_stylebox_override("normal", st_normal)
	btn.add_theme_stylebox_override("hover", st_hover)
	btn.add_theme_stylebox_override("pressed", st_hover)
	btn.add_theme_stylebox_override("focus", st_normal)

func _seleccionar_aula(idx: int):
	if idx < 0 or idx >= aulas_data.size():
		return
	aula_seleccionada_idx = idx
	for i in range(_botones_aulas.size()):
		_aplicar_estilo_aula(_botones_aulas[i], i == idx)
	var aula = aulas_data[idx]
	var aula_id = GameManager.id_str(aula.get("id"))
	GameManager.aula_seleccionada_id = aula_id
	titulo_alumnos.text = "ALUMNOS · %s" % str(aula.get("nombre", ""))
	_limpiar_contenedor(contenedor_alumnos)
	var cargando = Label.new()
	cargando.text = "Cargando alumnos..."
	cargando.add_theme_color_override("font_color", COLOR_MUTED)
	contenedor_alumnos.add_child(cargando)
	ConexionManager.peticion_get("/aulas/%s/alumnos" % aula_id, _on_alumnos_recibidos)

# =====================================================================
# ALUMNOS — cards dinámicas
# =====================================================================

func _on_alumnos_recibidos(data, code):
	_limpiar_contenedor(contenedor_alumnos)
	alumnos_data.clear()
	if code == 200 and data is Array:
		if data.size() == 0:
			var vacio = Label.new()
			vacio.text = "(Aula vacía)"
			vacio.add_theme_color_override("font_color", COLOR_MUTED)
			contenedor_alumnos.add_child(vacio)
			return
		alumnos_data = data
		for i in range(data.size()):
			contenedor_alumnos.add_child(_crear_card_alumno(data[i]))
	else:
		var err = Label.new()
		err.text = "Sin alumnos"
		err.add_theme_color_override("font_color", COLOR_MUTED)
		contenedor_alumnos.add_child(err)

func _crear_card_alumno(alu: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _styles_node.get_meta("sb_alumno_card"))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.set_meta("alumno", alu)
	card.gui_input.connect(_on_card_alumno_input.bind(card))
	card.mouse_entered.connect(func(): card.add_theme_stylebox_override("panel", _styles_node.get_meta("sb_alumno_hover")))
	card.mouse_exited.connect(func(): card.add_theme_stylebox_override("panel", _styles_node.get_meta("sb_alumno_card")))

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)

	var nombre_lbl := Label.new()
	var nombre_str = str(alu.get("nombreUsuario", alu.get("usuario", "Anónimo")))
	nombre_lbl.text = nombre_str
	nombre_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	nombre_lbl.add_theme_font_size_override("font_size", 16)
	nombre_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nombre_lbl.tooltip_text = "Doble clic para editar / añadir nota"
	fila.add_child(nombre_lbl)

	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _styles_node.get_meta("sb_badge_lv"))
	badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	var nivel_raw = alu.get("nivelActual")
	var nivel_txt = "LV %s" % str(nivel_raw) if nivel_raw != null else "LV –"
	var badge_lbl := Label.new()
	badge_lbl.text = nivel_txt
	badge_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	badge_lbl.add_theme_font_size_override("font_size", 13)
	badge.add_child(badge_lbl)
	fila.add_child(badge)

	card.add_child(fila)
	return card

func _on_card_alumno_input(event: InputEvent, card: Control):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			var alu = card.get_meta("alumno", {})
			if typeof(alu) == TYPE_DICTIONARY and not alu.is_empty():
				_abrir_gestion_alumno(alu)

func _limpiar_contenedor(cont: Container):
	for c in cont.get_children():
		c.queue_free()

# =====================================================================
# GENERACIÓN MASIVA / AÑADIR ALUMNO
# =====================================================================

func _on_abrir_generacion():
	_modo_solo_alumnos = false
	_aula_id_para_anadir = ""
	_limpiar_paneles_flotantes()
	titulo_flotante.text = "◆  CREAR AULA Y GENERAR ALUMNOS"
	vbox_generacion.visible = true
	panel_flotante.visible = true
	text_resultado.text = ""
	btn_confirmar_generar.disabled = false
	btn_confirmar_generar.text = "Generar Credenciales"
	# Mostramos el campo "nombre del aula" (oculto en modo "solo alumnos").
	var lbl_aula = vbox_generacion.get_node_or_null("LabelAula")
	if lbl_aula:
		lbl_aula.visible = true
	edit_nombre_aula.visible = true
	edit_nombre_aula.editable = true
	edit_nombre_aula.placeholder_text = "Nombre del aula"
	edit_nombre_aula.text = ""
	spin_alumnos.editable = true
	spin_alumnos.value = 15

func _on_iniciar_proceso_generacion():
	# Modo "añadir alumnos al aula existente": no se crea aula, solo se generan.
	if _modo_solo_alumnos:
		if _aula_id_para_anadir.is_empty():
			Notificador.notificar("Aula no válida", Color.RED)
			return
		var cant_sa = int(spin_alumnos.value)
		Notificador.notificar("Generando %d alumno(s)..." % cant_sa, Color.GOLD)
		btn_confirmar_generar.disabled = true
		ConexionManager.peticion_post(
			"/aulas/%s/generar-alumnos" % _aula_id_para_anadir,
			{"cantidad": cant_sa},
			_on_generacion_completada
		)
		return

	# Modo "crear aula + alumnos".
	var nombre = edit_nombre_aula.text.strip_edges()
	if nombre.is_empty():
		Notificador.notificar("Nombre de aula requerido", Color.MAGENTA)
		return

	Notificador.notificar("1/2: Creando aula...", Color.CYAN)
	var prof_id = GameManager.id_int(GameManager.usuario_actual.get("id"))
	var payload = {"nombre": nombre, "profesorId": prof_id}
	ConexionManager.peticion_post("/aulas/crear", payload, _on_aula_creada)

func _on_aula_creada(data, code):
	if (code == 200 or code == 201) and data != null:
		var cant = int(spin_alumnos.value)
		var aula_id = GameManager.id_str(data.get("id"))
		Notificador.notificar("2/2: Generando credenciales...", Color.GOLD)
		ConexionManager.peticion_post(
			"/aulas/%s/generar-alumnos" % aula_id,
			{"cantidad": cant},
			_on_generacion_completada
		)
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

func _on_generacion_completada(data, code):
	btn_confirmar_generar.disabled = false
	if code == 200 and data is Array:
		text_resultado.text = "CREDENCIALES (¡guárdalas, no se volverán a mostrar!):\n"
		text_resultado.text += "==========================================\n\n"
		for item in data:
			text_resultado.text += "USER: %-15s | PASS: %s\n" % [item.get("usuario"), item.get("password")]
		Notificador.notificar("Proceso completado", Color.GREEN)
		if _modo_solo_alumnos and aula_seleccionada_idx >= 0:
			# Refrescamos solo el panel de alumnos del aula actual: si recargáramos
			# las aulas, _on_aulas_recibidas saltaría a la aula 0.
			_seleccionar_aula(aula_seleccionada_idx)
		else:
			_cargar_aulas()
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

func _on_anadir_alumno_individual():
	if aulas_data.is_empty() or aula_seleccionada_idx < 0:
		Notificador.notificar("Selecciona un aula primero", Color.ORANGE)
		return
	var aula_id = GameManager.id_str(aulas_data[aula_seleccionada_idx].get("id"))
	if aula_id.is_empty():
		Notificador.notificar("Aula sin id válido", Color.RED)
		return

	# Abrimos el panel en modo "solo alumnos": no creamos el alumno hasta que
	# el profesor pulse "Generar". Antes la petición salía sola al abrir, y
	# luego aparecía el menú con un alumno ya creado de más.
	_modo_solo_alumnos = true
	_aula_id_para_anadir = aula_id
	var nombre_aula = str(aulas_data[aula_seleccionada_idx].get("nombre", "Aula"))
	_limpiar_paneles_flotantes()
	titulo_flotante.text = "◆  AÑADIR ALUMNOS · %s" % nombre_aula
	vbox_generacion.visible = true
	panel_flotante.visible = true
	text_resultado.text = ""
	btn_confirmar_generar.disabled = false
	btn_confirmar_generar.text = "Generar alumno(s)"
	# Ocultamos el campo "nombre del aula": no aplica en este modo.
	var lbl_aula = vbox_generacion.get_node_or_null("LabelAula")
	if lbl_aula:
		lbl_aula.visible = false
	edit_nombre_aula.visible = false
	spin_alumnos.editable = true
	spin_alumnos.value = 1

# =====================================================================
# RANKING
# =====================================================================

func _on_revisar_puntuaciones():
	if aulas_data.is_empty() or aula_seleccionada_idx < 0:
		Notificador.notificar("Selecciona un aula primero", Color.ORANGE)
		return

	_limpiar_paneles_flotantes()
	titulo_flotante.text = "◆  RANKING DEL AULA"
	tree_puntuaciones.visible = true
	panel_flotante.visible = true

	var aula_id = GameManager.id_str(aulas_data[aula_seleccionada_idx].get("id"))
	ConexionManager.peticion_get("/puntuacion/aula/%s" % aula_id, _on_puntuaciones_recibidas)

func _on_puntuaciones_recibidas(data, code):
	tree_puntuaciones.clear()
	var root = tree_puntuaciones.create_item()

	if code != 200 or not (data is Array) or data.is_empty():
		var vacio = tree_puntuaciones.create_item(root)
		vacio.set_text(0, "")
		vacio.set_text(1, "Sin datos de puntuaciones")
		return

	var agregados: Dictionary = {}
	for p in data:
		var nombre = str(p.get("nombreUsuario", "Alumno"))
		var puntos_raw = p.get("puntosObtenidos")
		var puntos = 0 if puntos_raw == null else int(puntos_raw)
		var nivel_raw = p.get("nivelActual")
		var nivel = 0 if nivel_raw == null else int(nivel_raw)
		if not agregados.has(nombre):
			agregados[nombre] = {"puntos": 0, "nivel": nivel}
		agregados[nombre]["puntos"] += puntos
		if nivel_raw != null:
			agregados[nombre]["nivel"] = nivel

	var ordenados: Array = agregados.keys()
	ordenados.sort_custom(func(a, b): return agregados[a]["puntos"] > agregados[b]["puntos"])

	var pos = 1
	for nombre in ordenados:
		var item = tree_puntuaciones.create_item(root)
		item.set_text(0, str(pos))
		item.set_text(1, nombre)
		item.set_text(2, str(agregados[nombre]["puntos"]))
		item.set_text(3, str(agregados[nombre]["nivel"]))
		if pos == 1:
			item.set_custom_color(1, Color(1, 0.85, 0.2))
		elif pos == 2:
			item.set_custom_color(1, Color(0.85, 0.85, 0.85))
		elif pos == 3:
			item.set_custom_color(1, Color(0.85, 0.6, 0.4))
		pos += 1

func _limpiar_paneles_flotantes():
	contenido_texto.visible = false
	tree_puntuaciones.visible = false
	vbox_generacion.visible = false
	scroll_gestion.visible = false
	vbox_estadisticas.visible = false

func _cerrar_panel_flotante():
	panel_flotante.visible = false

func _on_nueva_entrega():
	get_tree().change_scene_to_file("res://Pantallas/nueva_entrega.tscn")

func _on_corregir_pendientes():
	get_tree().change_scene_to_file("res://Pantallas/corregir_pendientes.tscn")

# =====================================================================
# GESTIÓN DE ALUMNO (edición + nota manual)
# =====================================================================

func _abrir_gestion_alumno(alu: Dictionary):
	alumno_seleccionado = alu
	_limpiar_paneles_flotantes()
	titulo_flotante.text = "◆  ALUMNO · %s" % str(alu.get("nombreUsuario", "—"))
	lbl_gestion_titulo.text = "Datos del alumno (id %s)" % GameManager.id_str(alu.get("id"))
	edit_usuario.text = str(alu.get("nombreUsuario", ""))
	edit_nombre.text = str(alu.get("nombreReal", ""))
	edit_apellidos.text = str(alu.get("apellidos", ""))
	edit_email.text = str(alu.get("email", ""))
	edit_password.text = ""
	var xp_raw = alu.get("experienciaActual")
	edit_experiencia.value = 0.0 if xp_raw == null else float(xp_raw)
	edit_experiencia.set_meta("valor_original", int(edit_experiencia.value))
	puntos_nota_spin.value = 10
	edit_motivo_nota.text = ""
	historial_notas.clear()
	scroll_gestion.visible = true
	panel_flotante.visible = true
	_cargar_historial_notas(alu)

func _on_guardar_alumno():
	if alumno_seleccionado.is_empty():
		return
	var alumno_id = GameManager.id_str(alumno_seleccionado.get("id"))
	if alumno_id.is_empty():
		return
	var payload = {}
	var usuario_nuevo = edit_usuario.text.strip_edges()
	if not usuario_nuevo.is_empty() and usuario_nuevo != str(alumno_seleccionado.get("nombreUsuario", "")):
		payload["nombreUsuario"] = usuario_nuevo
	var nombre = edit_nombre.text.strip_edges()
	if not nombre.is_empty():
		payload["nombreReal"] = nombre
	var apellidos = edit_apellidos.text.strip_edges()
	if not apellidos.is_empty():
		payload["apellidos"] = apellidos
	var email = edit_email.text.strip_edges()
	if not email.is_empty():
		payload["email"] = email
	var password = edit_password.text
	if not password.strip_edges().is_empty():
		if password.length() < 6:
			Notificador.notificar("La contraseña debe tener al menos 6 caracteres", Color.ORANGE)
			return
		payload["passwordPlana"] = password
	# Experiencia: si el valor del SpinBox difiere del cargado, lo enviamos.
	var xp_nueva: int = int(edit_experiencia.value)
	var xp_original: int = int(edit_experiencia.get_meta("valor_original", -1))
	if xp_nueva != xp_original:
		payload["experienciaActual"] = xp_nueva
	if payload.is_empty():
		Notificador.notificar("No hay cambios que guardar", Color.GOLD)
		return
	Notificador.notificar("Guardando cambios del alumno...", Color.CYAN)
	ConexionManager.peticion_put("/usuarios/%s" % alumno_id, payload, _on_alumno_guardado)

func _on_alumno_guardado(data, code):
	if code == 200 and typeof(data) == TYPE_DICTIONARY:
		Notificador.notificar("Alumno actualizado", Color.GREEN)
		alumno_seleccionado = data
		_seleccionar_aula(aula_seleccionada_idx)
		_abrir_gestion_alumno(data)
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

func _on_borrar_alumno():
	if alumno_seleccionado.is_empty():
		return
	var alumno_id = GameManager.id_str(alumno_seleccionado.get("id"))
	if alumno_id.is_empty():
		return
	Notificador.notificar("Borrando alumno...", Color.GOLD)
	ConexionManager.peticion_delete("/usuarios/%s" % alumno_id, _on_alumno_borrado)

func _on_alumno_borrado(data, code):
	if code == 204 or code == 200:
		Notificador.notificar("Alumno eliminado", Color.GREEN)
		alumno_seleccionado = {}
		_cerrar_panel_flotante()
		_seleccionar_aula(aula_seleccionada_idx)
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

func _on_anadir_nota_manual():
	if alumno_seleccionado.is_empty():
		return
	var payload = {
		"alumnoId": GameManager.id_int(alumno_seleccionado.get("id")),
		"puntos": int(puntos_nota_spin.value),
		"motivo": edit_motivo_nota.text.strip_edges()
	}
	Notificador.notificar("Guardando nota manual...", Color.CYAN)
	ConexionManager.peticion_post("/puntuacion/manual", payload, _on_nota_manual_guardada)

func _on_nota_manual_guardada(data, code):
	if (code == 200 or code == 201) and typeof(data) == TYPE_DICTIONARY:
		Notificador.notificar("Nota manual añadida (+%d)" % int(data.get("puntosObtenidos", 0)), Color.GREEN)
		edit_motivo_nota.text = ""
		_cargar_historial_notas(alumno_seleccionado)
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

func _cargar_historial_notas(alu: Dictionary):
	historial_notas.clear()
	historial_notas.add_item("Cargando historial...")
	if GameManager.aula_seleccionada_id.is_empty():
		historial_notas.clear()
		return
	var alumno_id = GameManager.id_int(alu.get("id"))
	ConexionManager.peticion_get(
		"/puntuacion/aula/%s" % GameManager.aula_seleccionada_id,
		_on_historial_notas.bind(alumno_id)
	)

# =====================================================================
# ESTADÍSTICAS DE PRUEBAS (profesor)
# =====================================================================

func _on_abrir_estadisticas():
	if GameManager.aula_seleccionada_id.is_empty():
		Notificador.notificar("Selecciona un aula primero", Color.ORANGE)
		return
	_limpiar_paneles_flotantes()
	titulo_flotante.text = "◆  ESTADÍSTICAS DE PRUEBAS"
	vbox_estadisticas.visible = true
	panel_flotante.visible = true

	tree_stats.clear()
	tree_stats.set_column_title(0, "Pregunta")
	tree_stats.set_column_title(1, "Saltadas")
	tree_stats.set_column_title(2, "Contestadas")
	tree_stats.set_column_title(3, "Total")
	tree_stats.set_column_expand(0, true)
	tree_stats.set_column_expand(1, false)
	tree_stats.set_column_expand(2, false)
	tree_stats.set_column_expand(3, false)

	cmb_pruebas_stats.clear()
	cmb_pruebas_stats.add_item("Cargando...")
	pruebas_stats.clear()
	ConexionManager.peticion_get(
		"/pruebas/aula/%s" % GameManager.aula_seleccionada_id,
		_on_pruebas_para_stats
	)

func _on_pruebas_para_stats(data, code):
	cmb_pruebas_stats.clear()
	tree_stats.clear()
	if code != 200 or not (data is Array) or data.is_empty():
		cmb_pruebas_stats.add_item("(Sin pruebas)")
		return
	pruebas_stats.clear()
	for p in data:
		var tipo = str(p.get("tipo", "")).to_upper()
		if tipo == "NOTA_MANUAL" or tipo == "DIALOGO":
			continue
		pruebas_stats.append(p)
	if pruebas_stats.is_empty():
		cmb_pruebas_stats.add_item("(Sin pruebas con preguntas)")
		return
	for p in pruebas_stats:
		cmb_pruebas_stats.add_item(str(p.get("titulo", "Prueba")))
	cmb_pruebas_stats.selected = 0
	_on_prueba_stats_elegida(0)

func _on_prueba_stats_elegida(idx: int):
	if idx < 0 or idx >= pruebas_stats.size():
		return
	var prueba = pruebas_stats[idx]
	var prueba_id = GameManager.id_str(prueba.get("id"))
	tree_stats.clear()
	var root = tree_stats.create_item()
	var cargando = tree_stats.create_item(root)
	cargando.set_text(0, "Cargando estadísticas...")
	ConexionManager.peticion_get("/pruebas/%s/estadisticas" % prueba_id, _on_stats_recibidas)

func _on_stats_recibidas(data, code):
	tree_stats.clear()
	var root = tree_stats.create_item()
	if code != 200 or not (data is Array):
		var item = tree_stats.create_item(root)
		item.set_text(0, ConexionManager.mensaje_error(data, code))
		return
	if data.is_empty():
		var item = tree_stats.create_item(root)
		item.set_text(0, "Sin preguntas en esta prueba")
		return
	for fila in data:
		var item = tree_stats.create_item(root)
		var enun = str(fila.get("enunciado", ""))
		if enun.length() > 80:
			enun = enun.substr(0, 77) + "..."
		item.set_text(0, "[%s] %s" % [str(fila.get("tipo", "")), enun])
		var saltadas = int(fila.get("saltadas", 0))
		var contestadas = int(fila.get("contestadas", 0))
		var total = int(fila.get("total", 0))
		item.set_text(1, str(saltadas))
		item.set_text(2, str(contestadas))
		item.set_text(3, str(total))
		if total > 0 and saltadas > contestadas:
			item.set_custom_color(1, Color(1, 0.55, 0.4, 1))
		elif saltadas > 0:
			item.set_custom_color(1, Color(1, 0.85, 0.4, 1))

func _on_historial_notas(data, code, alumno_id: int):
	historial_notas.clear()
	if code != 200 or not (data is Array):
		historial_notas.add_item("Sin historial")
		return
	var encontradas := 0
	for nota in data:
		if int(nota.get("alumnoId", -1)) != alumno_id:
			continue
		var puntos = int(nota.get("puntosObtenidos", 0))
		var titulo = str(nota.get("tituloPrueba", ""))
		var motivo = str(nota.get("motivo", ""))
		var tipo = str(nota.get("tipoPrueba", ""))
		var etiqueta = titulo
		if tipo == "NOTA_MANUAL":
			etiqueta = "Nota manual" + (" · %s" % motivo if not motivo.is_empty() else "")
		historial_notas.add_item("%+d  ·  %s" % [puntos, etiqueta])
		encontradas += 1
	if encontradas == 0:
		historial_notas.add_item("Sin notas todavía")
