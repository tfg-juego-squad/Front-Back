extends Node

# Safe area inferior: evita que la barra de tareas de Windows tape contenido.
# Hace dos cosas al iniciar y cada vez que cambia la escena principal:
#   1. Ajusta el tamaño/posición de la ventana al área usable del monitor
#      (DisplayServer.screen_get_usable_rect excluye la taskbar).
#   2. Reserva BOTTOM_PX al fondo de la escena actual recorriéndola y
#      detectando el primer container raíz que ocupa toda la pantalla:
#        - MarginContainer → suma BOTTOM_PX a su margin_bottom.
#        - VBoxContainer  → bumpea el último spacer (Control no-Container con
#          altura mínima pequeña) o añade uno propio "_SafeAreaSpacer".
#      Adicionalmente, cualquier Control anclado al borde inferior con
#      offset_bottom negativo (preset 3, 7, 9, etc.) se desplaza BOTTOM_PX
#      hacia arriba para que no quede tapado.

const BOTTOM_PX := 60

func _ready() -> void:
	_ajustar_ventana_a_area_usable()
	get_tree().root.child_entered_tree.connect(_on_nuevo_hijo_en_root)
	call_deferred("_aplicar_safe_area_a_escena_actual")

func _ajustar_ventana_a_area_usable() -> void:
	var modo := DisplayServer.window_get_mode()
	if modo == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN \
			or modo == DisplayServer.WINDOW_MODE_MINIMIZED:
		return
	# Si arranca maximizada, primero pasamos a windowed para poder redimensionar.
	if modo == DisplayServer.WINDOW_MODE_MAXIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var pantalla := DisplayServer.window_get_current_screen()
	var area := DisplayServer.screen_get_usable_rect(pantalla)
	DisplayServer.window_set_size(area.size)
	DisplayServer.window_set_position(area.position)

func _on_nuevo_hijo_en_root(_n: Node) -> void:
	call_deferred("_aplicar_safe_area_a_escena_actual")

func _aplicar_safe_area_a_escena_actual() -> void:
	var escena := get_tree().current_scene
	if escena == null or not is_instance_valid(escena):
		return
	if escena.has_meta("_safe_area_aplicada"):
		return
	escena.set_meta("_safe_area_aplicada", true)
	_recorrer_y_aplicar(escena)

func _recorrer_y_aplicar(nodo: Node) -> void:
	if nodo is Control:
		var c: Control = nodo
		if _es_root_pantalla_completa(c):
			# Caso A: MarginContainer raíz → suma al margin_bottom.
			if c is MarginContainer:
				_bump_margin_bottom(c)
				return
			# Caso B: VBoxContainer raíz → bumpea spacer existente o añade uno.
			if c is VBoxContainer:
				_bump_o_anadir_spacer(c)
				return
			# Otros containers (PanelContainer, Control genérico): seguimos buscando dentro.
		elif c.anchor_bottom == 1.0 and c.offset_bottom < 0.0:
			# Control pegado al borde inferior (preset 3, 7, 9...): empujar arriba.
			c.offset_bottom -= BOTTOM_PX
			if c.anchor_top == 1.0:
				c.offset_top -= BOTTOM_PX
	for hijo in nodo.get_children():
		_recorrer_y_aplicar(hijo)

func _es_root_pantalla_completa(c: Control) -> bool:
	return c.anchor_left == 0.0 and c.anchor_top == 0.0 \
			and c.anchor_right == 1.0 and c.anchor_bottom == 1.0

func _bump_margin_bottom(mc: MarginContainer) -> void:
	var actual := 0
	if mc.has_theme_constant_override("margin_bottom"):
		actual = mc.get_theme_constant("margin_bottom")
	mc.add_theme_constant_override("margin_bottom", actual + BOTTOM_PX)

func _bump_o_anadir_spacer(vbox: VBoxContainer) -> void:
	if vbox.has_node("_SafeAreaSpacer"):
		return
	# Si el último hijo es un Control "spacer" (no es un Container y tiene
	# altura mínima pequeña), simplemente le sumamos altura.
	if vbox.get_child_count() > 0:
		var ultimo := vbox.get_child(vbox.get_child_count() - 1)
		if ultimo is Control and not (ultimo is Container):
			var u: Control = ultimo
			if u.custom_minimum_size.y < 100:
				u.custom_minimum_size.y += BOTTOM_PX
				return
	# Sino, añadimos uno propio.
	var spacer := Control.new()
	spacer.name = "_SafeAreaSpacer"
	spacer.custom_minimum_size = Vector2(0, BOTTOM_PX)
	vbox.add_child(spacer)
