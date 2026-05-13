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

# --- Gestión de alumno ---
@onready var scroll_gestion = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion
@onready var lbl_gestion_titulo = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/LblGestionTitulo
@onready var edit_usuario = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/GridDatos/EditUsuario
@onready var edit_nombre = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/GridDatos/EditNombre
@onready var edit_apellidos = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/GridDatos/EditApellidos
@onready var edit_email = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/GridDatos/EditEmail
@onready var edit_password = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/GridDatos/EditPassword
@onready var btn_guardar_alumno = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HBoxAccionesAlumno/BtnGuardarAlumno
@onready var btn_borrar_alumno = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HBoxAccionesAlumno/BtnBorrarAlumno
@onready var puntos_nota_spin = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HBoxNotaManual/PuntosNotaSpin
@onready var edit_motivo_nota = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HBoxNotaManual/EditMotivoNota
@onready var btn_anadir_nota = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HBoxNotaManual/BtnAnadirNota
@onready var historial_notas = $PanelFlotante/MargenFlotante/VBoxFlotante/ScrollGestion/VBoxGestionAlumno/HistorialNotas

var aulas_data: Array = []
var alumnos_data: Array = []
var alumno_seleccionado: Dictionary = {}
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

	lista_alumnos.item_activated.connect(_on_alumno_activado)
	btn_guardar_alumno.pressed.connect(_on_guardar_alumno)
	btn_borrar_alumno.pressed.connect(_on_borrar_alumno)
	btn_anadir_nota.pressed.connect(_on_anadir_nota_manual)

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
	alumnos_data.clear()
	if code == 200 and data is Array:
		if data.size() == 0:
			lista_alumnos.add_item("(Aula vacía)")
		else:
			alumnos_data = data
			for i in range(data.size()):
				var alu = data[i]
				var nombre = alu.get("nombreUsuario", alu.get("usuario", "Anónimo"))
				var nivel = alu.get("nivelActual", null)
				var sufijo = "  ·  Nv %s" % str(nivel) if nivel != null else ""
				var idx = lista_alumnos.add_item("%s%s" % [nombre, sufijo])
				lista_alumnos.set_item_metadata(idx, alu)
				lista_alumnos.set_item_tooltip(idx, "Doble clic para editar / añadir nota")
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
	btn_exportar_csv.visible = false
	scroll_gestion.visible = false

func _cerrar_panel_flotante():
	panel_flotante.visible = false

func _on_nueva_entrega():
	get_tree().change_scene_to_file("res://Pantallas/nueva_entrega.tscn")

func _on_corregir_pendientes():
	get_tree().change_scene_to_file("res://Pantallas/corregir_pendientes.tscn")

func _on_cerrar_sesion():
	GameManager.cerrar_sesion()

# =====================================================================
# GESTIÓN DE ALUMNO (edición + nota manual)
# =====================================================================

func _on_alumno_activado(index: int):
	var meta = lista_alumnos.get_item_metadata(index)
	if typeof(meta) != TYPE_DICTIONARY:
		return
	_abrir_gestion_alumno(meta)

func _abrir_gestion_alumno(alu: Dictionary):
	alumno_seleccionado = alu
	_limpiar_paneles_flotantes()
	titulo_flotante.text = "ALUMNO · %s" % str(alu.get("nombreUsuario", "—"))
	lbl_gestion_titulo.text = "Datos del alumno (id %s)" % GameManager.id_str(alu.get("id"))
	edit_usuario.text = str(alu.get("nombreUsuario", ""))
	edit_nombre.text = str(alu.get("nombreReal", ""))
	edit_apellidos.text = str(alu.get("apellidos", ""))
	edit_email.text = str(alu.get("email", ""))
	edit_password.text = ""
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
	if payload.is_empty():
		Notificador.notificar("No hay cambios que guardar", Color.GOLD)
		return
	Notificador.notificar("Guardando cambios del alumno...", Color.CYAN)
	ConexionManager.peticion_put("/usuarios/%s" % alumno_id, payload, _on_alumno_guardado)

func _on_alumno_guardado(data, code):
	if code == 200 and typeof(data) == TYPE_DICTIONARY:
		Notificador.notificar("Alumno actualizado", Color.GREEN)
		alumno_seleccionado = data
		_on_aula_seleccionada(cmb_aulas.selected)
		# Reflejar los nuevos datos en el panel
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
		_on_aula_seleccionada(cmb_aulas.selected)
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
	# Reutilizamos el endpoint del aula y filtramos por alumno en cliente.
	var alumno_id = GameManager.id_int(alu.get("id"))
	ConexionManager.peticion_get(
		"/puntuacion/aula/%s" % GameManager.aula_seleccionada_id,
		_on_historial_notas.bind(alumno_id)
	)

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
