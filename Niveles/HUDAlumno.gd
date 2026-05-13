extends CanvasLayer

@onready var ui_parent = $UIParent
@onready var panel_tareas = $UIParent/PanelTareas
@onready var progress_bar = $UIParent/XPBarContainer/VBox/ProgressBar
@onready var xp_label = $UIParent/XPBarContainer/VBox/XPLabel
@onready var lista_vbox = $UIParent/PanelTareas/Margen/VBox/ListaTareas
@onready var info_tab = $UIParent/InfoTab

@onready var panel_ranking = $UIParent/PanelRanking
@onready var vbox_lista_ranking = $UIParent/PanelRanking/MargenRanking/VBoxRanking/VBoxLista
@onready var timer_refresh = $UIParent/PanelRanking/TimerRefresh

const TOP_N := 5
const COLOR_TU = Color(1, 0.9, 0.3, 1)        # destacado para "tú"
const COLOR_NORMAL = Color(0.9, 0.9, 0.95, 1)

var hud_visible = true

func _ready():
	ui_parent.visible = true
	$UIParent/XPBarContainer.visible = true
	info_tab.text = "Presiona [TAB] para ocultar tareas"
	info_tab.visible = true

	if GameManager.es_profesor:
		panel_tareas.visible = false
		$UIParent/XPBarContainer.visible = false
		panel_ranking.visible = false
		return

	panel_tareas.visible = true
	_actualizar_xp()
	_cargar_pruebas_pendientes()

	timer_refresh.timeout.connect(_cargar_ranking)
	_cargar_ranking()

	await get_tree().create_timer(1.0).timeout
	var nombre = GameManager.usuario_actual.get("nombreUsuario", "alumno")
	Notificador.notificar("Bienvenido, %s" % nombre, Color.CYAN)

func _input(event):
	if event.is_action_pressed("ui_focus_next"):
		hud_visible = !hud_visible
		panel_tareas.visible = hud_visible
		$UIParent/XPBarContainer.visible = hud_visible
		panel_ranking.visible = hud_visible
		info_tab.text = "Presiona [TAB] para %s tareas" % ("ocultar" if hud_visible else "ver")
		if hud_visible:
			_animar_aparicion()

func _animar_aparicion():
	ui_parent.modulate.a = 0
	create_tween().tween_property(ui_parent, "modulate:a", 1.0, 0.2)

func _actualizar_xp():
	# El backend devuelve null si el alumno aún no tiene nivel/XP iniciados.
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

# =====================================================================
# RANKING (top 5 + tu posición si no estás dentro)
# =====================================================================

func _cargar_ranking():
	var aula_id = GameManager.usuario_actual.get("aulaId")
	if aula_id == null:
		_mostrar_ranking_mensaje("Sin aula asignada")
		return
	ConexionManager.peticion_get("/puntuacion/aula/%s/ranking" % str(int(aula_id)), _on_ranking)

func _on_ranking(data, code):
	if code != 200 or not (data is Array):
		_mostrar_ranking_mensaje("Sin datos")
		return
	for hijo in vbox_lista_ranking.get_children():
		hijo.queue_free()
	if data.is_empty():
		_mostrar_ranking_mensaje("Aula vacía")
		return

	# top 5 + (si tú no estás dentro, añadirte al final)
	var top = data.slice(0, min(TOP_N, data.size()))
	var idx_tuyo_global := -1
	for i in range(data.size()):
		if bool(data[i].get("esTuyo", false)):
			idx_tuyo_global = i
			break

	for entrada in top:
		_anadir_fila_ranking(entrada)

	if idx_tuyo_global >= TOP_N:
		var sep = HSeparator.new()
		vbox_lista_ranking.add_child(sep)
		_anadir_fila_ranking(data[idx_tuyo_global])

func _anadir_fila_ranking(entrada: Dictionary):
	var es_tuyo = bool(entrada.get("esTuyo", false))
	var posicion = int(entrada.get("posicion", 0))
	var nombre = str(entrada.get("nombreUsuario", "alumno"))
	var puntos = int(entrada.get("puntos", 0))

	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)

	var lbl_pos = Label.new()
	lbl_pos.text = "#%d" % posicion
	lbl_pos.custom_minimum_size = Vector2(40, 0)
	lbl_pos.add_theme_color_override("font_color", COLOR_TU if es_tuyo else Color(0, 1, 1, 1))
	lbl_pos.add_theme_font_size_override("font_size", 13)
	fila.add_child(lbl_pos)

	var lbl_nombre = Label.new()
	lbl_nombre.text = ("TÚ · %s" % nombre) if es_tuyo else nombre
	lbl_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_nombre.add_theme_color_override("font_color", COLOR_TU if es_tuyo else COLOR_NORMAL)
	lbl_nombre.add_theme_font_size_override("font_size", 12)
	lbl_nombre.clip_text = true
	fila.add_child(lbl_nombre)

	var lbl_puntos = Label.new()
	lbl_puntos.text = "%d" % puntos
	lbl_puntos.add_theme_color_override("font_color", COLOR_TU if es_tuyo else COLOR_NORMAL)
	lbl_puntos.add_theme_font_size_override("font_size", 12)
	fila.add_child(lbl_puntos)

	vbox_lista_ranking.add_child(fila)

func _mostrar_ranking_mensaje(texto: String):
	for hijo in vbox_lista_ranking.get_children():
		hijo.queue_free()
	var lbl = Label.new()
	lbl.text = texto
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	lbl.add_theme_font_size_override("font_size", 11)
	vbox_lista_ranking.add_child(lbl)
