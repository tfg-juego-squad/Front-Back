extends Control

# Minijuego del NPC de Actividades: Memoria de Secuencia (estilo Simon).
# Por nivel se muestra una secuencia creciente de 4 colores; al terminar el
# nivel (acierto o fallo) saltamos una pregunta aleatoria del banco que el
# profesor configuró en la pestaña Avanzado.

@onready var btn_salir = $Layout/Header/HBox/BtnSalir
@onready var titulo = $Layout/Header/HBox/Titulo
@onready var lbl_nivel = $Layout/Header/HBox/LblNivel
@onready var lbl_estado = $Layout/CentroPanel/PanelJuego/VBoxCentro/LblEstado
@onready var lbl_tu_turno = $Layout/CentroPanel/PanelJuego/VBoxCentro/LblTuTurno
@onready var grid_botones = $Layout/CentroPanel/PanelJuego/VBoxCentro/GridBotones
@onready var botones = [
	$Layout/CentroPanel/PanelJuego/VBoxCentro/GridBotones/BtnRojo,
	$Layout/CentroPanel/PanelJuego/VBoxCentro/GridBotones/BtnVerde,
	$Layout/CentroPanel/PanelJuego/VBoxCentro/GridBotones/BtnAzul,
	$Layout/CentroPanel/PanelJuego/VBoxCentro/GridBotones/BtnAmarillo,
]

@onready var overlay_pregunta = $OverlayPregunta
@onready var lbl_enunciado = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/LblEnunciado
@onready var lbl_tiempo = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/LblTiempo
@onready var progreso_tiempo = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/ProgresoTiempo
@onready var contenedor_respuesta = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/ContenedorRespuesta
@onready var btn_enviar_pregunta = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/HBoxBotonesModal/BtnEnviarPregunta
@onready var btn_saltar_pregunta = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/HBoxBotonesModal/BtnSaltarPregunta
@onready var timer_pregunta = $TimerPregunta

const COLORES = [
	Color(1.0, 0.3, 0.3, 1),  # Rojo
	Color(0.3, 1.0, 0.4, 1),  # Verde
	Color(0.3, 0.55, 1.0, 1), # Azul
	Color(1.0, 0.95, 0.3, 1), # Amarillo
]
const COLOR_APAGADO = Color(0.25, 0.27, 0.35, 1)

const TIEMPO_FLASH := 0.55      # segundos que dura encendido cada color
const TIEMPO_ENTRE_FLASH := 0.2 # gap entre dos colores
const TIEMPO_CONTINUAR := 1.6   # pausa tras terminar pregunta / nivel

var _prueba_id: int = -1
var _prueba_titulo: String = ""
var _niveles_totales: int = 5
var _preguntas: Array = []        # lista cruda recibida del backend
var _nivel_actual: int = 0        # índice 1-based; 0 antes de empezar
var _secuencia_actual: Array = [] # índices a botones[]
var _pos_alumno: int = 0          # índice de la próxima pulsación esperada
var _esperando_alumno: bool = false
var _nivel_fallado: bool = false
var _niveles_pasados: int = 0

# Estado de la pregunta actual
var _pregunta_actual: Dictionary = {}
var _tiempo_restante_pregunta: float = 0.0
var _input_pregunta: Node = null
var _grupo_respuestas: ButtonGroup = null

func _ready():
	btn_salir.pressed.connect(_on_salir)
	for i in range(botones.size()):
		botones[i].pressed.connect(_on_boton_color.bind(i))
		_apagar_boton(i)
		botones[i].focus_mode = Control.FOCUS_NONE
	btn_enviar_pregunta.pressed.connect(_on_enviar_pregunta)
	btn_saltar_pregunta.pressed.connect(_on_saltar_pregunta)
	timer_pregunta.timeout.connect(_tick_pregunta)
	overlay_pregunta.visible = false

	# Si la escena se instancia directamente sin pasar por NpcManager,
	# intentamos arrancar igualmente con valores razonables.
	if _prueba_id < 0 and not GameManager.minijuego_pendiente.is_empty():
		var pendiente = GameManager.minijuego_pendiente
		iniciar_minijuego(
			int(pendiente.get("id", -1)),
			str(pendiente.get("titulo", "Minijuego")),
			int(pendiente.get("nivelesMinijuego", 5))
		)
		GameManager.minijuego_pendiente = {}

func iniciar_minijuego(prueba_id: int, prueba_titulo: String, niveles: int):
	_prueba_id = prueba_id
	_prueba_titulo = prueba_titulo
	_niveles_totales = clamp(niveles, 3, 10)
	titulo.text = "%s · Memoria de Secuencia" % _prueba_titulo
	_actualizar_label_nivel()
	lbl_estado.text = "Cargando preguntas..."
	ConexionManager.peticion_get("/preguntas/prueba/%d" % _prueba_id, _on_preguntas_recibidas)

func _on_preguntas_recibidas(data, code):
	if code == 200 and data is Array:
		_preguntas = data
	else:
		_preguntas = []
		if code != 204:
			Notificador.notificar("No se pudieron cargar las preguntas", Color.ORANGE)
	# Aunque no haya preguntas, el minijuego puede jugarse igualmente.
	_iniciar_siguiente_nivel()

func _actualizar_label_nivel():
	lbl_nivel.text = "Nivel %d / %d" % [max(_nivel_actual, 1), _niveles_totales]

func _iniciar_siguiente_nivel():
	_nivel_actual += 1
	if _nivel_actual > _niveles_totales:
		_finalizar_minijuego()
		return
	_actualizar_label_nivel()
	_nivel_fallado = false
	_pos_alumno = 0
	_esperando_alumno = false
	_generar_secuencia(_nivel_actual + 2)  # nivel 1 → 3 colores, crece +1
	lbl_estado.text = "Memoriza la secuencia..."
	lbl_tu_turno.text = ""
	_set_botones_habilitados(false)
	await get_tree().create_timer(0.6).timeout
	await _reproducir_secuencia()
	if not is_inside_tree():
		return
	lbl_estado.text = "¡Tu turno! Repite la secuencia"
	lbl_tu_turno.text = "0 / %d" % _secuencia_actual.size()
	_set_botones_habilitados(true)
	_esperando_alumno = true

func _generar_secuencia(longitud: int):
	_secuencia_actual.clear()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(longitud):
		_secuencia_actual.append(rng.randi_range(0, botones.size() - 1))

func _reproducir_secuencia():
	for indice in _secuencia_actual:
		_encender_boton(indice)
		await get_tree().create_timer(TIEMPO_FLASH).timeout
		_apagar_boton(indice)
		await get_tree().create_timer(TIEMPO_ENTRE_FLASH).timeout

func _encender_boton(i: int):
	if i < 0 or i >= botones.size():
		return
	botones[i].modulate = Color(1.5, 1.5, 1.5, 1)
	botones[i].add_theme_color_override("font_color", Color.WHITE)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = COLORES[i]
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	botones[i].add_theme_stylebox_override("normal", stylebox)
	botones[i].add_theme_stylebox_override("hover", stylebox)

func _apagar_boton(i: int):
	if i < 0 or i >= botones.size():
		return
	botones[i].modulate = Color(1, 1, 1, 1)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = COLORES[i].darkened(0.45)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	botones[i].add_theme_stylebox_override("normal", stylebox)
	stylebox = stylebox.duplicate()
	stylebox.bg_color = COLORES[i].darkened(0.25)
	botones[i].add_theme_stylebox_override("hover", stylebox)

func _set_botones_habilitados(on: bool):
	for b in botones:
		b.disabled = not on

func _on_boton_color(indice: int):
	if not _esperando_alumno:
		return
	# Mini-flash visual al pulsar
	_encender_boton(indice)
	await get_tree().create_timer(0.18).timeout
	_apagar_boton(indice)

	var esperado = _secuencia_actual[_pos_alumno]
	if indice != esperado:
		_esperando_alumno = false
		_set_botones_habilitados(false)
		_nivel_fallado = true
		lbl_estado.text = "¡Fallaste la secuencia!"
		lbl_tu_turno.text = ""
		await get_tree().create_timer(TIEMPO_CONTINUAR).timeout
		_lanzar_pregunta_aleatoria()
		return

	_pos_alumno += 1
	lbl_tu_turno.text = "%d / %d" % [_pos_alumno, _secuencia_actual.size()]
	if _pos_alumno >= _secuencia_actual.size():
		_esperando_alumno = false
		_set_botones_habilitados(false)
		_niveles_pasados += 1
		lbl_estado.text = "¡Secuencia correcta!"
		await get_tree().create_timer(TIEMPO_CONTINUAR).timeout
		_lanzar_pregunta_aleatoria()

# =====================================================================
# PREGUNTA SORPRESA
# =====================================================================

func _lanzar_pregunta_aleatoria():
	if _preguntas.is_empty():
		_continuar_tras_pregunta()
		return
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	_pregunta_actual = _preguntas[rng.randi_range(0, _preguntas.size() - 1)]
	_mostrar_modal_pregunta()

func _mostrar_modal_pregunta():
	lbl_enunciado.text = str(_pregunta_actual.get("enunciado", "Pregunta"))
	_tiempo_restante_pregunta = float(_pregunta_actual.get("tiempoLimiteSegundos", 30))
	if _tiempo_restante_pregunta <= 0:
		_tiempo_restante_pregunta = 30.0
	progreso_tiempo.max_value = _tiempo_restante_pregunta
	progreso_tiempo.value = _tiempo_restante_pregunta
	_refrescar_lbl_tiempo()

	_limpiar_contenedor_respuesta()
	var tipo = str(_pregunta_actual.get("tipo", "TEST"))
	if tipo == "TEST":
		_construir_respuesta_test()
	else:
		_construir_respuesta_desarrollo()

	overlay_pregunta.visible = true
	timer_pregunta.start()

func _limpiar_contenedor_respuesta():
	for hijo in contenedor_respuesta.get_children():
		hijo.queue_free()
	_input_pregunta = null
	_grupo_respuestas = null

func _construir_respuesta_test():
	_grupo_respuestas = ButtonGroup.new()
	var respuestas = _pregunta_actual.get("respuestasPosibles", [])
	for r in respuestas:
		var rb = CheckBox.new()
		rb.text = str(r.get("texto", ""))
		rb.button_group = _grupo_respuestas
		rb.set_meta("respuesta_id", r.get("id"))
		contenedor_respuesta.add_child(rb)
	_input_pregunta = _grupo_respuestas

func _construir_respuesta_desarrollo():
	var edit = TextEdit.new()
	edit.placeholder_text = "Escribe tu respuesta..."
	edit.custom_minimum_size = Vector2(0, 120)
	contenedor_respuesta.add_child(edit)
	_input_pregunta = edit

func _refrescar_lbl_tiempo():
	lbl_tiempo.text = "Tiempo restante: %d s" % int(ceil(_tiempo_restante_pregunta))

func _tick_pregunta():
	if not overlay_pregunta.visible:
		timer_pregunta.stop()
		return
	_tiempo_restante_pregunta -= timer_pregunta.wait_time
	progreso_tiempo.value = max(_tiempo_restante_pregunta, 0)
	_refrescar_lbl_tiempo()
	if _tiempo_restante_pregunta <= 0.0:
		timer_pregunta.stop()
		_cerrar_modal_y_continuar("Tiempo agotado")

func _on_enviar_pregunta():
	timer_pregunta.stop()
	_enviar_respuesta_al_backend()
	_cerrar_modal_y_continuar("Respuesta registrada")

func _on_saltar_pregunta():
	timer_pregunta.stop()
	_cerrar_modal_y_continuar("Pregunta saltada")

# Manda la respuesta al backend para que el profesor pueda revisarla luego.
# Es best-effort: si falla no bloqueamos el minijuego.
func _enviar_respuesta_al_backend():
	if _pregunta_actual.is_empty():
		return
	var pregunta_id = int(_pregunta_actual.get("id", -1))
	if pregunta_id < 0:
		return

	var tiempo_total = float(_pregunta_actual.get("tiempoLimiteSegundos", 30))
	var tiempo_usado = int(max(0, tiempo_total - _tiempo_restante_pregunta))
	var payload: Dictionary = {
		"preguntaId": pregunta_id,
		"tiempoRespuestaSegundos": tiempo_usado
	}

	var tipo = str(_pregunta_actual.get("tipo", "TEST"))
	if tipo == "TEST" and _grupo_respuestas != null:
		var marcado = _grupo_respuestas.get_pressed_button()
		if marcado != null and marcado.has_meta("respuesta_id"):
			payload["respuestaElegidaId"] = int(marcado.get_meta("respuesta_id"))
		else:
			return  # nada marcado, no enviamos
	elif _input_pregunta is TextEdit:
		var txt = (_input_pregunta as TextEdit).text.strip_edges()
		if txt.is_empty():
			return
		payload["textoRespuesta"] = txt
	else:
		return

	ConexionManager.peticion_post("/respuestas/enviar", payload, func(_data, _code): pass)

func _cerrar_modal_y_continuar(motivo: String):
	overlay_pregunta.visible = false
	_limpiar_contenedor_respuesta()
	lbl_estado.text = motivo
	await get_tree().create_timer(0.8).timeout
	_continuar_tras_pregunta()

func _continuar_tras_pregunta():
	if _nivel_actual >= _niveles_totales:
		_finalizar_minijuego()
		return
	_iniciar_siguiente_nivel()

# =====================================================================
# FIN
# =====================================================================

func _finalizar_minijuego():
	lbl_estado.text = "¡Minijuego completado! · %d / %d niveles superados" % [_niveles_pasados, _niveles_totales]
	lbl_tu_turno.text = "Vuelve al mapa cuando quieras"
	_set_botones_habilitados(false)
	for i in range(botones.size()):
		_apagar_boton(i)
	Notificador.notificar(
		"Minijuego completado: %d/%d niveles" % [_niveles_pasados, _niveles_totales],
		Color.GREEN
	)

func _on_salir():
	NpcManager.reset_npc_activo()
	get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
