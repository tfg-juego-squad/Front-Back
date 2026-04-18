extends Control

# --- Referencias UI ---
@onready var lista_alumnos = $Layout/MainContent/PanelAlumnos/MargenAlumnos/VBoxAlumnos/ListaAlumnos
@onready var cmb_aulas = $Layout/MainContent/PanelAlumnos/MargenAlumnos/VBoxAlumnos/HBoxAula/CmbAulas
@onready var btn_crear_aula = $Layout/MainContent/PanelAlumnos/MargenAlumnos/VBoxAlumnos/HBoxAula/BtnCrearAula

@onready var btn_nueva_entrega = $Layout/MainContent/PanelBotones/VBoxBotones/BtnNuevaEntrega
@onready var btn_revisar = $Layout/MainContent/PanelBotones/VBoxBotones/BtnRevisar
@onready var btn_ajustes = $Layout/MainContent/PanelBotones/VBoxBotones/BtnAjustes
@onready var btn_cerrar_sesion = $Layout/Header/HBoxHeader/BtnCerrarSesion

# Panel Flotante y sus sub-contenidos
@onready var panel_flotante = $PanelFlotante
@onready var titulo_flotante = $PanelFlotante/MargenFlotante/VBoxFlotante/HeaderFlotante/TituloFlotante
@onready var btn_cerrar_flotante = $PanelFlotante/MargenFlotante/VBoxFlotante/HeaderFlotante/BtnCerrarFlotante
@onready var contenido_texto = $PanelFlotante/MargenFlotante/VBoxFlotante/ContenidoFlotante
@onready var tree_puntuaciones = $PanelFlotante/MargenFlotante/VBoxFlotante/TreePuntuaciones
@onready var vbox_generacion = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxGeneracion

# Nodos de Generación
@onready var edit_nombre_aula = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxGeneracion/EditNombreAula
@onready var spin_alumnos = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxGeneracion/SpinAlumnos
@onready var btn_confirmar_generar = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxGeneracion/BtnConfirmarGenerar
@onready var text_resultado = $PanelFlotante/MargenFlotante/VBoxFlotante/VBoxGeneracion/TextResultado

var aulas_data = []

func _ready():
	# Conectar botones principales
	btn_nueva_entrega.pressed.connect(_on_nueva_entrega)
	btn_revisar.pressed.connect(_on_revisar_puntuaciones)
	btn_ajustes.pressed.connect(_on_abrir_generacion)
	btn_cerrar_sesion.pressed.connect(_on_cerrar_sesion)
	btn_cerrar_flotante.pressed.connect(_cerrar_panel_flotante)
	
	# Conectar gestión de aulas
	btn_crear_aula.pressed.connect(_on_abrir_generacion)
	cmb_aulas.item_selected.connect(_on_aula_seleccionada)
	
	# Conectar generación masiva
	btn_confirmar_generar.pressed.connect(_on_iniciar_proceso_generacion)
	
	panel_flotante.visible = false
	
	# Configurar Tree de puntuaciones
	tree_puntuaciones.set_column_title(0, "Alumno")
	tree_puntuaciones.set_column_title(1, "Prueba")
	tree_puntuaciones.set_column_title(2, "Nota")
	tree_puntuaciones.set_column_title(3, "Max")
	
	# Cargar datos iniciales
	_cargar_aulas()

# --- GESTION DE AULAS ---

func _cargar_aulas():
	var prof_id = GameManager.usuario_actual.get("id", "")
	# Corregido: Endpoint real del backend Java
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
		Notificador.notificar("No hay aulas disponibles", Color.ORANGE)

func _on_aula_seleccionada(index):
	if aulas_data.is_empty(): return
	var aula_id = aulas_data[index].get("id", "")
	lista_alumnos.clear()
	lista_alumnos.add_item("Cargando alumnos...")
	# Corregido: Endpoint real del backend Java
	ConexionManager.peticion_get("/aulas/%s/alumnos" % aula_id, _on_alumnos_recibidos)

func _on_alumnos_recibidos(data, code):
	lista_alumnos.clear()
	if code == 200 and data is Array:
		if data.size() == 0:
			lista_alumnos.add_item("(Aula vacia)")
		else:
			for alu in data:
				var nombre = alu.get("nombreUsuario", alu.get("usuario", "Anonimo"))
				lista_alumnos.add_item(nombre)
	else:
		lista_alumnos.add_item("Sin alumnos")

# --- GENERACION MASIVA ---

func _on_abrir_generacion():
	_limpiar_paneles_flotantes()
	titulo_flotante.text = "CREAR AULA Y GENERAR ALUMNOS"
	vbox_generacion.visible = true
	panel_flotante.visible = true
	text_resultado.text = ""

func _on_iniciar_proceso_generacion():
	var nombre = edit_nombre_aula.text.strip_edges()
	if nombre.is_empty():
		Notificador.notificar("Nombre de aula requerido", Color.MAGENTA)
		return
	
	Notificador.notificar("1/2: Creando aula...", Color.CYAN)
	
	var prof_id = GameManager.usuario_actual.get("id", "")
	print("[DEBUG] Intentando crear aula con ProfID: ", prof_id)
	
	# Endpoint: /aulas/crear?nombreAula=...&profesorId=...
	var url = "/aulas/crear?nombreAula=%s&profesorId=%s" % [nombre.uri_encode(), prof_id]
	ConexionManager.peticion_post(url, {}, _on_aula_creada_exito)

func _on_aula_creada_exito(data, code):
	if code == 200 and data != null:
		var nueva_aula_id = data.get("id", "")
		var cant = int(spin_alumnos.value)
		
		Notificador.notificar("2/2: Generando credenciales...", Color.GOLD)
		# Endpoint: /aulas/{id}/generar-alumnos?cantidad=...
		var url = "/aulas/%s/generar-alumnos?cantidad=%d" % [nueva_aula_id, cant]
		ConexionManager.peticion_post(url, {}, _on_generacion_completada)
	else:
		Notificador.notificar("Fallo al crear el aula (Error %d)" % code, Color.RED)

func _on_generacion_completada(data, code):
	if code == 200 and data is Array:
		text_resultado.text = "CREDENCIALES PARA LOS ALUMNOS:\n"
		text_resultado.text += "==============================\n\n"
		
		for item in data:
			text_resultado.text += "USER: %-15s | PASS: %s\n" % [item.get("usuario"), item.get("password")]
		
		Notificador.notificar("¡Proceso completado!", Color.GREEN)
		_cargar_aulas() # Refrescar lista de aulas
	else:
		Notificador.notificar("Error al generar alumnos: %d" % code, Color.RED)

# --- REVISION DE PUNTUACIONES ---

func _on_revisar_puntuaciones():
	if aulas_data.is_empty() or cmb_aulas.selected < 0:
		Notificador.notificar("Selecciona un aula primero", Color.ORANGE)
		return
		
	_limpiar_paneles_flotantes()
	titulo_flotante.text = "REVISION DE PUNTUACIONES"
	tree_puntuaciones.visible = true
	panel_flotante.visible = true
	
	var aula_id = aulas_data[cmb_aulas.selected].get("id", "")
	# Corregido: Endpoint real
	ConexionManager.peticion_get("/puntuaciones/aula/%s" % aula_id, _on_puntuaciones_recibidas)

func _on_puntuaciones_recibidas(data, code):
	tree_puntuaciones.clear()
	var root = tree_puntuaciones.create_item()
	
	if code == 200 and data is Array:
		for p in data:
			var item = tree_puntuaciones.create_item(root)
			item.set_text(0, str(p.get("estudianteNombre", "Alumno")))
			item.set_text(1, str(p.get("pruebaNombre", "Tarea")))
			item.set_text(2, str(p.get("puntos", 0)))
			item.set_text(3, str(p.get("maxPuntos", 10)))
	else:
		var item = tree_puntuaciones.create_item(root)
		item.set_text(0, "Sin datos de puntuaciones")

# --- UTILIDADES ---

func _limpiar_paneles_flotantes():
	contenido_texto.visible = false
	tree_puntuaciones.visible = false
	vbox_generacion.visible = false

func _cerrar_panel_flotante():
	panel_flotante.visible = false

func _on_nueva_entrega():
	get_tree().change_scene_to_file("res://Pantallas/nueva_entrega.tscn")

func _on_cerrar_sesion():
	get_tree().change_scene_to_file("res://Pantallas/login.tscn")
