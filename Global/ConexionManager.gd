extends Node

const BASE_URL = "http://localhost:8080/tfg"

func _construir_headers(json: bool = false) -> PackedStringArray:
	var headers: Array = []
	if json:
		headers.append("Content-Type: application/json")
	if not GameManager.token.is_empty():
		headers.append("Authorization: Bearer %s" % GameManager.token)
	return PackedStringArray(headers)

func _manejar_auth_error(response_code: int) -> bool:
	if response_code == 401 or response_code == 403:
		GameManager.cerrar_sesion("Sesión expirada")
		return true
	return false

func peticion_get(endpoint: String, callback: Callable):
	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(_result, response_code, _headers, body):
		var json_texto = body.get_string_from_utf8()
		print("[DEBUG] GET %s (Code %d): %s" % [endpoint, response_code, json_texto])
		var json_data = JSON.parse_string(json_texto)
		http.queue_free()
		if _manejar_auth_error(response_code):
			return
		callback.call(json_data, response_code)
	)

	if http.request(BASE_URL + endpoint, _construir_headers(false)) != OK:
		http.queue_free()

func peticion_post(endpoint: String, data: Dictionary, callback: Callable):
	_peticion_con_body(HTTPClient.METHOD_POST, endpoint, data, callback)

func peticion_put(endpoint: String, data: Dictionary, callback: Callable):
	_peticion_con_body(HTTPClient.METHOD_PUT, endpoint, data, callback)

func peticion_delete(endpoint: String, callback: Callable):
	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(_result, response_code, _headers, body):
		var json_texto = body.get_string_from_utf8()
		print("[DEBUG] DELETE %s (Code %d): %s" % [endpoint, response_code, json_texto])
		var json_data = JSON.parse_string(json_texto)
		http.queue_free()
		if _manejar_auth_error(response_code):
			return
		callback.call(json_data, response_code)
	)

	if http.request(BASE_URL + endpoint, _construir_headers(false), HTTPClient.METHOD_DELETE) != OK:
		http.queue_free()

func _peticion_con_body(method: int, endpoint: String, data: Dictionary, callback: Callable):
	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(_result, response_code, _headers, body):
		var json_texto = body.get_string_from_utf8()
		print("[DEBUG] %s %s (Code %d): %s" % [_nombre_metodo(method), endpoint, response_code, json_texto])
		var json_data = JSON.parse_string(json_texto)
		http.queue_free()
		if _manejar_auth_error(response_code):
			return
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
