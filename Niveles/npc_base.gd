extends CharacterBody2D

@onready var area_interaccion = $Area2D
var en_zona: bool = false

func _ready():
	# Conectamos las señales de la zona de interacción
	area_interaccion.body_entered.connect(_on_body_entered)
	area_interaccion.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Validamos que el que entra es el jugador
	if body.name == "User-PJ":
		en_zona = true
		# Usamos el mismo color Cyan del progreso de misiones
		Notificador.notificar("Presiona [E] o [ENTER] para hablar", Color.CYAN)

func _on_body_exited(body):
	if body.name == "User-PJ":
		en_zona = false

func _input(event):
	# Detectamos si estamos en zona y pulsamos la tecla
	if en_zona and (event.is_action_pressed("ui_accept") or event.is_action_pressed("interactuar") or Input.is_physical_key_pressed(KEY_E)):
		# Evitar que se dispare varias veces si se mantiene pulsado
		if not event.is_echo() and event.is_pressed():
			Notificador.notificar("Abriendo panel de misión...", Color.GOLD)
			# TODO: Aquí llamaremos al gestor de misiones en el futuro
