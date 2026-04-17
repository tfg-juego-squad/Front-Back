extends CanvasLayer

# --- Sistema de Notificaciones Global ---
# Estilo Dark Neon & Glassmorphism

var container: VBoxContainer

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	layer = 120
	
	# Contenedor principal alineado arriba a la derecha
	container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	container.anchor_left = 1.0
	container.anchor_right = 1.0
	container.offset_left = -380
	container.offset_right = -20
	container.offset_top = 20
	container.add_theme_constant_override("separation", 12)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE # No bloquea clics
	add_child(container)

func notificar(texto: String, color_neon: Color = Color.CYAN):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 0)
	
	# Estilo Dark Neon Premium
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.9) # Fondo oscuro traslúcido
	style.border_width_left = 5
	style.border_color = color_neon
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(color_neon.r, color_neon.g, color_neon.b, 0.3)
	style.shadow_size = 12
	
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	var label = Label.new()
	label.text = texto
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 14)
	margin.add_child(label)
	
	container.add_child(panel)
	
	# Animación de entrada por Fade y Scale
	panel.modulate.a = 0
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = Vector2(175, 25) # Centro aproximado para el escalado
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(panel, "scale", Vector2(1, 1), 0.4)
	
	# Espera
	tween.set_parallel(false)
	tween.tween_interval(3.5)
	
	# Salida
	tween.tween_property(panel, "modulate:a", 0.0, 0.6)
	tween.tween_callback(panel.queue_free)
