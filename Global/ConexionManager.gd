extends Node

const BASE_URL = "http://localhost:8081/tfg"

func peticion_get(endpoint: String, callback: Callable):
	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(_result, response_code, _headers, body):
		var json_texto = body.get_string_from_utf8()
		print("[DEBUG] Respuesta GET (Code %d): %s" % [response_code, json_texto])
		var json_data = JSON.parse_string(json_texto)
		callback.call(json_data, response_code)
		http.queue_free()
	)

	if http.request(BASE_URL + endpoint) != OK:
		http.queue_free()

func peticion_post(endpoint: String, data: Dictionary, callback: Callable):
	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(func(_result, response_code, _headers, body):
		var json_texto = body.get_string_from_utf8()
		print("[DEBUG] Respuesta POST (Code %d): %s" % [response_code, json_texto])
		var json_data = JSON.parse_string(json_texto)
		callback.call(json_data, response_code)
		http.queue_free()
	)

	var error = http.request(
		BASE_URL + endpoint,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(data)
	)
	if error != OK:
		http.queue_free()
