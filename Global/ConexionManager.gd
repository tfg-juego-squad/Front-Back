extends Node

const BASE_URL = "http://localhost:8080/tfg"
const TIMEOUT_SEGUNDOS = 15.0

func _construir_headers(json: bool = false) -> PackedStringArray:
	var headers: Array = []
	if json:
		headers.append("Content-Type: application/json")
	if not GameManager.token.is_empty():
		headers.append("Authorization: Bearer %s" % GameManager.token)
	return PackedStringArray(headers)

func _crear_http() -> HTTPRequest:
	var http = HTTPRequest.new()
	http.timeout = TIMEOUT_SEGUNDOS
	add_child(http)
	return http

func _manejar_auth_error(response_code: int) -> bool:
	if response_code == 401 or response_code == 403:
		GameManager.cerrar_sesion("Sesión expirada")
		return true
	return false

# Parsea el body como JSON, pero devuelve null silenciosamente si está vacío
# o no es JSON válido. Antes el parser escupía "Unknown error getting token"
# en consola por cada respuesta 204 / 200-sin-cuerpo / error sin payload.
func _parse_body_json(texto: String):
	if texto.strip_edges().is_empty():
		return null
	return JSON.parse_string(texto)

func peticion_get(endpoint: String, callback: Callable):
	var http = _crear_http()
	http.request_completed.connect(func(_result, response_code, _headers, body):
		var json_texto = body.get_string_from_utf8()
		print("[DEBUG] GET %s (Code %d): %s" % [endpoint, response_code, json_texto])
		var json_data = _parse_body_json(json_texto)
		http.queue_free()
		if _manejar_auth_error(response_code):
			return
		# Si el callback apuntaba a un nodo ya liberado (p.ej. la escena cambió
		# mientras esta petición estaba en vuelo) lo dejamos pasar en silencio.
		if callback.is_valid():
			callback.call(json_data, response_code)
	)
	if http.request(BASE_URL + endpoint, _construir_headers(false)) != OK:
		http.queue_free()

func peticion_post(endpoint: String, data: Dictionary, callback: Callable):
	_peticion_con_body(HTTPClient.METHOD_POST, endpoint, data, callback)

func peticion_put(endpoint: String, data: Dictionary, callback: Callable):
	_peticion_con_body(HTTPClient.METHOD_PUT, endpoint, data, callback)

func peticion_delete(endpoint: String, callback: Callable):
	var http = _crear_http()
	http.request_completed.connect(func(_result, response_code, _headers, body):
		var json_texto = body.get_string_from_utf8()
		print("[DEBUG] DELETE %s (Code %d): %s" % [endpoint, response_code, json_texto])
		var json_data = _parse_body_json(json_texto)
		http.queue_free()
		if _manejar_auth_error(response_code):
			return
		# Si el callback apuntaba a un nodo ya liberado (p.ej. la escena cambió
		# mientras esta petición estaba en vuelo) lo dejamos pasar en silencio.
		if callback.is_valid():
			callback.call(json_data, response_code)
	)
	if http.request(BASE_URL + endpoint, _construir_headers(false), HTTPClient.METHOD_DELETE) != OK:
		http.queue_free()

func _peticion_con_body(method: int, endpoint: String, data: Dictionary, callback: Callable):
	var http = _crear_http()
	http.request_completed.connect(func(_result, response_code, _headers, body):
		var json_texto = body.get_string_from_utf8()
		print("[DEBUG] %s %s (Code %d): %s" % [_nombre_metodo(method), endpoint, response_code, json_texto])
		var json_data = _parse_body_json(json_texto)
		http.queue_free()
		if _manejar_auth_error(response_code):
			return
		# Si el callback apuntaba a un nodo ya liberado (p.ej. la escena cambió
		# mientras esta petición estaba en vuelo) lo dejamos pasar en silencio.
		if callback.is_valid():
			callback.call(json_data, response_code)
	)
	var error = http.request(
		BASE_URL + endpoint,
		_construir_headers(true),
		method,
		JSON.stringify(data)
	)
	if error != OK:
		http.queue_free()

# Sube un archivo como multipart/form-data al endpoint indicado.
func peticion_multipart(endpoint: String, nombre_campo: String, ruta_local: String, callback: Callable):
	var file = FileAccess.open(ruta_local, FileAccess.READ)
	if file == null:
		callback.call({"message": "No se pudo abrir el archivo"}, 0)
		return
	var contenido = file.get_buffer(file.get_length())
	file.close()
	var nombre_archivo = ruta_local.get_file()

	var boundary = "----GodotFormBoundary%d" % Time.get_ticks_msec()
	var cuerpo = PackedByteArray()
	cuerpo.append_array(("--%s\r\n" % boundary).to_utf8_buffer())
	cuerpo.append_array((
		"Content-Disposition: form-data; name=\"%s\"; filename=\"%s\"\r\n" % [nombre_campo, nombre_archivo]
	).to_utf8_buffer())
	cuerpo.append_array("Content-Type: text/csv\r\n\r\n".to_utf8_buffer())
	cuerpo.append_array(contenido)
	cuerpo.append_array(("\r\n--%s--\r\n" % boundary).to_utf8_buffer())

	var headers = ["Content-Type: multipart/form-data; boundary=%s" % boundary]
	if not GameManager.token.is_empty():
		headers.append("Authorization: Bearer %s" % GameManager.token)

	var http = _crear_http()
	http.request_completed.connect(func(_result, response_code, _headers, body):
		var json_texto = body.get_string_from_utf8()
		print("[DEBUG] UPLOAD %s (Code %d): %s" % [endpoint, response_code, json_texto])
		var json_data = _parse_body_json(json_texto)
		http.queue_free()
		if _manejar_auth_error(response_code):
			return
		# Si el callback apuntaba a un nodo ya liberado (p.ej. la escena cambió
		# mientras esta petición estaba en vuelo) lo dejamos pasar en silencio.
		if callback.is_valid():
			callback.call(json_data, response_code)
	)
	var err = http.request_raw(
		BASE_URL + endpoint,
		PackedStringArray(headers),
		HTTPClient.METHOD_POST,
		cuerpo
	)
	if err != OK:
		http.queue_free()

func _nombre_metodo(method: int) -> String:
	match method:
		HTTPClient.METHOD_POST: return "POST"
		HTTPClient.METHOD_PUT: return "PUT"
		HTTPClient.METHOD_DELETE: return "DELETE"
		_: return "GET"

# Helper: extrae el mensaje de error del backend con fallback.
func mensaje_error(data, code: int) -> String:
	if typeof(data) == TYPE_DICTIONARY and data.has("message"):
		return str(data["message"])
	return "Error %d" % code
