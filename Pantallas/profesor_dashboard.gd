extends Control

@onready var lista_alumnos = $Layout/MainContent/PanelAlumnos/MargenAlumnos/VBoxAlumnos/ListaAlumnos
@onready var cmb_aulas = $Layout/MainContent/PanelAlumnos/MargenAlumnos/VBoxAlumnos/HBoxAula/CmbAulas
@onready var btn_crear_aula = $Layout/MainContent/PanelAlumnos/MargenAlumnos/VBoxAlumnos/HBoxAula/BtnCrearAula
@onready var btn_importar_csv = $Layout/MainContent/PanelAlumnos/MargenAlumnos/VBoxAlumnos/HBoxAula/BtnImportarCSV

@onready var dialogo_csv = $DialogoCSV
@onready var dialogo_exportar = $DialogoExportar

@onready var btn_nueva_entrega = $Layout/MainContent/PanelBotones/VBoxBotones/BtnNuevaEntrega
@onready var btn_revisar = $Layout/MainContent/PanelBotones/VBoxBotones/BtnRevisar
@onready var btn_corregir = $Layout/MainContent/PanelBotones/VBoxBotones/BtnCorregir
@onready var btn_ajustes = $Layout/MainContent/PanelBotones/VBoxBotones/BtnAjustes
@onready var btn_cerrar_sesion = $Layout/Header/HBoxHeader/BtnCerrarSesion

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
@onready var btn_exportar_csv = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxGeneracion/BtnExportarCSV

var aulas_data: Array = []
var credenciales_recientes: Array = []

func _ready():
	btn_nueva_entrega.pressed.connect(_on_nueva_entrega)
	btn_revisar.pressed.connect(_on_revisar_puntuaciones)
	btn_corregir.pressed.connect(_on_corregir_pendientes)
	btn_ajustes.pressed.connect(_on_abrir_generacion)
	btn_cerrar_sesion.pressed.connect(_on_cerrar_sesion)
	btn_cerrar_flotante.pressed.connect(_cerrar_panel_flotante)
	btn_crear_aula.pressed.connect(_on_abrir_generacion)
	cmb_aulas.item_selected.connect(_on_aula_seleccionada)
	btn_confirmar_generar.pressed.connect(_on_iniciar_proceso_generacion)
	btn_importar_csv.pressed.connect(_on_pulsar_importar_csv)
	btn_exportar_csv.pressed.connect(_on_pulsar_exportar_csv)
	dialogo_csv.file_selected.connect(_on_csv_seleccionado)
	dialogo_exportar.file_selected.connect(_on_destino_exportar_seleccionado)

	panel_flotante.visible = false
	btn_exportar_csv.visible = false

	tree_puntuaciones.set_column_title(0, "#")
	tree_puntuaciones.set_column_title(1, "Alumno")
	tree_puntuaciones.set_column_title(2, "Puntos")
	tree_puntuaciones.set_column_title(3, "Nivel")

	_cargar_aulas()

func _cargar_aulas():
	var prof_id = GameManager.id_str(GameManager.usuario_actual.get("id"))
	if prof_id.is_empty():
		return
	ConexionManager.peticion_get("/aulas/profesor/%s" % prof_id, _on_aulas_recibidas)

func _on_aulas_recibidas(data, code):
	if code == 200 and data is Array:
		aulas_data = data
		cmb_aulas.clear()
		for aula in aulas_data:
			cmb_aulas.add_item(aula.get("nombre", "Sin nombre"))
		if cmb_aulas.item_count > 0:
			_on_aula_seleccionada(0)
	elif code == 204:
		cmb_aulas.clear()
		cmb_aulas.add_item("Sin aulas creadas")
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.ORANGE)

func _on_aula_seleccionada(index):
	if aulas_data.is_empty(): return
	var aula_id = GameManager.id_str(aulas_data[index].get("id"))
	GameManager.aula_seleccionada_id = aula_id
	lista_alumnos.clear()
	lista_alumnos.add_item("Cargando alumnos...")
	ConexionManager.peticion_get("/aulas/%s/alumnos" % aula_id, _on_alumnos_recibidos)

func _on_alumnos_recibidos(data, code):
	lista_alumnos.clear()
	if code == 200 and data is Array:
		if data.size() == 0:
			lista_alumnos.add_item("(Aula vacía)")
		else:
			for alu in data:
				var nombre = alu.get("nombreUsuario", alu.get("usuario", "Anónimo"))
				var nivel = alu.get("nivelActual", null)
				var sufijo = "  ·  Nv %s" % str(nivel) if nivel != null else ""
				lista_alumnos.add_item("%s%s" % [nombre, sufijo])
	else:
		lista_alumnos.add_item("Sin alumnos")

func _on_abrir_generacion():
	_limpiar_paneles_flotantes()
	titulo_flotante.text = "CREAR AULA Y GENERAR ALUMNOS"
	vbox_generacion.visible = true
	panel_flotante.visible = true
	text_resultado.text = ""
	btn_exportar_csv.visible = false
	credenciales_recientes.clear()

func _on_iniciar_proceso_generacion():
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
	if code == 200 and data is Array:
		credenciales_recientes = data.duplicate(true)
		text_resultado.text = "CREDENCIALES (¡guárdalas, no se volverán a mostrar!):\n"
		text_resultado.text += "==========================================\n\n"
		for item in data:
			text_resultado.text += "USER: %-15s | PASS: %s\n" % [item.get("usuario"), item.get("password")]
		btn_exportar_csv.visible = data.size() > 0
		Notificador.notificar("Proceso completado", Color.GREEN)
		_cargar_aulas()
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

# ------- Importar CSV -------

func _on_pulsar_importar_csv():
	if GameManager.aula_seleccionada_id.is_empty():
		Notificador.notificar("Selecciona un aula primero", Color.ORANGE)
		return
	dialogo_csv.popup_centered_ratio(0.6)

func _on_csv_seleccionado(path: String):
	Notificador.notificar("Subiendo CSV...", Color.CYAN)
	ConexionManager.peticion_multipart(
		"/aulas/%s/importar-csv" % GameManager.aula_seleccionada_id,
		"file",
		path,
		_on_import_csv_completado
	)

func _on_import_csv_completado(data, code):
	if code == 200 and data is Array:
		credenciales_recientes = data.duplicate(true)
		_limpiar_paneles_flotantes()
		titulo_flotante.text = "ALUMNOS IMPORTADOS DEL CSV"
		vbox_generacion.visible = true
		panel_flotante.visible = true
		text_resultado.text = "CREDENCIALES IMPORTADAS (¡guárdalas!):\n"
		text_resultado.text += "==========================================\n\n"
		for item in data:
			text_resultado.text += "USER: %-15s | PASS: %s\n" % [item.get("usuario"), item.get("password")]
		btn_exportar_csv.visible = data.size() > 0
		Notificador.notificar("CSV importado: %d alumnos" % data.size(), Color.GREEN)
		_cargar_aulas()
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

# ------- Exportar credenciales -------

func _on_pulsar_exportar_csv():
	if credenciales_recientes.is_empty():
		Notificador.notificar("No hay credenciales que exportar", Color.ORANGE)
		return
	dialogo_exportar.popup_centered_ratio(0.6)

func _on_destino_exportar_seleccionado(path: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		Notificador.notificar("No se pudo escribir el archivo", Color.RED)
		return
	file.store_line("usuario,password")
	for item in credenciales_recientes:
		file.store_line("%s,%s" % [str(item.get("usuario", "")), str(item.get("password", ""))])
	file.close()
	Notificador.notificar("Credenciales guardadas en %s" % path.get_file(), Color.GREEN)

# ------- Ranking del aula -------

func _on_revisar_puntuaciones():
	if aulas_data.is_empty() or cmb_aulas.selected < 0:
		Notificador.notificar("Selecciona un aula primero", Color.ORANGE)
		return

	_limpiar_paneles_flotantes()
	titulo_flotante.text = "RANKING DEL AULA"
	tree_puntuaciones.visible = true
	panel_flotante.visible = true

	var aula_id = GameManager.id_str(aulas_data[cmb_aulas.selected].get("id"))
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
		if not agregados.has(nombre):
			agregados[nombre] = {"puntos": 0, "nivel": int(p.get("nivelActual", 0))}
		agregados[nombre]["puntos"] += int(p.get("puntosObtenidos", 0))
		agregados[nombre]["nivel"] = int(p.get("nivelActual", agregados[nombre]["nivel"]))

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
	btn_exportar_csv.visible = false

func _cerrar_panel_flotante():
	panel_flotante.visible = false

func _on_nueva_entrega():
	get_tree().change_scene_to_file("res://Pantallas/nueva_entrega.tscn")

func _on_corregir_pendientes():
	get_tree().change_scene_to_file("res://Pantallas/corregir_pendientes.tscn")

func _on_cerrar_sesion():
	GameManager.cerrar_sesion()
