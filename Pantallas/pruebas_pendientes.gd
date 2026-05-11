extends Control

@onready var lista = $Centro/Panel/Margen/VBox/Scroll/Lista
@onready var vacio = $Centro/Panel/Margen/VBox/Vacio
@onready var btn_volver = $Centro/Panel/Margen/VBox/BtnVolver

func _ready():
	btn_volver.pressed.connect(_on_volver)
	var alumno_id = GameManager.usuario_actual.get("id", -1)
	if alumno_id == -1:
		Notificador.notificar("Sesión no iniciada", Color.MAGENTA)
		_on_volver()
		return
	vacio.text = "Cargando..."
	ConexionManager.peticion_get("/pruebas/pendientes/%s" % str(alumno_id), _on_pruebas_recibidas)

func _on_pruebas_recibidas(data, code):
	if code == 204 or (data is Array and data.is_empty()):
		vacio.text = "No tienes pruebas pendientes"
		return
	if code != 200 or not (data is Array):
		vacio.text = "Error al cargar pruebas"
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)
		return

	vacio.visible = false
	for p in data:
		_crear_tarjeta_prueba(p)

func _crear_tarjeta_prueba(p: Dictionary):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var lbl_titulo = Label.new()
	lbl_titulo.text = str(p.get("titulo", "Prueba"))
	lbl_titulo.add_theme_font_size_override("font_size", 16)
	vbox.add_child(lbl_titulo)

	var lbl_meta = Label.new()
	var max_puntos = p.get("puntuacionMaxima", "-")
	var fecha_limite = p.get("fechaLimite", "")
	lbl_meta.text = "Máx: %s · Límite: %s" % [str(max_puntos), str(fecha_limite)]
	lbl_meta.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 1))
	lbl_meta.add_theme_font_size_override("font_size", 11)
	vbox.add_child(lbl_meta)

	var btn = Button.new()
	btn.text = "Empezar"
	btn.custom_minimum_size = Vector2(110, 40)
	var prueba_id = int(p.get("id", -1))
	var prueba_titulo = str(p.get("titulo", "Prueba"))
	btn.pressed.connect(func(): _empezar_prueba(prueba_id, prueba_titulo))
	hbox.add_child(btn)

	lista.add_child(panel)

func _empezar_prueba(p_id: int, p_titulo: String):
	var escena = load("res://Pantallas/sesion_prueba.tscn")
	var instancia = escena.instantiate()
	instancia.iniciar_con_prueba(p_id, p_titulo)
	var tree = get_tree()
	tree.root.add_child(instancia)
	tree.current_scene.queue_free()
	tree.current_scene = instancia

func _on_volver():
	get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
