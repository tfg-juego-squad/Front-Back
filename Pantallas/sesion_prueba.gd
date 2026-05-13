extends Control

@onready var titulo = $Centro/Panel/Margen/VBox/Titulo
@onready var progreso = $Centro/Panel/Margen/VBox/HBoxInfo/Progreso
@onready var tiempo_label = $Centro/Panel/Margen/VBox/HBoxInfo/TiempoLabel
@onready var timer_bar = $Centro/Panel/Margen/VBox/TimerBar
@onready var enunciado = $Centro/Panel/Margen/VBox/Enunciado
@onready var valor_label = $Centro/Panel/Margen/VBox/ValorLabel
@onready var opciones_test = $Centro/Panel/Margen/VBox/OpcionesTest
@onready var respuesta_desarrollo = $Centro/Panel/Margen/VBox/RespuestaDesarrollo
@onready var feedback_badge = $Centro/Panel/Margen/VBox/FeedbackBadge
@onready var btn_enviar = $Centro/Panel/Margen/VBox/HBoxBotones/BtnEnviar
@onready var btn_abandonar = $Centro/Panel/Margen/VBox/HBoxBotones/BtnAbandonar
@onready var overlay_level_up = $OverlayLevelUp
@onready var lbl_nivel_nuevo = $OverlayLevelUp/CenterLU/VBoxLU/LblNivelNuevo

const TIPO_TEST = "TEST"
const TIPO_DESARROLLO = "DESARROLLO"
const TIEMPO_POR_DEFECTO_SEG := 30

var prueba_id: int = -1
var prueba_titulo: String = ""
var preguntas: Array = []
var indice_actual: int = 0
var respuesta_elegida_id: int = -1
var pregunta_iniciada_en: float = 0.0
var tiempo_limite_seg: int = TIEMPO_POR_DEFECTO_SEG
var enviando: bool = false
var auto_enviada: bool = false

func iniciar_con_prueba(p_id: int, p_titulo: String):
	prueba_id = p_id
	prueba_titulo = p_titulo

func _ready():
	overlay_level_up.visible = false
	btn_enviar.pressed.connect(_on_enviar)
	btn_abandonar.pressed.connect(_on_abandonar)
	feedback_badge.visible = false
	if prueba_id < 0:
		Notificador.notificar("Prueba no especificada", Color.MAGENTA)
		_volver_al_nivel()
		return
	titulo.text = prueba_titulo if not prueba_titulo.is_empty() else "Prueba"
	progreso.text = "Cargando preguntas..."
	enunciado.text = ""
	tiempo_label.text = "—"
	btn_enviar.disabled = true
	ConexionManager.peticion_get("/preguntas/prueba/%s" % GameManager.id_str(prueba_id), _on_preguntas_recibidas)

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

	auto_enviada = false
	feedback_badge.visible = false
	var p = preguntas[indice_actual]
	progreso.text = "Pregunta %d / %d" % [indice_actual + 1, preguntas.size()]
	enunciado.text = str(p.get("enunciado", ""))
	var valor = int(p.get("valorPuntos", 0))
	valor_label.text = "Vale %d puntos" % valor if valor > 0 else ""
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
			var resp_id = GameManager.id_int(resp.get("id"))
			btn.toggled.connect(_on_opcion_test_toggled.bind(resp_id))
			opciones_test.add_child(btn)
	else:
		opciones_test.visible = false
		respuesta_desarrollo.visible = true

	btn_enviar.disabled = false
	pregunta_iniciada_en = Time.get_unix_time_from_system()
	tiempo_limite_seg = int(p.get("tiempoLimiteSegundos", TIEMPO_POR_DEFECTO_SEG))
	if tiempo_limite_seg <= 0:
		tiempo_limite_seg = TIEMPO_POR_DEFECTO_SEG
	timer_bar.max_value = tiempo_limite_seg
	timer_bar.value = tiempo_limite_seg
	_actualizar_tiempo_visible()

func _process(_delta):
	if indice_actual >= preguntas.size() or enviando or auto_enviada or tiempo_limite_seg <= 0:
		return
	_actualizar_tiempo_visible()
	var transcurrido = Time.get_unix_time_from_system() - pregunta_iniciada_en
	if transcurrido >= tiempo_limite_seg:
		auto_enviada = true
		Notificador.notificar("Tiempo agotado", Color.MAGENTA)
		_on_enviar()

func _actualizar_tiempo_visible():
	var restante = tiempo_limite_seg - int(Time.get_unix_time_from_system() - pregunta_iniciada_en)
	restante = max(restante, 0)
	timer_bar.value = restante
	tiempo_label.text = "%ds" % restante
	if restante <= 5:
		tiempo_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	else:
		tiempo_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))

func _on_opcion_test_toggled(pressed: bool, resp_id: int):
	# Callable.bind añade el resp_id AL FINAL, así que la firma debe ser
	# (pressed: bool, resp_id: int). En el orden inverso Godot lanzaba un
	# "Cannot convert argument" tras pulsar la primera opción.
	if pressed:
		respuesta_elegida_id = resp_id

func _on_enviar():
	if enviando:
		return
	if indice_actual >= preguntas.size():
		return

	var p = preguntas[indice_actual]
	var tipo = str(p.get("tipo", "")).to_upper()
	var preg_id = GameManager.id_int(p.get("id"))
	if preg_id < 0:
		Notificador.notificar("Pregunta sin id válido", Color.RED)
		return

	var payload: Dictionary = {
		"preguntaId": preg_id,
		"tiempoRespuestaSegundos": int(Time.get_unix_time_from_system() - pregunta_iniciada_en)
	}

	if tipo == TIPO_TEST:
		if respuesta_elegida_id < 0:
			if not auto_enviada:
				Notificador.notificar("Selecciona una respuesta", Color.ORANGE)
				return
			# Si se agotó el tiempo sin respuesta, no incluimos respuestaElegidaId
		else:
			payload["respuestaElegidaId"] = respuesta_elegida_id
	else:
		var texto = respuesta_desarrollo.text.strip_edges()
		if texto.is_empty():
			if auto_enviada:
				payload["textoRespuesta"] = "(sin respuesta)"
			else:
				Notificador.notificar("Escribe una respuesta", Color.ORANGE)
				return
		else:
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

	var puntos = null
	if data is Dictionary and data.has("puntosAsignados") and data["puntosAsignados"] != null:
		puntos = int(data["puntosAsignados"])

	var p_actual = preguntas[indice_actual]
	var tipo = str(p_actual.get("tipo", "")).to_upper()

	if tipo == TIPO_TEST:
		if puntos != null and puntos > 0:
			_mostrar_feedback("✓ Correcto  (+%d)" % puntos, Color(0.3, 0.9, 0.4, 1))
		else:
			_mostrar_feedback("✗ Incorrecto", Color(1, 0.4, 0.4, 1))
	else:
		_mostrar_feedback("Pendiente de corrección del profesor", Color(0.5, 0.85, 1, 1))

	await get_tree().create_timer(1.4).timeout
	indice_actual += 1
	_mostrar_pregunta_actual()

func _mostrar_feedback(texto: String, color: Color):
	feedback_badge.text = texto
	feedback_badge.add_theme_color_override("font_color", color)
	feedback_badge.visible = true
	feedback_badge.modulate.a = 0
	create_tween().tween_property(feedback_badge, "modulate:a", 1.0, 0.25)

func _consolidar_puntuacion():
	enunciado.text = "Calculando nota final..."
	opciones_test.visible = false
	respuesta_desarrollo.visible = false
	feedback_badge.visible = false
	timer_bar.value = 0
	tiempo_label.text = "—"
	btn_enviar.disabled = true
	ConexionManager.peticion_post("/puntuacion/alta", {"idPrueba": prueba_id}, _on_puntuacion_lista)

func _on_puntuacion_lista(data, code):
	if not (code == 200 or code == 201):
		Notificador.notificar(ConexionManager.mensaje_error(data, code), Color.RED)
		await get_tree().create_timer(2.0).timeout
		_volver_al_nivel()
		return

	var subio_nivel = GameManager.aplicar_recompensa(data)
	var puntos = 0
	if data is Dictionary:
		puntos = int(data.get("puntosObtenidos", 0))
	Notificador.notificar("Prueba completada (+%d XP)" % puntos, Color.GREEN)

	if subio_nivel:
		await _mostrar_animacion_level_up()
	else:
		await get_tree().create_timer(1.6).timeout
	_volver_al_nivel()

func _mostrar_animacion_level_up():
	var nivel = int(GameManager.usuario_actual.get("nivelActual", 1))
	lbl_nivel_nuevo.text = "Nivel %d" % nivel
	overlay_level_up.visible = true
	overlay_level_up.modulate.a = 0
	create_tween().tween_property(overlay_level_up, "modulate:a", 1.0, 0.35)
	await get_tree().create_timer(2.4).timeout

func _on_abandonar():
	_volver_al_nivel()

func _volver_al_nivel():
	get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
