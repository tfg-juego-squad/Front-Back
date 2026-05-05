extends CharacterBody2D

const SPEED = 150.0

@onready var sprite = get_node("AnimatedSprite2D")

func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()

	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			sprite.play("CaminarDerecha" if direction.x > 0 else "CaminarIzquierda")
		else:
			sprite.play("CaminarAbajo" if direction.y > 0 else "CaminarArriba")
	else:
		sprite.play("Quieto")
