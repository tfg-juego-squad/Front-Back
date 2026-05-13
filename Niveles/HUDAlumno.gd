extends CanvasLayer

@onready var ui_parent = $UIParent
@onready var panel_tareas = $UIParent/PanelTareas
@onready var progress_bar = $UIParent/XPBarContainer/VBox/ProgressBar
@onready var xp_label = $UIParent/XPBarContainer/VBox/XPLabel
@onready var lista_vbox = $UIParent/PanelTareas/Margen/VBox/ListaTareas
@onready var info_tab = $UIParent/InfoTab
@onready var panel_retrato = $UIParent/PanelRetrato
@onready var espejo_jugador: AnimatedSprite2D = $UIParent/PanelRetrato/VBoxRetrato/VistaCercana/SubViewport/EspejoJugador

var hud_visible = true
var _jugador_anim: AnimatedSprite2D = null

func _ready():
	ui_parent.visible = true
	$UIParent/XPBarContainer.visible = true
	info_tab.text = "Presiona [TAB] para ocultar tareas"
	info_tab.visible = true

	if GameManager.es_profesor:
		panel_tareas.visible = false
		$UIParent/XPBarContainer.visible = false
		panel_retrato.visible = false
		return

	panel_tareas.visible = true
	_actualizar_xp()
	_cargar_pruebas_pendientes()
	_inicializar_vista_cercana()

	await get_tree().create_timer(1.0).timeout
	var nombre = GameManager.usuario_actual.get("nombreUsuario", "alumno")
	Notificador.notificar("Bienvenido, %s" % nombre, Color.CYAN)

func _process(_delta):
	if _jugador_anim == null or not is_instance_valid(_jugador_anim) or espejo_jugador == null:
		return
	if espejo_jugador.sprite_frames == null:
		return
	# Reflejamos animación y frame del personaje real en el retrato del HUD.
	var anim_actual = _jugador_anim.animation
	if anim_actual == "" or not espejo_jugador.sprite_frames.has_animation(anim_actual):
		return
	if espejo_jugador.animation != anim_actual:
		espejo_jugador.play(anim_actual)
	espejo_jugador.frame = _jugador_anim.frame

func _input(event):
	if event.is_action_pressed("ui_focus_next"):
		hud_visible = !hud_visible
		panel_tareas.visible = hud_visible
		$UIParent/XPBarContainer.visible = hud_visible
		panel_retrato.visible = hud_visible
		info_tab.text = "Presiona [TAB] para %s tareas" % ("ocultar" if hud_visible else "ver")
		if hud_visible:
			_animar_aparicion()

func _animar_aparicion():
	ui_parent.modulate.a = 0
	create_tween().tween_property(ui_parent, "modulate:a", 1.0, 0.2)

# Inicializa el "espejo" del jugador: copia los SpriteFrames del personaje
# real y reproduce su animación en cada frame para mostrar un retrato vivo.
func _inicializar_vista_cercana():
	if espejo_jugador == null:
		return
	var arbol = get_tree()
	if arbol == null:
		return
	var jugador = arbol.get_root().find_child("User-PJ", true, false)
	if jugador == null:
		panel_retrato.visible = false
		return
	_jugador_anim = jugador.find_child("MoveAnimation", true, false) as AnimatedSprite2D
	if _jugador_anim == null:
		panel_retrato.visible = false
		return
	espejo_jugador.sprite_frames = _jugador_anim.sprite_frames
	# Arrancamos solo si la animación existe en los frames copiados.
	var anim = _jugador_anim.animation
	if espejo_jugador.sprite_frames and anim != "" and espejo_jugador.sprite_frames.has_animation(anim):
		espejo_jugador.play(anim)

func _actualizar_xp():
	# El backend devuelve null si el alumno aún no tiene nivel/XP iniciados.
	# int(null) revienta, así que comprobamos antes.
	var nivel_raw = GameManager.usuario_actual.get("nivelActual")
	var xp_raw = GameManager.usuario_actual.get("experienciaActual")
	var nivel = 1 if nivel_raw == null else int(nivel_raw)
	var xp = 0 if xp_raw == null else int(xp_raw)
	xp_label.text = "Nivel %d  ·  %d/100 XP" % [nivel, xp]
	progress_bar.max_value = 100
	progress_bar.value = clampi(xp, 0, 100)

func _cargar_pruebas_pendientes():
	for hijo in lista_vbox.get_children():
		hijo.queue_free()
	var lbl_cargando = Label.new()
	lbl_cargando.text = "Cargando..."
	lbl_cargando.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1))
	lista_vbox.add_child(lbl_cargando)

	var alumno_id = GameManager.id_str(GameManager.usuario_actual.get("id"))
	if alumno_id.is_empty():
		return
	ConexionManager.peticion_get("/pruebas/pendientes/%s" % alumno_id, _on_pendientes)

func _on_pendientes(data, code):
	for hijo in lista_vbox.get_children():
		hijo.queue_free()

	if code == 204 or (data is Array and data.is_empty()):
		var lbl = Label.new()
		lbl.text = "Sin pruebas pendientes"
		lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6, 1))
		lista_vbox.add_child(lbl)
		return

	if code != 200 or not (data is Array):
		var lbl = Label.new()
		lbl.text = "Error al cargar"
		lbl.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
		lista_vbox.add_child(lbl)
		return

	for prueba in data:
		var lbl = Label.new()
		lbl.text = "•  %s" % str(prueba.get("titulo", "Prueba"))
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lista_vbox.add_child(lbl)
