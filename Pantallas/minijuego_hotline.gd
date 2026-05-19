extends Control

# Minijuego "Hotline" (subtipo HOTLINE): top-down arena con combate mixto.
# - Mover: WASD / flechas
# - Apuntar: el ratón (un pequeño indicador en el jugador marca la dirección)
# - Atacar: ESPACIO (melee corto en la dirección a la que apunta el jugador)
# - Disparar: click izquierdo (munición limitada, los enemigos pueden soltar)
#
# Cada nivel se genera aleatorio entre dos objetivos:
#   1) LIMPIAR — matar a todos los enemigos generados
#   2) ESCAPE  — llegar a una zona de salida (los enemigos te complican el camino)
# Si superas el nivel: pregunta sorpresa.
# Si mueres antes de game over: pregunta extra de "revivir".
#
# Enemigos:
#   - Cada uno tiene HP (1 → básico rojo, 2 → naranja, 3+ → morado tanque).
#   - Las balas y el melee restan 1 HP. Solo mueren al llegar a 0.
#   - Al morir, ~35% de dropear munición que el jugador recoge pisándola.

@onready var btn_salir = $Layout/Header/HBox/BtnSalir
@onready var titulo = $Layout/Header/HBox/Titulo
@onready var lbl_nivel = $Layout/Header/HBox/LblNivel
@onready var area_juego: Control = $Layout/CentroPanel/PanelJuego/VBoxCentro/MargenJuego/AreaJuego
@onready var jugador: ColorRect = $Layout/CentroPanel/PanelJuego/VBoxCentro/MargenJuego/AreaJuego/Jugador
@onready var mira: ColorRect = $Layout/CentroPanel/PanelJuego/VBoxCentro/MargenJuego/AreaJuego/Jugador/Mira
@onready var salida: ColorRect = $Layout/CentroPanel/PanelJuego/VBoxCentro/MargenJuego/AreaJuego/Salida
@onready var lbl_estado = $Layout/CentroPanel/PanelJuego/VBoxCentro/HBoxEstado/LblEstado
@onready var lbl_objetivo = $Layout/CentroPanel/PanelJuego/VBoxCentro/HBoxEstado/LblObjetivo
@onready var lbl_municion = $Layout/CentroPanel/PanelJuego/VBoxCentro/HBoxEstado/LblMunicion
@onready var lbl_countdown: Label = $LblCountdown

@onready var overlay_pregunta = $OverlayPregunta
@onready var lbl_enunciado = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/LblEnunciado
@onready var lbl_tiempo_preg = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/LblTiempoPreg
@onready var progreso_tiempo = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/ProgresoTiempo
@onready var contenedor_respuesta = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/ContenedorRespuesta
@onready var btn_enviar_pregunta = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/HBoxBotonesModal/BtnEnviarPregunta
@onready var btn_saltar_pregunta = $OverlayPregunta/ModalPregunta/MarginModal/VBoxModal/HBoxBotonesModal/BtnSaltarPregunta
@onready var timer_pregunta = $TimerPregunta

const VEL_JUGADOR := 220.0
const VEL_ENEMIGO_BASE := 80.0
const VEL_ENEMIGO_INCR := 12.0
const VEL_BALA := 520.0

# --- Melee mejorado ---
# Antes: alcance 50, cono 60º (dot >= 0.5), cooldown 0.35.
# Ahora: más alcance, cono mucho más ancho, cooldown más corto, la distancia
# se mide al BORDE del enemigo y los enemigos quedan brevemente aturdidos al
# impactar → se nota el "swing".
const ALCANCE_MELEE := 80.0
const COOLDOWN_MELEE := 0.20
const DOT_CONO_MELEE := 0.20             # cos ~78º → cono frontal de ~155º
const KNOCKBACK_MELEE := 28.0            # empuje al enemigo al impactar
const STUN_MELEE_SEG := 0.18             # tiempo que el enemigo queda paralizado
const ALTO_FLASH_MELEE := 64.0           # alto del rect del flash (visual del cono)

# --- Drops de munición ---
# Los enemigos sueltan munición con cierta probabilidad. Para evitar rachas
# pésimas, llevamos un contador "pity": cada 4 kills sin drop, forzamos uno.
const PROB_DROP_BALAS := 0.50            # 50% de los enemigos sueltan balas
const BALAS_POR_DROP_MIN := 1
const BALAS_POR_DROP_MAX := 4
const PITY_DROP_KILLS := 4               # tras X kills sin drop, siguiente garantizado
const VIDA_DROP_SEG := 8.0               # tiempo que el pickup queda en el suelo
const AVISO_SIN_BALAS_COOLDOWN := 1.0    # throttle para la notificación

const COLOR_JUGADOR = Color(0.4, 0.95, 1.0, 1)
const COLOR_JUGADOR_MUERTO = Color(0.4, 0.4, 0.4, 1)
const COLOR_ENEMIGO = Color(1, 0.4, 0.4, 1)
const COLOR_ENEMIGO_MEDIO = Color(1, 0.55, 0.3, 1)
const COLOR_ENEMIGO_TANQUE = Color(0.85, 0.25, 0.7, 1)
const COLOR_BALA = Color(1, 0.95, 0.4, 1)
const COLOR_MELEE_FX = Color(1, 1, 0.5, 0.55)
const COLOR_DROP = Color(1, 0.85, 0.2, 1)
const TIEMPO_CONTINUAR := 0.9
const OBJETIVO_LIMPIAR := "LIMPIAR"
const OBJETIVO_ESCAPE := "ESCAPE"

var _prueba_id: int = -1
var _prueba_titulo: String = ""
var _niveles_totales: int = 5
var _preguntas: Array = []
var _nivel_actual: int = 0
var _niveles_pasados: int = 0
var _ya_revivido_este_nivel: bool = false

# Estado de juego activo
var _enemigos: Array = []  # [{rect, vel, hp, hp_max, hp_fill, stun_hasta}]
var _balas: Array = []     # [{rect, dir}]
var _drops: Array = []     # [{rect, vida, balas}]
var _balas_restantes: int = 0
var _melee_cooldown: float = 0.0
var _objetivo_actual: String = OBJETIVO_LIMPIAR
var _enemigos_totales_nivel: int = 0
var _enemigos_muertos: int = 0
var _kills_sin_drop: int = 0
var _aviso_sin_balas_hasta: float = 0.0
var _vivo: bool = false
var _nivel_en_curso: bool = false
var _input_activo: bool = false
var _en_countdown: bool = false
var _rng := RandomNumberGenerator.new()

# Estado de la pregunta activa
var _pregunta_actual: Dictionary = {}
var _tiempo_restante_pregunta: float = 0.0
var _input_pregunta = null
var _grupo_respuestas: ButtonGroup = null
# Si la pregunta fue lanzada al morir, al cerrarla revivimos en lugar de pasar nivel
var _pregunta_por_muerte: bool = false

func _ready():
	btn_salir.pressed.connect(_on_salir)
	btn_enviar_pregunta.pressed.connect(_on_enviar_pregunta)
	btn_saltar_pregunta.pressed.connect(_on_saltar_pregunta)
	timer_pregunta.timeout.connect(_tick_pregunta)
	overlay_pregunta.visible = false
	salida.visible = false
	lbl_countdown.visible = false
	_rng.randomize()
	titulo.text = "Hotline · top-down"

	if _prueba_id < 0 and not GameManager.minijuego_pendiente.is_empty():
		var pendiente = GameManager.minijuego_pendiente
		iniciar_minijuego(
			int(pendiente.get("id", -1)),
			str(pendiente.get("titulo", "Hotline")),
			int(pendiente.get("nivelesMinijuego", 5))
		)
		GameManager.minijuego_pendiente = {}

func iniciar_minijuego(prueba_id: int, prueba_titulo: String, niveles: int):
	_prueba_id = prueba_id
	_prueba_titulo = prueba_titulo
	_niveles_totales = clamp(niveles, 3, 10)
	titulo.text = "%s · Hotline" % _prueba_titulo
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
	_ya_revivido_este_nivel = false
	_limpiar_enemigos()
	_limpiar_balas()
	_limpiar_drops()

	# Decidimos el objetivo aleatorio para variar el ritmo del juego.
	_objetivo_actual = OBJETIVO_LIMPIAR if _rng.randi_range(0, 1) == 0 else OBJETIVO_ESCAPE
	_enemigos_muertos = 0
	# Munición por nivel: mínimo garantizado decreciente, pero conservamos
	# las balas que el alumno haya acumulado de drops/niveles anteriores.
	# Así, jugar bien (matar enemigos y recoger drops) se nota a largo plazo.
	var minimo_nivel = max(3, 6 - int(_nivel_actual / 2))
	_balas_restantes = max(_balas_restantes, minimo_nivel)

	# Generamos enemigos (más por nivel)
	var n_enemigos = 2 + _nivel_actual
	if _objetivo_actual == OBJETIVO_ESCAPE:
		n_enemigos = max(2, n_enemigos - 1)
	_enemigos_totales_nivel = n_enemigos
	for i in range(n_enemigos):
		_spawnear_enemigo()

	# Salida solo visible en modo ESCAPE
	if _objetivo_actual == OBJETIVO_ESCAPE:
		_colocar_salida()
		salida.visible = true
		lbl_objetivo.text = "Llega a la salida verde"
	else:
		salida.visible = false
		lbl_objetivo.text = "Mata a los %d enemigos" % n_enemigos

	# Reset del jugador
	var area = area_juego.size
	var tam_jugador = clamp(area.x / 40.0, 18, 36)
	jugador.custom_minimum_size = Vector2(tam_jugador, tam_jugador)
	jugador.size = Vector2(tam_jugador, tam_jugador)
	jugador.color = COLOR_JUGADOR
	jugador.visible = true
	_colocar_jugador_centro()
	_actualizar_municion_label()

	_vivo = true
	_nivel_en_curso = false
	_input_activo = false
	lbl_estado.text = "Prepárate..."
	_mostrar_countdown()

func _colocar_jugador_centro():
	var area = area_juego.size
	jugador.position = Vector2(
		area.x / 2.0 - jugador.size.x / 2.0,
		area.y / 2.0 - jugador.size.y / 2.0
	)

func _colocar_salida():
	var area = area_juego.size
	# Salida en una esquina aleatoria, lejos del jugador
	var esquinas = [
		Vector2(20, 20),
		Vector2(area.x - salida.size.x - 20, 20),
		Vector2(20, area.y - salida.size.y - 20),
		Vector2(area.x - salida.size.x - 20, area.y - salida.size.y - 20),
	]
	salida.position = esquinas[_rng.randi_range(0, esquinas.size() - 1)]

func _spawnear_enemigo():
	var area = area_juego.size
	var lado = _rng.randi_range(0, 3)
	var tam_base = clamp(area.x / 45.0, 16, 32)
	var tam = Vector2(tam_base, tam_base)
	var pos: Vector2
	match lado:
		0: pos = Vector2(_rng.randf_range(0, area.x - tam.x), 0)
		1: pos = Vector2(area.x - tam.x, _rng.randf_range(0, area.y - tam.y))
		2: pos = Vector2(_rng.randf_range(0, area.x - tam.x), area.y - tam.y)
		_: pos = Vector2(0, _rng.randf_range(0, area.y - tam.y))

	# HP escalada con el nivel: en lvl 1 mayormente 1hp, en lvl 5 hasta 3-4hp.
	var hp_max := 1
	hp_max += _rng.randi_range(0, min(_nivel_actual / 2, 2))
	if _nivel_actual >= 3 and _rng.randf() < 0.20:
		hp_max += 1  # "tanques" puntuales

	var color = COLOR_ENEMIGO
	if hp_max >= 3:
		color = COLOR_ENEMIGO_TANQUE
		tam = Vector2(tam_base * 1.25, tam_base * 1.25)  # los tanques son un poco más grandes
	elif hp_max == 2:
		color = COLOR_ENEMIGO_MEDIO

	var rect = ColorRect.new()
	rect.color = color
	rect.size = tam
	rect.position = pos
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Ojo amarillo como acento visual
	var ojo = ColorRect.new()
	ojo.color = Color(1, 0.9, 0.2, 0.9)
	ojo.size = Vector2(tam.x * 0.3, tam.y * 0.3)
	ojo.position = Vector2(tam.x * 0.35, tam.y * 0.2)
	ojo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.add_child(ojo)

	# Barra de vida: fondo negro semi-transparente + relleno rojo encima.
	# Solo se ve si el enemigo tiene más de 1 HP (los básicos no la necesitan).
	var hp_bg = ColorRect.new()
	hp_bg.color = Color(0, 0, 0, 0.7)
	hp_bg.size = Vector2(tam.x, 4)
	hp_bg.position = Vector2(0, tam.y + 3)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bg.visible = hp_max > 1
	rect.add_child(hp_bg)
	var hp_fill = ColorRect.new()
	hp_fill.color = Color(0.95, 0.3, 0.3, 1)
	hp_fill.size = Vector2(tam.x, 4)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bg.add_child(hp_fill)

	area_juego.add_child(rect)
	var vel = VEL_ENEMIGO_BASE + VEL_ENEMIGO_INCR * (_nivel_actual - 1) + _rng.randf_range(-15, 15)
	# Los tanques son un pelín más lentos para compensar.
	if hp_max >= 3:
		vel *= 0.8
	_enemigos.append({
		"rect": rect,
		"vel": vel,
		"hp": hp_max,
		"hp_max": hp_max,
		"hp_fill": hp_fill,
		"stun_hasta": 0.0
	})

func _limpiar_enemigos():
	for e in _enemigos:
		if e.rect and is_instance_valid(e.rect):
			e.rect.queue_free()
	_enemigos.clear()

func _limpiar_balas():
	for b in _balas:
		if b.rect and is_instance_valid(b.rect):
			b.rect.queue_free()
	_balas.clear()

func _limpiar_drops():
	for d in _drops:
		if d.rect and is_instance_valid(d.rect):
			d.rect.queue_free()
	_drops.clear()

func _actualizar_municion_label():
	lbl_municion.text = "Balas: %d" % _balas_restantes

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
	lbl_estado.text = "WASD mover · ESPACIO melee · CLIC disparar"
	_nivel_en_curso = true
	_input_activo = true

# =====================================================================
# LOOP DE JUEGO
# =====================================================================

func _process(delta):
	if not _nivel_en_curso or not _vivo or _en_countdown:
		return
	_orientar_mira()
	_mover_jugador(delta)
	if _melee_cooldown > 0.0:
		_melee_cooldown = max(0.0, _melee_cooldown - delta)
	_mover_enemigos(delta)
	_mover_balas(delta)
	_colisiones_balas_enemigos()
	_procesar_drops(delta)
	if _colision_jugador_enemigo():
		_on_muerte()
		return
	if _objetivo_actual == OBJETIVO_ESCAPE and _colision_jugador_salida():
		_on_nivel_superado()
		return
	if _objetivo_actual == OBJETIVO_LIMPIAR and _enemigos_muertos >= _enemigos_totales_nivel:
		_on_nivel_superado()

func _orientar_mira():
	# La mira es un pequeño indicador delante del jugador en la dirección
	# del ratón. Se usa también como dirección del melee/disparo.
	var pos_global = jugador.global_position + jugador.size / 2.0
	var dir = (jugador.get_global_mouse_position() - pos_global).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	# Colocamos la mira justo delante del jugador (en coords locales).
	var off = dir * (jugador.size.x * 0.55)
	mira.position = jugador.size / 2.0 - mira.size / 2.0 + off

func _direccion_apuntado() -> Vector2:
	var pos_global = jugador.global_position + jugador.size / 2.0
	var dir = (jugador.get_global_mouse_position() - pos_global).normalized()
	if dir == Vector2.ZERO:
		return Vector2.RIGHT
	return dir

func _mover_jugador(delta):
	if not _input_activo:
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
	var area = area_juego.size
	var pos = jugador.position + dir * VEL_JUGADOR * delta
	pos.x = clamp(pos.x, 0.0, area.x - jugador.size.x)
	pos.y = clamp(pos.y, 0.0, area.y - jugador.size.y)
	jugador.position = pos

func _mover_enemigos(delta):
	var pos_jugador = jugador.position + jugador.size / 2.0
	var ahora = Time.get_ticks_msec() / 1000.0
	for e in _enemigos:
		if not is_instance_valid(e.rect):
			continue
		# Enemigos aturdidos por melee se quedan plantados hasta que pase el stun.
		if float(e.get("stun_hasta", 0.0)) > ahora:
			continue
		var centro = e.rect.position + e.rect.size / 2.0
		var dir = (pos_jugador - centro).normalized()
		e.rect.position += dir * e.vel * delta

func _mover_balas(delta):
	var area = area_juego.size
	var vivas: Array = []
	for b in _balas:
		if not is_instance_valid(b.rect):
			continue
		b.rect.position += b.dir * VEL_BALA * delta
		var p = b.rect.position
		if p.x < -20 or p.y < -20 or p.x > area.x + 20 or p.y > area.y + 20:
			b.rect.queue_free()
		else:
			vivas.append(b)
	_balas = vivas

func _colisiones_balas_enemigos():
	var balas_vivas: Array = []
	for b in _balas:
		if not is_instance_valid(b.rect):
			continue
		var rb = Rect2(b.rect.position, b.rect.size)
		var impacto = false
		for e in _enemigos:
			if not is_instance_valid(e.rect):
				continue
			var re = Rect2(e.rect.position, e.rect.size)
			if rb.intersects(re):
				impacto = true
				_aplicar_dano_enemigo(e, 1, b.dir)
				break
		if impacto:
			b.rect.queue_free()
		else:
			balas_vivas.append(b)
	_balas = balas_vivas
	_limpiar_enemigos_muertos()

func _colision_jugador_enemigo() -> bool:
	var rj = Rect2(jugador.position, jugador.size).grow(-2)
	for e in _enemigos:
		if not is_instance_valid(e.rect):
			continue
		var re = Rect2(e.rect.position, e.rect.size)
		if rj.intersects(re):
			return true
	return false

func _colision_jugador_salida() -> bool:
	if not salida.visible:
		return false
	var rj = Rect2(jugador.position, jugador.size)
	var rs = Rect2(salida.position, salida.size)
	return rj.intersects(rs)

# =====================================================================
# DAÑO Y MUERTE DE ENEMIGOS
# =====================================================================

func _aplicar_dano_enemigo(e: Dictionary, dano: int, dir_empuje: Vector2 = Vector2.ZERO, es_melee: bool = false):
	if not is_instance_valid(e.rect):
		return
	e.hp -= dano
	if e.hp <= 0:
		var centro = e.rect.position + e.rect.size / 2.0
		_intentar_drop_balas(centro)
		e.rect.queue_free()
		_enemigos_muertos += 1
		return
	# Actualizar barra de vida.
	_actualizar_hp_bar(e)
	# Pequeño knockback si nos llega una dirección de impacto.
	if dir_empuje != Vector2.ZERO:
		e.rect.position += dir_empuje * 8.0
	# El melee aturde brevemente: el enemigo se queda plantado.
	if es_melee:
		e["stun_hasta"] = Time.get_ticks_msec() / 1000.0 + STUN_MELEE_SEG
	# Flash blanco rápido para dar feedback.
	if e.rect.has_meta("_flash_tween"):
		var prev = e.rect.get_meta("_flash_tween")
		if prev is Tween and prev.is_valid():
			prev.kill()
	e.rect.modulate = Color(2, 2, 2, 1)
	var tw = create_tween()
	tw.tween_property(e.rect, "modulate", Color.WHITE, 0.12)
	e.rect.set_meta("_flash_tween", tw)

func _actualizar_hp_bar(e: Dictionary):
	if not e.has("hp_fill") or not is_instance_valid(e.hp_fill):
		return
	var parent: Control = e.hp_fill.get_parent()
	if not is_instance_valid(parent):
		return
	var ratio = clamp(float(e.hp) / float(e.hp_max), 0.0, 1.0)
	e.hp_fill.size.x = parent.size.x * ratio

func _limpiar_enemigos_muertos():
	var vivos: Array = []
	for e in _enemigos:
		if is_instance_valid(e.rect):
			vivos.append(e)
	_enemigos = vivos

# =====================================================================
# DROPS DE MUNICIÓN
# =====================================================================

func _intentar_drop_balas(pos: Vector2):
	# Pity timer: si llevas PITY_DROP_KILLS kills sin un drop, el siguiente
	# enemigo lo suelta seguro. Evita rachas frustrantes de "ningún enemigo
	# suelta nada en todo el nivel".
	var forzar_drop = _kills_sin_drop >= PITY_DROP_KILLS
	if not forzar_drop and _rng.randf() > PROB_DROP_BALAS:
		_kills_sin_drop += 1
		return
	_kills_sin_drop = 0
	var cantidad = _rng.randi_range(BALAS_POR_DROP_MIN, BALAS_POR_DROP_MAX)
	var drop = ColorRect.new()
	drop.color = COLOR_DROP
	drop.size = Vector2(16, 16)
	drop.position = pos - drop.size / 2.0
	drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Cruz "+" oscura encima para que se lea como "ítem"
	var barra_h = ColorRect.new()
	barra_h.color = Color(0.1, 0.1, 0.15, 1)
	barra_h.size = Vector2(10, 2)
	barra_h.position = Vector2(3, 7)
	barra_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop.add_child(barra_h)
	var barra_v = ColorRect.new()
	barra_v.color = Color(0.1, 0.1, 0.15, 1)
	barra_v.size = Vector2(2, 10)
	barra_v.position = Vector2(7, 3)
	barra_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop.add_child(barra_v)
	area_juego.add_child(drop)
	_drops.append({"rect": drop, "vida": VIDA_DROP_SEG, "balas": cantidad})

func _procesar_drops(delta):
	var rj = Rect2(jugador.position, jugador.size)
	var vivos: Array = []
	for d in _drops:
		if not is_instance_valid(d.rect):
			continue
		d.vida -= delta
		if d.vida <= 0.0:
			d.rect.queue_free()
			continue
		# Parpadeo final cuando queda poco.
		if d.vida < 2.0:
			d.rect.modulate.a = 0.4 + 0.6 * abs(sin(d.vida * 8.0))
		# Pickup.
		var rd = Rect2(d.rect.position, d.rect.size)
		if rj.intersects(rd):
			_balas_restantes += int(d.balas)
			_actualizar_municion_label()
			Notificador.notificar("+%d balas" % int(d.balas), Color(1, 0.85, 0.2))
			d.rect.queue_free()
			continue
		vivos.append(d)
	_drops = vivos

# =====================================================================
# INPUT DE COMBATE
# =====================================================================

func _input(event):
	if not _input_activo or not _vivo or _en_countdown:
		return
	# ui_accept ya está mapeado por defecto a SPACE en Godot, así que con un
	# solo check sirve para teclado físico y para gamepad.
	if event.is_action_pressed("ui_accept"):
		_intentar_melee()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_intentar_disparar()

func _intentar_melee():
	if _melee_cooldown > 0.0:
		return
	_melee_cooldown = COOLDOWN_MELEE
	var origen = jugador.position + jugador.size / 2.0
	var dir = _direccion_apuntado()
	_mostrar_flash_melee(origen, dir)
	for e in _enemigos:
		if not is_instance_valid(e.rect):
			continue
		var centro = e.rect.position + e.rect.size / 2.0
		var rel = centro - origen
		# Distancia desde el centro del jugador al BORDE más cercano del enemigo.
		# Es más permisivo que medir centro-a-centro; antes con enemigos de 32 px
		# y alcance 50 había que estar literalmente pegado.
		var radio_enemigo = max(e.rect.size.x, e.rect.size.y) * 0.5
		var dist_borde = max(0.0, rel.length() - radio_enemigo)
		if dist_borde > ALCANCE_MELEE:
			continue
		# Cono frontal muy ancho (~155º).
		if rel.length() > 1.0 and rel.normalized().dot(dir) < DOT_CONO_MELEE:
			continue
		_aplicar_dano_enemigo(e, 1, dir * (KNOCKBACK_MELEE / 8.0), true)
	_limpiar_enemigos_muertos()

func _mostrar_flash_melee(origen: Vector2, dir: Vector2):
	# Flash en forma de "abanico ancho" para que el visual coincida con el
	# cono real de detección (~155º). Lo hacemos con un rect más alto que
	# ancho relativo, rotado alrededor del origen.
	var fx = ColorRect.new()
	fx.color = COLOR_MELEE_FX
	fx.size = Vector2(ALCANCE_MELEE + 20.0, ALTO_FLASH_MELEE)
	fx.position = origen - Vector2(0, ALTO_FLASH_MELEE / 2.0)
	fx.pivot_offset = Vector2(0, ALTO_FLASH_MELEE / 2.0)
	fx.rotation = dir.angle()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_juego.add_child(fx)
	var tw = create_tween()
	tw.tween_property(fx, "modulate:a", 0.0, 0.18)
	tw.tween_callback(fx.queue_free)

func _intentar_disparar():
	if _balas_restantes <= 0:
		# Throttle: solo lanzamos la notificación una vez por segundo aunque
		# el alumno haga spam-click sin munición.
		var ahora = Time.get_ticks_msec() / 1000.0
		if ahora >= _aviso_sin_balas_hasta:
			Notificador.notificar("Sin balas, usa el melee (ESPACIO)", Color.ORANGE)
			_aviso_sin_balas_hasta = ahora + AVISO_SIN_BALAS_COOLDOWN
		return
	_balas_restantes -= 1
	_actualizar_municion_label()
	var origen = jugador.position + jugador.size / 2.0
	var dir = _direccion_apuntado()
	var bala = ColorRect.new()
	bala.color = COLOR_BALA
	bala.size = Vector2(12, 6)
	bala.position = origen - bala.size / 2.0
	bala.pivot_offset = bala.size / 2.0
	bala.rotation = dir.angle()
	bala.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_juego.add_child(bala)
	_balas.append({"rect": bala, "dir": dir})

# =====================================================================
# RESULTADOS DEL NIVEL
# =====================================================================

func _on_nivel_superado():
	_niveles_pasados += 1
	_nivel_en_curso = false
	_input_activo = false
	lbl_estado.text = "¡Nivel %d superado!" % _nivel_actual
	# Limpiamos al terminar para que no se quede nadie correteando.
	_limpiar_enemigos()
	_limpiar_balas()
	_limpiar_drops()
	_pregunta_por_muerte = false
	_lanzar_pregunta_aleatoria()

func _on_muerte():
	_vivo = false
	_input_activo = false
	jugador.color = COLOR_JUGADOR_MUERTO
	if _ya_revivido_este_nivel:
		# Ya tuviste tu segunda oportunidad → game over de este nivel,
		# saltamos al siguiente sin marcarlo como superado.
		_nivel_en_curso = false
		lbl_estado.text = "Has caído. Pasando..."
		await get_tree().create_timer(1.2).timeout
		if not is_inside_tree():
			return
		_continuar_tras_nivel(false)
		return
	_ya_revivido_este_nivel = true
	lbl_estado.text = "¡Te alcanzaron! Responde para revivir"
	_pregunta_por_muerte = true
	_lanzar_pregunta_aleatoria()

func _revivir():
	# Limpiamos la arena para dar aire al alumno y reaparecemos en el centro.
	_limpiar_enemigos()
	_limpiar_balas()
	_limpiar_drops()
	_enemigos_muertos = 0
	# Generamos un set reducido para no machacar al alumno.
	var n_enemigos = max(2, _enemigos_totales_nivel - 2)
	_enemigos_totales_nivel = n_enemigos
	for i in range(n_enemigos):
		_spawnear_enemigo()
	jugador.color = COLOR_JUGADOR
	_colocar_jugador_centro()
	_vivo = true
	_nivel_en_curso = true
	_input_activo = true
	if _objetivo_actual == OBJETIVO_ESCAPE:
		lbl_objetivo.text = "Llega a la salida verde"
	else:
		lbl_objetivo.text = "Mata a los %d enemigos" % n_enemigos

# =====================================================================
# PREGUNTA SORPRESA
# =====================================================================

func _lanzar_pregunta_aleatoria():
	if _preguntas.is_empty():
		_cerrar_modal_y_continuar()
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
		_cerrar_modal_y_continuar()

func _on_enviar_pregunta():
	timer_pregunta.stop()
	_enviar_respuesta_al_backend()
	_cerrar_modal_y_continuar()

func _on_saltar_pregunta():
	timer_pregunta.stop()
	_cerrar_modal_y_continuar()

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

func _cerrar_modal_y_continuar():
	overlay_pregunta.visible = false
	_limpiar_contenedor_respuesta()
	await get_tree().create_timer(TIEMPO_CONTINUAR).timeout
	if not is_inside_tree():
		return
	if _pregunta_por_muerte:
		_pregunta_por_muerte = false
		_revivir()
		return
	_continuar_tras_nivel(true)

func _continuar_tras_nivel(_paso: bool):
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
	_limpiar_enemigos()
	_limpiar_balas()
	_limpiar_drops()
	jugador.visible = false
	lbl_estado.text = "¡Minijuego completado! · %d / %d niveles" % [_niveles_pasados, _niveles_totales]
	lbl_objetivo.text = ""
	Notificador.notificar(
		"Minijuego completado: %d/%d niveles" % [_niveles_pasados, _niveles_totales],
		Color.GREEN
	)
	if _prueba_id >= 0:
		ConexionManager.peticion_post(
			"/puntuacion/alta",
			{"idPrueba": _prueba_id},
			func(_d, _c): pass
		)

func _on_salir():
	NpcManager.reset_npc_activo()
	get_tree().change_scene_to_file("res://Niveles/nivel_01.tscn")
