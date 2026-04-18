extends Control

# Referencias a nodos de la UI
@onready var usuario_input = $CenterContainer/Panel/Margen/VBox/UsuarioInput
@onready var contrasena_input = $CenterContainer/Panel/Margen/VBox/ContrasenaInput
@onready var login_button = $CenterContainer/Panel/Margen/VBox/LoginButton
@onready var btn_registrar = $CenterContainer/Panel/Margen/VBox/BtnRegistrar

func _ready():
	login_button.pressed.connect(_on_login_pressed)
	btn_registrar.pressed.connect(_on_registrar_pressed)
	# Enter key también hace login
	contrasena_input.text_submitted.connect(func(_text): _on_login_pressed())

func _on_login_pressed():
	var usuario = usuario_input.text.strip_edges()
	var contrasena = contrasena_input.text.strip_edges()
	
	if usuario.is_empty() or contrasena.is_empty():
		Notificador.notificar("Rellena todos los campos", Color.MAGENTA)
		return
	
	var payload = {
		"usuario": usuario,
		"password": contrasena
	}
	
	Notificador.notificar("Autenticando...", Color.CYAN)
	ConexionManager.peticion_post("/usuarios/login", payload, _on_login_response)

func _on_registrar_pressed():
	var usuario = usuario_input.text.strip_edges()
	var contrasena = contrasena_input.text.strip_edges()
	
	if usuario.length() < 3:
		Notificador.notificar("El usuario es muy corto", Color.ORANGE)
		return
	
	# El backend espera un objeto Usuario con: nombreUsuario y hashContrasena (que luego hashea)
	var payload = {
		"nombreUsuario": usuario,
		"hashContrasena": contrasena
	}
	
	Notificador.notificar("Registrando profesor...", Color.GOLD)
	ConexionManager.peticion_post("/usuarios/profesor/alta", payload, _on_registro_response)

func _on_registro_response(data, code):
	if code == 200:
		Notificador.notificar("¡Profesor registrado! Ya puedes entrar", Color.GREEN)
	else:
		Notificador.notificar("Error al registrar: " + str(code), Color.RED)

func _on_login_response(data, code):
	if code == 200:
		if data != null:
			GameManager.guardar_sesion(data)
			if GameManager.es_profesor:
				get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
			else:
				get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
	elif code == 401:
		Notificador.notificar("Usuario o clave incorrectos", Color.MAGENTA)
	else:
		Notificador.notificar("Error servidor: " + str(code), Color.ORANGE)
