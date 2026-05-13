extends Control

# =====================================================================
# CONFIGURACIÓN
# =====================================================================

## Escena a la que saltamos al pulsar cualquier tecla / clic.
@export_file("*.tscn") var escena_siguiente: String = "res://Niveles/nivel_01.tscn"

# Texto principal
const TEXTO := "POKEDUCATION"
const TAMANO_TEXTO := 200
const DURACION_BRILLO := 1.5     # segundos de un ciclo completo de oscilación
const VEL_BARRIDO := 1.0          # velocidad con la que el brillo recorre el texto

# Gradiente del texto (paleta Pokémon: púrpura → rosa → dorado → naranja)
const COLORES_TEXTO := [
	Color(0.55, 0.20, 0.95),  # Púrpura
	Color(1.00, 0.30, 0.70),  # Rosa / Magenta
	Color(1.00, 0.85, 0.20),  # Dorado
	Color(1.00, 0.50, 0.10),  # Naranja
]

# Paleta multicolor de partículas
const COLORES_PARTICULAS := [
	Color(1.00, 0.00, 1.00),  # MAGENTA
	Color(0.00, 1.00, 1.00),  # CYAN
	Color(1.00, 1.00, 0.00),  # YELLOW
	Color(1.00, 0.55, 0.00),  # NARANJA
	Color(0.50, 1.00, 0.00),  # LIME
	Color(1.00, 0.40, 0.75),  # ROSA
	Color(0.60, 0.20, 1.00),  # PÚRPURA
	Color(0.30, 1.00, 1.00),  # CYAN BRILLANTE
]

# Partículas
const SPAWN_RATE := 0.05         # segundos entre spawns
const PARTICULA_RADIO_MIN := 2.0
const PARTICULA_RADIO_MAX := 6.0
const PARTICULA_VIDA_MIN := 1.6
const PARTICULA_VIDA_MAX := 3.4
const PARTICULA_VEL_X := 60.0
const PARTICULA_VEL_Y_MIN := -110.0
const PARTICULA_VEL_Y_MAX := -25.0

const COLOR_FONDO := Color(0.10, 0.10, 0.15)
const TEXTO_INSTRUCCION := "Pulsa cualquier tecla o clic para continuar"
const TAMANO_INSTRUCCION := 22

# =====================================================================
# CLASE INTERNA: PARTÍCULA
# =====================================================================

class Particula:
	var posicion: Vector2
	var velocidad: Vector2
	var color: Color
	var radio: float
	var vida: float
	var vida_max: float

	func _init(p_pos: Vector2, p_vel: Vector2, p_color: Color, p_radio: float, p_vida: float):
		posicion = p_pos
		velocidad = p_vel
		color = p_color
		radio = p_radio
		vida = p_vida
		vida_max = p_vida

	## Devuelve false cuando hay que retirarla.
	func actualizar(delta: float) -> bool:
		posicion += velocidad * delta
		vida -= delta
		return vida > 0.0

	func alpha() -> float:
		return clamp(vida / vida_max, 0.0, 1.0)

# =====================================================================
# ESTADO
# =====================================================================

var _tiempo: float = 0.0
var _spawn_acumulado: float = 0.0
var _particulas: Array = []
var _rng := RandomNumberGenerator.new()
var _saltado: bool = false

# =====================================================================
# CICLO DE VIDA
# =====================================================================

func _ready():
	# Ocupar pantalla completa.
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()

func _process(delta: float):
	_tiempo += delta
	_actualizar_particulas(delta)
	_spawn_continuo(delta)
	queue_redraw()  # _draw() en cada frame para animar

func _input(event):
	if _saltado:
		return
	var saltar := false
	if event is InputEventKey and event.pressed and not event.is_echo():
		saltar = true
	elif event is InputEventMouseButton and event.pressed:
		saltar = true
	elif event is InputEventScreenTouch and event.pressed:
		saltar = true
	if saltar:
		_saltar()

# =====================================================================
# PARTÍCULAS
# =====================================================================

func _spawn_continuo(delta: float):
	_spawn_acumulado += delta
	# Bucle por si en un frame caben varias partículas (frames lentos)
	while _spawn_acumulado >= SPAWN_RATE:
		_spawn_acumulado -= SPAWN_RATE
		_generar_particula()

func _generar_particula():
	var rect = get_viewport_rect().size
	var pos = Vector2(_rng.randf() * rect.x, _rng.randf() * rect.y)
	var vel = Vector2(
		_rng.randf_range(-PARTICULA_VEL_X, PARTICULA_VEL_X),
		_rng.randf_range(PARTICULA_VEL_Y_MIN, PARTICULA_VEL_Y_MAX)
	)
	var color = COLORES_PARTICULAS[_rng.randi() % COLORES_PARTICULAS.size()]
	var radio = _rng.randf_range(PARTICULA_RADIO_MIN, PARTICULA_RADIO_MAX)
	var vida = _rng.randf_range(PARTICULA_VIDA_MIN, PARTICULA_VIDA_MAX)
	_particulas.append(Particula.new(pos, vel, color, radio, vida))

func _actualizar_particulas(delta: float):
	# Filtrado in-place: más barato que crear arrays nuevos cuando hay muchas.
	var i = 0
	while i < _particulas.size():
		if _particulas[i].actualizar(delta):
			i += 1
		else:
			_particulas.remove_at(i)

# =====================================================================
# RENDERIZADO
# =====================================================================

func _draw():
	var pantalla = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, pantalla), COLOR_FONDO)
	_dibujar_particulas()
	_dibujar_texto(pantalla)
	_dibujar_instruccion(pantalla)

func _dibujar_particulas():
	for p in _particulas:
		var c = p.color
		c.a = p.alpha()
		draw_circle(p.posicion, p.radio, c)

func _dibujar_texto(pantalla: Vector2):
	var font = ThemeDB.fallback_font
	var alto = font.get_height(TAMANO_TEXTO)
	var ascent = font.get_ascent(TAMANO_TEXTO)
	var ancho_total = font.get_string_size(TEXTO, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO_TEXTO).x
	var x = (pantalla.x - ancho_total) / 2.0
	var y = (pantalla.y - alto) / 2.0 + ascent

	# Posición normalizada [0..1] del barrido del brillo
	var barrido = fposmod(_tiempo * VEL_BARRIDO / DURACION_BRILLO, 1.0)
	var canvas = get_canvas_item()

	var n = TEXTO.length()
	for i in range(n):
		# Letra individual como String — usamos draw_string para evitar el
		# typing inconsistente de Font.draw_char entre versiones de Godot.
		var ch: String = TEXTO.substr(i, 1)
		var ancho_letra = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO_TEXTO).x

		var t_letra = float(i) / max(n - 1, 1)
		var color = _color_gradiente(t_letra)

		# Brillo: ola que avanza de izquierda a derecha
		var dist = abs(t_letra - barrido)
		dist = min(dist, 1.0 - dist)  # circular para que vuelva a empezar suave
		var intensidad_brillo = clamp(1.0 - dist * 3.0, 0.0, 1.0)
		# Combinamos con una oscilación global suave de 1.5 s
		var oscilacion = (sin(_tiempo * TAU / DURACION_BRILLO) * 0.5 + 0.5) * 0.5 + 0.5
		intensidad_brillo *= oscilacion

		# Sombra (profundidad)
		font.draw_string(
			canvas,
			Vector2(x + 4, y + 5),
			ch,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			TAMANO_TEXTO,
			Color(0, 0, 0, 0.55)
		)

		# Halo de brillo: varias pasadas alrededor para simular bloom
		if intensidad_brillo > 0.01:
			var glow = Color(1, 1, 1, 0.55 * intensidad_brillo).lerp(color, 0.3)
			for off in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
				font.draw_string(
					canvas,
					Vector2(x + off.x, y + off.y),
					ch,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					TAMANO_TEXTO,
					glow
				)

		# Letra principal con su color del gradiente
		font.draw_string(
			canvas,
			Vector2(x, y),
			ch,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			TAMANO_TEXTO,
			color
		)
		x += ancho_letra

func _dibujar_instruccion(pantalla: Vector2):
	var font = ThemeDB.fallback_font
	# Parpadeo suave (entre 0.35 y 1.0)
	var blink = (sin(_tiempo * TAU * 1.2) * 0.5 + 0.5) * 0.65 + 0.35
	var ancho = font.get_string_size(
		TEXTO_INSTRUCCION, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO_INSTRUCCION
	).x
	var pos = Vector2((pantalla.x - ancho) / 2.0, pantalla.y * 0.82)
	font.draw_string(
		get_canvas_item(),
		pos,
		TEXTO_INSTRUCCION,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		TAMANO_INSTRUCCION,
		Color(1, 1, 1, blink)
	)

# =====================================================================
# UTILIDADES
# =====================================================================

func _color_gradiente(t: float) -> Color:
	var n = COLORES_TEXTO.size()
	if n == 0:
		return Color.WHITE
	if n == 1:
		return COLORES_TEXTO[0]
	var idx = t * (n - 1)
	var i = int(floor(idx))
	var f = idx - float(i)
	if i >= n - 1:
		return COLORES_TEXTO[n - 1]
	return COLORES_TEXTO[i].lerp(COLORES_TEXTO[i + 1], f)

func _saltar():
	_saltado = true
	if escena_siguiente.is_empty():
		return
	get_tree().change_scene_to_file(escena_siguiente)
