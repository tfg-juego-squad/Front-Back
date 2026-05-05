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

var contador_preguntas = 0

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
	var preguntas = []
	for child in lista_preguntas.get_children():
		var margin_node = child.get_child(0) if child.get_child_count() > 0 else null
		var vbox_node = margin_node.get_child(0) if margin_node and margin_node.get_child_count() > 0 else null
		if vbox_node:
			var txt = vbox_node.get_node_or_null("TextoPregunta")
			if txt and not txt.text.strip_edges().is_empty():
				preguntas.append(txt.text.strip_edges())
	
	var tipo = "TIPO_TEST" if preguntas.size() > 0 else "DESARROLLO"
	
	# Meter todo en el JSON de contenido
	var contenido = {
		"preguntas": preguntas,
		"descripcion": descripcion_input.text
	}
	if not fecha_input.text.strip_edges().is_empty():
		contenido["fecha_limite"] = fecha_input.text.strip_edges()
	if not hora_input.text.strip_edges().is_empty():
		contenido["hora_limite"] = hora_input.text.strip_edges()
	if check_sin_tiempo.button_pressed:
		contenido["sin_tiempo"] = true
	else:
		contenido["tiempo_minutos"] = int(tiempo_global_spin.value)
	
	var payload = {
		"aulaId": GameManager.aula_seleccionada_id,
		"titulo": nombre_input.text.strip_edges(),
		"tipo": tipo,
		"contenido": JSON.stringify(contenido),
		"puntuacionMaxima": preguntas.size() if preguntas.size() > 0 else 10
	}
	
	Notificador.notificar("Guardando prueba...", Color.CYAN)
	ConexionManager.peticion_post("/pruebas/crear", payload, _on_prueba_guardada)

func _on_prueba_guardada(_data, code):
	if code == 200:
		Notificador.notificar("Prueba creada", Color.GREEN)
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
	else:
		Notificador.notificar("Error al guardar: %d" % code, Color.RED)

func _on_volver():
	get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
