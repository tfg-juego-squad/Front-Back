extends Control

# --- Referencias UI ---
@onready var nombre_input = $Layout/Centro/Panel/Margen/VBox/NombreInput
@onready var descripcion_input = $Layout/Centro/Panel/Margen/VBox/DescripcionInput
@onready var puntuacion_input = $Layout/Centro/Panel/Margen/VBox/HBoxPuntuacion/PuntuacionInput
@onready var btn_guardar = $Layout/Centro/Panel/Margen/VBox/BtnGuardar
@onready var btn_volver = $Layout/Header/HBoxHeader/BtnVolver
@onready var mensaje = $Layout/Centro/Panel/Margen/VBox/Mensaje

func _ready():
	btn_guardar.pressed.connect(_on_guardar)
	btn_volver.pressed.connect(_on_volver)

func _on_guardar():
	var nombre = nombre_input.text.strip_edges()
	var descripcion = descripcion_input.text.strip_edges()
	var puntuacion = puntuacion_input.text.strip_edges()
	
	# Validacion basica
	if nombre.is_empty():
		mensaje.text = "El nombre es obligatorio"
		mensaje.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		return
	
	if puntuacion.is_empty() or not puntuacion.is_valid_int():
		mensaje.text = "La puntuacion debe ser un numero"
		mensaje.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		return
	
	# TODO: Enviar al backend (POST /tfg/prueba/alta)
	# var body = {
	#     "nombre": nombre,
	#     "descripcion": descripcion,
	#     "puntuacionMaxima": int(puntuacion)
	# }
	
	mensaje.text = "Entrega creada correctamente: " + nombre
	mensaje.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
	
	# Limpiar campos
	nombre_input.text = ""
	descripcion_input.text = ""
	puntuacion_input.text = ""

func _on_volver():
	get_tree().change_scene_to_file("res://Pantallas/profesor_dashboard.tscn")
