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

var contador_preguntas = 0
var _preguntas_pendientes: Array = []
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
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var lbl = Label.new()
	lbl.text = "Pregunta #" + str(contador_preguntas)
	lbl.add_theme_color_override("font_color", Color.AQUAMARINE)
	vbox.add_child(lbl)

	var txt = TextEdit.new()
	txt.name = "TextoPregunta"
	txt.placeholder_text = "Escribe la pregunta..."
	txt.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(txt)

	var btn_del = Button.new()
	btn_del.text = "Eliminar"
	btn_del.pressed.connect(func(): panel.queue_free())
	vbox.add_child(btn_del)

	lista_preguntas.add_child(panel)

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

	# Recoger preguntas de los nodos dinamicos
	var preguntas: Array = []
	for child in lista_preguntas.get_children():
		var margin_node = child.get_child(0) if child.get_child_count() > 0 else null
		var vbox_node = margin_node.get_child(0) if margin_node and margin_node.get_child_count() > 0 else null
		if vbox_node:
			var txt = vbox_node.get_node_or_null("TextoPregunta")
			if txt and not txt.text.strip_edges().is_empty():
				preguntas.append(txt.text.strip_edges())

	var payload = {
		"aulaId": int(GameManager.aula_seleccionada_id),
		"titulo": nombre_input.text.strip_edges(),
		"fechaLimite": _construir_fecha_limite(),
		"puntuacionMaxima": max(preguntas.size(), 1)
	}

	_preguntas_pendientes = preguntas
	Notificador.notificar("Guardando prueba...", Color.CYAN)
	ConexionManager.peticion_post("/pruebas/crear", payload, _on_prueba_guardada)

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

	if _preguntas_pendientes.is_empty():
		Notificador.notificar("Prueba creada (sin preguntas)", Color.GREEN)
		await get_tree().create_timer(1.2).timeout
		get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
		return

	Notificador.notificar("Subiendo preguntas...", Color.CYAN)
	_enviar_siguiente_pregunta()

func _enviar_siguiente_pregunta():
	if _preguntas_pendientes.is_empty():
		Notificador.notificar("Prueba y preguntas creadas", Color.GREEN)
		await get_tree().create_timer(1.2).timeout
		get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
		return

	var enunciado = _preguntas_pendientes.pop_front()
	# Por defecto DESARROLLO porque la UI todavía no recoge respuestas posibles.
	# Cuando se añadan inputs de respuesta, cambiar a TIPO_TEST y rellenar el array.
	var payload = {
		"enunciado": enunciado,
		"tipo": TIPO_DESARROLLO,
		"pruebaId": _prueba_id_actual,
		"respuestasPosibles": []
	}
	ConexionManager.peticion_post("/preguntas/crear", payload, _on_pregunta_guardada)

func _on_pregunta_guardada(data, code):
	if code == 200 or code == 201:
		_enviar_siguiente_pregunta()
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

func _on_volver():
	get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
