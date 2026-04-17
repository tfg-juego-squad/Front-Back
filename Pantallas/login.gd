extends Control

# Referencias a nodos de la UI
@onready var usuario_input = $CenterContainer/Panel/Margen/VBox/UsuarioInput
@onready var contrasena_input = $CenterContainer/Panel/Margen/VBox/ContrasenaInput
@onready var login_button = $CenterContainer/Panel/Margen/VBox/LoginButton
@onready var mensaje_error = $CenterContainer/Panel/Margen/VBox/MensajeError

func _ready():
	login_button.pressed.connect(_on_login_pressed)
	# Enter key también hace login
	contrasena_input.text_submitted.connect(func(_text): _on_login_pressed())

func _on_login_pressed():
	var usuario = usuario_input.text.strip_edges()
	var contrasena = contrasena_input.text.strip_edges()
	
	# Validación básica
	if usuario.is_empty() or contrasena.is_empty():
		Notificador.notificar("Rellena todos los campos", Color.MAGENTA)
		return
	
	Notificador.notificar("Autenticando usuario...", Color.CYAN)
	
	# TODO: Conectar con el backend real (GET /tfg/usuarios/nombre/{nombre})
	# Por ahora simulamos el login
	_simular_login(usuario, contrasena)

func _simular_login(usuario: String, _contrasena: String):
	await get_tree().create_timer(1.0).timeout
	
	if usuario.to_lower().find("profe") != -1 or usuario.to_lower() == "admin":
		get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
	else:
		get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
