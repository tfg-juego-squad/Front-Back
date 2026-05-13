extends Control

# Minijuego "Esquiva-bloques" (subtipo ESQUIVA del NPC de Actividades).
# Mismo flujo educativo que el de Memoria de Secuencia: cada nivel
# superado o fallado dispara una pregunta aleatoria del banco que el
# profesor configuró en la pestaña Avanzado.
#
# Mecánica: el alumno mueve su cuadrado con WASD/flechas dentro de una
# zona, y debe sobrevivir X segundos esquivando bloques que caen desde
# arriba. La dificultad sube con el nivel.

@onready var btn_salir = $Layout/Header/HBox/BtnSalir
@onready var titulo = $Layout/Header/HBox/Titulo
@onready var lbl_nivel = $Layout/Header/HBox/LblNivel
@onready var area_juego: Control = $Layout/CentroPanel/PanelJuego/VBoxCentro/MargenJuego/AreaJuego
@onready var jugador: ColorRect = $Layout/CentroPanel/PanelJuego/VBoxCentro/MargenJuego/AreaJuego/Jugador
@onready var lbl_estado = $Layout/CentroPanel/PanelJuego/VBoxCentro/HBoxEstado/LblEstado
@onready var lbl_tiempo = $Layout/CentroPanel/PanelJuego/VBoxCentro/HBoxEstado/LblTiempo

@onready var overlay_pregunta = $OverlayPregunta
@onready var lbl_enunciado = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/LblEnunciado
@onready var lbl_tiempo_preg = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/LblTiempoPreg
@onready var progreso_tiempo = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/ProgresoTiempo
@onready var contenedor_respuesta = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/ContenedorRespuesta
@onready var btn_enviar_pregunta = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/HBoxBotonesModal/BtnEnviarPregunta
@onready var btn_saltar_pregunta = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/HBoxBotonesModal/BtnSaltarPregunta
@onready var timer_pregunta = $TimerPregunta

# --- Parámetros de juego ---
const VEL_JUGADOR := 220.0          # px/s
const SUPERVIVENCIA_BASE := 8.0     # segundos del nivel 1
const SUPERVIVENCIA_INCREMENTO := 2.0 # +s por nivel
const SPAWN_INTERVALO_BASE := 0.75  # segundos entre bloques al inicio
const SPAWN_INTERVALO_MIN := 0.25
const SPAWN_INTERVALO_REDUCCION := 0.08  # por nivel
const VEL_BLOQUE_BASE := 140.0      # px/s
const VEL_BLOQUE_INCREMENTO := 25.0 # por nivel
const BLOQUE_TAMANO_MIN := 30.0
const BLOQUE_TAMANO_MAX := 60.0
const COLOR_BLOQUE = Color(1, 0.35, 0.35, 1)

const TIEMPO_CONTINUAR := 1.3
const TIEMPO_FLASH_FALLO := 0.5

var _prueba_id: int = -1
var _prueba_titulo: String = ""
var _niveles_totales: int = 5
var _preguntas: Array = []
var _nivel_actual: int = 0
var _niveles_pasados: int = 0

# Estado del nivel actual
var _bloques: Array = []            # [{rect: ColorRect, vel: float, ancho: float, alto: float}]
var _tiempo_supervivencia: float = 0.0  # segundos jugados en el nivel
var _objetivo_supervivencia: float = 0.0
var _spawn_acumulado: float = 0.0
var _spawn_intervalo: float = 0.75
var _nivel_en_curso: bool = false
var _input_jugador_activo: bool = false
var _rng := RandomNumberGenerator.new()

# Pregunta sorpresa
var _pregunta_actual: Dictionary = {}
var _tiempo_restante_pregunta: float = 0.0
var _input_pregunta = null
var _grupo_respuestas: ButtonGroup = null

func _ready():
	btn_salir.pressed.connect(_on_salir)
	btn_enviar_pregunta.pressed.connect(_on_enviar_pregunta)
	btn_saltar_pregunta.pressed.connect(_on_saltar_pregunta)
	timer_pregunta.timeout.connect(_tick_pregunta)
	overlay_pregunta.visible = false
	_rng.randomize()

	if _prueba_id < 0 and not GameManager.minijuego_pendiente.is_empty():
		var pendiente = GameManager.minijuego_pendiente
		iniciar_minijuego(
			int(pendiente.get("id", -1)),
			str(pendiente.get("titulo", "Esquiva-bloques")),
			int(pendiente.get("nivelesMinijuego", 5))
		)
		GameManager.minijuego_pendiente = {}

func iniciar_minijuego(prueba_id: int, prueba_titulo: String, niveles: int):
	_prueba_id = prueba_id
	_prueba_titulo = prueba_titulo
	_niveles_totales = clamp(niveles, 3, 10)
	titulo.text = "%s · Esquiva-bloques" % _prueba_titulo
	_actualizar_label_nivel()
	lbl_estado.text = "Cargando preguntas..."
	lbl_tiempo.text = ""
	ConexionManager.peticion_get("/preguntas/prueba/%d" % _prueba_id, _on_preguntas_recibidas)

func _on_preguntas_recibidas(data, code):
	if code == 200 and data is Array:
		_preguntas = data
	else:
		_preguntas = []
		if code != 204:
			Notificador.notificar("No se pudieron cargar las preguntas", Color.ORANGE)
	_iniciar_siguiente_nivel()

func _actualizar_label_nivel():
	lbl_nivel.text = "Nivel %d / %d" % [max(_nivel_actual, 1), _niveles_totales]

# =====================================================================
# CICLO DE NIVEL
# =====================================================================

func _iniciar_siguiente_nivel():
	_nivel_actual += 1
	if _nivel_actual > _niveles_totales:
		_finalizar_minijuego()
		return
	_actualizar_label_nivel()

	_limpiar_bloques()
	_tiempo_supervivencia = 0.0
	_objetivo_supervivencia = SUPERVIVENCIA_BASE + SUPERVIVENCIA_INCREMENTO * (_nivel_actual - 1)
	_spawn_acumulado = 0.0
	_spawn_intervalo = max(
		SPAWN_INTERVALO_MIN,
		SPAWN_INTERVALO_BASE - SPAWN_INTERVALO_REDUCCION * (_nivel_actual - 1)
	)

	# Centramos al jugador en la parte baja de la arena.
	var size = area_juego.size
	jugador.position = Vector2((size.x - jugador.size.x) / 2.0, size.y - jugador.size.y - 12)
	jugador.modulate = Color.WHITE
	jugador.visible = true

	lbl_estado.text = "¡Esquiva los bloques!"
	_nivel_en_curso = true
	_input_jugador_activo = true

func _limpiar_bloques():
	for b in _bloques:
		if b.rect and is_instance_valid(b.rect):
			b.rect.queue_free()
	_bloques.clear()

func _process(delta):
	if not _nivel_en_curso:
		return
	_mover_jugador(delta)
	_spawnear_bloques(delta)
	_mover_bloques(delta)
	if _detectar_colision():
		_terminar_nivel(false)
		return
	_tiempo_supervivencia += delta
	var restante = _objetivo_supervivencia - _tiempo_supervivencia
	if restante <= 0.0:
		_terminar_nivel(true)
		return
	lbl_tiempo.text = "%.1f s" % restante

func _mover_jugador(delta):
	if not _input_jugador_activo:
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if dir == Vector2.ZERO:
		return
	dir = dir.normalized()
	var pos = jugador.position + dir * VEL_JUGADOR * delta
	# Clamp dentro de la arena
	var area = area_juego.size
	pos.x = clamp(pos.x, 0.0, area.x - jugador.size.x)
	pos.y = clamp(pos.y, 0.0, area.y - jugador.size.y)
	jugador.position = pos

func _spawnear_bloques(delta):
	_spawn_acumulado += delta
	while _spawn_acumulado >= _spawn_intervalo:
		_spawn_acumulado -= _spawn_intervalo
		_spawnear_un_bloque()

func _spawnear_un_bloque():
	var area = area_juego.size
	var ancho = _rng.randf_range(BLOQUE_TAMANO_MIN, BLOQUE_TAMANO_MAX)
	var alto = _rng.randf_range(BLOQUE_TAMANO_MIN, BLOQUE_TAMANO_MAX)
	var rect = ColorRect.new()
	rect.color = COLOR_BLOQUE
	rect.size = Vector2(ancho, alto)
	rect.position = Vector2(_rng.randf_range(0, max(area.x - ancho, 0)), -alto)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_juego.add_child(rect)
	var vel = VEL_BLOQUE_BASE + VEL_BLOQUE_INCREMENTO * (_nivel_actual - 1) + _rng.randf_range(-20, 30)
	_bloques.append({"rect": rect, "vel": vel, "ancho": ancho, "alto": alto})

func _mover_bloques(delta):
	var area = area_juego.size
	var vivos: Array = []
	for b in _bloques:
		if not is_instance_valid(b.rect):
			continue
		b.rect.position.y += b.vel * delta
		if b.rect.position.y > area.y + 20:
			b.rect.queue_free()
		else:
			vivos.append(b)
	_bloques = vivos

func _detectar_colision() -> bool:
	var rj = Rect2(jugador.position, jugador.size)
	# Hitbox ligeramente más pequeña para que no se sienta injusto.
	rj = rj.grow(-3)
	for b in _bloques:
		if not is_instance_valid(b.rect):
			continue
		var rb = Rect2(b.rect.position, b.rect.size)
		if rj.intersects(rb):
			return true
	return false

func _terminar_nivel(superado: bool):
	_nivel_en_curso = false
	_input_jugador_activo = false
	if superado:
		_niveles_pasados += 1
		lbl_estado.text = "¡Has sobrevivido!"
	else:
		lbl_estado.text = "¡Te alcanzó un bloque!"
		jugador.modulate = Color(1, 0.3, 0.3, 1)
	lbl_tiempo.text = ""
	await get_tree().create_timer(TIEMPO_CONTINUAR).timeout
	if not is_inside_tree():
		return
	_lanzar_pregunta_aleatoria()

# =====================================================================
# PREGUNTA SORPRESA (idéntico a minijuego_secuencia)
# =====================================================================

func _lanzar_pregunta_aleatoria():
	if _preguntas.is_empty():
		_continuar_tras_pregunta()
		return
	_pregunta_actual = _preguntas[_rng.randi_range(0, _preguntas.size() - 1)]
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
	lbl_tiempo_preg.text = "Tiempo restante: %d s" % int(ceil(_tiempo_restante_pregunta))

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
			return
	elif _input_pregunta is TextEdit:
		var txt = (_input_pregunta as TextEdit).text.strip_edges()
		if txt.is_empty():
			return
		payload["textoRespuesta"] = txt
	else:
		return
	ConexionManager.peticion_post("/respuestas/enviar", payload, func(_d, _c): pass)

func _cerrar_modal_y_continuar(motivo: String):
	overlay_pregunta.visible = false
	_limpiar_contenedor_respuesta()
	lbl_estado.text = motivo
	await get_tree().create_timer(0.7).timeout
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
	_nivel_en_curso = false
	_input_jugador_activo = false
	_limpiar_bloques()
	lbl_estado.text = "¡Minijuego completado! · %d / %d niveles superados" % [_niveles_pasados, _niveles_totales]
	lbl_tiempo.text = ""
	jugador.visible = false
	Notificador.notificar(
		"Minijuego completado: %d/%d niveles" % [_niveles_pasados, _niveles_totales],
		Color.GREEN
	)

func _on_salir():
	NpcManager.reset_npc_activo()
	get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
