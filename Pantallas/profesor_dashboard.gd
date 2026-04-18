extends Control

# --- Referencias UI (rutas corregidas al layout de la escena) ---
@onready var lista_alumnos = $Layout/MainContent/PanelAlumnos/MargenAlumnos/VBoxAlumnos/ListaAlumnos
@onready var btn_nueva_entrega = $Layout/MainContent/PanelBotones/VBoxBotones/BtnNuevaEntrega
@onready var btn_revisar = $Layout/MainContent/PanelBotones/VBoxBotones/BtnRevisar
@onready var btn_ajustes = $Layout/MainContent/PanelBotones/VBoxBotones/BtnAjustes
@onready var btn_cerrar_sesion = $Layout/Header/HBoxHeader/BtnCerrarSesion
@onready var panel_flotante = $PanelFlotante
@onready var btn_cerrar_flotante = $PanelFlotante/MargenFlotante/VBoxFlotante/HeaderFlotante/BtnCerrarFlotante
@onready var contenido_flotante = $PanelFlotante/MargenFlotante/VBoxFlotante/ContenidoFlotante

func _ready():
	# Conectar botones
	btn_nueva_entrega.pressed.connect(_on_nueva_entrega)
	btn_revisar.pressed.connect(_on_revisar_entregas)
	btn_ajustes.pressed.connect(_on_ajustes_alumnado)
	btn_cerrar_sesion.pressed.connect(_on_cerrar_sesion)
	btn_cerrar_flotante.pressed.connect(_cerrar_panel_flotante)
	
	# Panel flotante oculto al inicio
	panel_flotante.visible = false
	
	# Cargar lista de alumnos (placeholder)
	_cargar_alumnos_placeholder()

# --- Lista de alumnos (placeholder sin datos reales aun) ---
func _cargar_alumnos_placeholder():
	lista_alumnos.clear()
	for i in range(8):
		lista_alumnos.add_item("Alumno %d" % (i + 1))
		lista_alumnos.set_item_disabled(i, true)
		lista_alumnos.set_item_selectable(i, false)

# --- Boton: Nueva Entrega -> Abre pantalla completa ---
func _on_nueva_entrega():
	get_tree().change_scene_to_file("res://Pantallas/nueva_entrega.tscn")

# --- Boton: Revisar Entregas -> Abre panel flotante fijo ---
func _on_revisar_entregas():
	contenido_flotante.text = _generar_texto_entregas()
	panel_flotante.visible = true

func _generar_texto_entregas() -> String:
	# TODO: Cargar entregas reales desde backend (GET /tfg/prueba)
	var texto = "=== ENTREGAS PENDIENTES DE REVISION ===\n\n"
	texto += "Entrega 1 - Matematicas Tema 3\n"
	texto += "   Estado: Pendiente | Alumnos entregados: 5/12\n\n"
	texto += "Entrega 2 - Lengua Tema 5\n"
	texto += "   Estado: En revision | Alumnos entregados: 10/12\n\n"
	texto += "Entrega 3 - Ciencias Tema 2\n"
	texto += "   Estado: Corregida | Alumnos entregados: 12/12\n\n"
	texto += "(Datos de ejemplo - se conectara con el backend)"
	return texto

# --- Boton: Ajustes Alumnado -> Panel flotante con opciones ---
func _on_ajustes_alumnado():
	Notificador.notificar("Accediendo a gestión de grupo", Color.GOLDENROD)
	contenido_flotante.text = _generar_texto_ajustes()
	panel_flotante.visible = true

func _generar_texto_ajustes() -> String:
	var texto = "=== AJUSTES DEL ALUMNADO ===\n\n"
	texto += "Gestion de alumnos:\n"
	texto += "   - Anadir nuevo alumno\n"
	texto += "   - Eliminar alumno\n"
	texto += "   - Modificar datos\n\n"
	texto += "Configuracion de grupo:\n"
	texto += "   - Asignar roles\n"
	texto += "   - Configurar permisos\n\n"
	texto += "(Funcionalidad en desarrollo)"
	return texto

# --- Cerrar panel flotante ---
func _cerrar_panel_flotante():
	panel_flotante.visible = false

# --- Cerrar sesion ---
func _on_cerrar_sesion():
	get_tree().change_scene_to_file("res://Pantallas/login.tscn")
