extends Control

# Minijuego "Conducción" (subtipo ESQUIVA): el alumno avanza por una pista
# de 3 carriles y debe cambiar de carril para esquivar coches que aparecen
# arriba. Hay dos disparadores educativos:
#   - Al chocar con un coche → pregunta sorpresa (sigues vivo, breve invuln).
#   - Cada N metros recorridos → pregunta sorpresa.
# El nivel termina cuando se alcanzan los metros objetivo (escala con nivel).

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

# --- Parámetros del juego ---
const NUM_CARRILES := 3
const VEL_METROS_POR_SEG := 28.0     # metros virtuales por segundo
const METROS_BASE_NIVEL := 220.0     # metros para superar nivel 1
const METROS_INCREMENTO := 80.0      # +metros por cada nivel
const METROS_ENTRE_PREGUNTAS := 90.0 # cada cuántos metros sale pregunta
const SPAWN_INTERVALO_BASE := 1.10   # segundos entre coches (nivel 1)
const SPAWN_INTERVALO_MIN := 0.45
const SPAWN_INTERVALO_RED := 0.07    # se reduce por nivel
const VEL_BLOQUE_PX := 280.0         # px/s que bajan los coches
const VEL_BLOQUE_INCR := 35.0        # por nivel
const TIEMPO_CONTINUAR := 0.9
const INVULN_TRAS_CHOQUE := 1.2
const TIEMPO_CAMBIO_CARRIL := 0.12   # segs interpolando entre carriles

const COLOR_COCHE = Color(1, 0.35, 0.35, 1)
const COLOR_JUGADOR = Color(0.3, 0.95, 1.0, 1)
const COLOR_JUGADOR_HIT = Color(1, 0.5, 0.3, 1)

var _prueba_id: int = -1
var _prueba_titulo: String = ""
var _niveles_totales: int = 5
var _preguntas: Array = []
var _nivel_actual: int = 0
var _niveles_pasados: int = 0

# Estado del nivel actual
var _carril_actual: int = 1                  # 0 / 1 / 2
var _carril_target: int = 1
var _cambio_carril_t: float = 0.0
var _bloques: Array = []                     # [{rect, vel, carril}]
var _metros_recorridos: float = 0.0
var _metros_objetivo: float = 0.0
var _spawn_acumulado: float = 0.0
var _spawn_intervalo: float = SPAWN_INTERVALO_BASE
var _vel_bloque_px: float = VEL_BLOQUE_PX
var _ultima_pregunta_metros: float = 0.0
var _invulnerable_hasta: float = 0.0
var _nivel_en_curso: bool = false
var _input_activo: bool = false
var _x_carril: Array = []                    # posiciones x de cada carril
var _rng := RandomNumberGenerator.new()

# Estado de la pregunta activa
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
	titulo.text = "Conducción · 3 carriles"
	jugador.color = COLOR_JUGADOR

	# Recalcular carriles cuando cambia el tamaño del área (full screen, etc.)
	area_juego.resized.connect(_recalcular_carriles)
	_recalcular_carriles()

	# Si la escena se instancia directamente leemos los datos pendientes.
	if _prueba_id < 0 and not GameManager.minijuego_pendiente.is_empty():
		var pendiente = GameManager.minijuego_pendiente
		iniciar_minijuego(
			int(pendiente.get("id", -1)),
			str(pendiente.get("titulo", "Conducción")),
			int(pendiente.get("nivelesMinijuego", 5))
		)
		GameManager.minijuego_pendiente = {}

func iniciar_minijuego(prueba_id: int, prueba_titulo: String, niveles: int):
	_prueba_id = prueba_id
	_prueba_titulo = prueba_titulo
	_niveles_totales = clamp(niveles, 3, 10)
	titulo.text = "%s · Conducción" % _prueba_titulo
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

func _recalcular_carriles():
	# Tres carriles equiespaciados respetando un margen lateral.
	var ancho = area_juego.size.x
	if ancho <= 0:
		return
	var margen = 30.0
	var ancho_util = max(ancho - 2 * margen, 60.0)
	_x_carril.clear()
	for i in range(NUM_CARRILES):
		var t = (float(i) + 0.5) / float(NUM_CARRILES)
		_x_carril.append(margen + ancho_util * t - jugador.size.x / 2.0)
	# Reposicionar al jugador en su carril actual
	_colocar_jugador_instant(_carril_actual)

func _colocar_jugador_instant(carril: int):
	if _x_carril.is_empty():
		return
	jugador.position = Vector2(
		_x_carril[carril],
		area_juego.size.y - jugador.size.y - 18
	)

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
	_metros_recorridos = 0.0
	_ultima_pregunta_metros = 0.0
	_metros_objetivo = METROS_BASE_NIVEL + METROS_INCREMENTO * (_nivel_actual - 1)
	_spawn_acumulado = 0.0
	_spawn_intervalo = max(
		SPAWN_INTERVALO_MIN,
		SPAWN_INTERVALO_BASE - SPAWN_INTERVALO_RED * (_nivel_actual - 1)
	)
	_vel_bloque_px = VEL_BLOQUE_PX + VEL_BLOQUE_INCR * (_nivel_actual - 1)
	_carril_actual = 1
	_carril_target = 1
	_cambio_carril_t = 1.0
	_colocar_jugador_instant(1)
	jugador.modulate = Color.WHITE
	jugador.color = COLOR_JUGADOR
	lbl_estado.text = "¡Esquiva los coches! Usa A / D o ← →"
	_nivel_en_curso = true
	_input_activo = true

func _limpiar_bloques():
	for b in _bloques:
		if b.rect and is_instance_valid(b.rect):
			b.rect.queue_free()
	_bloques.clear()

# =====================================================================
# LOOP DE JUEGO
# =====================================================================

func _process(delta):
	if not _nivel_en_curso:
		return
	_actualizar_cambio_carril(delta)
	_spawnear_coches(delta)
	_mover_coches(delta)
	# Metros avanzados antes de evaluar colisiones para que el HUD se actualice
	# aunque haya choque inmediato.
	_metros_recorridos += VEL_METROS_POR_SEG * delta
	lbl_tiempo.text = "%d / %d m" % [int(_metros_recorridos), int(_metros_objetivo)]

	if _detectar_colision():
		_on_choque()
		return

	# Disparador por distancia
	if _metros_recorridos - _ultima_pregunta_metros >= METROS_ENTRE_PREGUNTAS:
		_ultima_pregunta_metros = _metros_recorridos
		_lanzar_pregunta_aleatoria("Checkpoint a los %d m" % int(_metros_recorridos))
		return

	# Nivel completado
	if _metros_recorridos >= _metros_objetivo:
		_niveles_pasados += 1
		_nivel_en_curso = false
		_input_activo = false
		lbl_estado.text = "¡Nivel %d superado!" % _nivel_actual
		_lanzar_pregunta_aleatoria("Recompensa de nivel")

func _input(event):
	if not _input_activo:
		return
	if event.is_echo() or not event.is_pressed():
		return
	if event.is_action_pressed("ui_left"):
		_intentar_cambio_carril(-1)
	elif event.is_action_pressed("ui_right"):
		_intentar_cambio_carril(1)

func _intentar_cambio_carril(direccion: int):
	var nuevo = clamp(_carril_target + direccion, 0, NUM_CARRILES - 1)
	if nuevo == _carril_target:
		return
	_carril_actual = _carril_target  # punto de salida = donde realmente estamos
	_carril_target = nuevo
	_cambio_carril_t = 0.0

func _actualizar_cambio_carril(delta):
	if _x_carril.is_empty():
		return
	if _cambio_carril_t < 1.0:
		_cambio_carril_t = min(1.0, _cambio_carril_t + delta / TIEMPO_CAMBIO_CARRIL)
	var x_origen = _x_carril[_carril_actual]
	var x_destino = _x_carril[_carril_target]
	var x = lerp(x_origen, x_destino, _cambio_carril_t)
	jugador.position.x = x
	jugador.position.y = area_juego.size.y - jugador.size.y - 18

func _spawnear_coches(delta):
	_spawn_acumulado += delta
	while _spawn_acumulado >= _spawn_intervalo:
		_spawn_acumulado -= _spawn_intervalo
		_spawnear_un_coche()

func _spawnear_un_coche():
	if _x_carril.is_empty():
		return
	var carril = _rng.randi_range(0, NUM_CARRILES - 1)
	var ancho = jugador.size.x  # mismo ancho que el jugador
	var alto = jugador.size.y * 1.4
	var rect = ColorRect.new()
	rect.color = COLOR_COCHE
	rect.size = Vector2(ancho, alto)
	rect.position = Vector2(_x_carril[carril], -alto)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_juego.add_child(rect)
	_bloques.append({"rect": rect, "vel": _vel_bloque_px, "carril": carril})

func _mover_coches(delta):
	var alto = area_juego.size.y
	var vivos: Array = []
	for b in _bloques:
		if not is_instance_valid(b.rect):
			continue
		b.rect.position.y += b.vel * delta
		if b.rect.position.y > alto + 20:
			b.rect.queue_free()
		else:
			vivos.append(b)
	_bloques = vivos

func _detectar_colision() -> bool:
	if Time.get_ticks_msec() / 1000.0 < _invulnerable_hasta:
		return false
	var rj = Rect2(jugador.position, jugador.size).grow(-4)
	for b in _bloques:
		if not is_instance_valid(b.rect):
			continue
		var rb = Rect2(b.rect.position, b.rect.size)
		if rj.intersects(rb):
			return true
	return false

func _on_choque():
	# El choque NO termina el nivel: lanza una pregunta y al cerrar el modal
	# vuelves al volante con un par de segundos de invulnerabilidad para que
	# no encadenes choques.
	_input_activo = false
	jugador.color = COLOR_JUGADOR_HIT
	_invulnerable_hasta = Time.get_ticks_msec() / 1000.0 + INVULN_TRAS_CHOQUE
	lbl_estado.text = "¡Chocaste! Responde para seguir"
	# Limpiamos los coches solapados con el jugador para que al volver no te
	# vuelva a impactar inmediatamente.
	for b in _bloques:
		if not is_instance_valid(b.rect):
			continue
		var rj = Rect2(jugador.position, jugador.size).grow(-4)
		var rb = Rect2(b.rect.position, b.rect.size)
		if rj.intersects(rb):
			b.rect.queue_free()
	_lanzar_pregunta_aleatoria("Choque")

# =====================================================================
# PREGUNTA SORPRESA
# =====================================================================

func _lanzar_pregunta_aleatoria(motivo: String):
	if _preguntas.is_empty():
		_cerrar_modal_y_continuar(motivo, true)
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
		_cerrar_modal_y_continuar("Tiempo agotado", false)

func _on_enviar_pregunta():
	timer_pregunta.stop()
	_enviar_respuesta_al_backend()
	_cerrar_modal_y_continuar("Respuesta registrada", false)

func _on_saltar_pregunta():
	timer_pregunta.stop()
	_cerrar_modal_y_continuar("Pregunta saltada", false)

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

# Cuando se cierra la pregunta decidimos si seguir el nivel actual (en caso
# de choque o checkpoint intermedio) o pasar al siguiente (nivel completado).
func _cerrar_modal_y_continuar(_motivo: String, _sin_preguntas: bool):
	overlay_pregunta.visible = false
	_limpiar_contenedor_respuesta()
	await get_tree().create_timer(TIEMPO_CONTINUAR).timeout
	if _metros_recorridos >= _metros_objetivo:
		_continuar_tras_nivel()
		return
	# Reanudamos la conducción
	jugador.color = COLOR_JUGADOR
	_nivel_en_curso = true
	_input_activo = true
	lbl_estado.text = "¡Sigue conduciendo!"

func _continuar_tras_nivel():
	if _nivel_actual >= _niveles_totales:
		_finalizar_minijuego()
		return
	_iniciar_siguiente_nivel()

# =====================================================================
# FIN
# =====================================================================

func _finalizar_minijuego():
	_nivel_en_curso = false
	_input_activo = false
	_limpiar_bloques()
	lbl_estado.text = "¡Carrera completada! · %d / %d niveles" % [_niveles_pasados, _niveles_totales]
	lbl_tiempo.text = ""
	jugador.visible = false
	Notificador.notificar(
		"Minijuego completado: %d/%d niveles" % [_niveles_pasados, _niveles_totales],
		Color.GREEN
	)
	# Marcar la prueba como completada para que no salga más como pendiente.
	if _prueba_id >= 0:
		ConexionManager.peticion_post(
			"/puntuacion/alta",
			{"idPrueba": _prueba_id},
			func(_d, _c): pass
		)

func _on_salir():
	NpcManager.reset_npc_activo()
	get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
