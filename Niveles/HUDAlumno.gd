extends CanvasLayer

@onready var ui_parent = $UIParent
@onready var panel_tareas = $UIParent/PanelTareas
@onready var progress_bar = $UIParent/XPBarContainer/VBox/ProgressBar
@onready var lista_vbox = $UIParent/PanelTareas/Margen/VBox/ListaTareas
@onready var info_tab = $UIParent/InfoTab

var hud_visible = true

func _ready():
	ui_parent.visible = true
	panel_tareas.visible = true
	$UIParent/XPBarContainer.visible = true
	info_tab.text = "Presiona [TAB] para ocultar tareas"
	info_tab.visible = true
	
	_simular_tareas()
	
	await get_tree().create_timer(1.0).timeout
	Notificador.notificar("Bienvenido al Nivel 1", Color.CYAN)

func _input(event):
	if event.is_action_pressed("ui_focus_next"):
		hud_visible = !hud_visible
		panel_tareas.visible = hud_visible
		$UIParent/XPBarContainer.visible = hud_visible
		info_tab.text = "Presiona [TAB] para %s tareas" % ("ocultar" if hud_visible else "ver")
		if hud_visible:
			_animar_aparicion()

func _animar_aparicion():
	ui_parent.modulate.a = 0
	create_tween().tween_property(ui_parent, "modulate:a", 1.0, 0.2)

# TODO: Cambiar por peticion al backend cuando haya endpoint de tareas
func _simular_tareas():
	var tareas = [
		["Matematicas: Sumas", true],
		["Lengua: Vocales", false],
		["Ciencias: Plantas", false]
	]
	
	var completadas = 0
	for t in tareas:
		var lbl = Label.new()
		var check = "[X] " if t[1] else "[  ] "
		lbl.text = check + t[0]
		lbl.add_theme_color_override("font_color", Color.GRAY if t[1] else Color.WHITE)
		lista_vbox.add_child(lbl)
		if t[1]:
			completadas += 1
	
	progress_bar.value = (float(completadas) / tareas.size()) * 100
