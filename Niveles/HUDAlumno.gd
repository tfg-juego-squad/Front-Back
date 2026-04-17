extends CanvasLayer

@onready var ui_parent = $UIParent
@onready var panel_tareas = $UIParent/PanelTareas
@onready var progress_bar = $UIParent/XPBarContainer/VBox/ProgressBar
@onready var lista_vbox = $UIParent/PanelTareas/Margen/VBox/ListaTareas
@onready var info_tab = $UIParent/InfoTab

var hud_visible = true # Cambiado a true por defecto

func _ready():
	# El HUD está visible por defecto ahora
	ui_parent.visible = true
	panel_tareas.visible = true
	$UIParent/XPBarContainer.visible = true
	
	# El mensaje indica cómo ocultar
	info_tab.text = "Presiona [TAB] para ocultar tareas"
	info_tab.visible = true
	
	_simular_tareas()
	
	# Notificamos al entrar
	await get_tree().create_timer(1.0).timeout
	Notificador.notificar("¡Bienvenido al Nivel 1!", Color.CYAN)

func _input(event):
	if event.is_action_pressed("ui_focus_next"): # Tecla TAB
		hud_visible = !hud_visible
		
		if hud_visible:
			panel_tareas.visible = true
			$UIParent/XPBarContainer.visible = true
			info_tab.text = "Presiona [TAB] para ocultar tareas"
			_animar_aparicion()
		else:
			panel_tareas.visible = false
			$UIParent/XPBarContainer.visible = false
			info_tab.text = "Presiona [TAB] para ver tareas"

func _animar_aparicion():
	ui_parent.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(ui_parent, "modulate:a", 1.0, 0.2)

func _simular_tareas():
	var tareas = [
		["Matemáticas: Sumas", true],
		["Lengua: Vocales", false],
		["Ciencias: Plantas", false]
	]
	
	var completadas = 0
	for t in tareas:
		var lbl = Label.new()
		var check = "[X] " if t[1] else "[  ] "
		lbl.text = check + t[0]
		
		if t[1]:
			lbl.add_theme_color_override("font_color", Color.GRAY)
			completadas += 1
		else:
			lbl.add_theme_color_override("font_color", Color.WHITE)
			
		lista_vbox.add_child(lbl)
	
	# Calcular progreso porcentual
	var progreso = (float(completadas) / tareas.size()) * 100
	progress_bar.value = progreso
