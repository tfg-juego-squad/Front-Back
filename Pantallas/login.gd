extends Control

# Referencias a nodos de la UI
@onready var usuario_input = $CenterContainer/Panel/Margen/VBox/UsuarioInput
@onready var contrasena_input = $CenterContainer/Panel/Margen/VBox/ContrasenaInput
@onready var login_button = $CenterContainer/Panel/Margen/VBox/LoginButton
@onready var mensaje_error = $CenterContainer/Panel/Margen/VBox/MensajeError
@onready var http_request = $HTTPRequest

func _ready():
	login_button.pressed.connect(_on_login_pressed)
	# Enter key también hace login
	contrasena_input.text_submitted.connect(func(_text): _on_login_pressed())
	
	http_request.request_completed.connect(_on_http_request_completed)

func _on_login_pressed():
	var usuario = usuario_input.text.strip_edges()
	var contrasena = contrasena_input.text.strip_edges()
	
	# Validación básica
	if usuario.is_empty() or contrasena.is_empty():
		Notificador.notificar("Rellena todos los campos", Color.MAGENTA)
		return
	
	var body = JSON.stringify({
		"usuario": usuario,
		"password": contrasena
	})
	
	var headers = ["Content-Type: application/json"]
	var url = "http://localhost:8081/tfg/usuarios/login"
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		Notificador.notificar("Error al iniciar la petición HTTP", Color.ORANGE)
	else:
		Notificador.notificar("Autenticando...", Color.CYAN)

func _on_http_request_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		Notificador.notificar("Error de red", Color.ORANGE)
		return

	var json = JSON.new()
	var parse_err = json.parse(body.get_string_from_utf8())
	
	if response_code == 200:
		if parse_err == OK:
			var datos_usuario = json.get_data()
			# Llamada al Autoload para procesar roles [cite: 165, 171]
			GameManager.guardar_sesion(datos_usuario)
			
			if GameManager.es_profesor:
				get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
			else:
				get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
	elif response_code == 401:
		Notificador.notificar("Usuario o clave incorrectos", Color.MAGENTA)
	else:
		Notificador.notificar("Error servidor: " + str(response_code), Color.ORANGE)
