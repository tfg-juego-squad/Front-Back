extends Control

@onready var titulo = $Centro/Panel/Margen/VBox/Titulo
@onready var progreso = $Centro/Panel/Margen/VBox/Progreso
@onready var enunciado = $Centro/Panel/Margen/VBox/Enunciado
@onready var opciones_test = $Centro/Panel/Margen/VBox/OpcionesTest
@onready var respuesta_desarrollo = $Centro/Panel/Margen/VBox/RespuestaDesarrollo
@onready var btn_enviar = $Centro/Panel/Margen/VBox/HBoxBotones/BtnEnviar
@onready var btn_abandonar = $Centro/Panel/Margen/VBox/HBoxBotones/BtnAbandonar

const TIPO_TEST = "TEST"
const TIPO_DESARROLLO = "DESARROLLO"

var prueba_id: int = -1
var prueba_titulo: String = ""
var preguntas: Array = []
var indice_actual: int = 0
var respuesta_elegida_id: int = -1
var pregunta_iniciada_en: float = 0.0
var enviando: bool = false

func iniciar_con_prueba(p_id: int, p_titulo: String):
	prueba_id = p_id
	prueba_titulo = p_titulo

func _ready():
	btn_enviar.pressed.connect(_on_enviar)
	btn_abandonar.pressed.connect(_on_abandonar)
	if prueba_id < 0:
		Notificador.notificar("Prueba no especificada", Color.MAGENTA)
		_volver_al_nivel()
		return
	titulo.text = prueba_titulo if not prueba_titulo.is_empty() else "Prueba"
	progreso.text = "Cargando preguntas..."
	enunciado.text = ""
	btn_enviar.disabled = true
	ConexionManager.peticion_get("/preguntas/prueba/%d" % prueba_id, _on_preguntas_recibidas)

func _on_preguntas_recibidas(data, code):
	if code != 200 or not (data is Array):
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)
		_volver_al_nivel()
		return
	preguntas = data
	if preguntas.is_empty():
		Notificador.notificar("La prueba no tiene preguntas", Color.ORANGE)
		_volver_al_nivel()
		return
	indice_actual = 0
	_mostrar_pregunta_actual()

func _mostrar_pregunta_actual():
	if indice_actual >= preguntas.size():
		_consolidar_puntuacion()
		return

	var p = preguntas[indice_actual]
	progreso.text = "Pregunta %d / %d" % [indice_actual + 1, preguntas.size()]
	enunciado.text = str(p.get("enunciado", ""))
	respuesta_elegida_id = -1
	respuesta_desarrollo.text = ""

	for hijo in opciones_test.get_children():
		hijo.queue_free()

	var tipo = str(p.get("tipo", "")).to_upper()
	if tipo == TIPO_TEST:
		opciones_test.visible = true
		respuesta_desarrollo.visible = false
		var grupo = ButtonGroup.new()
		for resp in p.get("respuestasPosibles", []):
			var btn = CheckBox.new()
			btn.text = str(resp.get("texto", ""))
			btn.button_group = grupo
			var resp_id = int(resp.get("id", -1))
			btn.toggled.connect(_on_opcion_test_toggled.bind(resp_id))
			opciones_test.add_child(btn)
	else:
		opciones_test.visible = false
		respuesta_desarrollo.visible = true

	btn_enviar.disabled = false
	pregunta_iniciada_en = Time.get_unix_time_from_system()

func _on_opcion_test_toggled(resp_id: int, pressed: bool):
	if pressed:
		respuesta_elegida_id = resp_id

func _on_enviar():
	if enviando:
		return
	if indice_actual >= preguntas.size():
		return

	var p = preguntas[indice_actual]
	var tipo = str(p.get("tipo", "")).to_upper()
	var preg_id = int(p.get("id", -1))
	if preg_id < 0:
		Notificador.notificar("Pregunta sin id válido", Color.RED)
		return

	var payload: Dictionary = {
		"preguntaId": preg_id,
		"tiempoRespuestaSegundos": int(Time.get_unix_time_from_system() - pregunta_iniciada_en)
	}

	if tipo == TIPO_TEST:
		if respuesta_elegida_id < 0:
			Notificador.notificar("Selecciona una respuesta", Color.ORANGE)
			return
		payload["respuestaElegidaId"] = respuesta_elegida_id
	else:
		var texto = respuesta_desarrollo.text.strip_edges()
		if texto.is_empty():
			Notificador.notificar("Escribe una respuesta", Color.ORANGE)
			return
		payload["textoRespuesta"] = texto

	enviando = true
	btn_enviar.disabled = true
	ConexionManager.peticion_post("/respuestas/enviar", payload, _on_respuesta_enviada)

func _on_respuesta_enviada(data, code):
	enviando = false
	if not (code == 200 or code == 201):
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)
		btn_enviar.disabled = false
		return

	var puntos = data.get("puntosAsignados", null) if data is Dictionary else null
	var p_actual = preguntas[indice_actual]
	var tipo = str(p_actual.get("tipo", "")).to_upper()
	if tipo == TIPO_TEST and puntos != null:
		var color = Color.GREEN if int(puntos) > 0 else Color.MAGENTA
		Notificador.notificar("+%d puntos" % int(puntos), color)
	elif tipo == TIPO_DESARROLLO:
		Notificador.notificar("Respuesta enviada (pendiente de corrección)", Color.CYAN)

	indice_actual += 1
	_mostrar_pregunta_actual()

func _consolidar_puntuacion():
	enunciado.text = "Calculando nota final..."
	opciones_test.visible = false
	respuesta_desarrollo.visible = false
	btn_enviar.disabled = true
	ConexionManager.peticion_post("/puntuacion/alta", {"idPrueba": prueba_id}, _on_puntuacion_lista)

func _on_puntuacion_lista(data, code):
	if not (code == 200 or code == 201):
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)
		await get_tree().create_timer(2.0).timeout
		_volver_al_nivel()
		return

	var puntos = 0
	if data is Dictionary:
		puntos = int(data.get("puntos", 0))
	Notificador.notificar("Prueba completada (+%d XP)" % puntos, Color.GREEN)
	if data is Dictionary and (data.has("nivelActual") or data.has("experienciaActual")):
		GameManager.usuario_actual["nivelActual"] = data.get("nivelActual", GameManager.usuario_actual.get("nivelActual"))
		GameManager.usuario_actual["experienciaActual"] = data.get("experienciaActual", GameManager.usuario_actual.get("experienciaActual"))
	await get_tree().create_timer(1.8).timeout
	_volver_al_nivel()

func _on_abandonar():
	_volver_al_nivel()

func _volver_al_nivel():
	get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
