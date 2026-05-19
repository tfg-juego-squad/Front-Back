extends Control

# Minijuego "Conducción" (subtipo ESQUIVA): el alumno avanza por una pista
# con 3 carriles visibles pero **movimiento horizontal libre**. Tiene que
# esquivar distintos tipos de obstáculos que vienen por arriba:
#   - COCHE   → choque + pregunta sorpresa
#   - CONO    → choque + pregunta sorpresa (más pequeño y lento)
#   - BARRERA → choque + pregunta sorpresa (recorte de carretera, ocupa lateral)
#   - ACEITE  → no rompe pero te frena (slow) durante un instante
# Disparadores educativos:
#   - Al chocar con un coche / cono / barrera → pregunta sorpresa.
#   - Cada N metros recorridos → pregunta sorpresa.
# El nivel termina cuando se alcanzan los metros objetivo (escala con nivel).

@onready var btn_salir = $Layout/Header/HBox/BtnSalir
@onready var titulo = $Layout/Header/HBox/Titulo
@onready var lbl_nivel = $Layout/Header/HBox/LblNivel
@onready var area_juego: Control = $Layout/CentroPanel/PanelJuego/VBoxCentro/MargenJuego/AreaJuego
@onready var jugador: ColorRect = $Layout/CentroPanel/PanelJuego/VBoxCentro/MargenJuego/AreaJuego/Jugador
@onready var lbl_estado = $Layout/CentroPanel/PanelJuego/VBoxCentro/HBoxEstado/LblEstado
@onready var lbl_tiempo = $Layout/CentroPanel/PanelJuego/VBoxCentro/HBoxEstado/LblTiempo
@onready var lbl_countdown: Label = $LblCountdown

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
const MARGEN_PISTA := 30.0                    # padding lateral de la pista
const VEL_METROS_POR_SEG := 28.0
const METROS_BASE_NIVEL := 220.0
const METROS_INCREMENTO := 80.0
# Antes 90 m → preguntas muy seguidas. Ahora 180 m: una pregunta cada ~6.5 s
# de conducción real, deja más margen para jugar.
const METROS_ENTRE_PREGUNTAS := 180.0
const SPAWN_INTERVALO_BASE := 1.10
const SPAWN_INTERVALO_MIN := 0.45
const SPAWN_INTERVALO_RED := 0.07
const VEL_BLOQUE_PX := 280.0
const VEL_BLOQUE_INCR := 35.0
const TIEMPO_CONTINUAR := 0.9
const INVULN_TRAS_CHOQUE := 1.2

# Movimiento lateral continuo (en vez de saltos de carril).
const VEL_LATERAL := 520.0                    # px/seg horizontal
const FACTOR_SLOW_ACEITE := 0.35              # multiplicador de velocidad sobre aceite
const DURACION_SLOW_ACEITE := 0.45            # cuánto dura el efecto tras pasar el aceite

const COLORES_COCHE = [
	Color(1, 0.35, 0.35, 1),  # rojo
	Color(1, 0.55, 0.2, 1),   # naranja
	Color(0.95, 0.8, 0.2, 1), # amarillo
	Color(0.85, 0.3, 0.7, 1), # rosa
	Color(0.5, 0.35, 0.9, 1), # morado
]
const COLOR_JUGADOR = Color(0.3, 0.95, 1.0, 1)
const COLOR_JUGADOR_HIT = Color(1, 0.5, 0.3, 1)
const COLOR_CONO = Color(1, 0.55, 0.15, 1)
const COLOR_ACEITE = Color(0.05, 0.05, 0.1, 0.85)
const COLOR_BARRERA = Color(0.95, 0.85, 0.15, 1)

var _prueba_id: int = -1
var _prueba_titulo: String = ""
var _niveles_totales: int = 5
var _preguntas: Array = []
var _nivel_actual: int = 0
var _niveles_pasados: int = 0

# Estado del nivel actual
var _bloques: Array = []                     # [{rect, vel, tipo}]
var _metros_recorridos: float = 0.0
var _metros_objetivo: float = 0.0
var _spawn_acumulado: float = 0.0
var _spawn_intervalo: float = SPAWN_INTERVALO_BASE
var _vel_bloque_px: float = VEL_BLOQUE_PX
var _ultima_pregunta_metros: float = 0.0
var _invulnerable_hasta: float = 0.0
var _slow_hasta: float = 0.0
var _nivel_en_curso: bool = false
var _input_activo: bool = false
var _en_countdown: bool = false
var _x_carril: Array = []                    # posiciones x de cada carril (centros)
var _rng := RandomNumberGenerator.new()
var _marcas_carretera: Array = []  # líneas de carretera que se mueven hacia abajo

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
	lbl_countdown.visible = false
	_rng.randomize()
	titulo.text = "Conducción"
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
	var ancho = area_juego.size.x
	var alto = area_juego.size.y
	if ancho <= 0 or alto <= 0:
		return
	# Jugador ~6% del ancho de carril → coches pequeños y proporcionados.
	var ancho_carril = ancho / float(NUM_CARRILES)
	var tam_x = clamp(ancho_carril * 0.06, 22, 42)
	var tam_y = tam_x * 1.7
	jugador.custom_minimum_size = Vector2(tam_x, tam_y)
	jugador.size = Vector2(tam_x, tam_y)
	# Ajustar parabrisas del jugador
	var parabrisas = jugador.get_node_or_null("LblJugador")
	if parabrisas:
		parabrisas.size = Vector2(tam_x * 0.7, tam_y * 0.15)
		parabrisas.position = Vector2(tam_x * 0.15, tam_y * 0.1)
	var ancho_util = max(ancho - 2 * MARGEN_PISTA, 60.0)
	_x_carril.clear()
	for i in range(NUM_CARRILES):
		var t = (float(i) + 0.5) / float(NUM_CARRILES)
		_x_carril.append(MARGEN_PISTA + ancho_util * t - jugador.size.x / 2.0)
	# Colocar al jugador en el centro si aún no lo hemos movido
	jugador.position = Vector2(
		(ancho - jugador.size.x) / 2.0,
		alto - jugador.size.y - 18
	)
	_crear_marcas_carretera()

func _crear_marcas_carretera():
	# Limpiar marcas anteriores
	for m in _marcas_carretera:
		if is_instance_valid(m):
			m.queue_free()
	_marcas_carretera.clear()
	var ancho = area_juego.size.x
	var alto = area_juego.size.y
	# Marcas punteadas entre carriles
	for c in range(1, NUM_CARRILES):
		var x_linea = MARGEN_PISTA + (ancho - 2 * MARGEN_PISTA) * (float(c) / float(NUM_CARRILES))
		var y = 0.0
		while y < alto:
			var marca = ColorRect.new()
			marca.color = Color(0.6, 0.65, 0.7, 0.4)
			marca.size = Vector2(3, 30)
			marca.position = Vector2(x_linea - 1.5, y)
			marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
			area_juego.add_child(marca)
			area_juego.move_child(marca, 0)  # detrás de todo
			_marcas_carretera.append(marca)
			y += 55.0

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
	_slow_hasta = 0.0
	_invulnerable_hasta = 0.0
	jugador.modulate = Color.WHITE
	jugador.color = COLOR_JUGADOR
	# Centramos el coche en la pista al empezar el nivel.
	jugador.position = Vector2(
		(area_juego.size.x - jugador.size.x) / 2.0,
		area_juego.size.y - jugador.size.y - 18
	)
	lbl_estado.text = "Prepárate..."
	_nivel_en_curso = false
	_input_activo = false
	_mostrar_countdown()

func _limpiar_bloques():
	for b in _bloques:
		if b.rect and is_instance_valid(b.rect):
			b.rect.queue_free()
	_bloques.clear()

# =====================================================================
# COUNTDOWN 3 · 2 · 1 · YA
# =====================================================================

func _mostrar_countdown():
	if _en_countdown:
		return
	_en_countdown = true
	lbl_countdown.visible = true
	lbl_countdown.pivot_offset = lbl_countdown.size / 2.0
	for paso in ["3", "2", "1", "¡YA!"]:
		if not is_inside_tree():
			return
		lbl_countdown.text = paso
		lbl_countdown.scale = Vector2(1.8, 1.8)
		lbl_countdown.modulate = Color(1, 1, 1, 0)
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(lbl_countdown, "scale", Vector2.ONE, 0.18)
		tw.tween_property(lbl_countdown, "modulate:a", 1.0, 0.15)
		await get_tree().create_timer(0.7).timeout
	if not is_inside_tree():
		_en_countdown = false
		return
	lbl_countdown.visible = false
	_en_countdown = false
	lbl_estado.text = "← A / D → mover libremente · ¡Esquiva los obstáculos!"
	_nivel_en_curso = true
	_input_activo = true

# =====================================================================
# LOOP DE JUEGO
# =====================================================================

func _process(delta):
	# Si hay pregunta visible o no estamos jugando, congelamos el juego.
	if not _nivel_en_curso or overlay_pregunta.visible or _en_countdown:
		return
	_mover_jugador(delta)
	_spawnear_obstaculos(delta)
	_mover_bloques(delta)
	# Metros avanzados antes de evaluar colisiones para que el HUD se actualice
	# aunque haya choque inmediato.
	_metros_recorridos += VEL_METROS_POR_SEG * delta
	lbl_tiempo.text = "%d / %d m" % [int(_metros_recorridos), int(_metros_objetivo)]
	_animar_marcas_carretera(delta)

	# Nivel completado: lo evaluamos PRIMERO para que una recompensa de fin de
	# nivel no se confunda con un checkpoint si en el mismo frame se cruzan
	# ambos umbrales.
	if _metros_recorridos >= _metros_objetivo:
		_niveles_pasados += 1
		_nivel_en_curso = false
		_input_activo = false
		lbl_estado.text = "¡Nivel %d superado!" % _nivel_actual
		_lanzar_pregunta_aleatoria("Recompensa de nivel")
		return

	if _detectar_colisiones_y_aplicar_aceite():
		_on_choque()
		return

	# Disparador por distancia (solo si aún no hemos alcanzado el objetivo)
	if _metros_recorridos - _ultima_pregunta_metros >= METROS_ENTRE_PREGUNTAS:
		_ultima_pregunta_metros = _metros_recorridos
		_nivel_en_curso = false
		_input_activo = false
		_lanzar_pregunta_aleatoria("Checkpoint a los %d m" % int(_metros_recorridos))
		return

func _mover_jugador(delta):
	if not _input_activo:
		return
	var dir := 0.0
	if Input.is_action_pressed("ui_left"):
		dir -= 1.0
	if Input.is_action_pressed("ui_right"):
		dir += 1.0
	if dir == 0.0:
		return
	# Si estamos sobre aceite, vamos más lentos.
	var vel = VEL_LATERAL
	if Time.get_ticks_msec() / 1000.0 < _slow_hasta:
		vel *= FACTOR_SLOW_ACEITE
	var x_min = MARGEN_PISTA
	var x_max = area_juego.size.x - MARGEN_PISTA - jugador.size.x
	jugador.position.x = clamp(jugador.position.x + dir * vel * delta, x_min, x_max)
	jugador.position.y = area_juego.size.y - jugador.size.y - 18

func _spawnear_obstaculos(delta):
	_spawn_acumulado += delta
	while _spawn_acumulado >= _spawn_intervalo:
		_spawn_acumulado -= _spawn_intervalo
		_spawnear_uno()

func _spawnear_uno():
	if _x_carril.is_empty():
		return
	# Guardia: nunca dejamos al jugador con todos los carriles bloqueados arriba.
	var ocupados = _carriles_ocupados_arriba()
	var libres: Array = []
	for i in range(NUM_CARRILES):
		if not ocupados[i]:
			libres.append(i)
	# Si NO hay ningún carril libre arriba, esperamos al siguiente tick.
	if libres.is_empty():
		return
	# Pesos: coche 50%, cono 22%, aceite 18%, barrera 10%.
	# La barrera solo se permite si quedan al menos 2 carriles libres (porque
	# ella misma ocupa 2 y debe dejar al menos uno).
	var roll = _rng.randf()
	if roll < 0.50:
		_spawn_coche(libres)
	elif roll < 0.72:
		_spawn_cono(libres)
	elif roll < 0.90:
		_spawn_aceite()
	else:
		if libres.size() >= 3:
			_spawn_barrera()
		else:
			_spawn_coche(libres)

# Devuelve un Array[bool] de tamaño NUM_CARRILES indicando si ese carril
# tiene un obstáculo SÓLIDO en la zona alta del área (los primeros ~30%).
# El aceite no cuenta porque se puede pisar.
func _carriles_ocupados_arriba() -> Array:
	var ocupados: Array = []
	for i in range(NUM_CARRILES):
		ocupados.append(false)
	var umbral_y = area_juego.size.y * 0.30
	for b in _bloques:
		if not is_instance_valid(b.rect):
			continue
		var tipo = str(b.get("tipo", ""))
		if tipo == "ACEITE":
			continue
		if b.rect.position.y > umbral_y:
			continue
		for c in b.get("carriles", []):
			var idx = int(c)
			if idx >= 0 and idx < NUM_CARRILES:
				ocupados[idx] = true
	return ocupados

# Centro X del carril i (en coords locales del área de juego).
func _centro_carril_x(i: int) -> float:
	var ancho_util = area_juego.size.x - 2 * MARGEN_PISTA
	return MARGEN_PISTA + ancho_util * (float(i) + 0.5) / float(NUM_CARRILES)

# Coche: ocupa carril completo, tamaño = jugador, velocidad normal.
func _spawn_coche(libres: Array):
	var carril = libres[_rng.randi() % libres.size()]
	var ancho = jugador.size.x
	var alto = jugador.size.y
	var color = COLORES_COCHE[_rng.randi() % COLORES_COCHE.size()]
	var rect = ColorRect.new()
	rect.color = color
	rect.size = Vector2(ancho, alto)
	rect.position = Vector2(_centro_carril_x(carril) - ancho / 2.0, -alto)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Parabrisas
	var parabrisas = ColorRect.new()
	parabrisas.color = Color(0.15, 0.2, 0.3, 0.85)
	parabrisas.size = Vector2(ancho * 0.7, alto * 0.15)
	parabrisas.position = Vector2(ancho * 0.15, alto * 0.12)
	parabrisas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.add_child(parabrisas)
	area_juego.add_child(rect)
	_bloques.append({"rect": rect, "vel": _vel_bloque_px, "tipo": "COCHE", "carriles": [carril]})

# Cono: pequeño, lento, centrado en su carril (sin jitter — feel de 3 carriles).
func _spawn_cono(libres: Array):
	var carril = libres[_rng.randi() % libres.size()]
	var ancho = jugador.size.x * 0.55
	var alto = jugador.size.y * 0.55
	var rect = ColorRect.new()
	rect.color = COLOR_CONO
	rect.size = Vector2(ancho, alto)
	rect.position = Vector2(_centro_carril_x(carril) - ancho / 2.0, -alto)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Banda blanca central, look de cono.
	var banda = ColorRect.new()
	banda.color = Color(1, 1, 1, 0.85)
	banda.size = Vector2(ancho, alto * 0.18)
	banda.position = Vector2(0, alto * 0.4)
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.add_child(banda)
	area_juego.add_child(rect)
	_bloques.append({"rect": rect, "vel": _vel_bloque_px * 0.7, "tipo": "CONO", "carriles": [carril]})

# Mancha de aceite: ocupa 1 carril completo. No mata, te frena al pisarla.
# Como NO es sólido, no usa la lista de carriles libres — puede caer sobre
# cualquier carril.
func _spawn_aceite():
	var carril = _rng.randi_range(0, NUM_CARRILES - 1)
	var ancho_carril = (area_juego.size.x - 2 * MARGEN_PISTA) / float(NUM_CARRILES)
	var ancho = ancho_carril * 0.9
	var alto = jugador.size.y * 1.4
	var rect = ColorRect.new()
	rect.color = COLOR_ACEITE
	rect.size = Vector2(ancho, alto)
	rect.position = Vector2(_centro_carril_x(carril) - ancho / 2.0, -alto)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Reflejo central tipo charco.
	var brillo = ColorRect.new()
	brillo.color = Color(0.7, 0.7, 0.85, 0.18)
	brillo.size = Vector2(ancho * 0.6, alto * 0.3)
	brillo.position = Vector2(ancho * 0.2, alto * 0.3)
	brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.add_child(brillo)
	area_juego.add_child(rect)
	# Algo más lento que la pista, parece estático.
	_bloques.append({"rect": rect, "vel": _vel_bloque_px * 0.85, "tipo": "ACEITE", "carriles": [carril]})

# Barrera: ocupa exactamente 2 carriles adyacentes — el jugador debe esquivar
# al carril que queda libre. Se elige el par (0,1) o (1,2) al azar.
func _spawn_barrera():
	var pares = [[0, 1], [1, 2]]
	var par = pares[_rng.randi_range(0, pares.size() - 1)]
	var ancho_carril = (area_juego.size.x - 2 * MARGEN_PISTA) / float(NUM_CARRILES)
	var ancho = ancho_carril * 2.0
	var alto = jugador.size.y * 2.0
	# X = borde izquierdo del primer carril del par.
	var x = _centro_carril_x(par[0]) - ancho_carril / 2.0
	var rect = ColorRect.new()
	rect.color = COLOR_BARRERA
	rect.size = Vector2(ancho, alto)
	rect.position = Vector2(x, -alto)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Franjas negras estilo "obra"
	for i in range(4):
		var franja = ColorRect.new()
		franja.color = Color(0.1, 0.1, 0.1, 0.85)
		franja.size = Vector2(ancho / 4.0, alto)
		franja.position = Vector2((ancho / 4.0) * i, 0)
		franja.modulate.a = 0.0 if i % 2 == 0 else 1.0
		franja.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.add_child(franja)
	area_juego.add_child(rect)
	_bloques.append({"rect": rect, "vel": _vel_bloque_px, "tipo": "BARRERA", "carriles": par})

func _animar_marcas_carretera(delta):
	var alto = area_juego.size.y
	for m in _marcas_carretera:
		if not is_instance_valid(m):
			continue
		m.position.y += _vel_bloque_px * delta * 0.5
		if m.position.y > alto:
			m.position.y -= alto + 55.0

func _mover_bloques(delta):
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

# Devuelve true si hay choque sólido (no aceite). El aceite se aplica como
# slow en este mismo recorrido sin romper el nivel.
func _detectar_colisiones_y_aplicar_aceite() -> bool:
	var ahora = Time.get_ticks_msec() / 1000.0
	var rj = Rect2(jugador.position, jugador.size).grow(-4)
	var hay_choque = false
	for b in _bloques:
		if not is_instance_valid(b.rect):
			continue
		var rb = Rect2(b.rect.position, b.rect.size)
		if not rj.intersects(rb):
			continue
		var tipo = str(b.get("tipo", "COCHE"))
		if tipo == "ACEITE":
			# Mantener slow mientras el jugador siga sobre el aceite.
			_slow_hasta = max(_slow_hasta, ahora + DURACION_SLOW_ACEITE)
		elif ahora >= _invulnerable_hasta:
			hay_choque = true
	return hay_choque

func _on_choque():
	# El choque NO termina el nivel: lanza una pregunta y al cerrar el modal
	# vuelves al volante con un par de segundos de invulnerabilidad.
	_nivel_en_curso = false
	_input_activo = false
	jugador.color = COLOR_JUGADOR_HIT
	_invulnerable_hasta = Time.get_ticks_msec() / 1000.0 + INVULN_TRAS_CHOQUE
	lbl_estado.text = "¡Chocaste! Responde para seguir"
	# Limpiamos los obstáculos sólidos solapados con el jugador para no
	# encadenar choques al volver del modal.
	for b in _bloques:
		if not is_instance_valid(b.rect):
			continue
		var tipo = str(b.get("tipo", "COCHE"))
		if tipo == "ACEITE":
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
	if not is_inside_tree():
		return
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
