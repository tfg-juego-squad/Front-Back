extends Area2D

var frases: Array[String] = [
	"El agua está congelada, no es buen momento para nadar.",
	"No has traído bañador, mejor seguimos caminando.",
	"Unos extraños tentáculos se asoman por el fondo... aléjate.",
	"Profesor: ¡Eh! ¡Deja de perder el tiempo y vuelve a la tarea!"
]

var indice_frase: int = 0
var puede_avisar: bool = true 

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Jugador") and puede_avisar:
		
		puede_avisar = false
		
		Notificador.notificar(frases[indice_frase], Color.AQUAMARINE)
		
		indice_frase = (indice_frase + 1) % frases.size()
		
		await get_tree().create_timer(3.0).timeout
		puede_avisar = true
