extends CharacterBody2D

const SPEED = 150.0
const COOLDOWN_AVISO_AGUA := 3.0

@onready var sprite = get_node("MoveAnimation")
var _ultimo_aviso_agua: float = -COOLDOWN_AVISO_AGUA

func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()

	if direction != Vector2.ZERO and _esta_chocando_con_agua():
		_avisar_agua()

	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			sprite.play("CaminarDerecha" if direction.x > 0 else "CaminarIzquierda")
		else:
			sprite.play("CaminarAbajo" if direction.y > 0 else "CaminarArriba")
	else:
		sprite.play("Quieto")

func _esta_chocando_con_agua() -> bool:
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider is TileMapLayer and collider.name == "water":
			return true
	return false

func _avisar_agua():
	var ahora = Time.get_ticks_msec() / 1000.0
	if ahora - _ultimo_aviso_agua < COOLDOWN_AVISO_AGUA:
		return
	_ultimo_aviso_agua = ahora
	Notificador.notificar("No puedes meterte en el agua", Color.SKY_BLUE)
