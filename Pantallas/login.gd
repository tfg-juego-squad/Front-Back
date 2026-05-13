extends Control

@onready var usuario_input = $CenterContainer/Panel/Margen/VBox/UsuarioInput
@onready var contrasena_input = $CenterContainer/Panel/Margen/VBox/ContrasenaInput
@onready var login_button = $CenterContainer/Panel/Margen/VBox/LoginButton
@onready var btn_registrar = $CenterContainer/Panel/Margen/VBox/BtnRegistrar
@onready var btn_cancelar = $CenterContainer/Panel/Margen/VBox/BtnCancelarRegistro
@onready var panel_registro = $CenterContainer/Panel/Margen/VBox/PanelRegistro
@onready var nombre_real_input = $CenterContainer/Panel/Margen/VBox/PanelRegistro/NombreRealInput
@onready var apellidos_input = $CenterContainer/Panel/Margen/VBox/PanelRegistro/ApellidosInput
@onready var email_input = $CenterContainer/Panel/Margen/VBox/PanelRegistro/EmailInput
@onready var subtitulo = $CenterContainer/Panel/Margen/VBox/Subtitulo

var modo_registro: bool = false

func _ready():
	login_button.pressed.connect(_on_boton_principal)
	btn_registrar.pressed.connect(_on_btn_registrar)
	btn_cancelar.pressed.connect(_set_modo_login)
	contrasena_input.text_submitted.connect(func(_text): _on_boton_principal())
	_set_modo_login()

func _set_modo_login():
	modo_registro = false
	panel_registro.visible = false
	btn_cancelar.visible = false
	btn_registrar.visible = true
	subtitulo.text = "Iniciar Sesión"
	login_button.text = "Entrar"

func _set_modo_registro():
	modo_registro = true
	panel_registro.visible = true
	btn_cancelar.visible = true
	btn_registrar.visible = false
	subtitulo.text = "Registro de Profesor"
	login_button.text = "Crear cuenta"

func _on_btn_registrar():
	_set_modo_registro()

func _on_boton_principal():
	if modo_registro:
		_enviar_registro()
	else:
		_enviar_login()

func _enviar_login():
	var usuario = usuario_input.text.strip_edges()
	var contrasena = contrasena_input.text.strip_edges()

	if usuario.is_empty() or contrasena.is_empty():
		Notificador.notificar("Rellena todos los campos", Color.MAGENTA)
		return

	login_button.disabled = true
	var payload = {"nombreUsuario": usuario, "passwordPlana": contrasena}
	Notificador.notificar("Autenticando...", Color.CYAN)
	ConexionManager.peticion_post("/usuarios/login", payload, _on_login_response)

func _enviar_registro():
	var usuario = usuario_input.text.strip_edges()
	var contrasena = contrasena_input.text.strip_edges()
	var nombre_real = nombre_real_input.text.strip_edges()
	var apellidos = apellidos_input.text.strip_edges()
	var email = email_input.text.strip_edges()

	if usuario.length() < 3:
		Notificador.notificar("El usuario debe tener al menos 3 caracteres", Color.ORANGE)
		return
	if contrasena.length() < 6:
		Notificador.notificar("La contraseña debe tener al menos 6 caracteres", Color.ORANGE)
		return
	if nombre_real.is_empty() or apellidos.is_empty():
		Notificador.notificar("Nombre y apellidos son obligatorios", Color.ORANGE)
		return
	if not _email_valido(email):
		Notificador.notificar("Email no válido", Color.ORANGE)
		return

	var payload = {
		"nombreUsuario": usuario,
		"passwordPlana": contrasena,
		"nombreReal": nombre_real,
		"apellidos": apellidos,
		"email": email
	}
	Notificador.notificar("Registrando profesor...", Color.GOLD)
	ConexionManager.peticion_post("/usuarios/profesor/alta", payload, _on_registro_response)

func _email_valido(email: String) -> bool:
	if email.is_empty():
		return false
	var at = email.find("@")
	var dot = email.rfind(".")
	return at > 0 and dot > at + 1 and dot < email.length() - 1

func _on_registro_response(data, code):
	if code == 200 or code == 201:
		Notificador.notificar("Profesor registrado, ya puedes entrar", Color.GREEN)
		_set_modo_login()
	else:
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)

func _on_login_response(data, code):
	if code == 200 and data != null:
		GameManager.guardar_sesion(data)
		if GameManager.token.is_empty():
			Notificador.notificar("Sesión sin token, revisa el backend", Color.ORANGE)
			login_button.disabled = false
			return
		if GameManager.es_profesor:
			get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
		else:
			# Alumno → pantalla de carga animada antes del mapa.
			get_tree().change_scene_to_file("res://Pantallas/pantalla_carga.tscn")
	elif code == 401:
		login_button.disabled = false
		Notificador.notificar("Usuario o clave incorrectos", Color.MAGENTA)
	else:
		login_button.disabled = false
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.ORANGE)
