extends CharacterBody2D

# id del NPC dentro del catálogo (NpcManager.NPCS). Cámbialo en el inspector
# en cada NPC del nivel para que muestre solo las pruebas que le tocan.
@export var npc_id: String = "npc_general"

@onready var area_interaccion = $Area2D
var en_zona: bool = false

func _ready():
	area_interaccion.body_entered.connect(_on_body_entered)
	area_interaccion.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "User-PJ":
		en_zona = true
		var npc = NpcManager.buscar_npc(npc_id)
		var saludo = "Presiona [E] o [ENTER] para hablar"
		if not npc.is_empty():
			saludo = "%s · Pulsa [E] para hablar" % npc.get("nombre", "NPC")
		Notificador.notificar(saludo, Color.CYAN)

func _on_body_exited(body):
	if body.name == "User-PJ":
		en_zona = false

func _input(event):
	if not en_zona:
		return
	if event.is_echo() or not event.is_pressed():
		return
	var es_tecla_e = event is InputEventKey and event.physical_keycode == KEY_E
	if not (event.is_action_pressed("ui_accept") or es_tecla_e):
		return

	if GameManager.es_profesor:
		Notificador.notificar("Los profesores gestionan las pruebas desde el dashboard", Color.ORANGE)
		return

	NpcManager.set_npc_activo(npc_id)
	Notificador.notificar("Abriendo pruebas pendientes...", Color.GOLD)
	get_tree().change_scene_to_file("res://Pantallas/pruebas_pendientes.tscn")
