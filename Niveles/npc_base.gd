extends CharacterBody2D

@onready var area_interaccion = $Area2D
var en_zona: bool = false

func _ready():
	area_interaccion.body_entered.connect(_on_body_entered)
	area_interaccion.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "User-PJ":
		en_zona = true
		Notificador.notificar("Presiona [E] o [ENTER] para hablar", Color.CYAN)

func _on_body_exited(body):
	if body.name == "User-PJ":
		en_zona = false

func _input(event):
	if not en_zona:
		return
	if event.is_echo() or not event.is_pressed():
		return
	if not (event.is_action_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_E)):
		return

	if GameManager.es_profesor:
		Notificador.notificar("Los profesores gestionan las pruebas desde el dashboard", Color.ORANGE)
		return

	Notificador.notificar("Abriendo pruebas pendientes...", Color.GOLD)
	get_tree().change_scene_to_file("res://Pantallas/pruebas_pendientes.tscn")
