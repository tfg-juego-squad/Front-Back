extends Control

# Pantalla simple para mostrar el texto que un NPC parlante (tipo=DIALOGO)
# tiene asignado por el profesor. Pulsa Salir / cualquier tecla / clic
# para volver al mapa.

@onready var lbl_titulo = $Layout/Header/HBox/LblTitulo
@onready var lbl_texto = $Layout/Centro/PanelTexto/MargenTexto/LblTexto
@onready var btn_salir = $Layout/Header/HBox/BtnSalir

func _ready():
	btn_salir.pressed.connect(_volver)
	# Datos persistidos por pruebas_pendientes / NpcManager al entrar.
	var prueba = GameManager.dialogo_pendiente
	if prueba.is_empty():
		lbl_titulo.text = "NPC dice..."
		lbl_texto.text = "(No hay texto que mostrar)"
	else:
		lbl_titulo.text = "%s · NPC" % str(prueba.get("titulo", "Mensaje"))
		var texto = str(prueba.get("texto", ""))
		lbl_texto.text = texto if not texto.is_empty() else "(El profesor no ha escrito texto todavía)"
	GameManager.dialogo_pendiente = {}

func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		_volver()
	elif event is InputEventMouseButton and event.pressed:
		_volver()

func _volver():
	NpcManager.reset_npc_activo()
	get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
