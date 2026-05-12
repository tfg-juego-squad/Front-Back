extends Control

# Vista de solo lectura para que el profesor vea cómo se mostrará una prueba
# antes de enviarla al backend. NO hace peticiones: navega por la lista de
# preguntas que le pasa el constructor.

@onready var titulo = $Centro/Panel/Margen/VBox/Titulo
@onready var progreso = $Centro/Panel/Margen/VBox/HBoxInfo/Progreso
@onready var tiempo_label = $Centro/Panel/Margen/VBox/HBoxInfo/TiempoLabel
@onready var timer_bar = $Centro/Panel/Margen/VBox/TimerBar
@onready var enunciado = $Centro/Panel/Margen/VBox/Enunciado
@onready var valor_label = $Centro/Panel/Margen/VBox/ValorLabel
@onready var opciones_test = $Centro/Panel/Margen/VBox/OpcionesTest
@onready var respuesta_desarrollo = $Centro/Panel/Margen/VBox/RespuestaDesarrollo
@onready var btn_cerrar = $Centro/Panel/Margen/VBox/HBoxBotones/BtnCerrar
@onready var btn_anterior = $Centro/Panel/Margen/VBox/HBoxBotones/BtnAnterior
@onready var btn_siguiente = $Centro/Panel/Margen/VBox/HBoxBotones/BtnSiguiente

const TIPO_TEST = "TEST"
const TIPO_DESARROLLO = "DESARROLLO"
const TIEMPO_POR_DEFECTO_SEG := 30

var prueba_titulo: String = ""
var preguntas: Array = []
var indice_actual: int = 0
var tiempo_limite_seg: int = TIEMPO_POR_DEFECTO_SEG
var pregunta_iniciada_en: float = 0.0

func cargar_preview(titulo_prueba: String, lista_preguntas: Array):
	prueba_titulo = titulo_prueba if not titulo_prueba.is_empty() else "Prueba sin título"
	preguntas = lista_preguntas

func _ready():
	btn_cerrar.pressed.connect(_on_cerrar)
	btn_anterior.pressed.connect(_anterior)
	btn_siguiente.pressed.connect(_siguiente)
	titulo.text = prueba_titulo
	if preguntas.is_empty():
		enunciado.text = "Sin preguntas para previsualizar"
		btn_anterior.disabled = true
		btn_siguiente.disabled = true
		return
	indice_actual = 0
	_mostrar_pregunta_actual()

func _mostrar_pregunta_actual():
	var p = preguntas[indice_actual]
	progreso.text = "Pregunta %d / %d" % [indice_actual + 1, preguntas.size()]
	enunciado.text = str(p.get("enunciado", ""))
	var valor = int(p.get("valorPuntos", 0))
	valor_label.text = "Vale %d puntos" % valor if valor > 0 else ""

	for hijo in opciones_test.get_children():
		hijo.queue_free()

	var tipo = str(p.get("tipo", "")).to_upper()
	if tipo == TIPO_TEST:
		opciones_test.visible = true
		respuesta_desarrollo.visible = false
		var grupo = ButtonGroup.new()
		for resp in p.get("respuestasPosibles", []):
			var btn = CheckBox.new()
			# Mostramos también si el profesor la marcó como correcta
			var marca_correcta = " ✓" if resp.get("esCorrecta", false) else ""
			btn.text = "%s%s" % [str(resp.get("texto", "")), marca_correcta]
			btn.button_group = grupo
			btn.disabled = true
			opciones_test.add_child(btn)
	else:
		opciones_test.visible = false
		respuesta_desarrollo.visible = true
		respuesta_desarrollo.editable = false
		respuesta_desarrollo.text = ""

	tiempo_limite_seg = int(p.get("tiempoLimiteSegundos", TIEMPO_POR_DEFECTO_SEG))
	if tiempo_limite_seg <= 0:
		tiempo_limite_seg = TIEMPO_POR_DEFECTO_SEG
	timer_bar.max_value = tiempo_limite_seg
	timer_bar.value = tiempo_limite_seg
	pregunta_iniciada_en = Time.get_unix_time_from_system()

	btn_anterior.disabled = indice_actual == 0
	btn_siguiente.disabled = indice_actual >= preguntas.size() - 1

func _process(_delta):
	if preguntas.is_empty():
		return
	var restante = tiempo_limite_seg - int(Time.get_unix_time_from_system() - pregunta_iniciada_en)
	restante = max(restante, 0)
	timer_bar.value = restante
	tiempo_label.text = "%ds" % restante

func _anterior():
	if indice_actual > 0:
		indice_actual -= 1
		_mostrar_pregunta_actual()

func _siguiente():
	if indice_actual < preguntas.size() - 1:
		indice_actual += 1
		_mostrar_pregunta_actual()

func _on_cerrar():
	get_tree().change_scene_to_file("res://Pantallas/nueva_entrega.tscn")
