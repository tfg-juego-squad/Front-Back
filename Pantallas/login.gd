extends Control

@onready var usuario_input = $CenterContainer/Panel/Margen/VBox/UsuarioInput
@onready var contrasena_input = $CenterContainer/Panel/Margen/VBox/ContrasenaInput
@onready var login_button = $CenterContainer/Panel/Margen/VBox/LoginButton
@onready var btn_registrar = $CenterContainer/Panel/Margen/VBox/BtnRegistrar

func _ready():
	login_button.pressed.connect(_on_login_pressed)
	btn_registrar.pressed.connect(_on_registrar_pressed)
	contrasena_input.text_submitted.connect(func(_text): _on_login_pressed())

func _on_login_pressed():
	var usuario = usuario_input.text.strip_edges()
	var contrasena = contrasena_input.text.strip_edges()

	if usuario.is_empty() or contrasena.is_empty():
		Notificador.notificar("Rellena todos los campos", Color.MAGENTA)
		return

	var payload = {"nombreUsuario": usuario, "passwordPlana": contrasena}
	Notificador.notificar("Autenticando...", Color.CYAN)
	ConexionManager.peticion_post("/usuarios/login", payload, _on_login_response)

func _on_registrar_pressed():
	var usuario = usuario_input.text.strip_edges()
	var contrasena = contrasena_input.text.strip_edges()

	if usuario.length() < 3:
		Notificador.notificar("El usuario es muy corto", Color.ORANGE)
		return
	if contrasena.length() < 6:
		Notificador.notificar("La contraseña debe tener al menos 6 caracteres", Color.ORANGE)
		return

	# Nota: el backend requiere nombreReal/apellidos/email; faltan campos en la UI
	var payload = {
		"nombreUsuario": usuario,
		"passwordPlana": contrasena,
		"nombreReal": usuario,
		"apellidos": "(pendiente)",
		"email": "%s@pendiente.local" % usuario
	}
	Notificador.notificar("Registrando profesor...", Color.GOLD)
	ConexionManager.peticion_post("/usuarios/profesor/alta", payload, _on_registro_response)

func _on_registro_response(data, code):
	if code == 200 or code == 201:
		Notificador.notificar("Profesor registrado, ya puedes entrar", Color.GREEN)
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

func _on_login_response(data, code):
	if code == 200 and data != null:
		GameManager.guardar_sesion(data)
		if GameManager.token.is_empty():
			Notificador.notificar("Sesión sin token, revisa el backend", Color.ORANGE)
			return
		if GameManager.es_profesor:
			get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
		else:
			get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
	elif code == 401:
		Notificador.notificar("Usuario o clave incorrectos", Color.MAGENTA)
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.ORANGE)
