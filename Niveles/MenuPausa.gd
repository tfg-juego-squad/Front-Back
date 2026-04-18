extends CanvasLayer

@onready var btn_continuar = $Center/Panel/Margen/VBox/BtnContinuar
@onready var btn_menu = $Center/Panel/Margen/VBox/BtnMenuPrincipal
@onready var btn_salir = $Center/Panel/Margen/VBox/BtnSalir

func _ready():
	# Inicialmente oculto
	visible = false
	
	# Conectar señales
	btn_continuar.pressed.connect(_on_continuar)
	btn_menu.pressed.connect(_on_menu_principal)
	btn_salir.pressed.connect(_on_salir)

func toggle_pausa():
	visible = !visible
	get_tree().paused = visible
	
	if visible:
		# Asegurar que el mouse sea visible
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_continuar():
	toggle_pausa()

func _on_menu_principal():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Pantallas/login.tscn")

func _on_salir():
	get_tree().quit()
