extends Control

# --- Referencias Generales ---
@onready var btn_volver = $Layout/Header/HBoxHeader/BtnVolver
@onready var btn_guardar_global = $Layout/Centro/PanelContenedor/VBoxTabs/HBoxFinal/BtnGuardarGlobal

# --- Tab 1: Actividad ---
@onready var nombre_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/NombreInput
@onready var descripcion_input = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/DescripcionInput
@onready var btn_adjunto = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxAdjunto/BtnAdjunto
@onready var nombre_adjunto = $Layout/Centro/PanelContenedor/VBoxTabs/TabContainer/Actividad/VBox/HBoxAdjunto/NombreAdjunto

# --- Tab 2: Formulario ---
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
	# Conexiones principales
	btn_volver.pressed.connect(_on_volver)
	btn_guardar_global.pressed.connect(_on_guardar)
	
	# Tab 1
	btn_adjunto.pressed.connect(_on_btn_adjunto_pressed)
	
	# Tab 2
	btn_descargar_plantilla.pressed.connect(_on_descargar_plantilla)
	btn_subir_plantilla.pressed.connect(_on_subir_plantilla)
	check_sin_tiempo.toggled.connect(func(toggled): tiempo_global_spin.editable = not toggled)
	btn_add_pregunta.pressed.connect(_on_add_pregunta)
	btn_preview.pressed.connect(_on_preview_examen)
	
	# Inicializar
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
	txt.placeholder_text = "Escribe aquí la pregunta..."
	txt.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(txt)
	
	var btn_del = Button.new()
	btn_del.text = "Eliminar"
	btn_del.pressed.connect(func(): panel.queue_free())
	vbox.add_child(btn_del)
	
	lista_preguntas.add_child(panel)

func _on_btn_adjunto_pressed():
	nombre_adjunto.text = "Archivo seleccionado: proyecto.zip"
	Notificador.notificar("Adjunto vinculado", Color.CYAN)

func _on_descargar_plantilla():
	Notificador.notificar("Descargando plantilla Excel...", Color.CYAN)

func _on_subir_plantilla():
	Notificador.notificar("Formulario importado correctamente", Color.CYAN)

func _on_preview_examen():
	Notificador.notificar("Abriendo vista previa...", Color.GOLDENROD)

func _on_guardar():
	if nombre_input.text.is_empty():
		Notificador.notificar("ERROR: El título es obligatorio", Color.MAGENTA)
		return
	Notificador.notificar("Actividad guardada con éxito", Color.CYAN)

func _on_volver():
	get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
